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
    'absoluteScoreCap' : IDL.Opt(IDL.Nat64),
    'absoluteStreakCap' : IDL.Opt(IDL.Nat64),
    'created' : IDL.Nat64,
    'totalPlayers' : IDL.Nat,
    'owner' : IDL.Principal,
    'name' : IDL.Text,
    'maxScorePerRound' : IDL.Opt(IDL.Nat64),
    'gameId' : IDL.Text,
    'description' : IDL.Text,
    'isActive' : IDL.Bool,
    'maxStreakDelta' : IDL.Opt(IDL.Nat64),
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
    'changeNickname' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [Result_1], []),
    'deleteFile' : IDL.Func([IDL.Text], [Result_1], []),
    'destroySession' : IDL.Func([IDL.Text], [Result_1], []),
    'getAchievements' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [IDL.Vec(Achievement)], ['query']),
    'getActiveGames' : IDL.Func([], [IDL.Vec(GameInfo)], ['query']),
    'getActiveSessions' : IDL.Func([], [IDL.Nat], ['query']),
    'getAllProfiles' : IDL.Func([IDL.Text, IDL.Text], [IDL.Opt(UserProfile)], ['query']),
    'getAnalyticsSummary' : IDL.Func([], [
      IDL.Record({
        'uniquePlayers' : IDL.Nat,
        'totalEvents' : IDL.Nat,
        'totalDays' : IDL.Nat,
        'totalGames' : IDL.Nat,
        'recentEvents' : IDL.Nat,
        'mostActiveDay' : IDL.Text,
      }),
    ], ['query']),
    'getDailyStats' : IDL.Func([IDL.Text, IDL.Text], [IDL.Opt(DailyStats)], ['query']),
    'getFile' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Vec(IDL.Nat8))], ['query']),
    'getFileInfo' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Record({ 'name' : IDL.Text, 'size' : IDL.Nat }))], ['query']),
    'getGame' : IDL.Func([IDL.Text], [IDL.Opt(GameInfo)], ['query']),
    'getGameAuthStats' : IDL.Func([IDL.Text], [
      IDL.Record({
        'total' : IDL.Nat,
        'internetIdentity' : IDL.Nat,
        'apple' : IDL.Nat,
        'google' : IDL.Nat,
      }),
    ], ['query']),
    'getGameProfile' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [IDL.Opt(GameProfile)], ['query']),
    'getGameProfileBySession' : IDL.Func([IDL.Text, IDL.Text], [IDL.Opt(GameProfile)], ['query']),
    'getGamesByOwner' : IDL.Func([IDL.Principal], [IDL.Vec(GameInfo)], ['query']),
    'getLeaderboard' : IDL.Func([IDL.Text, SortBy, IDL.Nat], [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Nat64, IDL.Nat64, IDL.Text))], ['query']),
    'getLeaderboardByAuth' : IDL.Func([IDL.Text, AuthType, SortBy, IDL.Nat], [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Nat64, IDL.Nat64, IDL.Text))], ['query']),
    'getMyGameCount' : IDL.Func([], [IDL.Nat], ['query']),
    'getPlayerAnalytics' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [IDL.Opt(PlayerStats)], ['query']),
    'getProfile' : IDL.Func([IDL.Text, IDL.Text], [IDL.Opt(UserProfile)], ['query']),
    'getProfileBySession' : IDL.Func([IDL.Text], [IDL.Opt(UserProfile)], ['query']),
    'getRecentEvents' : IDL.Func([IDL.Nat], [IDL.Vec(AnalyticsEvent)], ['query']),
    'getRemainingGameSlots' : IDL.Func([], [IDL.Nat], ['query']),
    'getSessionInfo' : IDL.Func([IDL.Text], [
      IDL.Opt(IDL.Record({
        'created' : IDL.Nat64,
        'nickname' : IDL.Text,
        'expires' : IDL.Nat64,
        'authType' : IDL.Text,
        'email' : IDL.Text,
        'lastUsed' : IDL.Nat64,
      }))
    ], ['query']),
    'getSystemInfo' : IDL.Func([], [
      IDL.Record({
        'principalUserCount' : IDL.Nat,
        'fileCount' : IDL.Nat,
        'totalEvents' : IDL.Nat,
        'gameCount' : IDL.Nat,
        'suspicionLogSize' : IDL.Nat,
        'activeDays' : IDL.Nat,
        'emailUserCount' : IDL.Nat,
      }),
    ], ['query']),
    'iiLogin' : IDL.Func([IDL.Text], [Result_1], []),
    'listFiles' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'listGames' : IDL.Func([], [IDL.Vec(GameInfo)], ['query']),
    'registerGame' : IDL.Func([IDL.Text, IDL.Text, IDL.Text, IDL.Opt(IDL.Nat64), IDL.Opt(IDL.Nat64), IDL.Opt(IDL.Nat64), IDL.Opt(IDL.Nat64)], [Result_1], []),
    'socialLogin' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [Result_1], []),
    'submitScore' : IDL.Func([IDL.Text, IDL.Text, IDL.Text, IDL.Nat, IDL.Nat], [Result_1], []),
    'toggleGameActive' : IDL.Func([IDL.Text], [Result_1], []),
    'trackEvent' : IDL.Func([IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))], [], []),
    'unlockAchievement' : IDL.Func([IDL.Text, IDL.Text, IDL.Text, Achievement], [Result_1], []),
    'updateGame' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [Result_1], []),
    'updateGameRules' : IDL.Func([IDL.Text, IDL.Opt(IDL.Nat64), IDL.Opt(IDL.Nat64), IDL.Opt(IDL.Nat64), IDL.Opt(IDL.Nat64)], [Result_1], []),
    'uploadFile' : IDL.Func([IDL.Text, IDL.Vec(IDL.Nat8)], [Result_1], []),
    'validateSession' : IDL.Func([IDL.Text], [Result], []),
  });
};

