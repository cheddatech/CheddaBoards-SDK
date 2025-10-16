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
import Int "mo:base/Int";
import Order "mo:base/Order";
import Random "mo:base/Random";

persistent actor CheddaBoards {

  // ──────────────────────────────────────────────────────────────────────────
  // TYPES
  // ──────────────────────────────────────────────────────────────────────────

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

  public type Achievement = {
    id : Text;
    name : Text;
    description : Text;
    gameId : Text; 
  };

  public type GameProfile = {
    gameId : Text;
    total_score : Nat64;
    best_streak : Nat64;
    achievements : [Achievement];
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

  // ──────────────────────────────────────────────────────────────────────────
  // STABLE STORAGE
  // ──────────────────────────────────────────────────────────────────────────

  private stable var stableUsersByEmail : [(Text, UserProfile)] = [];
  private stable var stableUsersByPrincipal : [(Principal, UserProfile)] = [];
  private stable var stableGames : [(Text, GameInfo)] = [];
  private stable var stableSessions : [(Text, Session)] = [];
  private stable var stableSuspicionLog : [{ player_id : Text; gameId : Text; reason : Text; timestamp : Nat64 }] = [];
  private stable var stableFiles : [(Text, Blob)] = [];
  private stable var stableAnalyticsEvents : [AnalyticsEvent] = [];
  private stable var stableDailyStats : [(Text, DailyStats)] = [];
  private stable var stablePlayerStats : [(Text, PlayerStats)] = [];
  private stable var stableLastSubmitTime : [(Text, Nat64)] = [];
  private stable var sessionCounter : Nat64 = 0;

  // ──────────────────────────────────────────────────────────────────────────
  // RUNTIME MAPS
  // ──────────────────────────────────────────────────────────────────────────

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
  
  // ──────────────────────────────────────────────────────────────────────────
  // CONSTANTS  
  // ──────────────────────────────────────────────────────────────────────────

  private transient let CONTROLLER : Principal = Principal.fromText("xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxx");
  private transient let MIN_INTERVAL_NS : Nat64 = 0;

  private transient let DEFAULT_MAX_PER_ROUND : Nat64 = 5_000;
  private transient let DEFAULT_MAX_STREAK_DELTA : Nat64 = 200;
  private transient let DEFAULT_ABSOLUTE_SCORE_CAP : Nat64 = 100_000;
  private transient let DEFAULT_ABSOLUTE_STREAK_CAP : Nat64 = 2_000;

  private transient let MAX_FILE_SIZE : Nat = 5_000_000;
  private transient let MAX_FILES : Nat = 100;
  private transient let SESSION_DURATION_NS : Nat64 = 7 * 24 * 60 * 60 * 1_000_000_000;
  
  // NEW: Game limit per developer
  private transient let MAX_GAMES_PER_DEVELOPER : Nat = 3;

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  func now() : Nat64 = Nat64.fromIntWrap(Time.now());

  func generateSessionId() : Text {
    sessionCounter += 1;
    let timestamp = now();
    let random = Random.Finite(Blob.fromArray([1,2,3,4,5,6,7,8]));
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

  func isAdmin(caller : Principal) : Bool {
    caller == CONTROLLER
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
    let toRemove = Buffer.Buffer<Text>(0);
    
    for ((id, session) in sessions.entries()) {
      if (session.expires < currentTime) {
        toRemove.add(id);
      };
    };
    
    for (id in toRemove.vals()) {
      sessions.delete(id);
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
      let startIdx = analyticsEvents.size() - 10000;
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

  // NEW: Count games owned by a principal
  func countGamesByOwner(owner : Principal) : Nat {
    var count = 0;
    for ((_, game) in games.entries()) {
      if (game.owner == owner) {
        count += 1;
      };
    };
    count
  };

  // ──────────────────────────────────────────────────────────────────────────
  // UPGRADE HOOKS
  // ──────────────────────────────────────────────────────────────────────────

  system func preupgrade() {
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
  };

  system func postupgrade() {
    usersByEmail := HashMap.HashMap<Text, UserProfile>(10, Text.equal, Text.hash);
    for ((e, prof) in stableUsersByEmail.vals()) { usersByEmail.put(e, prof) };

    usersByPrincipal := HashMap.HashMap<Principal, UserProfile>(10, Principal.equal, Principal.hash);
    for ((p, prof) in stableUsersByPrincipal.vals()) { usersByPrincipal.put(p, prof) };

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

    sessions := HashMap.HashMap<Text, Session>(10, Text.equal, Text.hash);
    for ((id, session) in stableSessions.vals()) { sessions.put(id, session) };

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
  };

  // ──────────────────────────────────────────────────────────────────────────
  // GAME REGISTRATION (UPDATED WITH LIMITS)
  // ──────────────────────────────────────────────────────────────────────────

  public shared(msg) func registerGame(
    gameId : Text, 
    name : Text, 
    description : Text,
    maxScorePerRound : ?Nat64,
    maxStreakDelta : ?Nat64,
    absoluteScoreCap : ?Nat64,
    absoluteStreakCap : ?Nat64
  ) : async Result.Result<Text, Text> {
    
    // NEW: Prevent anonymous principal from registering games
    if (Principal.isAnonymous(msg.caller)) {
      return #err("❌ Must authenticate with Internet Identity to register a game");
    };
    
    // Validate game ID length
    if (Text.size(gameId) < 3 or Text.size(gameId) > 50) {
      return #err("Game ID must be 3-50 characters");
    };
    
    // Check if game already exists
    switch (games.get(gameId)) {
      case (?existing) {
        if (existing.owner == msg.caller) {
          #ok("You already own this game")
        } else {
          #err("Game ID already taken by another developer")
        }
      };
      case null {
        // NEW: Check game limit for this developer
        let currentGameCount = countGamesByOwner(msg.caller);
        
        if (currentGameCount >= MAX_GAMES_PER_DEVELOPER and not isAdmin(msg.caller)) {
          return #err("🚫 Maximum " # Nat.toText(MAX_GAMES_PER_DEVELOPER) # " games per developer. You currently have " # Nat.toText(currentGameCount) # " games registered.");
        };
        
        // Create the new game
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
        
        #ok("✅ Game '" # name # "' registered successfully! (" # Nat.toText(currentGameCount + 1) # "/" # Nat.toText(MAX_GAMES_PER_DEVELOPER) # " games)")
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

  // Rest of the file remains the same...
  // (All authentication, score submission, leaderboard, achievements, analytics, file management, and admin functions stay exactly as they were)

  // ──────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION
  // ──────────────────────────────────────────────────────────────────────────

  public shared func socialLogin(
    email : Text,
    nickname : Text,
    provider : Text
  ) : async Result.Result<Text, Text> {
    
    if (Text.size(nickname) < 2 or Text.size(nickname) > 12) {
      return #err("Nickname must be 2-12 characters");
    };
    
    let authType = if (provider == "google") { #google } else { #apple };
    
    switch (usersByEmail.get(email)) {
      case (?user) {
        #ok("Welcome back, " # user.nickname)
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
        
        #ok("Account created for " # nickname)
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

  public shared(msg) func iiLogin(nickname : Text) : async Result.Result<Text, Text> {
    let caller = msg.caller;
    
    if (Text.size(nickname) < 2 or Text.size(nickname) > 12) {
      return #err("Nickname must be 2-12 characters");
    };
    
    if (Principal.isAnonymous(caller)) {
      return #err("Internet Identity required");
    };
    
    switch (usersByPrincipal.get(caller)) {
      case (?user) {
        #ok("Welcome back, " # user.nickname)
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
        
        #ok("Account created")
      };
    }
  };

  public shared(msg) func changeNickname(
    userIdType : Text,
    userId : Text,
    newNickname : Text
  ) : async Result.Result<Text, Text> {
    
    if (Text.size(newNickname) < 2 or Text.size(newNickname) > 12) {
      return #err("Nickname must be 2-12 characters");
    };
    
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(msg.caller) };
      case (_) { return #err("Invalid user type") };
    };
    
    let user = getUserByIdentifier(identifier);
    
    switch (user) {
      case null { #err("User not found") };
      case (?u) {
        let updatedUser : UserProfile = {
          identifier = u.identifier;
          nickname = newNickname;
          authType = u.authType;
          gameProfiles = u.gameProfiles;
          created = u.created;
          last_updated = now();
        };
        
        putUserByIdentifier(updatedUser);
        
        trackEventInternal(u.identifier, "default", "nickname_change", [
          ("old", u.nickname),
          ("new", newNickname)
        ]);
        
        #ok("Nickname changed to " # newNickname)
      };
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // SCORE SUBMISSION
  // ──────────────────────────────────────────────────────────────────────────

  public shared(msg) func submitScore(
    userIdType : Text,
    userId : Text,
    gameId : Text,
    scoreNat : Nat,
    streakNat : Nat
  ) : async Result.Result<Text, Text> {
    
    let score = Nat64.fromNat(scoreNat);
    let streak = Nat64.fromNat(streakNat);
    let t = now();

    let rules = getValidationRules(gameId);

    if (score > rules.absoluteScoreCap or streak > rules.absoluteStreakCap) {
      logSuspicion(userId # "/" # userIdType, gameId, "Absolute cap exceeded");
      return #err("Invalid score or streak (exceeds maximum allowed)");
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

    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(msg.caller) };
      case (_) { return #err("Invalid user type") };
    };

    let user = getUserByIdentifier(identifier);

    switch (user) {
      case (?u) {
        let submitKey = makeSubmitKey(u.identifier, gameId);
        switch (lastSubmitTime.get(submitKey)) {
          case (?prev) {
            if (t - prev < 2_000_000_000) {
              return #err("Please wait 2 seconds between your submissions.");
            };
          };
          case null {};
        };
        lastSubmitTime.put(submitKey, t);

        var gameProfiles = Buffer.Buffer<(Text, GameProfile)>(u.gameProfiles.size());
        var found = false;
        var scoreImproved = false;
        var streakImproved = false;

        for ((gId, gProfile) in u.gameProfiles.vals()) {
          if (gId == gameId) {
            found := true;
            
            var updatedScore = gProfile.total_score;
            var updatedStreak = gProfile.best_streak;
            
            if (score > gProfile.total_score) {
              if (score - gProfile.total_score > rules.maxScorePerRound) {
                logSuspicion(identifierToText(u.identifier), gameId, "Score delta too high");
                return #err("Score increase too large for a single round.");
              };
              updatedScore := score;
              scoreImproved := true;
            };

            if (streak > gProfile.best_streak) {
              if (streak - gProfile.best_streak > rules.maxStreakDelta) {
                logSuspicion(identifierToText(u.identifier), gameId, "Streak delta too high");
                return #err("Streak increase too large for a single round.");
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
          
          switch (games.get(gameId)) {
            case (?gameInfo) {
              games.put(gameId, updateGameStats(gameInfo, 1, 1));
            };
            case null {};
          };
        } else {
          switch (games.get(gameId)) {
            case (?gameInfo) {
              games.put(gameId, updateGameStats(gameInfo, 0, 1));
            };
            case null {};
          };
        };

        if (not scoreImproved and not streakImproved) {
          return #ok("No update: score and streak unchanged.");
        };

        let updatedUser : UserProfile = {
          identifier = u.identifier;
          nickname = u.nickname;
          authType = u.authType;
          gameProfiles = Buffer.toArray(gameProfiles);
          created = u.created;
          last_updated = t;
        };
        
        putUserByIdentifier(updatedUser);
        
        cachedLeaderboards.delete(gameId # ":score");
        cachedLeaderboards.delete(gameId # ":streak");

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
          case null {};
        };
        
        trackEventInternal(u.identifier, gameId, "game_end", [
          ("score", Nat64.toText(score)),
          ("streak", Nat64.toText(streak)),
          ("score_improved", if (scoreImproved) "true" else "false"),
          ("streak_improved", if (streakImproved) "true" else "false")
        ]);
        
        let message = if (scoreImproved and streakImproved) {
          "New high score and streak!"
        } else if (scoreImproved) {
          "New high score!"
        } else if (streakImproved) {
          "New best streak!"
        } else {
          "Score submitted"
        };
        
        #ok(message # " Score: " # Nat64.toText(score) # ", Streak: " # Nat64.toText(streak))
      };
      case null {
        #err("User not found. Please login first.")
      };
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // SESSION QUERIES
  // ──────────────────────────────────────────────────────────────────────────
  
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

  public query func getProfileBySession(sessionId : Text) : async ?UserProfile {
    switch (sessions.get(sessionId)) {
      case (?session) {
        getUserByIdentifier(#email(session.email))
      };
      case null { null };
    }
  };

  public query func getGameProfileBySession(sessionId : Text, gameId : Text) : async ?GameProfile {
    switch (sessions.get(sessionId)) {
      case (?session) {
        switch (getUserByIdentifier(#email(session.email))) {
          case (?u) {
            for ((gId, gProfile) in u.gameProfiles.vals()) {
              if (gId == gameId) return ?gProfile;
            };
            null
          };
          case null { null };
        }
      };
      case null { null };
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // ACHIEVEMENTS
  // ──────────────────────────────────────────────────────────────────────────

  public shared func unlockAchievement(
    userIdType : Text,
    userId : Text,
    gameId : Text,
    achievement : Achievement
  ) : async Result.Result<Text, Text> {
    
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(Principal.fromText(userId)) };
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
            
            for (a in gProfile.achievements.vals()) {
              if (a.id == achievement.id) {
                return #ok("Achievement already unlocked.");
              };
            };
            
            let updated : GameProfile = {
              gameId = gameId;
              total_score = gProfile.total_score;
              best_streak = gProfile.best_streak;
              achievements = Array.append(gProfile.achievements, [achievement]);
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
          ("achievement_id", achievement.id),
          ("achievement_name", achievement.name)
        ]);
        
        #ok("Achievement unlocked: " # achievement.name)
      };
    }
  };

  public query func getAchievements(userIdType : Text, userId : Text, gameId : Text) : async [Achievement] {
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

  // ──────────────────────────────────────────────────────────────────────────
  // LEADERBOARD
  // ──────────────────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────────────────
  // PROFILE QUERIES
  // ──────────────────────────────────────────────────────────────────────────

  public query func getProfile(userIdType : Text, userId : Text) : async ?UserProfile {
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(Principal.fromText(userId)) };
      case (_) { return null };
    };
    
    getUserByIdentifier(identifier)
  };

  public query func getGameProfile(userIdType : Text, userId : Text, gameId : Text) : async ?GameProfile {
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(Principal.fromText(userId)) };
      case (_) { return null };
    };

    switch (getUserByIdentifier(identifier)) {
      case (?u) {
        for ((gId, gProfile) in u.gameProfiles.vals()) {
          if (gId == gameId) return ?gProfile;
        };
        null
      };
      case null { null };
    }
  };

  public query func getAllProfiles(userIdType : Text, userId : Text) : async ?UserProfile {
    let identifier : UserIdentifier = switch (userIdType) {
      case ("email") { #email(userId) };
      case ("principal") { #principal(Principal.fromText(userId)) };
      case (_) { return null };
    };
    
    getUserByIdentifier(identifier)
  };

  // ──────────────────────────────────────────────────────────────────────────
  // ANALYTICS
  // ──────────────────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────────────────
  // FILE MANAGEMENT
  // ──────────────────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────────────────
  // ADMIN
  // ──────────────────────────────────────────────────────────────────────────

  public shared(msg) func adminGate(command : Text, args : [Text]) : async Result.Result<Text, Text> {
    if (not isAdmin(msg.caller)) {
      return #err("⛔️ Unauthorized: Admin access only");
    };

    switch (command) {
      case ("resetAll") {
        usersByEmail := HashMap.HashMap<Text, UserProfile>(10, Text.equal, Text.hash);
        usersByPrincipal := HashMap.HashMap<Principal, UserProfile>(10, Principal.equal, Principal.hash);
        games := HashMap.HashMap<Text, GameInfo>(10, Text.equal, Text.hash);
        lastSubmitTime := HashMap.HashMap<Text, Nat64>(10, Text.equal, Text.hash);
        suspicionLog := List.nil();
        files := List.nil();
        analyticsEvents := Buffer.Buffer<AnalyticsEvent>(100);
        dailyStats := HashMap.HashMap<Text, DailyStats>(10, Text.equal, Text.hash);
        playerStats := HashMap.HashMap<Text, PlayerStats>(10, Text.equal, Text.hash);
        #ok("✅ All data reset successfully.")
      };

      case ("removeUser") {
        if (args.size() < 2) return #err("Usage: removeUser <type> <id>");
        
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
      };

      case ("setScore") {
        if (args.size() < 5) return #err("Usage: setScore <type> <id> <gameId> <score> <streak>");
        
        let userType = args[0];
        let userId = args[1];
        let gameId = args[2];
        let score = Nat64.fromNat(switch (Nat.fromText(args[3])) {
          case (?n) n;
          case null return #err("Invalid score");
        });
        let streak = Nat64.fromNat(switch (Nat.fromText(args[4])) {
          case (?n) n;
          case null return #err("Invalid streak");
        });
        
        let identifier : UserIdentifier = switch (userType) {
          case ("email") { #email(userId) };
          case ("principal") { 
            let p = try {
              Principal.fromText(userId)
            } catch (_) {
              return #err("Invalid principal");
            };
            #principal(p)
          };
          case (_) { return #err("Invalid user type") };
        };
        
        switch (getUserByIdentifier(identifier)) {
          case null { #err("User not found") };
          case (?user) {
            var gameProfiles = Buffer.Buffer<(Text, GameProfile)>(user.gameProfiles.size());
            var found = false;
            
            for ((gId, gProfile) in user.gameProfiles.vals()) {
              if (gId == gameId) {
                found := true;
                gameProfiles.add((gId, {
                  gameId = gameId;
                  total_score = score;
                  best_streak = streak;
                  achievements = gProfile.achievements;
                  last_played = now();
                  play_count = gProfile.play_count;
                }));
              } else {
                gameProfiles.add((gId, gProfile));
              };
            };
            
            if (not found) {
              gameProfiles.add((gameId, {
                gameId = gameId;
                total_score = score;
                best_streak = streak;
                achievements = [];
                last_played = now();
                play_count = 0;
              }));
            };
            
            let updatedUser = {
              identifier = user.identifier;
              nickname = user.nickname;
              authType = user.authType;
              gameProfiles = Buffer.toArray(gameProfiles);
              created = user.created;
              last_updated = now();
            };
            
            putUserByIdentifier(updatedUser);
            #ok("✅ Score set successfully.")
          };
        }
      };

      case ("getSuspicionLog") {
        let logs = List.toArray(suspicionLog);
        var result = "Suspicion Log (" # Nat.toText(logs.size()) # " entries):\n";
        var count = 0;
        for (log in logs.vals()) {
          if (count < 50) {
            result := result # "\n[" # Nat64.toText(log.timestamp) # "] " # 
                      log.gameId # " - " # log.player_id # ": " # log.reason;
            count += 1;
          };
        };
        if (logs.size() > 50) {
          result := result # "\n... and " # Nat.toText(logs.size() - 50) # " more entries";
        };
        #ok(result)
      };

      case ("clearSuspicionLog") {
        suspicionLog := List.nil();
        #ok("✅ Suspicion log cleared.")
      };

      case ("getStats") {
        let emailUsers = usersByEmail.size();
        let principalUsers = usersByPrincipal.size();
        let gameCount = games.size();
        let fileCount = List.size(files);
        let eventCount = analyticsEvents.size();
        let suspicionCount = List.size(suspicionLog);
        
        var totalGameProfiles = 0;
        for ((_, user) in usersByEmail.entries()) {
          totalGameProfiles += user.gameProfiles.size();
        };
        for ((_, user) in usersByPrincipal.entries()) {
          totalGameProfiles += user.gameProfiles.size();
        };
        
        #ok("📊 System Stats:\n" #
            "Email users: " # Nat.toText(emailUsers) # "\n" #
            "Principal users: " # Nat.toText(principalUsers) # "\n" #
            "Total users: " # Nat.toText(emailUsers + principalUsers) # "\n" #
            "Total games: " # Nat.toText(gameCount) # "\n" #
            "Total game profiles: " # Nat.toText(totalGameProfiles) # "\n" #
            "Files: " # Nat.toText(fileCount) # "\n" #
            "Analytics events: " # Nat.toText(eventCount) # "\n" #
            "Daily stats: " # Nat.toText(dailyStats.size()) # "\n" #
            "Player stats: " # Nat.toText(playerStats.size()) # "\n" #
            "Suspicion logs: " # Nat.toText(suspicionCount))
      };

      case (_) {
        #err("Unknown command. Available: resetAll, removeUser, setScore, getSuspicionLog, clearSuspicionLog, getStats")
      };
    }
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
}
