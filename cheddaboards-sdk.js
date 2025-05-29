import { AuthClient } from "@dfinity/auth-client";
import { HttpAgent, Actor, AnonymousIdentity } from "@dfinity/agent";

export class CheddaBoards {
  constructor({ canisterId, idlFactory, gameId, host = "https://identity.ic0.app", apiKey = null }) {
    // Validate canister ID format
    if (typeof canisterId !== "string" || !canisterId.includes("-") || canisterId.includes("http")) {
      throw new Error(`❌ Invalid canisterId provided: ${canisterId}`);
    }
    // Store config and initial state
    this.canisterId = canisterId;
    this.idlFactory = idlFactory;
    this.gameId = gameId;
    this.apiKey = apiKey;
    this.host = host;
    this.authClient = null;
    this.identity = apiKey ? null : new AnonymousIdentity();
    this.actor = null;
    this.principalId = null;
    this.profile = null;
    this._cache = { web2: null, web3: null, leaderboard: null }; // Local score cache

    this._initActor();
    if (typeof window !== "undefined") window.chedda = this;
    console.log("✅ CheddaBoards initialized with:", { canisterId, gameId, apiKey, host });
  }

  _initActor() {
    // Create a DFINITY agent and actor for canister communication
    const agent = new HttpAgent({ identity: this.identity, host: this.host });
    this.actor = Actor.createActor(this.idlFactory, {
      agent,
      canisterId: this.canisterId,
    });
    console.log("🎭 Actor created with:", {
      canisterId: this.canisterId,
      identity: !!this.identity,
    });
  }

  async init() {
    // Initialize identity if not using API key
    if (!this.apiKey) {
      this.authClient = this.authClient || (await AuthClient.create());
      const isAuthenticated = await this.authClient.isAuthenticated();
      console.log("🔑 isAuthenticated:", isAuthenticated);
      if (isAuthenticated) {
        this.identity = this.authClient.getIdentity();
        this.principalId = this.identity.getPrincipal().toText();
        console.log("✅ Already authenticated principal:", this.principalId);
        await this.refreshProfile();
      }
    }
    this._initActor();
    return this.principalId;
  }

  async login() {
    // Login using Internet Identity
    if (!this.authClient) this.authClient = await AuthClient.create();
    return new Promise((resolve, reject) => {
      this.authClient.login({
        identityProvider: "https://identity.ic0.app",
        onSuccess: async () => {
          try {
            this.identity = this.authClient.getIdentity();
            this.principalId = this.identity.getPrincipal().toText();
            localStorage.setItem("auth_method", "ii");
            localStorage.setItem("ii_login_result", this.principalId);
            this._initActor();
            const profile = await this.refreshProfile();
            if (!profile || !profile.nickname) {
              const nickname = prompt("Choose a nickname:");
              if (!nickname || nickname.length < 2) return reject("Nickname too short.");
              localStorage.setItem("player_name", nickname);
              await this.signup(nickname);
              await this.refreshProfile();
            }
            resolve(this.principalId);
          } catch (e) {
            console.error("❌ login() error:", e);
            reject(e);
          }
        },
        onError: (err) => {
          console.error("❌ II login error:", err);
          reject(err);
        },
      });
    });
  }

  async refreshProfile() {
    // Refresh user profile and emit to browser/Godot
    try {
      const profile = await this.getProfile();
      if (profile) {
        this.profile = profile;
        console.log("✅ Profile refreshed:", profile);
        if (typeof window !== "undefined") {
          window.dispatchEvent(new CustomEvent("chedda:profile", { detail: profile }));
          if (window.godot?.emit_signal) {
            window.godot.emit_signal("profile_loaded", profile.nickname, profile.total_score.toString(), profile.best_streak.toString(), JSON.stringify(profile.achievements));
          }
        }
      }
      return profile;
    } catch (e) {
      console.error("❌ Failed to refresh profile:", e);
      return null;
    }
  }