export const init = ({ IDL }) => { return []; };

class CheddaBoardsSimple {
  constructor(config = {}) {
    if (!config.gameId) {
      throw new Error('[CheddaBoards] gameId is required');
    }
    
    this.canisterId = config.canisterId || "fdvph-sqaaa-aaaap-qqc4a-cai";
    this.gameId = config.gameId;
    this.gameName = config.gameName || "Unnamed Game";
    this.gameDescription = config.gameDescription || "CheddaBoards SDK";
    this.host = config.host || (this._isLocal() ? "http://localhost:4943" : "https://icp-api.io");
    this.autoInit = config.autoInit !== false;
    this.config = config;
    
    this.actor = null;
    this.identity = new AnonymousIdentity();
    this.authClient = null;
    this.profile = null;
    
    this.sessionId = null;
    this.userType = null;
    this.userId = null;
    this.authType = null;
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
      await this._createActor();
      await this._restoreSession();
      
      if (this.userType) {
        const profile = await this.loadProfile();
        if (profile && typeof window !== 'undefined' && window.emitToGodot) {
          window.emitToGodot('profile_loaded', profile.nickname, String(profile.score || 0), String(profile.streak || 0), JSON.stringify(profile.achievements || []));
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
      
      if (auth.sessionId) {
        const validation = await this.actor.validateSession(auth.sessionId);
        if (validation && validation.ok) {
          this.sessionId = auth.sessionId;
          this.authData = auth;
          this.userType = auth.userType;
          this.userId = auth.userId;
          this.authType = auth.authType;
        } else {
          localStorage.removeItem("chedda_auth");
          this.sessionId = null;
        }
      } else {
        this.authData = auth;
        this.userType = auth.userType;
        this.userId = auth.userId;
        this.authType = auth.authType;
        
        if (auth.authType === "internetIdentity") {
          await this._restoreIISession();
        }
      }
    } catch (e) {
      console.error('[CheddaBoards] Session restoration failed:', e);
      localStorage.removeItem("chedda_auth");
    }
  }

  async _restoreIISession() {
    this.authClient = await AuthClient.create();
    const isAuthenticated = await this.authClient.isAuthenticated();
    
    if (isAuthenticated) {
      this.identity = this.authClient.getIdentity();
      await this._createActor();
    } else {
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
      identity: this.identity,
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
  
  async registerGame(gameName, gameDescription, rules = {}) {
    try {
      if (!this.authClient || !await this.authClient.isAuthenticated()) {
        throw new Error('Must authenticate with Internet Identity to register a game');
      }
      
      this.identity = this.authClient.getIdentity();
      await this._createActor();
      
      const result = await this.actor.registerGame(
        this.gameId,
        gameName || this.gameName,
        gameDescription || this.gameDescription,
        rules.maxScorePerRound ? [rules.maxScorePerRound] : [],
        rules.maxStreakDelta ? [rules.maxStreakDelta] : [],
        rules.absoluteScoreCap ? [rules.absoluteScoreCap] : [],
        rules.absoluteStreakCap ? [rules.absoluteStreakCap] : []
      );
      
      if (result && result.ok) {
        return { success: true, message: result.ok };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true, message: 'Game registered' };
    } catch (e) {
      console.error('[CheddaBoards] Game registration failed:', e);
      return { success: false, error: e.message };
    }
  }

  async getMyGameCount() {
    try {
      if (!this.authClient || !await this.authClient.isAuthenticated()) {
        return 0;
      }
      
      this.identity = this.authClient.getIdentity();
      await this._createActor();
      
      const count = await this.actor.getMyGameCount();
      return Number(count);
    } catch (e) {
      console.error('[CheddaBoards] Get game count failed:', e);
      return 0;
    }
  }

  async getRemainingGameSlots() {
    try {
      if (!this.authClient || !await this.authClient.isAuthenticated()) {
        return 0;
      }
      
      this.identity = this.authClient.getIdentity();
      await this._createActor();
      
      const slots = await this.actor.getRemainingGameSlots();
      return Number(slots);
    } catch (e) {
      console.error('[CheddaBoards] Get remaining slots failed:', e);
      return 0;
    }
  }

  async loginII(nickname = null) {
    try {
      if (!this.authClient) {
        this.authClient = await AuthClient.create();
      }
      
      return new Promise((resolve, reject) => {
        this.authClient.login({
          identityProvider: "https://identity.ic0.app",
          onSuccess: async () => {
            try {
              this.identity = this.authClient.getIdentity();
              await this._createActor();
              
              const principalText = this.identity.getPrincipal().toText();
              const nick = nickname || `Player${Math.floor(Math.random() * 10000)}`;
              const signupResult = await this.actor.iiLogin(nick);
              
              if (signupResult && signupResult.err) {
                throw new Error(signupResult.err);
              }
              
              this.userType = "principal";
              this.userId = principalText;
              this.authType = "internetIdentity";
              this.sessionId = null;
              
              this.authData = {
                userType: "principal",
                userId: principalText,
                authType: "internetIdentity",
                nickname: nick
              };
              
              localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
              localStorage.setItem('auth_method', 'internetIdentity');
              
              await this.loadProfile();
              
              if (typeof window !== 'undefined' && window.emitToGodot) {
                window.emitToGodot('ii_login_success', this.profile.nickname, String(this.profile.score || 0), String(this.profile.streak || 0), JSON.stringify(this.profile.achievements || []));
              }
              
              resolve(this.profile);
            } catch (e) {
              reject(e);
            }
          },
          onError: (error) => {
            reject(error);
          }
        });
      });
    } catch (e) {
      throw e;
    }
  }

  async loginGoogle(googleCredential, nickname = null) {
    try {
      let payload;
      try {
        const parts = googleCredential.split('.');
        if (parts.length !== 3) {
          throw new Error('Invalid JWT format');
        }
        
        const base64Url = parts[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(
          atob(base64).split('').map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)).join('')
        );
        
        payload = JSON.parse(jsonPayload);
      } catch (e) {
        throw new Error('Failed to parse Google credential');
      }
      
      if (!payload.email) {
        throw new Error('Google credential missing email');
      }
      
      this.identity = new AnonymousIdentity();
      await this._createActor();
      
      let finalNickname = nickname || `Player${Math.floor(Math.random() * 10000)}`;
      if (finalNickname.length > 12) {
        finalNickname = finalNickname.substring(0, 12);
      }
      
      const signupResult = await this.actor.socialLogin(payload.email, finalNickname, "google");
      
      if (signupResult && signupResult.err) {
        throw new Error(signupResult.err);
      }
      
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
      
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent("chedda:google_login", { detail: { profile: this.profile, googleUser: { email: payload.email, name: payload.name, picture: payload.picture }}}));
        
        if (window.emitToGodot) {
          window.emitToGodot('google_login_success', this.profile?.nickname || finalNickname, String(this.profile?.score || 0), String(this.profile?.streak || 0), JSON.stringify(this.profile?.achievements || []));
        }
      }
      
      return this.profile;
    } catch (e) {
      console.error('[CheddaBoards] Google login failed:', e);
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
      
      let payload;
      try {
        const parts = idToken.split('.');
        const base64Url = parts[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(
          atob(base64).split('').map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)).join('')
        );
        
        payload = JSON.parse(jsonPayload);
      } catch (e) {
        throw new Error('Failed to parse Apple ID token');
      }
      
      if (!payload.email) {
        throw new Error('Apple ID token missing email');
      }
      
      this.identity = new AnonymousIdentity();
      await this._createActor();
      
      let finalNickname = nickname || `Player${Math.floor(Math.random() * 10000)}`;
      if (finalNickname.length > 12) {
        finalNickname = finalNickname.substring(0, 12);
      }
      
      const signupResult = await this.actor.socialLogin(payload.email, finalNickname, "apple");
      
      if (signupResult && signupResult.err) {
        throw new Error(signupResult.err);
      }

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
      
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent("chedda:apple_login", { detail: { profile: this.profile, appleUser: { email: payload.email }}}));
        
