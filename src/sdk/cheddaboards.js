
import { Actor, HttpAgent, AnonymousIdentity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";

const idlFactory = ({ IDL }) => {
  const Result_1 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const Achievement = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'gameId' : IDL.Text,
    'description' : IDL.Text,
  });
  const GameInfo = IDL.Record({
    'created' : IDL.Nat64,
    'totalPlayers' : IDL.Nat,
    'owner' : IDL.Principal,
    'name' : IDL.Text,
    'gameId' : IDL.Text,
    'description' : IDL.Text,
    'isActive' : IDL.Bool,
    'totalPlays' : IDL.Nat,
  });
  const GameProfile = IDL.Record({
    'total_score' : IDL.Nat64,
    'gameId' : IDL.Text,
    'best_streak' : IDL.Nat64,
    'achievements' : IDL.Vec(Achievement),
    'last_played' : IDL.Nat64,
    'play_count' : IDL.Nat,
  });
  const AuthType = IDL.Variant({
    'internetIdentity' : IDL.Null,
    'apple' : IDL.Null,
    'google' : IDL.Null,
    'anonymous' : IDL.Null,
  });
  const UserIdentifier = IDL.Variant({
    'principal' : IDL.Principal,
    'email' : IDL.Text,
  });
  const UserProfile = IDL.Record({
    'created' : IDL.Nat64,
    'nickname' : IDL.Text,
    'gameProfiles' : IDL.Vec(IDL.Tuple(IDL.Text, GameProfile)),
    'authType' : AuthType,
    'last_updated' : IDL.Nat64,
    'identifier' : UserIdentifier,
  });
  const DailyStats = IDL.Record({
    'uniquePlayers' : IDL.Nat,
    'date' : IDL.Text,
    'gameId' : IDL.Text,
    'anonymousPlays' : IDL.Nat,
    'totalScore' : IDL.Nat64,
    'totalGames' : IDL.Nat,
    'newUsers' : IDL.Nat,
    'authenticatedPlays' : IDL.Nat,
  });
  const SortBy = IDL.Variant({ 'streak' : IDL.Null, 'score' : IDL.Null });
  const PlayerStats = IDL.Record({
    'lastPlayed' : IDL.Nat64,
    'avgScore' : IDL.Nat64,
    'gameId' : IDL.Text,
    'favoriteTime' : IDL.Text,
    'totalGames' : IDL.Nat,
    'playStreak' : IDL.Nat,
    'identifier' : UserIdentifier,
  });
  const AnalyticsEvent = IDL.Record({
    'metadata' : IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
    'gameId' : IDL.Text,
    'timestamp' : IDL.Nat64,
    'identifier' : UserIdentifier,
    'eventType' : IDL.Text,
  });
  const Result = IDL.Variant({
    'ok' : IDL.Record({
      'nickname' : IDL.Text,
      'valid' : IDL.Bool,
      'email' : IDL.Text,
    }),
    'err' : IDL.Text,
  });
  return IDL.Service({
    'adminGate' : IDL.Func([IDL.Text, IDL.Vec(IDL.Text)], [Result_1], []),
    'anonymousLogin' : IDL.Func([IDL.Text], [Result_1], []),
    'deleteFile' : IDL.Func([IDL.Text], [Result_1], []),
    'destroySession' : IDL.Func([IDL.Text], [Result_1], []),
    'getAchievements' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text],
        [IDL.Vec(Achievement)],
        ['query'],
      ),
    'getActiveGames' : IDL.Func([], [IDL.Vec(GameInfo)], ['query']),
    'getActiveSessions' : IDL.Func([], [IDL.Nat], ['query']),
    'getAllProfiles' : IDL.Func(
        [IDL.Text, IDL.Text],
        [IDL.Opt(UserProfile)],
        ['query'],
      ),
    'getAnalyticsSummary' : IDL.Func(
        [],
        [
          IDL.Record({
            'uniquePlayers' : IDL.Nat,
            'totalEvents' : IDL.Nat,
            'totalDays' : IDL.Nat,
            'totalGames' : IDL.Nat,
            'recentEvents' : IDL.Nat,
            'mostActiveDay' : IDL.Text,
          }),
        ],
        ['query'],
      ),
    'getDailyStats' : IDL.Func(
        [IDL.Text, IDL.Text],
        [IDL.Opt(DailyStats)],
        ['query'],
      ),
    'getFile' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Vec(IDL.Nat8))], ['query']),
    'getFileInfo' : IDL.Func(
        [IDL.Text],
        [IDL.Opt(IDL.Record({ 'name' : IDL.Text, 'size' : IDL.Nat }))],
        ['query'],
      ),
    'getGame' : IDL.Func([IDL.Text], [IDL.Opt(GameInfo)], ['query']),
    'getGameAuthStats' : IDL.Func(
        [IDL.Text],
        [
          IDL.Record({
            'total' : IDL.Nat,
            'internetIdentity' : IDL.Nat,
            'apple' : IDL.Nat,
            'google' : IDL.Nat,
            'anonymous' : IDL.Nat,
          }),
        ],
        ['query'],
      ),
    'getGameProfile' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text],
        [IDL.Opt(GameProfile)],
        ['query'],
      ),
    'getGameProfileBySession' : IDL.Func(
        [IDL.Text, IDL.Text],
        [IDL.Opt(GameProfile)],
        ['query'],
      ),
    'getGamesByOwner' : IDL.Func(
        [IDL.Principal],
        [IDL.Vec(GameInfo)],
        ['query'],
      ),
    'getLeaderboard' : IDL.Func(
        [IDL.Text, SortBy, IDL.Nat],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Nat64, IDL.Nat64, IDL.Text))],
        ['query'],
      ),
    'getLeaderboardByAuth' : IDL.Func(
        [IDL.Text, AuthType, SortBy, IDL.Nat],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Nat64, IDL.Nat64, IDL.Text))],
        ['query'],
      ),
    'getPlayerAnalytics' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text],
        [IDL.Opt(PlayerStats)],
        ['query'],
      ),
    'getProfile' : IDL.Func(
        [IDL.Text, IDL.Text],
        [IDL.Opt(UserProfile)],
        ['query'],
      ),
    'getProfileBySession' : IDL.Func(
        [IDL.Text],
        [IDL.Opt(UserProfile)],
        ['query'],
      ),
    'getRecentEvents' : IDL.Func(
        [IDL.Nat],
        [IDL.Vec(AnalyticsEvent)],
        ['query'],
      ),
    'getSessionInfo' : IDL.Func(
        [IDL.Text],
        [
          IDL.Opt(
            IDL.Record({
              'created' : IDL.Nat64,
              'nickname' : IDL.Text,
              'expires' : IDL.Nat64,
              'authType' : IDL.Text,
              'email' : IDL.Text,
              'lastUsed' : IDL.Nat64,
            })
          ),
        ],
        ['query'],
      ),
    'getSystemInfo' : IDL.Func(
        [],
        [
          IDL.Record({
            'principalUserCount' : IDL.Nat,
            'fileCount' : IDL.Nat,
            'totalEvents' : IDL.Nat,
            'gameCount' : IDL.Nat,
            'suspicionLogSize' : IDL.Nat,
            'activeDays' : IDL.Nat,
            'emailUserCount' : IDL.Nat,
          }),
        ],
        ['query'],
      ),
    'iiLogin' : IDL.Func([IDL.Text], [Result_1], []),
    'listFiles' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'listGames' : IDL.Func([], [IDL.Vec(GameInfo)], ['query']),
    'registerGame' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [Result_1], []),
    'socialLogin' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [Result_1], []),
    'submitScore' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Nat, IDL.Nat],
        [Result_1],
        [],
      ),
    'toggleGameActive' : IDL.Func([IDL.Text], [Result_1], []),
    'trackEvent' : IDL.Func(
        [
          IDL.Text,
          IDL.Text,
          IDL.Text,
          IDL.Text,
          IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
        ],
        [],
        [],
      ),
    'unlockAchievement' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, Achievement],
        [Result_1],
        [],
      ),
    'updateGame' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [Result_1], []),
    'uploadFile' : IDL.Func([IDL.Text, IDL.Vec(IDL.Nat8)], [Result_1], []),
    'validateSession' : IDL.Func([IDL.Text], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };

