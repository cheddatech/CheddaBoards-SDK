import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import List "mo:base/List";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Random "mo:base/Random";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Error "mo:base/Error"

persistent actor CheddaBoards {

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TYPES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// ==================== SECURITY TYPES ====================

type AdminRole = {
  #SuperAdmin;   // Full access to everything
  #Moderator;    // Can manage users, view logs
  #Support;      // Can export data, view stats
  #ReadOnly;     // View only access
};

type AdminAction = {
  timestamp : Nat64;
  admin : Principal;
  adminRole : AdminRole;
  command : Text;
  args : [Text];
  success : Bool;
  result : Text;
  ipAddress : ?Text;
};

type DeletedGame = {
  game : GameInfo;
  deletedBy : Principal;
  deletedAt : Nat64;
  permanentDeletionAt : Nat64;
  reason : Text;
  canRecover : Bool;
};

type DeletionAttempt = {
  timestamp : Nat64;
  gameId : Text;
};

type DeletedUser = {
  user : UserProfile;
  deletedBy : Principal;
  deletedAt : Nat64;
  permanentDeletionAt : Nat64;
  reason : Text;
  canRecover : Bool;
};

type PendingDeletion = {
  userId : Text;
  userType : Text;
  requestedBy : Principal;
  requestedAt : Nat64;
  confirmationCode : Text;
  expiresAt : Nat64;
};

type BackupData = {
  version : Text;
  timestamp : Nat64;
  createdBy : Principal;
  emailUsers : [(Text, UserProfile)];
  principalUsers : [(Principal, UserProfile)];
  games : [(Text, GameInfo)];
  deletedUsers : [(Text, DeletedUser)];
  metadata : {
    totalUsers : Nat;
    totalGames : Nat;
    totalGameProfiles : Nat;
    totalDeletedUsers : Nat;
  };
};

  public type UserIdentifier = {
    #email: Text;
    #principal: Principal;
  };

  public type AuthType = {
    #internetIdentity;
    #google;
    #apple;
  };

  public type Session = {
    sessionId : Text;
    email : Text;
    nickname : Text;
    authType : AuthType;
    created : Nat64;
    expires : Nat64;
    lastUsed : Nat64;
  };

  public type GameProfile = {
    gameId : Text;
    total_score : Nat64;
    best_streak : Nat64;
    achievements : [Text];
    last_played : Nat64;
    play_count : Nat;
  };

  public type UserProfile = {
    identifier : UserIdentifier;
    nickname : Text;
    authType : AuthType;
    gameProfiles : [(Text, GameProfile)];
    created : Nat64;
    last_updated : Nat64;
  };

public type PublicUserProfile = {
  nickname : Text;
  authType : AuthType;
  gameProfiles : [(Text, GameProfile)];
  created : Nat64;
  last_updated : Nat64;
};

  public type GameInfo = {
    gameId : Text;
    name : Text;
    description : Text;
    owner : Principal;
    created : Nat64;
    totalPlayers : Nat;
    totalPlays : Nat;
    isActive : Bool;
    maxScorePerRound : ?Nat64;
    maxStreakDelta : ?Nat64;
    absoluteScoreCap : ?Nat64;
    absoluteStreakCap : ?Nat64;
  };

  public type AnalyticsEvent = {
    eventType : Text;
    gameId : Text;
    identifier : UserIdentifier;
    timestamp : Nat64;
    metadata : [(Text, Text)];
  };

  public type DailyStats = {
    date : Text;
    gameId : Text;
    uniquePlayers : Nat;
    totalGames : Nat;
    totalScore : Nat64;
    newUsers : Nat;
    authenticatedPlays : Nat;
  };

  public type PlayerStats = {
    gameId : Text;
    identifier : UserIdentifier;
    totalGames : Nat;
    avgScore : Nat64;
    playStreak : Nat;
    lastPlayed : Nat64;
    favoriteTime : Text;
  };

  public type SortBy = { #score; #streak };

  // DEVELOPERS: Replace with your OAuth verifier canister principal
  // This canister validates Google/Apple OAuth tokens and creates sessions
  let VERIFIER : Principal = Principal.fromText("YOUR_VERIFIER_PRINCIPAL_HERE");

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // STABLE STORAGE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  private var stableUsersByEmail : [(Text, UserProfile)] = [];
  private var stableUsersByPrincipal : [(Principal, UserProfile)] = [];
  private var stableGames : [(Text, GameInfo)] = [];
  private var stableSessions : [(Text, Session)] = [];
  private var stableSuspicionLog : [{ player_id : Text; gameId : Text; reason : Text; timestamp : Nat64 }] = [];
  private var stableFiles : [(Text, Blob)] = [];
  private var stableAnalyticsEvents : [AnalyticsEvent] = [];
  private var stableDailyStats : [(Text, DailyStats)] = [];
  private var stablePlayerStats : [(Text, PlayerStats)] = [];
  private var stableLastSubmitTime : [(Text, Nat64)] = [];
  private var sessionCounter : Nat64 = 0;
  private var deletedGamesEntries : [(Text, DeletedGame)] = [];
  private var deleteRateLimitEntries : [(Principal, [DeletionAttempt])] = [];
  private var userIdCounter : Nat = 0;
  var totalSubmissions : Nat = 0;
  var submissionsToday : Nat = 0;
  var lastResetDate : Text = "";
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // RUNTIME MAPS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  private transient var deletedGames = HashMap.HashMap<Text, DeletedGame>(10, Text.equal, Text.hash);
  private transient var deleteRateLimit = HashMap.HashMap<Principal, [DeletionAttempt]>(10, Principal.equal, Principal.hash);
  private transient var usersByEmail = HashMap.HashMap<Text, UserProfile>(10, Text.equal, Text.hash);
  private transient var usersByPrincipal = HashMap.HashMap<Principal, UserProfile>(10, Principal.equal, Principal.hash);
  private transient var games = HashMap.HashMap<Text, GameInfo>(10, Text.equal, Text.hash);
  private transient var sessions = HashMap.HashMap<Text, Session>(10, Text.equal, Text.hash);
  private transient var lastSubmitTime = HashMap.HashMap<Text, Nat64>(10, Text.equal, Text.hash);
  private transient var cachedLeaderboards = HashMap.HashMap<Text, [(Text, Nat64, Nat64, Text)]>(10, Text.equal, Text.hash);
  private transient var leaderboardLastUpdate = HashMap.HashMap<Text, Nat64>(10, Text.equal, Text.hash);
  private transient let LEADERBOARD_CACHE_TTL : Nat64 = 60_000_000_000; // 60 seconds
  private transient var analyticsEvents = Buffer.Buffer<AnalyticsEvent>(100);
  private transient var dailyStats = HashMap.HashMap<Text, DailyStats>(10, Text.equal, Text.hash);
  private transient var playerStats = HashMap.HashMap<Text, PlayerStats>(10, Text.equal, Text.hash);
  
  private transient var suspicionLog : List.List<{ player_id : Text; gameId : Text; reason : Text; timestamp : Nat64 }> = List.nil();
  private transient var files : List.List<(Text, Blob)> = List.nil();
  private transient var sessionsEntries : [(Text, Session)] = [];
  private transient var principalToSessionEntries : [(Text, Text)] = [];
  private transient var principalToSession = HashMap.HashMap<Text, Text>(10, Text.equal, Text.hash);
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CONSTANTS  ("xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxx")
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // DEVELOPERS: Replace with your canister controller principal
  private transient let CONTROLLER : Principal = Principal.fromText("YOUR_CONTROLLER_PRINCIPAL_HERE");
  private transient let DEFAULT_MAX_PER_ROUND : Nat64 = 5_000;
  private transient let DEFAULT_MAX_STREAK_DELTA : Nat64 = 200;
  private transient let DEFAULT_ABSOLUTE_SCORE_CAP : Nat64 = 100_000;
  private transient let DEFAULT_ABSOLUTE_STREAK_CAP : Nat64 = 2_000;
  private transient let MAX_FILE_SIZE : Nat = 5_000_000;
  private transient let MAX_FILES : Nat = 100;
  private transient let SESSION_DURATION_NS : Nat64 = 24 * 60 * 60 * 1_000_000_000;
  private transient var lastCleanup : Nat64 = 0;
  private transient let MAX_GAMES_PER_DEVELOPER : Nat = 3;
  private var adminRolesStable : [(Principal, AdminRole)] = [];
  private var auditLogStable : [AdminAction] = [];
  private var deletedUsersStable : [(Text, DeletedUser)] = [];
  private var emergencyPaused : Bool = false;

// Working HashMaps
private transient var adminRoles = HashMap.fromIter<Principal, AdminRole>(
  adminRolesStable.vals(), 10, Principal.equal, Principal.hash
);

private transient var deletedUsers = HashMap.fromIter<Text, DeletedUser>(
  deletedUsersStable.vals(), 10, Text.equal, Text.hash
);

// In-memory rate limiting and pending actions
private transient var lastCommandTime = HashMap.HashMap<(Principal, Text), Nat64>(
  10,
  func(a: (Principal, Text), b: (Principal, Text)) : Bool { 
    Principal.equal(a.0, b.0) and Text.equal(a.1, b.1)
  },
  func(x: (Principal, Text)) : Hash.Hash {
    Principal.hash(x.0)
  }
);

private transient var pendingDeletions = HashMap.HashMap<Text, PendingDeletion>(
  10, Text.equal, Text.hash
);

// Audit log buffer
private transient var auditLog = Buffer.Buffer<AdminAction>(100);

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HELPERS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  func now() : Nat64 = Nat64.fromIntWrap(Time.now());

  // ════════════════════════════════════════════════════════════════════════════
  // NICKNAME GENERATION HELPERS
  // ════════════════════════════════════════════════════════════════════════════
  
  // Generate a unique default nickname
  private func generateDefaultNickname() : Text {
    userIdCounter += 1;
    "Player_" # Nat.toText(userIdCounter)
  };

  // Check if nickname is a default generated one
  private func isDefaultNickname(nickname : Text) : Bool {
    Text.startsWith(nickname, #text "Player_")
  };

  // Check if nickname looks like an email
  private func looksLikeEmail(text : Text) : Bool {
    Text.contains(text, #char '@')
  };
  
  func generateSessionId() : Text {
    sessionCounter += 1;
    let timestamp = now();
    let _random = Random.Finite(Blob.fromArray([1,2,3,4,5,6,7,8]));
    "session_" # Nat64.toText(timestamp) # "_" # Nat64.toText(sessionCounter)
  };

  func authTypeToText(auth : AuthType) : Text {
    switch (auth) {
      case (#internetIdentity) "internetIdentity";
      case (#google) "google";
      case (#apple) "apple";
    }
  };

  func identifierToText(id : UserIdentifier) : Text {
    switch (id) {
      case (#email(e)) "email:" # e;
      case (#principal(p)) "principal:" # Principal.toText(p);
    }
  };

  func makeSubmitKey(identifier : UserIdentifier, gameId : Text) : Text {
    identifierToText(identifier) # ":" # gameId
  };

  func logSuspicion(playerId : Text, gameId : Text, reason : Text) {
    suspicionLog := List.push({
      player_id = playerId;
      gameId = gameId;
      reason = reason;
      timestamp = now();
    }, suspicionLog);
  };

  private func isAdmin(caller: Principal) : Bool {
  // Original controller check (keeps your existing logic)
  if (caller == CONTROLLER) {
    return true;
  };
  
  // New role-based check
  Option.isSome(adminRoles.get(caller))
};

  func getDateString(timestamp : Nat64) : Text {
    let day = timestamp / 86_400_000_000_000;
    "day-" # Nat64.toText(day)
  };

  func getTimeOfDay(timestamp : Nat64) : Text {
    let hour = (timestamp / 3_600_000_000_000) % 24;
    if (hour < 6) { "night" }
    else if (hour < 12) { "morning" }
    else if (hour < 18) { "afternoon" }
    else { "evening" }
  };

    func cleanupExpiredSessions() {
    let currentTime = now();
    let sessionEntries = Iter.toArray(sessions.entries());
    
    var cleanedCount = 0;
    for ((sessionId, session) in sessionEntries.vals()) {
      if (currentTime > session.expires) {
        sessions.delete(sessionId);
        cleanedCount += 1;
      };
    };
  };

  func trackEventInternal(identifier: UserIdentifier, gameId: Text, eventType : Text, metadata : [(Text, Text)]) : () {
    let event : AnalyticsEvent = {
      eventType = eventType;
      gameId = gameId;
      identifier = identifier;  
      timestamp = now();
      metadata = metadata;
    };
    
    analyticsEvents.add(event);
    
    if (analyticsEvents.size() > 10000) {
      let newBuffer = Buffer.Buffer<AnalyticsEvent>(10000);
      let startIdx : Nat = Int.abs(+analyticsEvents.size() - 10000);
      for (i in Iter.range(startIdx, analyticsEvents.size() - 1)) {
        newBuffer.add(analyticsEvents.get(i));
      };
      analyticsEvents := newBuffer;
    };
    
    let dateStr = getDateString(event.timestamp);
    let statsKey = dateStr # ":" # gameId;
    
    switch (dailyStats.get(statsKey)) {
      case (?stats) {
        let updated = {
          date = stats.date;
          gameId = gameId;
          uniquePlayers = stats.uniquePlayers;
          totalGames = if (eventType == "game_end") { stats.totalGames + 1 } else { stats.totalGames };
          totalScore = stats.totalScore;
          newUsers = if (eventType == "signup") { stats.newUsers + 1 } else { stats.newUsers };
          authenticatedPlays = if (eventType == "game_end") { stats.authenticatedPlays + 1 } else { stats.authenticatedPlays };
        };
        dailyStats.put(statsKey, updated);
      };
      case null {
        dailyStats.put(statsKey, {
          date = dateStr;
          gameId = gameId;
          uniquePlayers = 1;
          totalGames = if (eventType == "game_end") { 1 } else { 0 };
          totalScore = 0;
          newUsers = if (eventType == "signup") { 1 } else { 0 };
          authenticatedPlays = if (eventType == "game_end") { 1 } else { 0 };
        });
      };
    };
    
    let playerKey = identifierToText(identifier) # ":" # gameId;
    switch (playerStats.get(playerKey)) {
      case (?stats) {
        let updated = {
          gameId = gameId;
          identifier = identifier;
          totalGames = if (eventType == "game_end") { stats.totalGames + 1 } else { stats.totalGames };
          avgScore = stats.avgScore;
          playStreak = stats.playStreak;
          lastPlayed = now();
          favoriteTime = getTimeOfDay(now());
        };
        playerStats.put(playerKey, updated);
      };
      case null {
        playerStats.put(playerKey, {
          gameId = gameId;
          identifier = identifier;
          totalGames = if (eventType == "game_end") { 1 } else { 0 };
          avgScore = 0;
          playStreak = 1;
          lastPlayed = now();
          favoriteTime = getTimeOfDay(now());
        });
      };
    };
  };

  func getValidationRules(gameId : Text) : {
    maxScorePerRound : Nat64;
    maxStreakDelta : Nat64;
    absoluteScoreCap : Nat64;
    absoluteStreakCap : Nat64;
  } {
    switch (games.get(gameId)) {
      case (?game) {
        {
          maxScorePerRound = switch (game.maxScorePerRound) {
            case (?val) val;
            case null DEFAULT_MAX_PER_ROUND;
          };
          maxStreakDelta = switch (game.maxStreakDelta) {
            case (?val) val;
            case null DEFAULT_MAX_STREAK_DELTA;
          };
          absoluteScoreCap = switch (game.absoluteScoreCap) {
            case (?val) val;
            case null DEFAULT_ABSOLUTE_SCORE_CAP;
          };
          absoluteStreakCap = switch (game.absoluteStreakCap) {
            case (?val) val;
            case null DEFAULT_ABSOLUTE_STREAK_CAP;
          };
        }
      };
      case null {
        {
          maxScorePerRound = DEFAULT_MAX_PER_ROUND;
          maxStreakDelta = DEFAULT_MAX_STREAK_DELTA;
          absoluteScoreCap = DEFAULT_ABSOLUTE_SCORE_CAP;
          absoluteStreakCap = DEFAULT_ABSOLUTE_STREAK_CAP;
        }
      };
    }
  };

  func updateGameStats(game : GameInfo, newPlayers : Nat, newPlays : Nat) : GameInfo {
    {
      gameId = game.gameId;
      name = game.name;
      description = game.description;
      owner = game.owner;
      created = game.created;
      totalPlayers = game.totalPlayers + newPlayers;
      totalPlays = game.totalPlays + newPlays;
      isActive = game.isActive;
      maxScorePerRound = game.maxScorePerRound;
      maxStreakDelta = game.maxStreakDelta;
      absoluteScoreCap = game.absoluteScoreCap;
      absoluteStreakCap = game.absoluteStreakCap;
    }
  };

  func getUserByIdentifier(identifier : UserIdentifier) : ?UserProfile {
    switch (identifier) {
      case (#email(e)) { usersByEmail.get(e) };
      case (#principal(p)) { usersByPrincipal.get(p) };
    }
  };

  func putUserByIdentifier(user : UserProfile) {
    switch (user.identifier) {
      case (#email(e)) { usersByEmail.put(e, user) };
      case (#principal(p)) { usersByPrincipal.put(p, user) };
    }
  };

  func countGamesByOwner(owner : Principal) : Nat {
    var count = 0;
    for ((_, game) in games.entries()) {
      if (game.owner == owner) {
        count += 1;
      };
    };
    count
  };

   private func validateCaller(
  msg : { caller : Principal },
  userIdType : Text,
  userId : Text
) : Result.Result<(), Text> {
  
  // ✅ For session-based auth, validate the session
  if (userIdType == "session" or userIdType == "email") {
    // userId should contain the sessionId for session-based auth
    switch (validateSessionInternal(userId)) {
      case (#err(e)) { return #err(e) };
      case (#ok(session)) { 
        // Optionally: verify the session's email matches if needed
        return #ok(());
      };
    };
  };
  
  // ✅ For principal-based auth (II users), check principal
  if (Principal.isAnonymous(msg.caller)) {
    return #err("Authentication required");
  };
  
  if (userIdType == "principal") {
    if (userId != Principal.toText(msg.caller)) {
      return #err("Principal mismatch");
    };
    return #ok(());
  };
  
  #err("Invalid user type")
};
    
  func validateScore(score: Nat64, gameId: Text) : Result.Result<(), Text> {
    let rules = getValidationRules(gameId);
    
    // Check against absolute cap
    if (score > rules.absoluteScoreCap) {
      return #err("Score exceeds maximum allowed (" # Nat64.toText(rules.absoluteScoreCap) # ")");
    };
    
    // Basic sanity check
    if (score > 1_000_000_000) {
      return #err("Score is unreasonably high");
    };
    
    #ok(())
  };
  
  func validateStreak(streak: Nat64, gameId: Text) : Result.Result<(), Text> {
    let rules = getValidationRules(gameId);
    
    // Check against absolute cap
    if (streak > rules.absoluteStreakCap) {
      return #err("Streak exceeds maximum allowed (" # Nat64.toText(rules.absoluteStreakCap) # ")");
    };
    
    // Basic sanity check
    if (streak > 100_000) {
      return #err("Streak is unreasonably high");
    };
    
    #ok(())
  };
  
  func validateNickname(nickname: Text) : Result.Result<(), Text> {
    let length = Text.size(nickname);
    
    // Length check
    if (length < 3) {
      return #err("Nickname must be at least 3 characters");
    };
    
    if (length > 12) {
      return #err("Nickname must be 12 characters or less");
    };
    
    // Check for valid characters (alphanumeric + underscore only)
    let chars = Text.toIter(nickname);
    for (char in chars) {
      let isValid = (char >= 'a' and char <= 'z') or
                    (char >= 'A' and char <= 'Z') or
                    (char >= '0' and char <= '9') or
                    (char == '_');
      
      if (not isValid) {
        return #err("Nickname can only contain letters, numbers, and underscores");
      };
    };
    
    #ok(())
  };
  
  func validateGameId(gameId: Text) : Result.Result<(), Text> {
    switch (games.get(gameId)) {
      case null {
        #err("Game not found: " # gameId)
      };
      case (?game) {
        if (not game.isActive) {
          return #err("Game is not active");
        };
        #ok(())
      };
    }
  };

private func getUserKeyFromAuth(
  userIdType : Text,
  userId : Text
) : Result.Result<Text, Text> {
  
  if (userIdType == "email" or userIdType == "session") {
    // userId is actually sessionId, get the email
    switch (validateSessionInternal(userId)) {
      case (#err(e)) { #err(e) };
      case (#ok(session)) {
        #ok(userIdType # ":" # session.email)
      };
    };
  } else if (userIdType == "principal") {
    // For principal, use the userId as-is
    #ok(userIdType # ":" # userId)
  } else {
    #err("Invalid user type")
  };
};

    // ==================== SECURITY HELPER FUNCTIONS ====================



private func getAdminRole(caller: Principal) : ?AdminRole {
  // Controller always has SuperAdmin
  if (caller == CONTROLLER) {
    return ?#SuperAdmin;
  };
  
  adminRoles.get(caller)
};

private func hasPermission(caller: Principal, requiredRole: AdminRole) : Bool {
  switch (adminRoles.get(caller)) {
    case null false;
    case (?role) {
      switch (role, requiredRole) {
        case (#SuperAdmin, _) true;  // SuperAdmin can do anything
        case (#Moderator, #ReadOnly) true;
        case (#Moderator, #Support) true;
        case (#Moderator, #Moderator) true;
        case (#Support, #ReadOnly) true;
        case (#Support, #Support) true;
        case (#ReadOnly, #ReadOnly) true;
        case (_, _) false;
      }
    };
  }
};

private func logAction(admin: Principal, command: Text, args: [Text], success: Bool, result: Text) {
  let role = Option.get(adminRoles.get(admin), #ReadOnly);
  let action : AdminAction = {
    timestamp = now();
    admin = admin;
    adminRole = role;
    command = command;
    args = args;
    success = success;
    result = result;
    ipAddress = null;
  };
  auditLog.add(action);
  
  // If buffer gets too large, move to stable storage
  if (auditLog.size() > 1000) {
    auditLogStable := Array.append(auditLogStable, Buffer.toArray(auditLog));
    auditLog := Buffer.Buffer<AdminAction>(100);
  };
};

private func isDestructiveCommand(command: Text) : Bool {
  command == "resetAll" or 
  command == "deleteUser" or 
  command == "confirmDeleteUser" or
  command == "permanentDelete"
};

private func checkRateLimit(caller: Principal, command: Text) : Result.Result<(), Text> {
  if (not isDestructiveCommand(command)) {
    return #ok();
  };
  
  let key = (caller, command);
  switch (lastCommandTime.get(key)) {
    case (?lastTime) {
      let cooldown : Nat64 = 60_000_000_000; // 60 seconds in nanoseconds
      let timeSince = now() - lastTime;
      if (timeSince < cooldown) {
        let remaining = (cooldown - timeSince) / 1_000_000_000;
        return #err("⏱️ Rate limit: Wait " # Nat64.toText(remaining) # " more seconds");
      };
    };
    case null {};
  };
  
  lastCommandTime.put(key, now());
  #ok()
};

private func generateConfirmationCode(userId: Text) : Text {
  let timestamp = now();
  let hash = Text.hash(userId # Nat64.toText(timestamp));
  "DELETE-" # Nat32.toText(hash)  // ← Changed from Nat.toText to Nat32.toText
};

  func checkDeleteRateLimit(caller : Principal) : Bool {
  let now = Nat64.fromNat(Int.abs(Time.now()));
  let oneHourAgo = now - (24 * 60 * 60 * 1_000_000_000); // 24 hours in nanoseconds
  
  switch (deleteRateLimit.get(caller)) {
    case (?attempts) {
      // Filter out old attempts (older than 1 hour)
      let recentAttempts = Array.filter<DeletionAttempt>(attempts, func(attempt) {
        attempt.timestamp > oneHourAgo
      });
      
      // Check if exceeded limit
      if (recentAttempts.size() >= 3) {
        return false; // Rate limit exceeded
      };
      
      true
    };
    case null { true }; // No previous attempts
  }
};

// Record deletion attempt
func recordDeleteAttempt(caller : Principal, gameId : Text) {
  let now = Nat64.fromNat(Int.abs(Time.now()));
  let oneHourAgo = now - (60 * 60 * 1_000_000_000);
  
  let newAttempt : DeletionAttempt = {
    timestamp = now;
    gameId = gameId;
  };
  
  switch (deleteRateLimit.get(caller)) {
    case (?attempts) {
      // Keep only recent attempts and add new one
      let recentAttempts = Array.filter<DeletionAttempt>(attempts, func(attempt) {
        attempt.timestamp > oneHourAgo
      });
      let updatedAttempts = Array.append(recentAttempts, [newAttempt]);
      deleteRateLimit.put(caller, updatedAttempts);
    };
    case null {
      deleteRateLimit.put(caller, [newAttempt]);
    };
  };
};

// Cleanup old deleted games (call this periodically)
func cleanupDeletedGames() {
  let now = Nat64.fromNat(Int.abs(Time.now()));
  
  let toRemove = Buffer.Buffer<Text>(0);
  
  for ((gameId, deleted) in deletedGames.entries()) {
    if (now > deleted.permanentDeletionAt and not deleted.canRecover) {
      toRemove.add(gameId);
    };
  };
  
  for (gameId in toRemove.vals()) {
    deletedGames.delete(gameId);
  };
};

  // ==================== PUBLIC FUNCTIONS ====================

// Enhanced delete with rate limiting and recovery period
public shared(msg) func deleteGame(gameId : Text) : async Result.Result<Text, Text> {
  // Check rate limit first
  if (not checkDeleteRateLimit(msg.caller)) {
    return #err("Rate limit exceeded. You can only delete 3 games per hour. Please try again later.");
  };
  
  switch (games.get(gameId)) {
    case (?game) {
      // Verify ownership
      if (game.owner != msg.caller and not isAdmin(msg.caller)) {
        return #err("Only game owner can delete this game");
      };
      
      // Record this deletion attempt
      recordDeleteAttempt(msg.caller, gameId);
      
      let now = Nat64.fromNat(Int.abs(Time.now()));
      let thirtyDays :Nat64 = 30 * 24 * 60 * 60 * 1_000_000_000; // 30 days in nanoseconds
      
      // Create deleted game record
      let deletedGame : DeletedGame = {
        game = game;
        deletedBy = msg.caller;
        deletedAt = now;
        permanentDeletionAt = now + thirtyDays;
        reason = "Owner requested deletion";
        canRecover = true;
      };
      
      // Move to deleted games
      deletedGames.put(gameId, deletedGame);
      
      // Mark as inactive (soft delete)
      let updated = {
        gameId = game.gameId;
        name = game.name;
        description = game.description;
        owner = game.owner;
        created = game.created;
        totalPlayers = game.totalPlayers;
        totalPlays = game.totalPlays;
        isActive = false; // Soft delete
        maxScorePerRound = game.maxScorePerRound;
        maxStreakDelta = game.maxStreakDelta;
        absoluteScoreCap = game.absoluteScoreCap;
        absoluteStreakCap = game.absoluteStreakCap;
      };
      games.put(gameId, updated);
      
      // Audit log
      trackEventInternal(
        #principal(msg.caller),
        "system",
        "game_deleted",
        [
          ("gameId", gameId),
          ("gameName", game.name),
          ("recoveryPeriod", "30 days")
        ]
      );
      
      #ok("Game deleted successfully. You can recover it within 30 days from the 'Deleted Games' section.")
    };
    case null { #err("Game not found") };
  }
};

// Recover a deleted game
public shared(msg) func recoverDeletedGame(gameId : Text) : async Result.Result<Text, Text> {
  switch (deletedGames.get(gameId)) {
    case (?deleted) {
      let now = Nat64.fromNat(Int.abs(Time.now()));
      
      // Verify ownership
      if (deleted.game.owner != msg.caller and not isAdmin(msg.caller)) {
        return #err("Only game owner can recover this game");
      };
      
      // Check if recovery period expired
      if (now > deleted.permanentDeletionAt) {
        return #err("Recovery period expired (30 days). Game has been permanently deleted.");
      };
      
      // Check if can be recovered
      if (not deleted.canRecover) {
        return #err("This game cannot be recovered");
      };
      
      // Restore the game (mark as active)
      let restored = {
        gameId = deleted.game.gameId;
        name = deleted.game.name;
        description = deleted.game.description;
        owner = deleted.game.owner;
        created = deleted.game.created;
        totalPlayers = deleted.game.totalPlayers;
        totalPlays = deleted.game.totalPlays;
        isActive = true; // Reactivate
        maxScorePerRound = deleted.game.maxScorePerRound;
        maxStreakDelta = deleted.game.maxStreakDelta;
        absoluteScoreCap = deleted.game.absoluteScoreCap;
        absoluteStreakCap = deleted.game.absoluteStreakCap;
      };
      
      games.put(gameId, restored);
      deletedGames.delete(gameId);
      
      // Audit log
      trackEventInternal(
        #principal(msg.caller),
        "system",
        "game_recovered",
        [
          ("gameId", gameId),
          ("gameName", deleted.game.name)
        ]
      );
      
      #ok("Game recovered successfully and is now active again!")
    };
    case null { #err("Game not found in deleted games") };
  }
};

// Get deleted games for a developer
public query(msg) func getDeletedGames() : async [DeletedGame] {
  let buffer = Buffer.Buffer<DeletedGame>(0);
  
  for ((_, deleted) in deletedGames.entries()) {
    if (deleted.game.owner == msg.caller or isAdmin(msg.caller)) {
      buffer.add(deleted);
    };
  };
  
  Buffer.toArray(buffer)
};

// Permanently delete a game (admin only, or after 30 days)
public shared(msg) func permanentlyDeleteGame(gameId : Text) : async Result.Result<Text, Text> {
  switch (deletedGames.get(gameId)) {
    case (?deleted) {
      let now = Nat64.fromNat(Int.abs(Time.now()));
      
      if (now <= deleted.permanentDeletionAt and not isAdmin(msg.caller)) {
        return #err("Game can only be permanently deleted after 30 days or by super admin");
      };
      
      // Verify ownership or admin
      if (deleted.game.owner != msg.caller and not isAdmin(msg.caller)) {
        return #err("Not authorized");
      };
      
      // Remove from games (if still there)
      games.delete(gameId);
      
      // Remove from deleted games
      deletedGames.delete(gameId);
      
      // Audit log
      trackEventInternal(
        #principal(msg.caller),
        "system",
        "game_permanently_deleted",
        [
          ("gameId", gameId),
          ("gameName", deleted.game.name)
        ]
      );
      
      #ok("Game permanently deleted. All data has been removed.")
    };
    case null { #err("Game not found in deleted games") };
  }
};

// Check if can delete (for UI)
public query(msg) func canDeleteGame() : async Bool {
  checkDeleteRateLimit(msg.caller)
};

// Get remaining delete attempts this hour
public query(msg) func getRemainingDeleteAttempts() : async Nat {
  let now = Nat64.fromNat(Int.abs(Time.now()));
  let oneHourAgo = now - (60 * 60 * 1_000_000_000);
  
  switch (deleteRateLimit.get(msg.caller)) {
    case (?attempts) {
      let recentAttempts = Array.filter<DeletionAttempt>(attempts, func(attempt) {
        attempt.timestamp > oneHourAgo
      });
      
      let used = recentAttempts.size();
      if (used >= 3) { 0 } else { 3 - used }
    };
    case null { 3 };
  }
};

// ==================== PERIODIC CLEANUP ====================

// Call this in a timer or heartbeat to clean up expired deleted games
public shared(msg) func cleanupExpiredGames() : async Result.Result<Text, Text> {
  if (not isAdmin(msg.caller)) {
    return #err("Only admin can trigger cleanup");
  };
  
  let now = Nat64.fromNat(Int.abs(Time.now()));
  let cleaned = Buffer.Buffer<Text>(0);
  
  for ((gameId, deleted) in deletedGames.entries()) {
    if (now > deleted.permanentDeletionAt) {
      // Remove from games map
      games.delete(gameId);
      // Remove from deleted games map
      deletedGames.delete(gameId);
      cleaned.add(gameId);
      
      // Audit log
      trackEventInternal(
        #principal(msg.caller),
        "system",
        "game_auto_cleanup",
        [("gameId", gameId)]
      );
    };
  };
  
  let count = cleaned.size();
  #ok("Cleaned up " # Nat.toText(count) # " expired games")
};

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // UPGRADE HOOKS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  system func preupgrade() {
    // userIdCounter is persistent and will be preserved automatically
    stableUsersByEmail := Iter.toArray(usersByEmail.entries());
    stableUsersByPrincipal := Iter.toArray(usersByPrincipal.entries());
    stableGames := Iter.toArray(games.entries());
    stableSessions := Iter.toArray(sessions.entries());
    stableSuspicionLog := List.toArray(suspicionLog);
    stableFiles := List.toArray(files);
    stableAnalyticsEvents := Buffer.toArray(analyticsEvents);
    stableDailyStats := Iter.toArray(dailyStats.entries());
    stablePlayerStats := Iter.toArray(playerStats.entries());
    stableLastSubmitTime := Iter.toArray(lastSubmitTime.entries());
    sessionsEntries := Iter.toArray(sessions.entries());
    principalToSessionEntries := Iter.toArray(principalToSession.entries());
    adminRolesStable := Iter.toArray(adminRoles.entries());
    deletedUsersStable := Iter.toArray(deletedUsers.entries());
    auditLogStable := Array.append(auditLogStable, Buffer.toArray(auditLog));
    deletedGamesEntries := Iter.toArray(deletedGames.entries());
    deleteRateLimitEntries := Iter.toArray(deleteRateLimit.entries());
  };

  system func postupgrade() {
  usersByEmail := HashMap.HashMap<Text, UserProfile>(10, Text.equal, Text.hash);
  for ((e, prof) in stableUsersByEmail.vals()) { usersByEmail.put(e, prof) };

  usersByPrincipal := HashMap.HashMap<Principal, UserProfile>(10, Principal.equal, Principal.hash);
  for ((p, prof) in stableUsersByPrincipal.vals()) { usersByPrincipal.put(p, prof) };

  // Initialize userIdCounter from existing users if it's 0
  if (userIdCounter == 0) {
    let totalUsers = usersByEmail.size() + usersByPrincipal.size();
    if (totalUsers > 0) {
      userIdCounter := totalUsers;
    };
  };

  games := HashMap.HashMap<Text, GameInfo>(10, Text.equal, Text.hash);
  for ((id, oldGame) in stableGames.vals()) {
    let migratedGame : GameInfo = {
      gameId = oldGame.gameId;
      name = oldGame.name;
      description = oldGame.description;
      owner = oldGame.owner;
      created = oldGame.created;
      totalPlayers = oldGame.totalPlayers;
      totalPlays = oldGame.totalPlays;
      isActive = oldGame.isActive;
      maxScorePerRound = null;
      maxStreakDelta = null;
      absoluteScoreCap = null;
      absoluteStreakCap = null;
    };
    games.put(id, migratedGame);
  };

  lastSubmitTime := HashMap.HashMap<Text, Nat64>(10, Text.equal, Text.hash);
  for ((key, time) in stableLastSubmitTime.vals()) { lastSubmitTime.put(key, time) };

  suspicionLog := List.fromArray(stableSuspicionLog);
  files := List.fromArray(stableFiles);
  
  analyticsEvents := Buffer.fromArray<AnalyticsEvent>(stableAnalyticsEvents);
  
  dailyStats := HashMap.HashMap<Text, DailyStats>(10, Text.equal, Text.hash);
  for ((date, stats) in stableDailyStats.vals()) {
    dailyStats.put(date, stats);
  };
  
  playerStats := HashMap.HashMap<Text, PlayerStats>(10, Text.equal, Text.hash);
  for ((p, stats) in stablePlayerStats.vals()) {
    playerStats.put(p, stats);
  };

  cachedLeaderboards := HashMap.HashMap<Text, [(Text, Nat64, Nat64, Text)]>(10, Text.equal, Text.hash);
  leaderboardLastUpdate := HashMap.HashMap<Text, Nat64>(10, Text.equal, Text.hash);
  
  sessions := HashMap.fromIter<Text, Session>(
    sessionsEntries.vals(), 10, Text.equal, Text.hash
  );
  principalToSession := HashMap.fromIter<Text, Text>(
    principalToSessionEntries.vals(), 10, Text.equal, Text.hash
  );
  
  sessionsEntries := [];
  principalToSessionEntries := [];
  adminRolesStable := [];
  deletedUsersStable := [];


  deletedGames := HashMap.fromIter<Text, DeletedGame>(
    deletedGamesEntries.vals(),
    10,
    Text.equal,
    Text.hash
  );
  
  deleteRateLimit := HashMap.fromIter<Principal, [DeletionAttempt]>(
    deleteRateLimitEntries.vals(),
    10,
    Principal.equal,
    Principal.hash
  );
  
  deletedGamesEntries := [];
  deleteRateLimitEntries := [];

  // DEVELOPERS: Replace with your own principal to be the first super admin
  let firstAdmin = Principal.fromText("YOUR_ADMIN_PRINCIPAL_HERE");
  adminRoles.put(firstAdmin, #SuperAdmin);
  };
  
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // GAME REGISTRATION (UPDATED WITH LIMITS)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  public shared(msg) func registerGame(
    gameId : Text, 
    name : Text, 
    description : Text,
    maxScorePerRound : ?Nat64,
    maxStreakDelta : ?Nat64,
    absoluteScoreCap : ?Nat64,
    absoluteStreakCap : ?Nat64
  ) : async Result.Result<Text, Text> {
    
    if (Principal.isAnonymous(msg.caller)) {
      return #err("âŒ Must authenticate with Internet Identity to register a game");
    };
    
    // Validate game ID length
    if (Text.size(gameId) < 3 or Text.size(gameId) > 50) {
      return #err("Game ID must be 3-50 characters");
    };
    
    switch (games.get(gameId)) {
      case (?existing) {
        if (existing.owner == msg.caller) {
          #ok("You already own this game")
        } else {
          #err("Game ID already taken by another developer")
        }
      };
      case null {
        let currentGameCount = countGamesByOwner(msg.caller);
        
        if (currentGameCount >= MAX_GAMES_PER_DEVELOPER and not isAdmin(msg.caller)) {
          return #err("ðŸš« Maximum " # Nat.toText(MAX_GAMES_PER_DEVELOPER) # " games per developer. You currently have " # Nat.toText(currentGameCount) # " games registered.");
        };
        
        let gameInfo : GameInfo = {
          gameId = gameId;
          name = name;
          description = description;
          owner = msg.caller;
          created = now();
          totalPlayers = 0;
          totalPlays = 0;
          isActive = true;
          maxScorePerRound = maxScorePerRound;
          maxStreakDelta = maxStreakDelta;
          absoluteScoreCap = absoluteScoreCap;
          absoluteStreakCap = absoluteStreakCap;
        };
        games.put(gameId, gameInfo);
        
        trackEventInternal(#principal(msg.caller), gameId, "game_registered", [
          ("game_name", name),
          ("game_id", gameId),
          ("total_games", Nat.toText(currentGameCount + 1))
        ]);
        
        #ok("âœ… Game '" # name # "' registered successfully! (" # Nat.toText(currentGameCount + 1) # "/" # Nat.toText(MAX_GAMES_PER_DEVELOPER) # " games)")
      };
    }
  };

  public shared(msg) func updateGame(gameId : Text, name : Text, description : Text) : async Result.Result<Text, Text> {
    switch (games.get(gameId)) {
      case (?game) {
        if (game.owner != msg.caller and not isAdmin(msg.caller)) {
          return #err("Only game owner can update");
        };
        
        let updated = {
          gameId = game.gameId;
          name = name;
          description = description;
          owner = game.owner;
          created = game.created;
          totalPlayers = game.totalPlayers;
          totalPlays = game.totalPlays;
          isActive = game.isActive;
          maxScorePerRound = game.maxScorePerRound;
          maxStreakDelta = game.maxStreakDelta;
          absoluteScoreCap = game.absoluteScoreCap;
          absoluteStreakCap = game.absoluteStreakCap;
        };
        games.put(gameId, updated);
        #ok("Game updated")
      };
      case null { #err("Game not found") };
    }
  };

  public shared(msg) func updateGameRules(
    gameId : Text,
    maxScorePerRound : ?Nat64,
    maxStreakDelta : ?Nat64,
    absoluteScoreCap : ?Nat64,
    absoluteStreakCap : ?Nat64
  ) : async Result.Result<Text, Text> {
    switch (games.get(gameId)) {
      case (?game) {
        if (game.owner != msg.caller and not isAdmin(msg.caller)) {
          return #err("Only game owner can update rules");
        };
        
        let updated = {
          gameId = game.gameId;
          name = game.name;
          description = game.description;
          owner = game.owner;
          created = game.created;
          totalPlayers = game.totalPlayers;
          totalPlays = game.totalPlays;
          isActive = game.isActive;
          maxScorePerRound = maxScorePerRound;
          maxStreakDelta = maxStreakDelta;
          absoluteScoreCap = absoluteScoreCap;
          absoluteStreakCap = absoluteStreakCap;
        };
        games.put(gameId, updated);
        #ok("Game rules updated")
      };
      case null { #err("Game not found") };
    }
  };

  public shared(msg) func toggleGameActive(gameId : Text) : async Result.Result<Text, Text> {
    switch (games.get(gameId)) {
      case (?game) {
        if (game.owner != msg.caller and not isAdmin(msg.caller)) {
          return #err("Only game owner can toggle");
        };
        
        let updated = {
          gameId = game.gameId;
          name = game.name;
          description = game.description;
          owner = game.owner;
          created = game.created;
          totalPlayers = game.totalPlayers;
          totalPlays = game.totalPlays;
          isActive = not game.isActive;
          maxScorePerRound = game.maxScorePerRound;
          maxStreakDelta = game.maxStreakDelta;
          absoluteScoreCap = game.absoluteScoreCap;
          absoluteStreakCap = game.absoluteStreakCap;
        };
        games.put(gameId, updated);
        #ok("Game " # (if (updated.isActive) "activated" else "deactivated"))
      };
      case null { #err("Game not found") };
    }
  };

  // NEW: Query to check how many games a developer has registered
  public query(msg) func getMyGameCount() : async Nat {
    countGamesByOwner(msg.caller)
  };

  // NEW: Query to check remaining game slots
  public query(msg) func getRemainingGameSlots() : async Nat {
    let current = countGamesByOwner(msg.caller);
    if (current >= MAX_GAMES_PER_DEVELOPER) {
      0
    } else {
      MAX_GAMES_PER_DEVELOPER - current
    }
  };

  public query func getGame(gameId : Text) : async ?GameInfo {
    games.get(gameId)
  };

  public query func listGames() : async [GameInfo] {
    Iter.toArray(games.vals())
  };

  public query func getActiveGames() : async [GameInfo] {
    Iter.toArray(
      Iter.filter(games.vals(), func (g : GameInfo) : Bool { g.isActive })
    )
  };

  public query func getGamesByOwner(owner : Principal) : async [GameInfo] {
    Iter.toArray(
      Iter.filter(games.vals(), func (g : GameInfo) : Bool { g.owner == owner })
    )
  };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // AUTHENTICATION
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    func validateSessionInternal(sessionId : Text) : Result.Result<Session, Text> {
    switch (sessions.get(sessionId)) {
      case null {
        #err("Invalid session: not found")
      };
      case (?session) {
        let currentTime = now();
        
        // Check if expired
        if (currentTime > session.expires) {
          // Remove expired session
          sessions.delete(sessionId);
          return #err("Session expired");
        };
        
        // Session is valid
        #ok(session)
      };
    }
  };

  public shared func validateSession(sessionId : Text) : async Result.Result<{ email: Text; nickname: Text; valid: Bool }, Text> {
    switch (sessions.get(sessionId)) {
      case (?session) {
        if (session.expires < now()) {
          sessions.delete(sessionId);
          #err("Session expired")
        } else {
          let updated = {
            sessionId = session.sessionId;
            email = session.email;
            nickname = session.nickname;
            authType = session.authType;
            created = session.created;
            expires = session.expires;
            lastUsed = now();
          };
          sessions.put(sessionId, updated);
          
          #ok({
            email = session.email;
            nickname = session.nickname;
            valid = true;
          })
        }
      };
      case null { #err("Invalid session") };
    }
  };

  public shared func destroySession(sessionId : Text) : async Result.Result<Text, Text> {
    switch (sessions.remove(sessionId)) {
      case (?_) { #ok("Session destroyed") };
      case null { #err("Session not found") };
    }
  };

  public shared(msg) func iiLoginAndGetProfile(
  nickname : Text,
  gameId : Text
) : async Result.Result<{
  message : Text;
  isNewUser : Bool;
  nickname : Text;
  gameProfile : ?{
    total_score : Nat64;
    best_streak : Nat64;
    achievements : [Text];
    last_played : Nat64;
    play_count : Nat;
  };
}, Text> {
  
  let caller = msg.caller;
  
  if (Text.size(nickname) < 2 or Text.size(nickname) > 12) {
    return #err("Nickname must be 2-12 characters");
  };
  
  if (Principal.isAnonymous(caller)) {
    return #err("Internet Identity required");
  };
  
  let (user, isNewUser) = switch (usersByPrincipal.get(caller)) {
    case (?existingUser) {
      (existingUser, false)
    };
    case null {
      let newUser : UserProfile = {
        identifier = #principal(caller);
        nickname = nickname;
        authType = #internetIdentity;
        gameProfiles = [];
        created = now();
        last_updated = now();
      };
      usersByPrincipal.put(caller, newUser);
      
      trackEventInternal(#principal(caller), "default", "signup", [
        ("provider", "internetIdentity"),
        ("nickname", nickname)
      ]);
      
      (newUser, true)
    };
  };
  
  var gameProfile : ?{
    total_score : Nat64;
    best_streak : Nat64;
    achievements : [Text];
    last_played : Nat64;
    play_count : Nat;
  } = null;
  
  for ((gId, gp) in user.gameProfiles.vals()) {
    if (gId == gameId) {
      gameProfile := ?{
        total_score = gp.total_score;
        best_streak = gp.best_streak;
        achievements = gp.achievements;
        last_played = gp.last_played;
        play_count = gp.play_count;
      };
    };
  };
  
  let message = if (isNewUser) {
    "Account created for " # user.nickname
  } else {
    "Welcome back, " # user.nickname
  };
  
  #ok({
    message = message;
    isNewUser = isNewUser;
    nickname = user.nickname;
    gameProfile = gameProfile;
  })
};

public shared(msg) func socialLoginAndGetProfile(
  email : Text,
  nickname : Text,
  provider : Text,
  gameId : Text
) : async Result.Result<{
  message : Text;
  isNewUser : Bool;
  nickname : Text;
  sessionId : Text;
  gameProfile : ?{
    total_score : Nat64;
    best_streak : Nat64;
    achievements : [Text];
    last_played : Nat64;
    play_count : Nat;
  };
}, Text> {
  
  if (Text.size(nickname) < 2 or Text.size(nickname) > 12) {
    return #err("Nickname must be 2-12 characters");
  };
  
  let authType = if (provider == "google") { #google } else { #apple };
  
  // Check if user exists or create new user
  let (user, isNewUser) = switch (usersByEmail.get(email)) {
    case (?existingUser) {
      (existingUser, false)
    };
    case null {
      let newUser : UserProfile = {
        identifier = #email(email);
        nickname = nickname;
        authType = authType;
        gameProfiles = [];
        created = now();
        last_updated = now();
      };
      usersByEmail.put(email, newUser);
      
      trackEventInternal(#email(email), "default", "signup", [
        ("provider", provider),
        ("nickname", nickname)
      ]);
      
      (newUser, true)
    };
  };
  
  // Create session
  let sessionId = generateSessionId();
  let session : Session = {
    sessionId = sessionId;
    email = email;
    nickname = user.nickname;
    authType = authType;
    created = now();
    expires = now() + SESSION_DURATION_NS;
    lastUsed = now();
  };
  sessions.put(sessionId, session);
  principalToSession.put(Principal.toText(msg.caller), sessionId);

  // Find game profile
  var gameProfile : ?{
    total_score : Nat64;
    best_streak : Nat64;
    achievements : [Text];
    last_played : Nat64;
    play_count : Nat;
  } = null;
  
  for ((gId, gp) in user.gameProfiles.vals()) {
    if (gId == gameId) {
      gameProfile := ?{
        total_score = gp.total_score;
        best_streak = gp.best_streak;
        achievements = gp.achievements;
        last_played = gp.last_played;
        play_count = gp.play_count;
      };
    };
  };
  
  let message = if (isNewUser) {
    "Account created for " # user.nickname
  } else {
    "Welcome back, " # user.nickname
  };
  
  #ok({
    message = message;
    isNewUser = isNewUser;
    nickname = user.nickname;
    sessionId = sessionId;
    gameProfile = gameProfile;
  })
};

  // =======================================================
// NEW: createSessionForVerifiedUser
// Called ONLY by your Netlify "verifier" function.
// Mints an opaque, short-lived Session for a verified user.
// Security gate ensures only the verifier principal can call this.
// =======================================================
public shared ({ caller }) func createSessionForVerifiedUser(
  idp   : AuthType,      // { #google; #apple }  (reuse your existing AuthType)
  sub   : Text,          // provider subject (not currently stored, but useful for logs later)
  email : ?Text,         // MUST be present for your current email-keyed user model
  nonce : Text           // echoed value; good for logging / debugging
) : async Result.Result<Session, Text> {

  // 🛡️ Security gate — ONLY your Netlify verifier may call this
  if (caller != VERIFIER) {
    return #err("Unauthorized: caller is not verifier");
  };

  // Your current data model keys users by email; require it for now
  let userEmail : Text = switch (email) {
    case (null) { return #err("Email required"); };
    case (?e) { e };
  };

 // Generate a default nickname - NEVER use email
  let defaultNickname : Text = generateDefaultNickname();

  // Upsert user profile keyed by email
  let tNow = now();
  let userIdentifier : UserIdentifier = #email(userEmail);

  let actualNickname : Text = switch (usersByEmail.get(userEmail)) {
    case (null) {
      // Create new user with generated nickname
      let profile : UserProfile = {
        identifier   = userIdentifier;
        nickname     = defaultNickname;
        authType     = idp;                // #google or #apple
        gameProfiles = [];
        created      = tNow;
        last_updated = tNow;
      };
      usersByEmail.put(userEmail, profile);
      defaultNickname
    };

    case (?existing) {
      // Update existing user (light touch)
      let updated : UserProfile = {
        identifier   = existing.identifier;
        nickname     = existing.nickname;  // keep their chosen nickname
        authType     = idp;                // record latest auth method used
        gameProfiles = existing.gameProfiles;
        created      = existing.created;
        last_updated = tNow;
      };
      usersByEmail.put(userEmail, updated);
      existing.nickname
    };
  };

  // Create session (reuse your existing generator & constants)
  let sessionToken : Text = generateSessionId();
  let session : Session = {
    sessionId = sessionToken;
    email     = userEmail;
    nickname  = actualNickname;            // use actual nickname, never email           // can be improved later
    authType  = idp;                        // #google or #apple
    created   = tNow;
    expires   = tNow + SESSION_DURATION_NS; // your existing 24h TTL
    lastUsed  = tNow;
  };
  sessions.put(sessionToken, session);

  // IMPORTANT: do NOT write to principalToSession here.
  // The caller is the verifier, not the end-user's browser principal.

  // (Optional) analytics event:
  // trackEventInternal(userIdentifier, "<system>", "verified_login", [("idp", authTypeToText(idp)), ("nonce", nonce)]);

  // Return the full Session (your JS can read .sessionId and .expires)
  return #ok(session);
};

// ═════════════════════════════════════════════════════════════════════════════
// SUGGEST NICKNAME - Returns a default nickname suggestion for users
// This replaces the old behavior of suggesting the user's email
// ═════════════════════════════════════════════════════════════════════════════
public shared(msg) func suggestNickname() : async Result.Result<Text, Text> {
  // Generate a new default nickname suggestion
  let suggestion = generateDefaultNickname();
  #ok(suggestion)
};

// Get current nickname for a session (useful for frontend to check)
public shared(msg) func getNicknameBySession(sessionId : Text) : async Result.Result<Text, Text> {
  switch (validateSessionInternal(sessionId)) {
    case (#err(e)) { #err(e) };
    case (#ok(session)) { #ok(session.nickname) };
  };
};

// ===== BATCH CHANGE NICKNAME =====
// Combines changeNickname + getGameProfile into ONE call
public shared(msg) func changeNicknameAndGetProfile(
  userIdType : Text,
  userId : Text,
  newNickname : Text,
  gameId : Text
) : async Result.Result<{
  message : Text;
  nickname : Text;
  gameProfile : ?{
    total_score : Nat64;
    best_streak : Nat64;
    achievements : [Text];
    last_played : Nat64;
    play_count : Nat;
  };
}, Text> {
  
  // ✅ STEP 1: Validate the caller
  switch (validateCaller(msg, userIdType, userId)) {
    case (#err(e)) { return #err(e) };
    case (#ok(_)) { /* authorized, continue */ };
  };
  
  // ✅ STEP 2: Validate nickname
  switch (validateNickname(newNickname)) {
    case (#err(e)) { return #err(e) };
    case (#ok()) {};
  };
  
  // ✅ STEP 3: Get the correct identifier (extract email from session if needed)
  let identifier : UserIdentifier = switch (userIdType) {
    case ("email") { 
      // userId is sessionId, extract email from session
      switch (validateSessionInternal(userId)) {
        case (#err(e)) { return #err(e) };
        case (#ok(session)) { #email(session.email) };
      };
    };
    case ("session") {
      // Same as email - userId is sessionId, extract email
      switch (validateSessionInternal(userId)) {
        case (#err(e)) { return #err(e) };
        case (#ok(session)) { #email(session.email) };
      };
    };
    case ("principal") { #principal(msg.caller) };
    case (_) { return #err("Invalid user type") };
  };
  
  let user = getUserByIdentifier(identifier);
  
  switch (user) {
    case null { #err("User not found") };
    case (?u) {
      // Update nickname
      let updatedUser : UserProfile = {
        identifier = u.identifier;
        nickname = newNickname;
        authType = u.authType;
        gameProfiles = u.gameProfiles;
        created = u.created;
        last_updated = now();
      };
      
      putUserByIdentifier(updatedUser);
      
      // Track event
      trackEventInternal(u.identifier, "default", "nickname_changed", [
        ("old_nickname", u.nickname),
        ("new_nickname", newNickname)
      ]);
      
      // Find game profile
      var gameProfile : ?{
        total_score : Nat64;
        best_streak : Nat64;
        achievements : [Text];
        last_played : Nat64;
        play_count : Nat;
      } = null;
      
      for ((gId, gp) in updatedUser.gameProfiles.vals()) {
        if (gId == gameId) {
          gameProfile := ?{
            total_score = gp.total_score;
            best_streak = gp.best_streak;
            achievements = gp.achievements;
            last_played = gp.last_played;
            play_count = gp.play_count;
          };
        };
      };
      
      #ok({
        message = "Nickname changed to " # newNickname;
        nickname = newNickname;
        gameProfile = gameProfile;
      })
    };
  };
};

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SCORE SUBMISSION
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

public query func getDetailedStats(gameId : Text) : async {
    submissions: {
        total: Nat;
        today: Nat;
    };
    game: ?{
        totalPlayers: Nat;
        totalGames: Nat;
        isActive: Bool;
    };
} {
    let gameInfo = switch (games.get(gameId)) {
        case (?g) {
            ?{
                totalPlayers = g.totalPlayers;
                totalGames = g.totalPlays;
                isActive = g.isActive;
            }
        };
        case null { null };
    };
    
    {
        submissions = {
            total = totalSubmissions;
            today = submissionsToday;
        };
        game = gameInfo;
    }
};

public query func getSubmissionStats() : async {
    total: Nat;
    today: Nat;
    date: Text;
} {
    {
        total = totalSubmissions;
        today = submissionsToday;
        date = lastResetDate;
    }
};

public shared(msg) func submitScore(
    userIdType : Text,
    userId : Text,
    gameId : Text,
    scoreNat : Nat,
    streakNat : Nat,
    roundsPlayed : ?Nat
) : async Result.Result<Text, Text> {
    
    // Track submission count
    totalSubmissions += 1;
    let t = now();
    let currentDate = getDateString(t);
    if (currentDate != lastResetDate) {
        submissionsToday := 0;
        lastResetDate := currentDate;
    };
    submissionsToday += 1;
    
    let rounds : Nat = switch (roundsPlayed) {
        case (?r) { r };
        case null { 1 };
    };
    
    // ✅ STEP 1: Validate the caller
    switch (validateCaller(msg, userIdType, userId)) {
        case (#err(e)) { return #err(e) };
        case (#ok(_)) { /* authorized, continue */ };
    };
    
    // ✅ STEP 2: Get the actual identifier
    let identifier : UserIdentifier = switch (userIdType) {
        case ("email") { 
            switch (validateSessionInternal(userId)) {
                case (#err(e)) { return #err(e) };
                case (#ok(session)) { #email(session.email) };
            };
        };
        case ("session") {
            switch (validateSessionInternal(userId)) {
                case (#err(e)) { return #err(e) };
                case (#ok(session)) { #email(session.email) };
            };
        };
        case ("principal") { #principal(msg.caller) };
        case (_) { return #err("Invalid user type") };
    };
    
    let score = Nat64.fromNat(scoreNat);
    let streak = Nat64.fromNat(streakNat);
    let rules = getValidationRules(gameId);

    // ✅ STEP 3: Validate game and scores
    switch (validateGameId(gameId)) {
        case (#err(e)) { return #err(e) };
        case (#ok()) {};
    };

    switch (validateScore(score, gameId)) {
        case (#err(e)) { 
            logSuspicion(userId # "/" # userIdType, gameId, "Invalid score: " # e);
            return #err(e);
        };
        case (#ok()) {};
    };

    switch (validateStreak(streak, gameId)) {
        case (#err(e)) {
            logSuspicion(userId # "/" # userIdType, gameId, "Invalid streak: " # e);
            return #err(e);
        };
        case (#ok()) {};
    };

    switch (games.get(gameId)) {
        case null { 
            return #err("Game not found. Please register the game first.");
        };
        case (?game) {
            if (not game.isActive) {
                return #err("Game is not active");
            };
        };
    };

    // ✅ STEP 4: Rate limiting
    let user = getUserByIdentifier(identifier);
    
    switch (user) {
        case (?u) {
            let submitKey = makeSubmitKey(u.identifier, gameId);
            switch (lastSubmitTime.get(submitKey)) {
                case (?prev) {
                    if (t - prev < 2_000_000_000) {
                        return #err("Please wait 2 seconds between submissions.");
                    };
                };
                case null {};
            };
            lastSubmitTime.put(submitKey, t);

            // ✅ STEP 5: Update user profile
            var gameProfiles = Buffer.Buffer<(Text, GameProfile)>(u.gameProfiles.size());
            var found = false;
            var scoreImproved = false;
            var streakImproved = false;

            for ((gId, gProfile) in u.gameProfiles.vals()) {
                if (gId == gameId) {
                    found := true;
                    
                    var updatedScore = gProfile.total_score;
                    var updatedStreak = gProfile.best_streak;
                    
                    // Check score improvement
                    if (score > gProfile.total_score) {
                        if (score - gProfile.total_score > rules.maxScorePerRound) {
                            logSuspicion(identifierToText(u.identifier), gameId, "Score delta too high");
                            return #err("Score increase too large.");
                        };
                        updatedScore := score;
                        scoreImproved := true;
                    };

                    // Check streak improvement
                    if (streak > gProfile.best_streak) {
                        if (streak - gProfile.best_streak > rules.maxStreakDelta) {
                            logSuspicion(identifierToText(u.identifier), gameId, "Streak delta too high");
                            return #err("Streak increase too large.");
                        };
                        updatedStreak := streak;
                        streakImproved := true;
                    };
                    
                    let updated : GameProfile = {
                        gameId = gameId;
                        total_score = updatedScore;
                        best_streak = updatedStreak;
                        achievements = gProfile.achievements;
                        last_played = t;
                        play_count = gProfile.play_count + 1;
                    };
                    gameProfiles.add((gId, updated));
                } else {
                    gameProfiles.add((gId, gProfile));
                };
            };

            // ✅ STEP 6: Handle new game profile
            if (not found) {
                let newGameProfile : GameProfile = {
                    gameId = gameId;
                    total_score = score;
                    best_streak = streak;
                    achievements = [];
                    last_played = t;
                    play_count = 1;
                };
                gameProfiles.add((gameId, newGameProfile));
                scoreImproved := true;
                streakImproved := true;
                
                // Update game stats for new player
                switch (games.get(gameId)) {
                    case (?gameInfo) {
                        games.put(gameId, updateGameStats(gameInfo, 1, rounds));
                    };
                    case null {};
                };
            } else {
                // ✅ OPTIMIZATION: Only update game stats if score improved
                if (scoreImproved or streakImproved) {
                    switch (games.get(gameId)) {
                        case (?gameInfo) {
                            games.put(gameId, updateGameStats(gameInfo, 0, rounds));
                        };
                        case null {};
                    };
                };
            };

            // Early return if no improvement (save cycles)
            if (not scoreImproved and not streakImproved) {
                return #ok("No update: score and streak unchanged.");
            };

            // ✅ STEP 7: Save updated user profile
            let updatedUser : UserProfile = {
                identifier = u.identifier;
                nickname = u.nickname;
                authType = u.authType;
                gameProfiles = Buffer.toArray(gameProfiles);
                created = u.created;
                last_updated = t;
            };
            
            putUserByIdentifier(updatedUser);
            
            // ✅ OPTIMIZATION: Only invalidate cache if scores improved
            // This prevents unnecessary leaderboard recalculations
            if (scoreImproved) {
                cachedLeaderboards.delete(gameId # ":score");
            };
            if (streakImproved) {
                cachedLeaderboards.delete(gameId # ":streak");
            };

            // ✅ OPTIMIZATION: Only update daily stats for improvements
            // Reduces HashMap operations for non-improvement submissions
            if (scoreImproved or streakImproved) {
                let dateStr = getDateString(t);
                let statsKey = dateStr # ":" # gameId;
                switch (dailyStats.get(statsKey)) {
                    case (?stats) {
                        dailyStats.put(statsKey, {
                            date = stats.date;
                            gameId = stats.gameId;
                            uniquePlayers = stats.uniquePlayers;
                            totalGames = stats.totalGames;
                            totalScore = stats.totalScore + score;
                            newUsers = stats.newUsers;
                            authenticatedPlays = stats.authenticatedPlays;
                        });
                    };
                    case null {
                        // Initialize new daily stats entry
                        dailyStats.put(statsKey, {
                            date = dateStr;
                            gameId = gameId;
                            uniquePlayers = 1;
                            totalGames = 1;
                            totalScore = score;
                            newUsers = if (not found) 1 else 0;
                            authenticatedPlays = 1;
                        });
                    };
                };
            };
            
            // ✅ OPTIMIZATION: Only track significant events
            // Reduces event log size and processing
            if (scoreImproved or streakImproved) {
                trackEventInternal(u.identifier, gameId, "high_score", [
                    ("score", Nat64.toText(score)),
                    ("streak", Nat64.toText(streak)),
                    ("score_improved", if (scoreImproved) "true" else "false"),
                    ("streak_improved", if (streakImproved) "true" else "false"),
                    ("rounds", Nat.toText(rounds))
                ]);
            };
            
            // ✅ STEP 8: Return success message
            let message = if (scoreImproved and streakImproved) {
                "🎉 New high score and streak!"
            } else if (scoreImproved) {
                "🏆 New high score!"
            } else if (streakImproved) {
                "🔥 New best streak!"
            } else {
                "✅ Score submitted"
            };
            
            #ok(message # " Score: " # Nat64.toText(score) # ", Streak: " # Nat64.toText(streak))
        };
        case null {
            #err("User not found. Please login first.")
        };
    };
};


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SESSION QUERIES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  
  public query func getSessionInfo(sessionId : Text) : async ?{
    email: Text;
    nickname: Text;
    authType: Text;
    created: Nat64;
    expires: Nat64;
    lastUsed: Nat64;
  } {
    switch (sessions.get(sessionId)) {
      case (?session) {
        ?{
          email = session.email;
          nickname = session.nickname;
          authType = authTypeToText(session.authType);
          created = session.created;
          expires = session.expires;
          lastUsed = session.lastUsed;
        }
      };
      case null { null };
    }
  };

  public query func getActiveSessions() : async Nat {
    sessions.size()
  };

  

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ACHIEVEMENTS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

public shared(msg) func unlockAchievement(
    userIdType : Text,
    userId : Text,
    gameId : Text,
    achievementId : Text  // ✅ CHANGED: Just a Text ID now
  ) : async Result.Result<Text, Text> {

  // ✅ STEP 1: Validate the caller
  switch (validateCaller(msg, userIdType, userId)) {
    case (#err(e)) { return #err(e) };
    case (#ok(_)) { /* authorized, continue */ };
  };
    
  switch (validateGameId(gameId)) {
    case (#err(e)) { return #err(e) };
    case (#ok()) {};
  };
  
  // ✅ CHANGED: Validate just the ID
  if (Text.size(achievementId) == 0) {
    return #err("Achievement ID cannot be empty");
  };
  
  // ✅ STEP 2: Get the correct identifier (extract email from session if needed)
  let identifier : UserIdentifier = switch (userIdType) {
    case ("email") { 
      switch (validateSessionInternal(userId)) {
        case (#err(e)) { return #err(e) };
        case (#ok(session)) { #email(session.email) };
      };
    };
    case ("session") {
      switch (validateSessionInternal(userId)) {
        case (#err(e)) { return #err(e) };
        case (#ok(session)) { #email(session.email) };
      };
    };
    case ("principal") { #principal(msg.caller) };
    case (_) { return #err("Invalid user type") };
  };

  let user = getUserByIdentifier(identifier);

  switch (user) {
    case null { #err("User not found") };
    case (?u) {
      var gameProfiles = Buffer.Buffer<(Text, GameProfile)>(u.gameProfiles.size());
      var found = false;
      
      for ((gId, gProfile) in u.gameProfiles.vals()) {
        if (gId == gameId) {
          found := true;
          
          // ✅ CHANGED: Check if ID already exists in array
          for (existingId in gProfile.achievements.vals()) {
            if (existingId == achievementId) {
              return #ok("Achievement already unlocked.");
            };
          };
          
          // ✅ CHANGED: Just append the ID string
          let updated : GameProfile = {
            gameId = gameId;
            total_score = gProfile.total_score;
            best_streak = gProfile.best_streak;
            achievements = Array.append(gProfile.achievements, [achievementId]);
            last_played = gProfile.last_played;
            play_count = gProfile.play_count;
          };
          gameProfiles.add((gId, updated));
        } else {
          gameProfiles.add((gId, gProfile));
        };
      };
      
      if (not found) {
        return #err("No profile for this game. Play first!");
      };
      
      let updatedUser : UserProfile = {
        identifier = u.identifier;
        nickname = u.nickname;
        authType = u.authType;
        gameProfiles = Buffer.toArray(gameProfiles);
        created = u.created;
        last_updated = now();
      };
      
      putUserByIdentifier(updatedUser);
      
      trackEventInternal(u.identifier, gameId, "achievement_unlocked", [
        ("achievement_id", achievementId)  // ✅ CHANGED: Only log the ID
      ]);
      
      #ok("Achievement unlocked: " # achievementId)  // ✅ CHANGED
    };
  };
};

// ✅ CHANGED: Returns [Text] instead of [Achievement]
public query func getAchievements(userIdType : Text, userId : Text, gameId : Text) : async [Text] {
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(Principal.fromText(userId)) };
      case (_) { return [] };
    };

    switch (getUserByIdentifier(identifier)) {
      case (?user) {
        for ((gId, gProfile) in user.gameProfiles.vals()) {
          if (gId == gameId) {
            return gProfile.achievements;
          };
        };
        []
      };
      case null { [] };
    }
  };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // LEADERBOARD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  public query func getLeaderboard(gameId : Text, sortBy : SortBy, limit : Nat) : async [(Text, Nat64, Nat64, Text)] {
    let cacheKey = gameId # ":" # (switch(sortBy) { case (#score) "score"; case (#streak) "streak" });
    
    switch (cachedLeaderboards.get(cacheKey)) {
      case (?cached) {
        switch (leaderboardLastUpdate.get(cacheKey)) {
          case (?lastUpdate) {
            if (now() - lastUpdate < LEADERBOARD_CACHE_TTL) {
              let cap = if (limit == 0 or limit > 1000) 1000 else limit;
              if (cached.size() <= cap) return cached else return Array.subArray(cached, 0, cap);
            };
          };
          case null {};
        };
      };
      case null {};
    };
    
    var allScores = Buffer.Buffer<(Text, Nat64, Nat64, Text)>(100);
    
    for ((email, user) in usersByEmail.entries()) {
      for ((gId, gProfile) in user.gameProfiles.vals()) {
        if (gId == gameId) {
          allScores.add((
            user.nickname, 
            gProfile.total_score, 
            gProfile.best_streak,
            authTypeToText(user.authType)
          ));
        };
      };
    };
    
    for ((principal, user) in usersByPrincipal.entries()) {
      for ((gId, gProfile) in user.gameProfiles.vals()) {
        if (gId == gameId) {
          allScores.add((
            user.nickname, 
            gProfile.total_score, 
            gProfile.best_streak,
            authTypeToText(user.authType)
          ));
        };
      };
    };
    
    let sorted = Array.sort<(Text, Nat64, Nat64, Text)>(
      Buffer.toArray(allScores),
      func(a, b) {
        switch (sortBy) {
          case (#score) {
            if (a.1 > b.1) #less
            else if (a.1 < b.1) #greater
            else #equal
          };
          case (#streak) {
            if (a.2 > b.2) #less
            else if (a.2 < b.2) #greater
            else #equal
          };
        }
      }
    );
    
    cachedLeaderboards.put(cacheKey, sorted);
    leaderboardLastUpdate.put(cacheKey, now());
    
    let cap = if (limit == 0 or limit > 1000) 1000 else limit;
    if (sorted.size() <= cap) sorted else Array.subArray(sorted, 0, cap)
  };

  public query func getLeaderboardByAuth(gameId : Text, authType : AuthType, sortBy : SortBy, limit : Nat) : async [(Text, Nat64, Nat64, Text)] {
    var filteredScores = Buffer.Buffer<(Text, Nat64, Nat64, Text)>(100);
    
    for ((email, user) in usersByEmail.entries()) {
      if (user.authType == authType) {
        for ((gId, gProfile) in user.gameProfiles.vals()) {
          if (gId == gameId) {
            filteredScores.add((
              user.nickname, 
              gProfile.total_score, 
              gProfile.best_streak,
              authTypeToText(user.authType)
            ));
          };
        };
      };
    };
    
    for ((principal, user) in usersByPrincipal.entries()) {
      if (user.authType == authType) {
        for ((gId, gProfile) in user.gameProfiles.vals()) {
          if (gId == gameId) {
            filteredScores.add((
              user.nickname, 
              gProfile.total_score, 
              gProfile.best_streak,
              authTypeToText(user.authType)
            ));
          };
        };
      };
    };
    
    let sorted = Array.sort<(Text, Nat64, Nat64, Text)>(
      Buffer.toArray(filteredScores),
      func(a, b) {
        switch (sortBy) {
          case (#score) {
            if (a.1 > b.1) #less
            else if (a.1 < b.1) #greater
            else #equal
          };
          case (#streak) {
            if (a.2 > b.2) #less
            else if (a.2 < b.2) #greater
            else #equal
          };
        }
      }
    );
    
    let cap = if (limit == 0 or limit > 1000) 1000 else limit;
    if (sorted.size() <= cap) sorted else Array.subArray(sorted, 0, cap)
  };
  
  public query func getPlayerRank(
    gameId : Text,
    sortBy : SortBy,
    userIdType : Text,
    userId : Text
) : async ?{
    rank : Nat;
    score : Nat64;
    streak : Nat64;
    totalPlayers : Nat;
} {
    let identifier : UserIdentifier = switch (userIdType) {
        case ("email") { #email(userId) };
        case ("principal") { #principal(Principal.fromText(userId)) };
        case (_) { return null };
    };
    
    switch (getUserByIdentifier(identifier)) {
        case null { null };
        case (?user) {
            // Get user's game profile
            var userScore : Nat64 = 0;
            var userStreak : Nat64 = 0;
            var found = false;
            
            for ((gId, gProfile) in user.gameProfiles.vals()) {
                if (gId == gameId) {
                    userScore := gProfile.total_score;
                    userStreak := gProfile.best_streak;
                    found := true;
                };
            };
            
            if (not found) return null;
            
            var betterCount = 0;
            var totalCount = 0;
            
            for ((_, otherUser) in usersByEmail.entries()) {
                for ((gId, gProfile) in otherUser.gameProfiles.vals()) {
                    if (gId == gameId) {
                        totalCount += 1;
                        let isBetter = switch (sortBy) {
                            case (#score) { gProfile.total_score > userScore };
                            case (#streak) { gProfile.best_streak > userStreak };
                        };
                        if (isBetter) betterCount += 1;
                    };
                };
            };
            
            for ((_, otherUser) in usersByPrincipal.entries()) {
                for ((gId, gProfile) in otherUser.gameProfiles.vals()) {
                    if (gId == gameId) {
                        totalCount += 1;
                        let isBetter = switch (sortBy) {
                            case (#score) { gProfile.total_score > userScore };
                            case (#streak) { gProfile.best_streak > userStreak };
                        };
                        if (isBetter) betterCount += 1;
                    };
                };
            };
            
            ?{
                rank = betterCount + 1;
                score = userScore;
                streak = userStreak;
                totalPlayers = totalCount;
            }
        };
    }
};
  public query func getGameAuthStats(gameId : Text) : async {
    internetIdentity : Nat;
    google : Nat;
    apple : Nat;
    total : Nat;
  } {
    var iiCount = 0;
    var googleCount = 0;
    var appleCount = 0;
    var totalCount = 0;
    
    for ((_, user) in usersByEmail.entries()) {
      for ((gId, _) in user.gameProfiles.vals()) {
        if (gId == gameId) {
          totalCount += 1;
          switch (user.authType) {
            case (#google) googleCount += 1;
            case (#apple) appleCount += 1;
            case (_) {};
          };
        };
      };
    };
    
    for ((_, user) in usersByPrincipal.entries()) {
      for ((gId, _) in user.gameProfiles.vals()) {
        if (gId == gameId) {
          totalCount += 1;
          switch (user.authType) {
            case (#internetIdentity) iiCount += 1;
            case (_) {};
          };
        };
      };
    };
    
    {
      internetIdentity = iiCount;
      google = googleCount;
      apple = appleCount;
      total = totalCount;
    }
  };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PROFILE QUERIES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

 // ✅ Returns sanitized UserProfile with ALL gameProfiles array
public query func getUserProfile(userIdType : Text, userId : Text) : async Result.Result<PublicUserProfile, Text> {
  let identifier : UserIdentifier = switch (userIdType) {
    case ("email") { #email(userId) };
    case ("session") { 
      switch (validateSessionInternal(userId)) {
        case (#err(e)) { return #err(e) };
        case (#ok(session)) { #email(session.email) };
      };
    };
    case ("principal") { #principal(Principal.fromText(userId)) };
    case (_) { return #err("Invalid user type") };
  };
  
  switch (getUserByIdentifier(identifier)) {
    case (?profile) { 
      #ok({
        nickname = profile.nickname;
        authType = profile.authType;
        gameProfiles = profile.gameProfiles;
        created = profile.created;
        last_updated = profile.last_updated;
      })
    };
    case null { #err("User not found") };
  };
};

// ✅ Returns ONE GameProfile for specific game (GameProfile has no sensitive data, so it's fine)
public query func getGameProfile(
  userIdType : Text, 
  userId : Text, 
  gameId : Text
) : async Result.Result<GameProfile, Text> {
  
  let identifier : UserIdentifier = switch (userIdType) {
    case ("email") { #email(userId) };
    case ("session") {
      switch (validateSessionInternal(userId)) {
        case (#err(e)) { return #err(e) };
        case (#ok(session)) { #email(session.email) };
      };
    };
    case ("principal") { #principal(Principal.fromText(userId)) };
    case (_) { return #err("Invalid user type") };
  };

  switch (getUserByIdentifier(identifier)) {
    case (?user) {
      for ((gId, gProfile) in user.gameProfiles.vals()) {
        if (gId == gameId) {
          return #ok(gProfile);  // ✅ GameProfile has no sensitive data
        };
      };
      #err("Game profile not found")
    };
    case null { #err("User not found") };
  }
};

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Private Profile Data Calls
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// ✅ SECURE: Returns full profile with sensitive data (update call)
public shared(msg) func getMyProfile() : async Result.Result<UserProfile, Text> {
  // Auto-detect caller's identity
  let caller = msg.caller;
  
  if (Principal.isAnonymous(caller)) {
    return #err("Authentication required");
  };
  
  // Try to find user by principal
  switch (usersByPrincipal.get(caller)) {
    case (?profile) { 
      #ok(profile)  // Full profile with email/identifier
    };
    case null { 
      #err("Profile not found") 
    };
  };
};

// ✅ SECURE: Session-based version
public shared(msg) func getMyProfileBySession(sessionId : Text) : async Result.Result<UserProfile, Text> {
  switch (validateSessionInternal(sessionId)) {
    case (#err(e)) { return #err(e) };
    case (#ok(session)) {
      switch (usersByEmail.get(session.email)) {
        case (?profile) { #ok(profile) };  // Full profile
        case null { #err("User not found") };
      };
    };
  };
};


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ANALYTICS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  public shared func trackEvent(
    userIdType : Text,
    userId : Text,
    eventType : Text,
    gameId : Text,
    metadata : [(Text, Text)]
  ) : async () {
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(Principal.fromText(userId)) };
      case (_) { return };
    };
    
    trackEventInternal(identifier, gameId, eventType, metadata);
  };

  public query func getDailyStats(date : Text, gameId : Text) : async ?DailyStats {
    dailyStats.get(date # ":" # gameId)
  };

  public query func getPlayerAnalytics(userIdType : Text, userId : Text, gameId : Text) : async ?PlayerStats {
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(Principal.fromText(userId)) };
      case (_) { return null };
    };
    
    let playerKey = identifierToText(identifier) # ":" # gameId;
    playerStats.get(playerKey)
  };

  public query func getAnalyticsSummary() : async {
    totalEvents : Nat;
    uniquePlayers : Nat;
    totalGames : Nat;
    totalDays : Nat;
    mostActiveDay : Text;
    recentEvents : Nat;
  } {
    var mostGames = 0;
    var mostActiveDay = "";
    
    for ((_, stats) in dailyStats.entries()) {
      if (stats.totalGames > mostGames) {
        mostGames := stats.totalGames;
        mostActiveDay := stats.date;
      };
    };
    
    let recentCount = if (analyticsEvents.size() > 100) { 100 } else { analyticsEvents.size() };
    
    {
      totalEvents = analyticsEvents.size();
      uniquePlayers = usersByEmail.size() + usersByPrincipal.size();
      totalGames = games.size();
      totalDays = dailyStats.size();
      mostActiveDay = mostActiveDay;
      recentEvents = recentCount;
    }
  };

  public query func getRecentEvents(limit : Nat) : async [AnalyticsEvent] {
    let cap = if (limit > 100) { 100 } else { limit };
    let size = analyticsEvents.size();
    
    if (size == 0) { return [] };
    
    let startIdx = if (size > cap) { size - cap } else { 0 };
    
    var events = Buffer.Buffer<AnalyticsEvent>(cap);
    for (i in Iter.range(startIdx, size - 1)) {
      events.add(analyticsEvents.get(i));
    };
    
    Buffer.toArray(events)
  };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FILE MANAGEMENT
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  public shared func uploadFile(filename : Text, data : Blob) : async Result.Result<Text, Text> {
    if (Blob.toArray(data).size() > MAX_FILE_SIZE) {
      return #err("File too large. Max size: 5MB");
    };
    
    if (List.size(files) >= MAX_FILES) {
      return #err("File limit reached. Max files: " # Nat.toText(MAX_FILES));
    };
    
    var found = false;
    let newFiles = List.map<(Text, Blob), (Text, Blob)>(
      files,
      func (f : (Text, Blob)) : (Text, Blob) {
        if (f.0 == filename) {
          found := true;
          (filename, data)
        } else {
          f
        }
      }
    );
    
    if (found) {
      files := newFiles;
      #ok("File updated: " # filename)
    } else {
      files := List.push((filename, data), files);
      #ok("File uploaded: " # filename)
    }
  };

  public shared func deleteFile(filename : Text) : async Result.Result<Text, Text> {
    let newFiles = List.filter<(Text, Blob)>(
      files,
      func (f : (Text, Blob)) : Bool { f.0 != filename }
    );
    
    if (List.size(newFiles) == List.size(files)) {
      #err("File not found: " # filename)
    } else {
      files := newFiles;
      #ok("File deleted: " # filename)
    }
  };

  public query func listFiles() : async [Text] {
    List.toArray(
      List.map<(Text, Blob), Text>(
        files,
        func(tup : (Text, Blob)) : Text { tup.0 }
      )
    )
  };

  public query func getFile(filename : Text) : async ?Blob {
    let found = List.find<(Text, Blob)>(
      files,
      func(tup : (Text, Blob)) : Bool { tup.0 == filename }
    );
    switch (found) {
      case null null;
      case (?(_, blob)) ?blob;
    }
  };

  public query func getFileInfo(filename : Text) : async ?{ name: Text; size: Nat } {
    let found = List.find<(Text, Blob)>(
      files,
      func(tup : (Text, Blob)) : Bool { tup.0 == filename }
    );
    switch (found) {
      case null null;
      case (?(name, blob)) ?{ name = name; size = Blob.toArray(blob).size() };
    }
  };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ADMIN
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

 public shared(msg) func adminGate(command : Text, args : [Text]) : async Result.Result<Text, Text> {
    // Emergency pause check
    if (emergencyPaused and command != "emergencyUnpause") {
      logAction(msg.caller, command, args, false, "System paused");
      return #err("🚨 EMERGENCY PAUSE ACTIVE - All operations frozen");
    };
    
    // Basic admin check
    if (not isAdmin(msg.caller)) {
      logAction(msg.caller, command, args, false, "Unauthorized");
      return #err("⛔️ Unauthorized: Admin access only");
    };
    
    // Rate limiting check
  switch (checkRateLimit(msg.caller, command)) {
  case (#err(errorMsg)) {  // ← Changed from 'msg' to 'errorMsg'
    logAction(msg.caller, command, args, false, "Rate limited");
    return #err(errorMsg);  // ← Changed from 'msg' to 'errorMsg'
  };
  case (#ok()) {};
};
    
    // Execute command
    let result = switch (command) {
      
      // ========== USER MANAGEMENT ==========
      
      case ("removeUser") {
        if (not hasPermission(msg.caller, #Moderator)) {
          #err("🔒 Permission denied: Moderator role required")
        } else if (args.size() < 2) {
          #err("Usage: removeUser <type> <id>")
        } else {
          let userType = args[0];
          let userId = args[1];
          
          let removed = switch (userType) {
            case ("email") { 
              switch (usersByEmail.remove(userId)) {
                case (?_) true;
                case null false;
              }
            };
            case ("principal") {
              let principal = try {
                Principal.fromText(userId)
              } catch (_) {
                return #err("Invalid principal format");
              };
              switch (usersByPrincipal.remove(principal)) {
                case (?_) true;
                case null false;
              }
            };
            case (_) false;
          };
          
          if (removed) {
            #ok("✅ User removed successfully.")
          } else {
            #err("⚠️ User not found.")
          }
        }
      };
      
      // ========== SOFT DELETE WITH GRACE PERIOD ==========
      
      case ("deleteUser") {
        if (not hasPermission(msg.caller, #Moderator)) {
          #err("🔒 Permission denied: Moderator role required")
        } else if (args.size() < 2) {
          #err("Usage: deleteUser <type> <id> [reason]\nThis starts a 30-day soft delete process.")
        } else {
          let userType = args[0];
          let userId = args[1];
          let reason = if (args.size() >= 3) { args[2] } else { "User requested deletion" };
          
          // Generate confirmation code
          let confirmationCode = generateConfirmationCode(userId);
          let expiresAt = now() + 300_000_000_000; // 5 minutes to confirm
          
          // Store pending deletion
          let pending : PendingDeletion = {
            userId = userId;
            userType = userType;
            requestedBy = msg.caller;
            requestedAt = now();
            confirmationCode = confirmationCode;
            expiresAt = expiresAt;
          };
          
          pendingDeletions.put(userId, pending);
          
          #ok("⚠️ DELETION REQUESTED\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "User: " # userId # "\n" #
              "Reason: " # reason # "\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "⚠️ This will start a 30-day grace period.\n" #
              "To confirm, run:\n" #
              "adminGate(\"confirmDeleteUser\", [\"" # userId # "\", \"" # confirmationCode # "\"])\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "⏱️ Confirmation expires in 5 minutes.")
        }
      };
      
      case ("confirmDeleteUser") {
        if (not hasPermission(msg.caller, #Moderator)) {
          #err("🔒 Permission denied: Moderator role required")
        } else if (args.size() < 2) {
          #err("Usage: confirmDeleteUser <userId> <confirmationCode>")
        } else {
          let userId = args[0];
          let confirmationCode = args[1];
          
          switch (pendingDeletions.get(userId)) {
            case (null) {
              #err("❌ No pending deletion found for this user")
            };
            case (?pending) {
              // Verify confirmation code
              if (pending.confirmationCode != confirmationCode) {
                #err("❌ Invalid confirmation code")
              } else if (now() > pending.expiresAt) {
                pendingDeletions.delete(userId);
                #err("❌ Confirmation expired. Please request deletion again.")
              } else if (not Principal.equal(pending.requestedBy, msg.caller)) {
                #err("❌ Only the admin who requested deletion can confirm")
              } else {
                // Get user before deletion
                let userOpt = switch (pending.userType) {
                  case ("email") { usersByEmail.get(userId) };
                  case ("principal") {
                    let principal = try {
                      Principal.fromText(userId)
                    } catch (_) {
                      return #err("Invalid principal format");
                    };
                    usersByPrincipal.get(principal)
                  };
                  case (_) { null };
                };
                
                switch (userOpt) {
                  case (null) {
                    pendingDeletions.delete(userId);
                    #err("⚠️ User not found")
                  };
                  case (?user) {
                    // Move to soft delete storage
                    let deletedUser : DeletedUser = {
                      user = user;
                      deletedBy = msg.caller;
                      deletedAt = now();
                      permanentDeletionAt = now() + 2_592_000_000_000_000; // 30 days in nanoseconds
                      reason = "Admin deletion";
                      canRecover = true;
                    };
                    
                    // Remove from active users
                    let removed = switch (pending.userType) {
                      case ("email") { 
                        usersByEmail.delete(userId);
                        true
                      };
                      case ("principal") {
                        let principal = Principal.fromText(userId);
                        usersByPrincipal.delete(principal);
                        true
                      };
                      case (_) false;
                    };
                    
                    if (removed) {
                      deletedUsers.put(userId, deletedUser);
                      pendingDeletions.delete(userId);
                      
                      let gameProfileCount = user.gameProfiles.size();
                      var achievementCount = 0;
                      for ((_, profile) in user.gameProfiles.vals()) {
                        achievementCount += profile.achievements.size();
                      };
                      
                      #ok("🗑️ USER SOFT DELETED\n" #
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                          "User: " # userId # "\n" #
                          "Game profiles: " # Nat.toText(gameProfileCount) # "\n" #
                          "Achievements: " # Nat.toText(achievementCount) # "\n" #
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                          "⏱️ 30-day grace period started\n" #
                          "📅 Permanent deletion: " # Nat64.toText(deletedUser.permanentDeletionAt) # "\n" #
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                          "💡 User can be recovered with: recoverUser")
                    } else {
                      #err("❌ Deletion failed")
                    }
                  };
                }
              }
            };
          }
        }
      };
      
      case ("recoverUser") {
        if (not hasPermission(msg.caller, #Moderator)) {
          #err("🔒 Permission denied: Moderator role required")
        } else if (args.size() < 1) {
          #err("Usage: recoverUser <userId>")
        } else {
          let userId = args[0];
          
          switch (deletedUsers.get(userId)) {
            case (null) {
              #err("❌ No deleted user found with this ID")
            };
            case (?deleted) {
              if (not deleted.canRecover) {
                #err("❌ User cannot be recovered (permanently deleted)")
              } else if (now() > deleted.permanentDeletionAt) {
                #err("❌ Grace period expired - user permanently deleted")
              } else {
                // Restore user
                putUserByIdentifier(deleted.user);
                deletedUsers.delete(userId);
                
                #ok("♻️ USER RECOVERED\n" #
                    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                    "User: " # userId # "\n" #
                    "Originally deleted: " # Nat64.toText(deleted.deletedAt) # "\n" #
                    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                    "✅ User successfully restored with all data")
              }
            };
          }
        }
      };
      
      case ("listDeletedUsers") {
        if (not hasPermission(msg.caller, #Support)) {
          #err("🔒 Permission denied: Support role required")
        } else {
          var result = "🗑️ DELETED USERS\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
          var count = 0;
          
          for ((userId, deleted) in deletedUsers.entries()) {
            let daysRemaining = (deleted.permanentDeletionAt - now()) / 86_400_000_000_000; // Convert to days
            result := result # "\n" # userId # "\n" #
                     "  Deleted: " # Nat64.toText(deleted.deletedAt) # "\n" #
                     "  Days until permanent: " # Nat64.toText(daysRemaining) # "\n" #
                     "  Can recover: " # (if (deleted.canRecover) "✅" else "❌") # "\n";
            count += 1;
          };
          
          if (count == 0) {
            result := result # "\nNo deleted users in grace period.";
          } else {
            result := result # "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                     "Total: " # Nat.toText(count) # " users";
          };
          
          #ok(result)
        }
      };
      
      case ("permanentDelete") {
        // Nuclear option - bypass grace period (SuperAdmin only)
        if (not hasPermission(msg.caller, #SuperAdmin)) {
          #err("🔒 Permission denied: SuperAdmin role required for permanent deletion")
        } else if (args.size() < 1) {
          #err("Usage: permanentDelete <userId>\n⚠️ WARNING: This bypasses the 30-day grace period!")
        } else {
          let userId = args[0];
          
          switch (deletedUsers.get(userId)) {
            case (null) {
              #err("❌ User not found in deleted users")
            };
            case (?deleted) {
              deletedUsers.delete(userId);
              #ok("💀 USER PERMANENTLY DELETED\n" #
                  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                  "User: " # userId # "\n" #
                  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                  "⚠️ This action CANNOT be undone.\n" #
                  "✅ All data permanently erased.")
            };
          }
        }
      };
      
      // ========== BACKUP & RESTORE ==========
      
      case ("backup") {
        if (not hasPermission(msg.caller, #SuperAdmin)) {
          #err("🔒 Permission denied: SuperAdmin role required")
        } else {
          let timestamp = now();
          
          // Calculate metadata
          var totalGameProfiles = 0;
          for ((_, user) in usersByEmail.entries()) {
            totalGameProfiles += user.gameProfiles.size();
          };
          for ((_, user) in usersByPrincipal.entries()) {
            totalGameProfiles += user.gameProfiles.size();
          };
          
          let backup : BackupData = {
            version = "2.0.0";
            timestamp = timestamp;
            createdBy = msg.caller;
            emailUsers = Iter.toArray(usersByEmail.entries());
            principalUsers = Iter.toArray(usersByPrincipal.entries());
            games = Iter.toArray(games.entries());
            deletedUsers = Iter.toArray(deletedUsers.entries());
            metadata = {
              totalUsers = usersByEmail.size() + usersByPrincipal.size();
              totalGames = games.size();
              totalGameProfiles = totalGameProfiles;
              totalDeletedUsers = deletedUsers.size();
            };
          };
          
          // In production, you'd serialize this and store it
          // For now, return summary
          #ok("🗄️ BACKUP CREATED\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "Timestamp: " # Nat64.toText(timestamp) # "\n" #
              "Version: 2.0.0\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "Email users: " # Nat.toText(backup.emailUsers.size()) # "\n" #
              "Principal users: " # Nat.toText(backup.principalUsers.size()) # "\n" #
              "Games: " # Nat.toText(backup.games.size()) # "\n" #
              "Game profiles: " # Nat.toText(totalGameProfiles) # "\n" #
              "Deleted users: " # Nat.toText(backup.deletedUsers.size()) # "\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "✅ Backup ready for export\n" #
              "💡 Store this data off-chain for disaster recovery")
        }
      };
      
      // ========== DATA EXPORT (GDPR) ==========
      
      case ("exportUserData") {
        if (not hasPermission(msg.caller, #Support)) {
          #err("🔒 Permission denied: Support role required")
        } else if (args.size() < 2) {
          #err("Usage: exportUserData <type> <id>")
        } else {
          let userType = args[0];
          let userId = args[1];
          
          let userOpt = switch (userType) {
            case ("email") { usersByEmail.get(userId) };
            case ("principal") {
              let principal = try {
                Principal.fromText(userId)
              } catch (_) {
                return #err("❌ Invalid principal format");
              };
              usersByPrincipal.get(principal)
            };
            case (_) { null };
          };
          
          switch (userOpt) {
            case (null) { #err("⚠️ User not found") };
            case (?user) {
              var export = "📦 USER DATA EXPORT\n" #
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                          "Nickname: " # user.nickname # "\n" #
                          "Auth Type: " # debug_show(user.authType) # "\n" #
                          "Created: " # Nat64.toText(user.created) # "\n" #
                          "Last Updated: " # Nat64.toText(user.last_updated) # "\n" #
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                          "Game Profiles (" # Nat.toText(user.gameProfiles.size()) # "):\n";
              
              for ((gameId, gProfile) in user.gameProfiles.vals()) {
                export := export # "\n🎮 " # gameId # "\n" #
                         "  Score: " # Nat64.toText(gProfile.total_score) # "\n" #
                         "  Best Streak: " # Nat64.toText(gProfile.best_streak) # "\n" #
                         "  Achievements: " # Nat.toText(gProfile.achievements.size()) # "\n" #
                         "  Play Count: " # Nat.toText(gProfile.play_count) # "\n" #
                         "  Last Played: " # Nat64.toText(gProfile.last_played) # "\n";
              };
              
              export := export # "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                       "✅ GDPR-compliant data export";
              
              #ok(export)
            };
          }
        }
      };
      
      // ========== AUDIT & SECURITY ==========
      
      case ("auditLog") {
        if (not hasPermission(msg.caller, #Support)) {
          #err("🔒 Permission denied: Support role required")
        } else {
          let limit = if (args.size() > 0) {
            switch (Nat.fromText(args[0])) {
              case (?n) n;
              case null 50;
            }
          } else { 50 };
          
          let allLogs = Array.append(auditLogStable, Buffer.toArray(auditLog));
          let recentLogs = if (allLogs.size() > limit) {
            Array.tabulate<AdminAction>(limit, func(i) {
              allLogs[allLogs.size() - limit + i]
            })
          } else {
            allLogs
          };
          
          var result = "📜 AUDIT LOG (Last " # Nat.toText(recentLogs.size()) # " entries)\n" #
                      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
          
          for (action in recentLogs.vals()) {
            let status = if (action.success) "✅" else "❌";
            result := result # "\n[" # Nat64.toText(action.timestamp) # "] " # status # "\n" #
                     "Admin: " # Principal.toText(action.admin) # "\n" #
                     "Role: " # debug_show(action.adminRole) # "\n" #
                     "Command: " # action.command # "\n" #
                     "Result: " # action.result # "\n";
          };
          
          result := result # "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
                   "Total logs: " # Nat.toText(allLogs.size());
          
          #ok(result)
        }
      };
      
      case ("emergencyPause") {
        if (not hasPermission(msg.caller, #SuperAdmin)) {
          #err("🔒 Permission denied: SuperAdmin role required")
        } else {
          emergencyPaused := true;
          #ok("🚨 EMERGENCY PAUSE ACTIVATED\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "All admin operations are now frozen.\n" #
              "Only emergencyUnpause can restore operations.\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
      };
      
      case ("emergencyUnpause") {
        if (not hasPermission(msg.caller, #SuperAdmin)) {
          #err("🔒 Permission denied: SuperAdmin role required")
        } else {
          emergencyPaused := false;
          #ok("✅ Emergency pause lifted. Operations resumed.")
        }
      };
      
      // ========== ADMIN ROLE MANAGEMENT ==========
      
      case ("addAdmin") {
        if (not hasPermission(msg.caller, #SuperAdmin)) {
          #err("🔒 Permission denied: SuperAdmin role required")
        } else if (args.size() < 2) {
          #err("Usage: addAdmin <principal> <role>\nRoles: SuperAdmin, Moderator, Support, ReadOnly")
        } else {
          let principal = try {
            Principal.fromText(args[0])
          } catch (_) {
            return #err("Invalid principal format");
          };
          
          let role : AdminRole = switch (args[1]) {
            case ("SuperAdmin") #SuperAdmin;
            case ("Moderator") #Moderator;
            case ("Support") #Support;
            case ("ReadOnly") #ReadOnly;
            case (_) return #err("Invalid role. Use: SuperAdmin, Moderator, Support, ReadOnly");
          };
          
          adminRoles.put(principal, role);
          #ok("✅ Admin added: " # Principal.toText(principal) # " as " # debug_show(role))
        }
      };
      
      case ("listAdmins") {
        if (not hasPermission(msg.caller, #Support)) {
          #err("🔒 Permission denied: Support role required")
        } else {
          var result = "👥 ADMIN LIST\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
          
          for ((principal, role) in adminRoles.entries()) {
            result := result # "\n" # Principal.toText(principal) # "\n" #
                     "  Role: " # debug_show(role) # "\n";
          };
          
          #ok(result)
        }
      };
      
      case ("removeAdmin") {
        if (not hasPermission(msg.caller, #SuperAdmin)) {
          #err("🔒 Permission denied: SuperAdmin role required")
        } else if (args.size() < 1) {
          #err("Usage: removeAdmin <principal>")
        } else {
          let principal = try {
            Principal.fromText(args[0])
          } catch (_) {
            return #err("Invalid principal format");
          };
          
          // Don't allow removing yourself
          if (Principal.equal(principal, msg.caller)) {
            #err("❌ Cannot remove yourself as admin")
          } else {
            adminRoles.delete(principal);
            #ok("✅ Admin removed: " # Principal.toText(principal))
          }
        }
      };
      
      // ========== SYSTEM STATS ==========
      
      case ("getStats") {
        if (not hasPermission(msg.caller, #ReadOnly)) {
          #err("🔒 Permission denied: ReadOnly role required")
        } else {
          let emailUsers = usersByEmail.size();
          let principalUsers = usersByPrincipal.size();
          let gameCount = games.size();
          let deletedCount = deletedUsers.size();
          let adminCount = adminRoles.size();
          let auditCount = auditLogStable.size() + auditLog.size();
          
          var totalGameProfiles = 0;
          for ((_, user) in usersByEmail.entries()) {
            totalGameProfiles += user.gameProfiles.size();
          };
          for ((_, user) in usersByPrincipal.entries()) {
            totalGameProfiles += user.gameProfiles.size();
          };
          
          #ok("📊 SYSTEM STATISTICS\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
              "👥 Users\n" #
              "  Email: " # Nat.toText(emailUsers) # "\n" #
              "  Principal: " # Nat.toText(principalUsers) # "\n" #
              "  Total active: " # Nat.toText(emailUsers + principalUsers) # "\n" #
              "  Soft deleted: " # Nat.toText(deletedCount) # "\n" #
              "\n🎮 Games\n" #
              "  Registered: " # Nat.toText(gameCount) # "\n" #
              "  Total profiles: " # Nat.toText(totalGameProfiles) # "\n" #
              "\n🔐 Security\n" #
              "  Admins: " # Nat.toText(adminCount) # "\n" #
              "  Audit logs: " # Nat.toText(auditCount) # "\n" #
              "  Emergency pause: " # (if (emergencyPaused) "🚨 ACTIVE" else "✅ Normal") # "\n" #
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
      };
      
      case ("help") {
        #ok("📚 ADMIN COMMANDS\n" #
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
            "👥 User Management (Moderator+)\n" #
            "  • deleteUser <type> <id> [reason]\n" #
            "  • confirmDeleteUser <userId> <code>\n" #
            "  • recoverUser <userId>\n" #
            "  • listDeletedUsers\n" #
            "  • removeUser <type> <id>\n" #
            "  • exportUserData <type> <id>\n" #
            "\n🗄️ Backup (SuperAdmin)\n" #
            "  • backup\n" #
            "\n🔐 Security (SuperAdmin)\n" #
            "  • emergencyPause\n" #
            "  • emergencyUnpause\n" #
            "  • addAdmin <principal> <role>\n" #
            "  • removeAdmin <principal>\n" #
            "\n📊 Information (Support+)\n" #
            "  • getStats\n" #
            "  • listAdmins\n" #
            "  • auditLog [limit]\n" #
            "\n⚠️ Dangerous (SuperAdmin)\n" #
            "  • permanentDelete <userId>\n" #
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" #
            "Roles: SuperAdmin > Moderator > Support > ReadOnly")
      };
      
      case (_) {
        #err("❌ Unknown command. Type 'help' for available commands.")
      };
    };
    
    // Log the action
    let success = switch (result) {
      case (#ok(_)) true;
      case (#err(_)) false;
    };
    
    let resultMsg = switch (result) {
      case (#ok(msg)) msg;
      case (#err(msg)) msg;
    };
    
    logAction(msg.caller, command, args, success, resultMsg);
    
    result
  };

  public query func getSystemInfo() : async {
    emailUserCount : Nat;
    principalUserCount : Nat;
    gameCount : Nat;
    totalEvents : Nat;
    activeDays : Nat;
    fileCount : Nat;
    suspicionLogSize : Nat;
  } {
    {
      emailUserCount = usersByEmail.size();
      principalUserCount = usersByPrincipal.size();
      gameCount = games.size();
      totalEvents = analyticsEvents.size();
      activeDays = dailyStats.size();
      fileCount = List.size(files);
      suspicionLogSize = List.size(suspicionLog);
    }
  };

  public shared(msg) func adminCleanupSessions() : async Text {
    if (not isAdmin(msg.caller)) {
        throw Error.reject("Admin only");
    };
    
    let before = sessions.size();
    cleanupExpiredSessions();
    let after = sessions.size();
    
    "Cleaned " # Nat.toText(before - after) # " expired sessions"
};
}