        if (window.emitToGodot) {
          window.emitToGodot('apple_login_success', this.profile?.nickname || finalNickname, String(this.profile?.score || 0), String(this.profile?.streak || 0), JSON.stringify(this.profile?.achievements || []));
        }
      }
      
      return this.profile;
    } catch (e) {
      console.error('[CheddaBoards] Apple login failed:', e);
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
      if (this.sessionId) {
        await this.actor.destroySession(this.sessionId).catch(() => {});
      }
      
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
      return false;
    }
  }

  async submitScore(score, streak = 0) {
    try {
      if (!this.actor) {
        await this._createActor();
      }
      
      if (!this.userType) {
        return { success: false, error: "Not authenticated" };
      }
      
      let userIdType, userId;
      
      if (this.userType === "principal") {
        if (this.authClient && await this.authClient.isAuthenticated()) {
          const iiIdentity = this.authClient.getIdentity();
          
          if (this.identity !== iiIdentity) {
            this.identity = iiIdentity;
            await this._createActor();
          }
        } else {
          return { success: false, error: "Internet Identity session expired" };
        }
        
        userIdType = "principal";
        userId = "";
      } else if (this.userType === "email") {
        userIdType = "email";
        userId = this.userId;
        
        if (!(this.identity instanceof AnonymousIdentity)) {
          this.identity = new AnonymousIdentity();
          await this._createActor();
        }
      }
      
      const result = await this.actor.submitScore(userIdType, userId, this.gameId, Math.floor(score), Math.floor(streak));
      
      await this.loadProfile();
      
      if (result && result.ok) {
        return { success: true, message: result.ok };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true, message: String(result) };
    } catch (e) {
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
      return [];
    }
  }

  async getLeaderboardByAuth(authType, sortBy = "score", limit = 100) {
    const allResults = await this.getLeaderboard(sortBy, limit * 2);
    return allResults.filter(entry => entry.authType === authType).slice(0, limit);
  }

  async getGameAuthStats() {
    try {
      if (!this.actor) await this._createActor();
      const stats = await this.actor.getGameAuthStats(this.gameId);
      return {
        internetIdentity: Number(stats.internetIdentity || 0),
        google: Number(stats.google || 0),
        apple: Number(stats.apple || 0),
        total: Number(stats.total || 0)
      };
    } catch (e) {
      return null;
    }
  }

  async getProfile() {
    try {
      if (!this.actor) await this._createActor();
      
      if (!this.userType) {
        return null;
      }
      
      let gameProfileResult;
      let userProfile;
      
      if (this.sessionId) {
        gameProfileResult = await this.actor.getGameProfileBySession(this.sessionId, this.gameId);
        userProfile = await this.actor.getProfileBySession(this.sessionId);
      } else if (this.userType === "principal") {
        if (this.authClient) {
          const isAuth = await this.authClient.isAuthenticated();
          if (isAuth) {
            this.identity = this.authClient.getIdentity();
            await this._createActor();
          }
        }
        
        gameProfileResult = await this.actor.getGameProfile("principal", this.userId, this.gameId);
        userProfile = await this.actor.getProfile("principal", this.userId);
      } else {
        gameProfileResult = await this.actor.getGameProfile(this.userType, this.userType === "email" ? this.userId : "", this.gameId);
        userProfile = await this.actor.getProfile(this.userType, this.userType === "email" ? this.userId : "");
      }
      
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
      } else {
        userProfile = await this.actor.getProfile(this.userType, this.userType === "email" ? this.userId : "");
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
      return null;
    }
  }

  async loadProfile() {
    this.profile = await this.getProfile();
    
    if (this.profile && typeof window !== "undefined") {
      window.dispatchEvent(new CustomEvent("chedda:profile", { detail: this.profile }));
      
      if (window.emitToGodot) {
        window.emitToGodot('profile_loaded', this.profile.nickname || 'Player', String(this.profile.score || 0), String(this.profile.streak || 0), JSON.stringify(this.profile.achievements || []));
      }
    }
    
    return this.profile;
  }

  async changeNickname(newNickname) {
    try {
      if (!this.actor) await this._createActor();
      
      if (!this.userType) {
        return { success: false, error: "Not authenticated" };
      }
      
      if (!newNickname || newNickname.length < 2 || newNickname.length > 12) {
        return { success: false, error: "Nickname must be 2-12 characters" };
      }
      
      let userIdType, userId;
      
      if (this.userType === "email") {
        userIdType = "email";
        userId = this.userId;
      } else if (this.userType === "principal") {
        if (this.authClient) {
          const isAuth = await this.authClient.isAuthenticated();
          if (isAuth) {
            this.identity = this.authClient.getIdentity();
            await this._createActor();
          }
        }
        userIdType = "principal";
        userId = "";
      } 
      const result = await this.actor.changeNickname(userIdType, userId, newNickname);
      
      if (result && result.ok) {
        if (this.authData) {
          this.authData.nickname = newNickname;
          localStorage.setItem("chedda_auth", JSON.stringify(this.authData));
        }
        
        await this.loadProfile();
        
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new CustomEvent("chedda:nickname_changed", { detail: { nickname: newNickname }}));
          
          if (window.emitToGodot) {
            window.emitToGodot('nickname_changed', newNickname);
          }
        }
        
        return { success: true, nickname: newNickname };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true, nickname: newNickname };
    } catch (e) {
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
      } else {
        userIdType = this.userType;
        userId = this.userType === "email" ? this.userId : "";
      }
      
      const result = await this.actor.unlockAchievement(userIdType, userId, this.gameId, achievement);
      
      if (result && result.ok) {
        await this.loadProfile();
        return { success: true };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true };
    } catch (e) {
      return { success: false, error: e.message };
    }
  }

  async trackEvent(eventType, metadata = {}) {
    try {
      if (!this.actor) await this._createActor();
      
      metadata.gameId = this.gameId;
      metadata.authType = this.authType || 'none';
      
      const metadataArray = Object.entries(metadata).map(([k, v]) => [k, String(v)]);

      if (!this.userType) {
        return { success: false, error: "Not authenticated" };
      }

      let userIdType = this.userType;
      let userId = this.userType === "email" ? this.userId : "";
      
      if (this.userType === "principal" && this.authClient) {
        const isAuth = await this.authClient.isAuthenticated();
        if (isAuth) {
          this.identity = this.authClient.getIdentity();
          await this._createActor();
        }
      }
      
      await this.actor.trackEvent(userIdType, userId, eventType, this.gameId, metadataArray);
      
      return { success: true };
    } catch (e) {
      return { success: false, error: e.message };
    }
  }

  async getDailyStats(date) {
    try {
      if (!this.actor) await this._createActor();
      const stats = await this.actor.getDailyStats(date, this.gameId);
      return stats || null;
    } catch (e) {
      return null;
    }
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
      return null;
    }
  }

  async listGames() {
    try {
      if (!this.actor) await this._createActor();
      const games = await this.actor.listGames();
      return games || [];
    } catch (e) {
      return [];
    }
  }

  async getGameInfo() {
    try {
      if (!this.actor) await this._createActor();
      const game = await this.actor.getGame(this.gameId);
      return game || null;
    } catch (e) {
      return null;
    }
  }

  async getSystemInfo() {
    try {
      if (!this.actor) await this._createActor();
      return await this.actor.getSystemInfo();
    } catch (e) {
      return null;
    }
  }

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
      return { success: false, error: e.message };
    }
  }

  async listFiles() {
    try {
      if (!this.actor) await this._createActor();
      const files = await this.actor.listFiles();
      return files || [];
    } catch (e) {
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
      return null;
    }
  }

  async updateGameRules(maxScorePerRound, maxStreakDelta, absoluteScoreCap, absoluteStreakCap) {
    try {
      if (!this.actor) await this._createActor();
      
      const result = await this.actor.updateGameRules(
        this.gameId,
        maxScorePerRound ? [maxScorePerRound] : [],
        maxStreakDelta ? [maxStreakDelta] : [],
        absoluteScoreCap ? [absoluteScoreCap] : [],
        absoluteStreakCap ? [absoluteStreakCap] : []
      );
      
      if (result && result.ok) {
        return { success: true, message: result.ok };
      } else if (result && result.err) {
        return { success: false, error: result.err };
      }
      
      return { success: true };
    } catch (e) {
      return { success: false, error: e.message };
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
      return "email:" + this.userId;
    } else {
      return null;
    }
  }

  getAuthData() {
    return this.authData;
  }

  getSessionId() {
    return this.sessionId;
  }
}