class CheddaBoardsSimple {
  constructor(config = {}) {
    // gameId is REQUIRED
    if (!config.gameId) {
      throw new Error('[CheddaBoards] gameId is required. Initialize with: CheddaBoards.init(canisterId, { gameId: "your-game-id" })');
    }
    
    this.canisterId = config.canisterId || "fdvph-sqaaa-aaaap-qqc4a-cai";
    this.gameId = config.gameId;
    this.gameName = config.gameName || "Unnamed Game";
    this.gameDescription = config.gameDescription || "CheddaBoards SDK";
    this.host = config.host || (this._isLocal() ? "http://localhost:4943" : "https://icp-api.io");
    this.autoInit = config.autoInit !== false;
    
    this.actor = null;
    this.identity = new AnonymousIdentity();
    this.authClient = null;
    this.profile = null;
    
    // Session-based auth tracking
    this.sessionId = null; // Session ID for social logins
    this.userType = null; // "email", "principal", or "anonymous"
    this.userId = null; // email address or principal text
    this.authType = null; // "google", "apple", "internetIdentity", "anonymous"
    this.authData = null;
    
    if (this.autoInit) {
      this.init();
    }
  }

  _isLocal() {
    return typeof window !== "undefined" && 
           (window.location.hostname === "localhost" || 
            window.location.hostname === "127.0.0.1");
  }

  async init() {
    try {
      console.log('[CheddaBoards] Initializing for game:', this.gameId);
      
      // Create initial actor for registration
      await this._createActor();
      
      // Register game (don't fail init if this fails)
      await this._registerGame().catch(e => {
        console.log('[CheddaBoards] Game registration skipped:', e.message);
      });
      
      // Check for existing auth and restore session
      await this._restoreSession();
      
      // Load profile if authenticated
      if (this.userType) {
        const profile = await this.loadProfile();
        
        if (profile) {
          console.log('[CheddaBoards] Profile loaded');
          
          // Emit profile event
          if (typeof window !== 'undefined' && window.emitToGodot) {
            window.emitToGodot(
              'profile_loaded',
              profile.nickname,
              String(profile.score || 0),
              String(profile.streak || 0),
              JSON.stringify(profile.achievements || [])
            );
          }
        }
      }
      
      return true;
    } catch (e) {
      console.error('[CheddaBoards] Init failed:', e);
      return false;
    }
  }