  async signup(nickname = null) {
    // Sign up user depending on auth method
    if (this.apiKey) return;
    if (!nickname) nickname = localStorage.getItem("player_name") || "Player" + Math.floor(Math.random() * 10000);
    const method = localStorage.getItem("auth_method");
    try {
      if (method === "email" || method === "google") {
        const email = localStorage.getItem("email_user");
        return await this.actor.signup_email(email, nickname);
      } else {
        return await this.actor.signup_ii(nickname);
      }
    } catch (err) {
      console.error("❌ Signup error:", err);
    }
  }

  async submitScore(score, streak = 0, playerId = null, opts = {}) {
    // Submit score using correct method
    try {
      if (this.apiKey && playerId) {
        return await this.actor.submitScore(this.apiKey, this.gameId, playerId, BigInt(score), BigInt(streak));
      } else if (opts.email) {
        return await this.actor.submitScore_email(opts.email, BigInt(score), BigInt(streak), this.gameId);
      } else {
        return await this.actor.submitScore_ii(BigInt(score), BigInt(streak), this.gameId);
      }
    } catch (err) {
      console.error("❌ Submit score error:", err);
      return { success: false, error: err.message };
    }
  }

  async submitScoreSmart({ score, streak = 0 }) {
    // Automatically route score submission
    try {
      const method = localStorage.getItem("auth_method");
      if (method === "ii") {
        const principal = this.identity?.getPrincipal?.().toText() || "anonymous";
        return await this.actor.submitScore_ii(BigInt(score), BigInt(streak), this.gameId);
      } else if (method === "email" || method === "google") {
        const email = localStorage.getItem("email_user") || this.principalId;
        return await this.actor.submitScore_email(email, BigInt(score), BigInt(streak), this.gameId);
      } else if (this.apiKey) {
        const pid = this.principalId || localStorage.getItem("email_user");
        return await this.submitScore(score, streak, pid, { gameId: this.gameId });
      } else {
        return { success: false, error: "Not logged in" };
      }
    } catch (e) {
      console.error("❌ Score submission failed:", e);
      return { success: false, error: e.message };
    }
  }

  async getLeaderboard() {
    // Fetch leaderboard based on auth type
    try {
      if (this.apiKey && this.gameId) {
        return await this.actor.getLeaderboard(this.gameId);
      }
      const isEmail = localStorage.getItem("auth_method") === "email";
      if (isEmail && this.actor.getLeaderboard_email) {
        return await this.actor.getLeaderboard_email();
      }
      return await this.actor.getLeaderboard_ii();
    } catch (err) {
      console.error("❌ Leaderboard fetch error:", err);
      return [];
    }
  }

  async getScores() {
    // Get full leaderboard and stringify BigInts
    try {
      const raw = await this.getLeaderboard();
      return JSON.stringify({ error: 0, result: raw }, (_, v) => (typeof v === "bigint" ? v.toString() : v));
    } catch (err) {
      return JSON.stringify({ error: 1, result: [] });
    }
  }

  async getWeb2Scores() {
    // Fetch scores of Web2 users
    try {
      const raw = await this.actor.getLeaderboard_email();
      const entries = Object.entries(raw);
      return JSON.stringify({ error: 0, result: entries }, (_, v) => (typeof v === "bigint" ? v.toString() : v));
    } catch (err) {
      return JSON.stringify({ error: 1, result: [] });
    }
  }

  async getWeb3Scores() {
    // Fetch scores of Web3 (II) users
    try {
      const raw = await this.actor.getLeaderboard_ii();
      const entries = Object.entries(raw);
      return JSON.stringify({ error: 0, result: entries }, (_, v) => (typeof v === "bigint" ? v.toString() : v));
    } catch (err) {
      return JSON.stringify({ error: 1, result: [] });
    }
  }

  async fetchWeb2Scores() {
    // Fetch and cache Web2 scores
    const json = await this.getWeb2Scores();
    const { result } = JSON.parse(json);
    this._cache.web2 = result;
    if (window.godot?.emit_signal) window.godot.emit_signal("scores_updated", "web2", JSON.stringify(result));
    return result;
  }