const CheddaAPI = {
  init: async (canisterId, config = {}) => {
    if (!config.gameId) {
      throw new Error('[CheddaBoards] gameId is required');
    }
    
    const instance = new CheddaBoardsSimple({ canisterId, ...config });
    await instance.init();
    
    return {
      login: {
        google: (cred, nickname) => instance.loginGoogle(cred, nickname),
        apple: (resp, nickname) => instance.loginApple(resp, nickname),
        ii: (nickname) => instance.loginII(nickname),
      },
      logout: () => instance.logout(),
      registerGame: (name, desc, rules) => instance.registerGame(name, desc, rules),
      getMyGameCount: () => instance.getMyGameCount(),
      getRemainingGameSlots: () => instance.getRemainingGameSlots(),
      submitScore: (score, streak) => instance.submitScore(score, streak),
      getLeaderboard: (sortBy, limit) => instance.getLeaderboard(sortBy, limit),
      getLeaderboardByAuth: (authType, sortBy, limit) => instance.getLeaderboardByAuth(authType, sortBy, limit),
      getGameAuthStats: () => instance.getGameAuthStats(),
      changeNickname: (name) => instance.changeNickname(name),
      unlockAchievement: (id, name, desc) => instance.unlockAchievement(id, name, desc),
      listGames: () => instance.listGames(),
      getGameInfo: () => instance.getGameInfo(),
      getSystemInfo: () => instance.getSystemInfo(),
      updateGameRules: (maxScore, maxStreak, capScore, capStreak) => instance.updateGameRules(maxScore, maxStreak, capScore, capStreak),
      getProfile: () => instance.getProfile(),
      getAllGameProfiles: () => instance.getAllGameProfiles(),
      isAuthenticated: () => instance.isAuthenticated(),
      trackEvent: (type, data) => instance.trackEvent(type, data),
      getDailyStats: (date) => instance.getDailyStats(date),
      getAnalyticsSummary: () => instance.getAnalyticsSummary(),
      uploadFile: (name, data) => instance.uploadFile(name, data),
      listFiles: () => instance.listFiles(),
      getFile: (name) => instance.getFile(name),
      gameId: instance.gameId,
      getPrincipal: () => instance.getPrincipal(),
      getAuthType: () => instance.getAuthType(),
      getAuthData: () => instance.getAuthData(),
      getSessionId: () => instance.getSessionId(),
      instance: instance
    };
  }
};

export default CheddaAPI;

if (typeof window !== 'undefined') {
  window.CheddaBoards = CheddaAPI;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = CheddaAPI;
}