  async _restoreSession() {
    const storedAuth = localStorage.getItem("chedda_auth");
    if (!storedAuth) return;
    
    try {
      const auth = JSON.parse(storedAuth);
      console.log('[CheddaBoards] Found stored auth:', auth.authType);
      
      // For session-based auth (Google/Apple), validate the session
      if (auth.sessionId) {
        const validation = await this.actor.validateSession(auth.sessionId);
        
        if (validation && validation.ok) {
          console.log('[CheddaBoards] Session still valid');
          this.sessionId = auth.sessionId;
          this.authData = auth;
          this.userType = auth.userType;
          this.userId = auth.userId;
          this.authType = auth.authType;
        } else {
          console.log('[CheddaBoards] Session expired, clearing auth');
          localStorage.removeItem("chedda_auth");
          this.sessionId = null;
        }
      } else {
        // For II and anonymous, restore as before
        this.authData = auth;
        this.userType = auth.userType;
        this.userId = auth.userId;
        this.authType = auth.authType;
        
        // For Internet Identity, restore the auth client
        if (auth.authType === "internetIdentity") {
          await this._restoreIISession();
        }
      }
      
      console.log('[CheddaBoards] Session restored');
    } catch (e) {
      console.error('[CheddaBoards] Session restoration failed:', e);
      localStorage.removeItem("chedda_auth");
    }
  }

  async _restoreIISession() {
    this.authClient = await AuthClient.create();
    const isAuthenticated = await this.authClient.isAuthenticated();
    
    if (isAuthenticated) {
      console.log('[CheddaBoards] II session still valid');
      this.identity = this.authClient.getIdentity();
      await this._createActor();
    } else {
      console.log('[CheddaBoards] II session expired');
      localStorage.removeItem("chedda_auth");
      this.userType = null;
      this.userId = null;
      this.authType = null;
      this.sessionId = null;
    }
  }

 
  async _createActor() {
  if (!this.identity) {
    this.identity = new AnonymousIdentity();
  }
  
  const agent = new HttpAgent({ 
    identity: this.identity,  // Use existing identity
    host: this.host 
  });
  
  if (this._isLocal()) {
    await agent.fetchRootKey().catch(() => {});
  }
  
  this.actor = Actor.createActor(idlFactory, {
    agent,
    canisterId: this.canisterId
  });
}

  async _registerGame() {
    try {
      const existing = await this.actor.getGame(this.gameId).catch(() => null);
      if (!existing || (Array.isArray(existing) && existing.length === 0)) {
        console.log('[CheddaBoards] Registering new game:', this.gameId);
        const result = await this.actor.registerGame(
          this.gameId,
          this.gameName,
          this.gameDescription
        );
        console.log('[CheddaBoards] Game registration result:', result);
      } else {
        console.log('[CheddaBoards] Game already registered:', this.gameId);
      }
    } catch (e) {
      console.log('[CheddaBoards] Game registration skipped:', e.message);
    }
  }

  _promptNickname(message, defaultValue) {
    // This is a placeholder - should be implemented in the UI layer
    return prompt(message, defaultValue);
  }

  // ===== AUTH METHODS =====
  
  async loginAnonymous(nickname = null) {
    try {
      console.log('[CheddaBoards] Starting anonymous login...');
      
      this.identity = new AnonymousIdentity();
      await this._createActor();
      
      const nick = nickname || `Player${Math.floor(Math.random() * 10000)}`;
      
      const result = await this.actor.anonymousLogin(nick);
      console.log('[CheddaBoards] Anonymous login result:', result);
      
      if (result && result.err) {
        throw new Error(result.err);
      }
      
      this.userType = "anonymous";
      this.userId = "2vxsx-fae"; // Anonymous principal
      this.authType = "anonymous";
      this.sessionId = null; // No session for anonymous
      
      this.authData = {
        userType: "anonymous",
        userId: "2vxsx-fae",
        authType: "anonymous",
        nickname: nick
      };
      
      localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
      localStorage.setItem('auth_method', 'anonymous');
      
      await this.loadProfile();
      
      if (this.profile && typeof window !== 'undefined' && window.emitToGodot) {
        window.emitToGodot(
          'profile_loaded',
          this.profile.nickname,
          String(this.profile.score || 0),
          String(this.profile.streak || 0),
          JSON.stringify(this.profile.achievements || [])
        );
      }
      
      return this.profile;
    } catch (e) {
      console.error('[CheddaBoards] Anonymous login failed:', e);
      throw e;
    }
  }

  async loginII(nickname = null) {
    try {
      console.log('[CheddaBoards] Starting Internet Identity login...');
      
      if (!this.authClient) {
        this.authClient = await AuthClient.create();
      }
      
      return new Promise((resolve, reject) => {
        this.authClient.login({
          identityProvider: "https://identity.ic0.app",
          onSuccess: async () => {
            try {
              // Use the real II identity
              this.identity = this.authClient.getIdentity();
              await this._createActor();
              
              const principalText = this.identity.getPrincipal().toText();
              console.log('[CheddaBoards] II login successful, principal:', principalText);
              
              // Create/update profile with nickname
              const nick = nickname || `Player${Math.floor(Math.random() * 10000)}`;
              const signupResult = await this.actor.iiLogin(nick);
              console.log('[CheddaBoards] II signup result:', signupResult);
              
              if (signupResult && signupResult.err) {
                throw new Error(signupResult.err);
              }
              
              this.userType = "principal";
              this.userId = principalText;
              this.authType = "internetIdentity";
              this.sessionId = null; // No session for II
              
              this.authData = {
                userType: "principal",
                userId: principalText,
                authType: "internetIdentity",
                nickname: nick
              };
              
              localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
              localStorage.setItem('auth_method', 'internetIdentity');
              
              await this.loadProfile();
              
              // Emit events
              if (typeof window !== 'undefined' && window.emitToGodot) {
                window.emitToGodot(
                  'ii_login_success',
                  this.profile.nickname,
                  String(this.profile.score || 0),
                  String(this.profile.streak || 0),
                  JSON.stringify(this.profile.achievements || [])
                );
              }
              
              console.log('[CheddaBoards] II login complete:', this.profile.nickname);
              resolve(this.profile);
            } catch (e) {
              console.error('[CheddaBoards] II login error:', e);
              reject(e);
            }
          },
          onError: (error) => {
            console.error('[CheddaBoards] II authentication failed:', error);
            reject(error);
          }
        });
      });
    } catch (e) {
      console.error("II login failed:", e);
      throw e;
    }
  }