  async fetchWeb3Scores() {
    // Fetch and cache Web3 scores
    const json = await this.getWeb3Scores();
    const { result } = JSON.parse(json);
    this._cache.web3 = result;
    if (window.godot?.emit_signal) window.godot.emit_signal("scores_updated", "web3", JSON.stringify(result));
    return result;
  }

  async fetchLeaderboard() {
    // Fetch and cache full leaderboard
    const raw = await this.getLeaderboard();
    this._cache.leaderboard = raw;
    if (window.godot?.emit_signal) window.godot.emit_signal("scores_updated", "leaderboard", JSON.stringify(raw));
    return raw;
  }

  getCached(type = "leaderboard") {
    // Get cached scores by type
    return this._cache[type] || null;
  }

  clearCache() {
    // Clear all local caches
    this._cache = { web2: null, web3: null, leaderboard: null };
  }

  async emitProfileToGodot() {
    // Emit current profile to Godot (used in game engines)
    let profile = null;
    const auth = localStorage.getItem("auth_method");
    try {
      if (auth === "ii") {
        profile = await this.actor.getProfile_ii();
        profile = Array.isArray(profile) ? profile[0] : profile;
      } else if (auth === "email") {
        const email = localStorage.getItem("email_user");
        if (!email) return;
        profile = await this.actor.getProfile_email(email);
        profile = Array.isArray(profile) ? profile[0] : profile;
      } else return;
      if (!profile) return;
      const nick = profile.nickname;
      const totalScore = profile.total_score.toString();
      const bestStreak = profile.best_streak.toString();
      const achsJson = JSON.stringify(profile.achievements);
      window.godot?.emit_signal("profile_loaded", nick, totalScore, bestStreak, achsJson);
    } catch (err) {
      console.error("❌ emitProfileToGodot error:", err);
    }
  }

  async getProfile(playerId = null) {
    // Get player profile depending on auth method
    const method = localStorage.getItem("auth_method");
    try {
      if (this.apiKey) {
        if (!playerId) return null;
        return await this.actor.getProfile(this.gameId, playerId);
      } else if (method === "email" || method === "google") {
        const email = localStorage.getItem("email_user");
        return await this.actor.getProfile_email(email);
      } else {
        return await this.actor.getProfile_ii();
      }
    } catch (err) {
      console.error("❌ Get profile error:", err);
      return null;
    }
  }

  async changeNickname(newNickname) {
    // Change current user's nickname
    if (this.apiKey) return;
    try {
      return await this.actor.changeNickname_ii(newNickname);
    } catch (err) {
      console.error("❌ Nickname change error:", err);
    }
  }

  async registerApiKey(apiKey, ownerName) {
    // Register new API key (admin only)
    try {
      return await this.actor.registerApiKey(apiKey, ownerName);
    } catch (err) {
      console.error("❌ API key registration failed:", err);
    }
  }

  async registerGame(title, description) {
    // Register a new game using API key
    try {
      return await this.actor.registerGame(this.apiKey, this.gameId, title, description);
    } catch (err) {
      console.error("❌ Game registration failed:", err);
    }
  }

  async listGames() {
    // List all registered games
    try {
      return (await this.actor.listGames?.()) || [];
    } catch (err) {
      console.error("❌ Could not list games:", err);
      return [];
    }
  }

  getPrincipal() {
    // Return the user's principal ID
    return this.principalId;
  }

  isAuthenticated() {
    // Check if user is authenticated
    return !!this.identity && !(this.identity instanceof AnonymousIdentity);
  }

  isLoggedIn() {
    // Check if user is logged in (II or API key)
    return this.isAuthenticated() || !!this.apiKey;
  }

  async logout() {
    // Logout and clear all local/session data
    if (this.authClient) {
      await this.authClient.logout();
      this.identity = new AnonymousIdentity();
      this.principalId = null;
      this.profile = null;
      this._initActor();
      this.clearCache();
      ["auth_method", "email_user", "ii_login_result", "email_login_result", "player_name"].forEach(k => localStorage.removeItem(k));
    }
  }
}