  async loginGoogle(googleCredential, nickname = null) {
  try {
    console.log('[CheddaBoards] Starting Google login...');
    
    // Parse the Google JWT token
    let payload;
    try {
      const parts = googleCredential.split('.');
      if (parts.length !== 3) {
        throw new Error('Invalid JWT format');
      }
      
      const base64Url = parts[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      );
      
      payload = JSON.parse(jsonPayload);
    } catch (e) {
      console.error('[CheddaBoards] Failed to parse Google JWT:', e);
      throw new Error('Failed to parse Google credential');
    }
    
    if (!payload.email) {
      throw new Error('Google credential missing email');
    }
    
    console.log('[CheddaBoards] Google user info:', {
      email: payload.email,
      name: payload.name,
      email_verified: payload.email_verified
    });
    
    // Use anonymous identity for the call
    this.identity = new AnonymousIdentity();
    await this._createActor();
    
    // Determine nickname
    let finalNickname = nickname || 
                       payload.name || 
                       payload.given_name || 
                       payload.email?.split('@')[0] || 
                       `Player${Math.floor(Math.random() * 10000)}`;
    
    if (finalNickname.length > 12) {
      finalNickname = finalNickname.substring(0, 12);
    }
    
    // Call socialLogin - backend returns simple text result
    const signupResult = await this.actor.socialLogin(
      payload.email,
      finalNickname,
      "google"
    );
    
    console.log('[CheddaBoards] Google signup result:', signupResult);
    
    if (signupResult && signupResult.err) {
      throw new Error(signupResult.err);
    }
    
    // NO SESSION HANDLING - Just set up direct authentication
    this.userType = "email";
    this.userId = payload.email;
    this.authType = "google";
    
    this.authData = {
      userType: "email",
      userId: payload.email,
      authType: "google",
      nickname: finalNickname,
      name: payload.name,
      picture: payload.picture
    };
    
    localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
    localStorage.setItem('auth_method', 'google');
    
    await this.loadProfile();
    
    // Emit events
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new CustomEvent("chedda:google_login", { 
        detail: {
          profile: this.profile,
          googleUser: {
            email: payload.email,
            name: payload.name,
            picture: payload.picture
          }
        }
      }));
      
      if (window.emitToGodot) {
        window.emitToGodot(
          'google_login_success',
          this.profile?.nickname || finalNickname,
          String(this.profile?.score || 0),
          String(this.profile?.streak || 0),
          JSON.stringify(this.profile?.achievements || [])
        );
      }
    }
    
    console.log('[CheddaBoards] Google login successful:', this.profile?.nickname || finalNickname);
    return this.profile;
    
  } catch (e) {
    console.error('[CheddaBoards] Google login failed:', e);
    
    // Clean up on failure
    this.userType = null;
    this.userId = null;
    this.authType = null;
    this.authData = null;
    localStorage.removeItem("chedda_auth");
    localStorage.removeItem('auth_method');
    
    throw e;
  }
}

  async loginApple(appleResponse, nickname = null) {
    try {
      console.log('[CheddaBoards] Starting Apple login...');
      
      // Extract ID token
      let idToken;
      if (appleResponse.authorization?.id_token) {
        idToken = appleResponse.authorization.id_token;
      } else if (appleResponse.id_token) {
        idToken = appleResponse.id_token;
      } else if (appleResponse.identityToken) {
        idToken = appleResponse.identityToken;
      } else {
        throw new Error('No ID token found in Apple response');
      }
      
      // Parse the Apple JWT token
      let payload;
      try {
        const parts = idToken.split('.');
        const base64Url = parts[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(
          atob(base64)
            .split('')
            .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
            .join('')
        );
        
        payload = JSON.parse(jsonPayload);
      } catch (e) {
        console.error('[CheddaBoards] Failed to parse Apple JWT:', e);
        throw new Error('Failed to parse Apple ID token');
      }
      
      if (!payload.email) {
        throw new Error('Apple ID token missing email');
      }
      
      console.log('[CheddaBoards] Apple user info:', {
        email: payload.email,
        email_verified: payload.email_verified
      });
      
      // Use anonymous identity for the call
      this.identity = new AnonymousIdentity();
      await this._createActor();
      
      // Determine nickname
      let finalNickname = nickname || payload.email?.split('@')[0] || `Player${Math.floor(Math.random() * 10000)}`;
      
      if (finalNickname.length > 12) {
        finalNickname = finalNickname.substring(0, 12);
      }
      
      // Call social login to create session
      const signupResult = await this.actor.socialLogin(
        payload.email,
        finalNickname,
        "apple"
      );
      
      console.log('[CheddaBoards] Apple signup result:', signupResult);
      
      if (signupResult && signupResult.err) {
  throw new Error(signupResult.err);
}

// No session needed - backend returns simple text
// Just continue with the auth flow
this.userType = "email";
this.userId = payload.email;
this.authType = "apple";

this.authData = {
  userType: "email",
  userId: payload.email,
  authType: "apple",
  nickname: finalNickname,
  name: payload.name,
  picture: payload.picture
};
      
      localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
      localStorage.setItem('auth_method', 'apple');
      
      await this.loadProfile();
      
      // Emit events
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent("chedda:apple_login", { 
          detail: {
            profile: this.profile,
            appleUser: {
              email: payload.email
            }
          }
        }));
        
        if (window.emitToGodot) {
          window.emitToGodot(
            'apple_login_success',
            this.profile.nickname,
            String(this.profile.score || 0),
            String(this.profile.streak || 0),
            JSON.stringify(this.profile.achievements || [])
          );
        }
      }
      
      console.log('[CheddaBoards] Apple login successful:', this.profile.nickname);
      return this.profile;
      
    } catch (e) {
      console.error('[CheddaBoards] Apple login failed:', e);
      
      // Clean up on failure
      this.userType = null;
      this.userId = null;
      this.authType = null;
      this.authData = null;
      this.sessionId = null;
      localStorage.removeItem("chedda_auth");
      localStorage.removeItem('auth_method');
      
      throw e;
    }
  }

  async logout() {
    try {
      // Destroy session on backend if exists
      if (this.sessionId) {
        await this.actor.destroySession(this.sessionId).catch(e => {
          console.warn('[CheddaBoards] Session destroy failed:', e);
        });
      }
      
      // Logout from II if needed
      if (this.authClient) {
        await this.authClient.logout();
      }
      
      this.identity = new AnonymousIdentity();
      this.userType = null;
      this.userId = null;
      this.authType = null;
      this.authData = null;
      this.profile = null;
      this.sessionId = null;
      
      localStorage.removeItem("chedda_auth");
      localStorage.removeItem("auth_method");
      
      await this._createActor();
      return true;
    } catch (e) {
      console.error("Logout failed:", e);
      return false;
    }
  }

  // ===== GAME METHODS =====
  
  async submitScore(score, streak = 0) {
  try {
    // Ensure actor exists with correct identity
    if (!this.actor) {
      await this._createActor();
    }
    
    if (!this.userType) {
      console.warn('[CheddaBoards] Not authenticated. Score submission may fail.');
      return { success: false, error: "Not authenticated" };
    }
    
    console.log('[CheddaBoards] Submitting score:', {
      score,
      streak,
      userType: this.userType,
      userId: this.userId,
      authType: this.authType,
      currentIdentity: this.identity?.getPrincipal?.()?.toText() || 'anonymous'
    });
    
    let userIdType, userId;
    
    // Determine how to submit based on auth type
    if (this.userType === "principal") {
      // For II users, ensure we're using their authenticated identity
      if (this.authClient && await this.authClient.isAuthenticated()) {
        const iiIdentity = this.authClient.getIdentity();
        
        // CRITICAL: Only recreate actor if identity changed
        if (this.identity !== iiIdentity) {
          console.log('[CheddaBoards] Restoring II identity for score submission');
          this.identity = iiIdentity;
          await this._createActor();
        }
      } else {
        console.error('[CheddaBoards] II authentication lost!');
        return { success: false, error: "Internet Identity session expired" };
      }
      
      userIdType = "principal";
      userId = ""; // Empty because backend uses msg.caller
      
      console.log('[CheddaBoards] Submitting as II principal:', this.identity.getPrincipal().toText());
      
    } else if (this.userType === "email") {
      // Social logins use email directly
      userIdType = "email";
      userId = this.userId;
      
      // Ensure we're using anonymous identity for social logins
      if (!(this.identity instanceof AnonymousIdentity)) {
        this.identity = new AnonymousIdentity();
        await this._createActor();
      }
      
      console.log('[CheddaBoards] Submitting as email user:', userId);
      
    } else if (this.userType === "anonymous") {
      userIdType = "anonymous";
      userId = "";
      
      // Ensure anonymous identity
      if (!(this.identity instanceof AnonymousIdentity)) {
        this.identity = new AnonymousIdentity();
        await this._createActor();
      }
      
      console.log('[CheddaBoards] Submitting as anonymous');
      
    } else {
      return { success: false, error: "Unknown user type" };
    }
    
    // Make the actual submission
    const result = await this.actor.submitScore(
      userIdType,
      userId,
      this.gameId,
      Math.floor(score),
      Math.floor(streak)
    );
    
    console.log('[CheddaBoards] Score submission result:', result);
    
    // Refresh profile after score submission
    await this.loadProfile();
    
    if (result && result.ok) {
      return { success: true, message: result.ok };
    } else if (result && result.err) {
      return { success: false, error: result.err };
    }
    
    return { success: true, message: String(result) };
  } catch (e) {
    console.error("Score submission failed:", e);
    return { success: false, error: e.message };
  }
}

  async getLeaderboard(sortBy = "score", limit = 100) {
    try {
      if (!this.actor) await this._createActor();
      
      const sortByVariant = sortBy === "streak" ? { streak: null } : { score: null };
      
      const results = await this.actor.getLeaderboard(this.gameId, sortByVariant, limit);
      
      return results.map(([nickname, score, streak, authType]) => ({
        nickname: nickname,
        score: Number(score || 0),
        streak: Number(streak || 0),
        authType: authType || "unknown"
      }));
    } catch (e) {
      console.error("Leaderboard fetch failed:", e);
      return [];
    }
  }

  async getLeaderboardByAuth(authType, sortBy = "score", limit = 100) {
    // Filter leaderboard by auth type on client side
    const allResults = await this.getLeaderboard(sortBy, limit * 2);
    return allResults.filter(entry => entry.authType === authType).slice(0, limit);
  }

  async getGameAuthStats() {
    try {
      if (!this.actor) await this._createActor();
      
      const leaderboard = await this.getLeaderboard("score", 1000);
      
      const stats = {
        anonymous: 0,
        internetIdentity: 0,
        google: 0,
        apple: 0,
        total: 0
      };
      
      for (const entry of leaderboard) {
        stats.total++;
        switch (entry.authType) {
          case "anonymous": stats.anonymous++; break;
          case "internetIdentity": stats.internetIdentity++; break;
          case "google": stats.google++; break;
          case "apple": stats.apple++; break;
        }
      }
      
      return stats;
    } catch (e) {
      console.error("Game auth stats fetch failed:", e);
      return null;
    }
  }

  async getProfile() {
    try {
      if (!this.actor) await this._createActor();
      
      if (!this.userType) {
        console.log('[CheddaBoards] getProfile: No userType');
        return null;
      }
      
      console.log('[CheddaBoards] Getting profile for:', {
        userType: this.userType,
        sessionId: this.sessionId,
        userId: this.userId,
        gameId: this.gameId
      });
      
      let gameProfileResult;
      let userProfile;
      
      // Get profile based on auth type
      if (this.sessionId) {
        gameProfileResult = await this.actor.getGameProfileBySession(
          this.sessionId,
          this.gameId
        );
        userProfile = await this.actor.getProfileBySession(this.sessionId);
      } else if (this.userType === "principal") {
        // For II users, ensure we're using their identity
        if (this.authClient) {
          const isAuth = await this.authClient.isAuthenticated();
          if (isAuth) {
            this.identity = this.authClient.getIdentity();
            await this._createActor();
          }
        }
        
        console.log('[CheddaBoards] Getting profile by principal:', this.userId);
        gameProfileResult = await this.actor.getGameProfile(
          "principal",
          this.userId,
          this.gameId
        );
        userProfile = await this.actor.getProfile("principal", this.userId);
      } else if (this.userType === "anonymous") {
        console.log('[CheddaBoards] Getting anonymous profile');
        gameProfileResult = await this.actor.getGameProfile(
          "anonymous",
          "",
          this.gameId
        );
        userProfile = await this.actor.getProfile("anonymous", "");
      } else {
        gameProfileResult = await this.actor.getGameProfile(
          this.userType,
          this.userType === "email" ? this.userId : "",
          this.gameId
        );
        userProfile = await this.actor.getProfile(
          this.userType,
          this.userType === "email" ? this.userId : ""
        );
      }
      
      console.log('[CheddaBoards] Profile results:', {
        gameProfileResult,
        userProfile
      });
      
      let nickname = this.authData?.nickname || "Player";
      if (userProfile && userProfile[0]) {
        nickname = userProfile[0].nickname || nickname;
      }
      
      if (gameProfileResult && gameProfileResult[0]) {
        return {
          nickname: nickname,
          score: Number(gameProfileResult[0].total_score || 0),
          streak: Number(gameProfileResult[0].best_streak || 0),
          achievements: gameProfileResult[0].achievements || [],
          lastPlayed: gameProfileResult[0].last_played,
          playCount: Number(gameProfileResult[0].play_count || 0),
          gameId: this.gameId,
          authType: this.authType
        };
      } else {
        // User exists but hasn't played this game
        return {
          nickname: nickname,
          score: 0,
          streak: 0,
          achievements: [],
          playCount: 0,
          gameId: this.gameId,
          authType: this.authType
        };
      }
    } catch (e) {
      console.error("Profile fetch failed:", e);
      return null;
    }
  }

  async getAllGameProfiles() {
    try {
      if (!this.actor) await this._createActor();
      
      if (!this.userType) {
        return null;
      }
      
      let userProfile;
      
      if (this.sessionId) {
        userProfile = await this.actor.getProfileBySession(this.sessionId);
      } else if (this.userType === "principal") {
        userProfile = await this.actor.getProfile("principal", this.userId);
      } else if (this.userType === "anonymous") {
        userProfile = await this.actor.getProfile("anonymous", "");
      } else {
        userProfile = await this.actor.getProfile(
          this.userType,
          this.userType === "email" ? this.userId : ""
        );
      }
      
      if (userProfile && userProfile[0]) {
        const profile = userProfile[0];
        return {
          nickname: profile.nickname,
          authType: this.authType,
          games: profile.gameProfiles.map(([gameId, gameProfile]) => ({
            gameId,
            score: Number(gameProfile.total_score || 0),
            streak: Number(gameProfile.best_streak || 0),
            achievements: gameProfile.achievements || [],
            lastPlayed: gameProfile.last_played,
            playCount: Number(gameProfile.play_count || 0)
          })),
          created: profile.created
        };
      }
      
      return null;
    } catch (e) {
      console.error("All profiles fetch failed:", e);
      return null;
    }
  }

  async loadProfile() {
    this.profile = await this.getProfile();
    if (this.profile && typeof window !== "undefined") {
      window.dispatchEvent(new CustomEvent("chedda:profile", { detail: this.profile }));
    }
    return this.profile;
  }

  async changeNickname(newNickname) {
    try {
      if (!this.actor) await this._createActor();
      
      if (!this.userType) {
        return { success: false, error: "Not authenticated" };
      }
      
      let result;
      
      if (this.sessionId) {
        // For session users, recreate session with new nickname
        const validation = await this.actor.validateSession(this.sessionId);
        if (validation && validation.ok) {
          const email = validation.ok.email;
          const authType = this.authType === "google" ? "google" : "apple";
          
          // Destroy old session
          await this.actor.destroySession(this.sessionId).catch(() => {});
          
          // Create new session with updated nickname
          const newSession = await this.actor.socialLogin(email, newNickname, authType);
          
          if (newSession && newSession.ok) {
            this.sessionId = newSession.ok.sessionId;
            
            // Update stored auth
            if (this.authData) {
              this.authData.sessionId = this.sessionId;
              this.authData.nickname = newNickname;
              localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
            }
            
            result = { ok: "Nickname updated" };
          } else {
            result = newSession;
          }
        } else {
          return { success: false, error: "Session invalid" };
        }
      } else if (this.userType === "principal") {
        // For II users, ensure we're using their identity
        if (this.authClient) {
          const isAuth = await this.authClient.isAuthenticated();
          if (isAuth) {
            this.identity = this.authClient.getIdentity();
            await this._createActor();
          }
        }
        result = await this.actor.iiLogin(newNickname);
      } else {
        result = await this.actor.anonymousLogin(newNickname);
      }
      
      if (result && result.ok) {
        // Update stored auth
        if (this.authData && !this.sessionId) {
          this.authData.nickname = newNickname;
          localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
        }
        
        await this.loadProfile();
        return { success: true, nickname: newNickname };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true, nickname: newNickname };
    } catch (e) {
      console.error("Nickname change failed:", e);
      return { success: false, error: e.message };
    }
  }

  async unlockAchievement(achievementId, name, description) {
    try {
      if (!this.actor) await this._createActor();
      
      if (!this.userType) {
        return { success: false, error: "Not authenticated" };
      }
      
      const achievement = {
        id: achievementId,
        name: name,
        description: description,
        gameId: this.gameId
      };
      
      let userIdType, userId;
      
      if (this.sessionId) {
        // Validate session first
        const validation = await this.actor.validateSession(this.sessionId);
        if (validation && validation.ok) {
          userIdType = "email";
          userId = validation.ok.email;
        } else {
          return { success: false, error: "Session invalid" };
        }
      } else if (this.userType === "principal") {
        userIdType = "principal";
        userId = this.userId;
      } else if (this.userType === "anonymous") {
        userIdType = "anonymous";
        userId = "";
      } else {
        userIdType = this.userType;
        userId = this.userType === "email" ? this.userId : "";
      }
      
      const result = await this.actor.unlockAchievement(
        userIdType,
        userId,
        this.gameId,
        achievement
      );
      
      if (result && result.ok) {
        await this.loadProfile();
        return { success: true };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true };
    } catch (e) {
      console.error("Achievement unlock failed:", e);
      return { success: false, error: e.message };
    }
  }

  // ===== ANALYTICS METHODS =====
  
  async trackEvent(eventType, metadata = {}) {
    try {
      if (!this.actor) await this._createActor();
      
      // Always add gameId and authType to metadata
      metadata.gameId = this.gameId;
      metadata.authType = this.authType || 'none';
      
      // Convert metadata object to array of tuples
      const metadataArray = Object.entries(metadata).map(([k, v]) => [k, String(v)]);
      
      let userIdType = "anonymous";
      let userId = "";
      
      if (this.sessionId) {
        // Validate session first
        const validation = await this.actor.validateSession(this.sessionId);
        if (validation && validation.ok) {
          userIdType = "email";
          userId = validation.ok.email;
        }
      } else if (this.userType) {
        userIdType = this.userType;
        userId = this.userType === "email" ? this.userId : "";
      }
      
      await this.actor.trackEvent(
        userIdType,
        userId,
        eventType,
        this.gameId,
        metadataArray
      );
      
      return { success: true };
    } catch (e) {
      console.error("Event tracking failed:", e);
      return { success: false, error: e.message };
    }
  }

  async getDailyStats(date) {
    try {
      if (!this.actor) await this._createActor();
      
      const stats = await this.actor.getDailyStats(date, this.gameId);
      return stats || null;
    } catch (e) {
      console.error("Daily stats fetch failed:", e);
      return null;
    }
  }

  async getPlayerAnalytics(identifier) {
    // Simplified - would need backend support for full analytics
    return null;
  }

  async getAnalyticsSummary() {
    try {
      if (!this.actor) await this._createActor();
      
      const summary = await this.actor.getAnalyticsSummary();
      
      return {
        totalEvents: Number(summary.totalEvents || 0),
        uniquePlayers: Number(summary.uniquePlayers || 0),
        totalGames: Number(summary.totalGames || 0),
        totalDays: Number(summary.totalDays || 0)
      };
    } catch (e) {
      console.error("Analytics fetch failed:", e);
      return null;
    }
  }

  // ===== GAME MANAGEMENT =====
  
  async listGames() {
    try {
      if (!this.actor) await this._createActor();
      
      const games = await this.actor.listGames();
      return games || [];
    } catch (e) {
      console.error("List games failed:", e);
      return [];
    }
  }

  async getGameInfo() {
    try {
      if (!this.actor) await this._createActor();
      
      const game = await this.actor.getGame(this.gameId);
      return game || null;
    } catch (e) {
      console.error("Get game info failed:", e);
      return null;
    }
  }

  async getSystemInfo() {
    try {
      if (!this.actor) await this._createActor();
      
      const info = await this.actor.getSystemInfo();
      return info;
    } catch (e) {
      console.error("System info fetch failed:", e);
      return null;
    }
  }

  // ===== FILE MANAGEMENT =====
  
  async uploadFile(filename, data) {
    try {
      if (!this.actor) await this._createActor();
      
      let blob;
      if (data instanceof Blob) {
        blob = data;
      } else if (typeof data === 'string') {
        blob = new Blob([data], { type: 'text/plain' });
      } else if (data instanceof ArrayBuffer) {
        blob = new Blob([data]);
      } else {
        blob = new Blob([JSON.stringify(data)], { type: 'application/json' });
      }
      
      const arrayBuffer = await blob.arrayBuffer();
      const result = await this.actor.uploadFile(filename, [...new Uint8Array(arrayBuffer)]);
      
      if (result && result.ok) {
        return { success: true, message: result.ok };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true };
    } catch (e) {
      console.error("File upload failed:", e);
      return { success: false, error: e.message };
    }
  }

  async listFiles() {
    try {
      if (!this.actor) await this._createActor();
      
      const files = await this.actor.listFiles();
      return files || [];
    } catch (e) {
      console.error("List files failed:", e);
      return [];
    }
  }

  async getFile(filename) {
    try {
      if (!this.actor) await this._createActor();
      
      const file = await this.actor.getFile(filename);
      if (file) {
        const uint8Array = new Uint8Array(file);
        return new Blob([uint8Array]);
      }
      return null;
    } catch (e) {
      console.error("Get file failed:", e);
      return null;
    }
  }

  // ===== HELPER METHODS =====
  
  _authTypeToString(authType) {
    if (!authType) return "unknown";
    if (authType.anonymous !== undefined) return "anonymous";
    if (authType.internetIdentity !== undefined) return "internetIdentity";
    if (authType.google !== undefined) return "google";
    if (authType.apple !== undefined) return "apple";
    return "unknown";
  }

  _stringToAuthType(authString) {
    switch (authString.toLowerCase()) {
      case "anonymous":
        return { anonymous: null };
      case "internetidentity":
      case "ii":
        return { internetIdentity: null };
      case "google":
        return { google: null };
      case "apple":
        return { apple: null };
      default:
        return { anonymous: null };
    }
  }

  isAuthenticated() {
    return this.userType !== null && (this.sessionId !== null || this.userId !== null);
  }

  getAuthType() {
    return this.authType;
  }

  getGameId() {
    return this.gameId;
  }

  getPrincipal() {
    if (this.userType === "principal") {
      return this.userId;
    } else if (this.userType === "email") {
      return "session:" + this.sessionId;
    } else {
      return "2vxsx-fae"; // Anonymous
    }
  }

  getAuthData() {
    return this.authData;
  }

  getSessionId() {
    return this.sessionId;
  }
}

// ===== ONE-LINE INITIALIZATION =====
const CheddaAPI = {
  init: async (canisterId, config = {}) => {
    // GameId is REQUIRED
    if (!config.gameId) {
      throw new Error('[CheddaBoards] gameId is required. Usage: CheddaBoards.init(canisterId, { gameId: "your-game-id" })');
    }
    
    const instance = new CheddaBoardsSimple({ 
      canisterId, 
      ...config 
    });
    
    await instance.init();
    
    return {
      // Auth
      login: {
        anonymous: (nickname) => instance.loginAnonymous(nickname),
        google: (cred, nickname) => instance.loginGoogle(cred, nickname),
        apple: (resp, nickname) => instance.loginApple(resp, nickname),
        ii: (nickname) => instance.loginII(nickname),
      },
      logout: () => instance.logout(),
      
      // Game operations
      submitScore: (score, streak) => instance.submitScore(score, streak),
      getLeaderboard: (sortBy, limit) => instance.getLeaderboard(sortBy, limit),
      getLeaderboardByAuth: (authType, sortBy, limit) => instance.getLeaderboardByAuth(authType, sortBy, limit),
      getGameAuthStats: () => instance.getGameAuthStats(),
      changeNickname: (name) => instance.changeNickname(name),
      unlockAchievement: (id, name, desc) => instance.unlockAchievement(id, name, desc),
      
      // Profile operations
      getProfile: () => instance.getProfile(),
      getAllGameProfiles: () => instance.getAllGameProfiles(),
      isAuthenticated: () => instance.isAuthenticated(),
      
      // Analytics
      trackEvent: (type, data) => instance.trackEvent(type, data),
      getDailyStats: (date) => instance.getDailyStats(date),
      getPlayerAnalytics: (identifier) => instance.getPlayerAnalytics(identifier),
      getAnalyticsSummary: () => instance.getAnalyticsSummary(),
      
      // Game management
      listGames: () => instance.listGames(),
      getGameInfo: () => instance.getGameInfo(),
      getSystemInfo: () => instance.getSystemInfo(),
      
      // File management
      uploadFile: (name, data) => instance.uploadFile(name, data),
      listFiles: () => instance.listFiles(),
      getFile: (name) => instance.getFile(name),
      
      // Info
      gameId: instance.gameId,
      getPrincipal: () => instance.getPrincipal(),
      getAuthType: () => instance.getAuthType(),
      getAuthData: () => instance.getAuthData(),
      getSessionId: () => instance.getSessionId(),
      
      // Raw instance
      instance: instance
    };
  }
};

// Export
export default CheddaAPI;

if (typeof window !== 'undefined') {
  window.CheddaBoards = CheddaAPI;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = CheddaAPI;
}


