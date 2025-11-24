 // ======================= Imports =======================
import { Actor, HttpAgent, AnonymousIdentity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { idlFactory } from "../declarations/cheddaboards_v2_backend/cheddaboards_v2_backend.did.js";

// =================== Module-scope helpers ===================
function topOrigin() {
  try {
    if (window.top === window) return window.location.origin;
    const ref = document.referrer;
    if (ref) return new URL(ref).origin;
  } catch (_) {}
  return window.location.origin;
}

// Preload AuthClient once so the click handler has no await before .login()
(async () => {
  try {
    if (!window.cheddaAuthClient) {
      window.cheddaAuthClient = await AuthClient.create();
    }
  } catch (e) {
    console.error("[CheddaBoards] Failed to create AuthClient early:", e);
  }
})();

// ======================= Class =======================
class CheddaBoards {
  constructor(config = {}) {
    if (!config.gameId) {
      throw new Error(
        '[CheddaBoards] gameId is required. Initialize with: CheddaBoards.init(canisterId, { gameId: "your-game-id" })'
      );
    }

    // DEVELOPERS: Replace with your own canister ID after deployment
    this.canisterId =
      config.canisterId || "YOUR_CANISTER_ID_HERE";
    this.gameId = config.gameId;
    this.gameName = config.gameName || "Unnamed Game";
    this.gameDescription = config.gameDescription || "CheddaBoards SDK";
    this.host =
      config.host || (this._isLocal() ? "http://localhost:4943" : "https://icp-api.io");
    this.autoInit = config.autoInit === true;
    this.config = config;

    // identity/auth
    this.actor = null;
    this.agent = null;
    this.identity = new AnonymousIdentity();
    this.authClient = null;
    this.profile = null;

    // session and auth state
    this.sessionId = null;
    this.userType = null; // "principal" or "email"
    this.userId = null; // principal text or email
    this.authType = null; // "cheddaId" | "google" | "apple" | null
    this.authData = null;

    // flags
    this._initialized = false;
    this._initInProgress = false;
    this._initPromise = null;
    this._iiInFlight = false;

    if (this.autoInit) {
      this.init().catch((e) =>
        console.error("[CheddaBoards] autoInit failed:", e)
      );
    }
  }

  _isLocal() {
    try {
      const hn = window?.location?.hostname || "";
      return hn === "localhost" || hn === "127.0.0.1";
    } catch {
      return false;
    }
  }

  // =================== Lifecycle ===================
  async init() {
    if (this._initialized) return true;
    if (this._initPromise) return this._initPromise;

    this._initPromise = (async () => {
      this._initInProgress = true;
      try {
        console.log("[CheddaBoards] Initializing for game:", this.gameId);

        // Initial anonymous actor
        await this._createActor({ identity: this.identity });

        // Try to restore session/auth
        await this._restoreSession();

        // Load profile if authenticated
        if (this.userType) {
          const profile = await this.loadProfile();
          if (profile && typeof window !== "undefined" && window.emitToGodot) {
            window.emitToGodot(
              "profile_loaded",
              profile.nickname,
              String(profile.score || 0),
              String(profile.streak || 0),
              JSON.stringify(profile.achievements || [])
            );
          }
        }

        this._initialized = true;
        return true;
      } catch (e) {
        console.error("[CheddaBoards] Init failed:", e);
        return false;
      } finally {
        this._initInProgress = false;
        this._initPromise = null;
      }
    })();

    return this._initPromise;
  }

  async _restoreSession() {
    const storedAuth = sessionStorage.getItem("chedda_auth");
    if (!storedAuth) return;

    try {
      const auth = JSON.parse(storedAuth);

      if (auth.sessionId) {
        // legacy/email path
        const validation = await this.actor.validateSession(auth.sessionId);
        if (validation && validation.ok) {
          Object.assign(this, {
            sessionId: auth.sessionId,
            authData: auth,
            userType: auth.userType,
            userId: auth.userId,
            authType: auth.authType,
          });
        } else {
          sessionStorage.removeItem("chedda_auth");
        }
      } else {
        // II path
        this.authData = auth;
        this.userType = auth.userType;
        this.userId = auth.userId;
        this.authType = auth.authType;

        if (auth.authType === "internetIdentity" || auth.authType === "cheddaId") {
          await this._restoreIISession();
        }
      }

    } catch (e) {
      console.error("[CheddaBoards] Session restoration failed:", e);
      sessionStorage.removeItem("chedda_auth");
    }
  }

  async _restoreIISession() {
    try {
      this.authClient = window.cheddaAuthClient || (await AuthClient.create());
      const isAuthenticated = await this.authClient.isAuthenticated();

      if (isAuthenticated) {
        this.identity = this.authClient.getIdentity();
        await this._createActor({ identity: this.identity });
      } else {
        sessionStorage.removeItem("chedda_auth");
        this.identity = new AnonymousIdentity();
        this.userType = null;
        this.userId = null;
        this.authType = null;
        this.sessionId = null;
        await this._createActor({ identity: this.identity });
      }
    } catch (e) {
      console.error("[CheddaBoards] II restore failed:", e);
    }
  }

  async _createActor({ identity } = {}) {
    const id = identity || this.identity || new AnonymousIdentity();
    this.identity = id;

    this.agent = new HttpAgent({ identity: id, host: this.host });

    if (this._isLocal()) {
      try {
        await this.agent.fetchRootKey();
      } catch (_) {}
    }

    this.actor = Actor.createActor(idlFactory, {
      agent: this.agent,
      canisterId: this.canisterId,
    });
  }

  _promptForNickname(defaultValue = "") {
    if (typeof window === "undefined") return null;
    const nickname = window.prompt("Choose your nickname:", defaultValue);
    return nickname ? nickname.trim() : null;
  }

  async _getSuggestedNickname() {
  try {
    if (!this.actor) await this._createActor({ identity: this.identity });
    const result = await this.actor.suggestNickname();
    if (result?.ok) {
      return result.ok;  // Returns "Player_X"
    }
    // Fallback if backend call fails
    return `Player_${Math.floor(Math.random() * 10000)}`;
  } catch (e) {
    console.error("[CheddaBoards] Failed to get nickname suggestion:", e);
    return `Player_${Math.floor(Math.random() * 10000)}`;
  }
}

  // =================== Game Registration / Slots ===================
  async registerGame(gameName, gameDescription, rules = {}) {
    try {
      const ac = this.authClient || window.cheddaAuthClient;
      if (!ac || !(await ac.isAuthenticated())) {
        throw new Error("⚠ Must authenticate with Chedda ID to register a game. Call loginChedda() first.");
      }
      this.identity = ac.getIdentity();
      await this._createActor({ identity: this.identity });

      const result = await this.actor.registerGame(
        this.gameId,
        gameName || this.gameName,
        gameDescription || this.gameDescription,
        rules.maxScorePerRound ? [rules.maxScorePerRound] : [],
        rules.maxStreakDelta ? [rules.maxStreakDelta] : [],
        rules.absoluteScoreCap ? [rules.absoluteScoreCap] : [],
        rules.absoluteStreakCap ? [rules.absoluteStreakCap] : []
      );

      if (result?.ok) return { success: true, message: result.ok };
      if (result?.err) return { success: false, error: result.err };
      return { success: true, message: "Game registered" };
    } catch (e) {
      console.error("[CheddaBoards] Game registration failed:", e);
      return { success: false, error: e.message };
    }
  }

  async getMyGameCount() {
    try {
      const ac = this.authClient || window.cheddaAuthClient;
      if (!ac || !(await ac.isAuthenticated())) return 0;
      this.identity = ac.getIdentity();
      await this._createActor({ identity: this.identity });
      const count = await this.actor.getMyGameCount();
      return Number(count);
    } catch (e) {
      console.error("[CheddaBoards] Get game count failed:", e);
      return 0;
    }
  }

  async getRemainingGameSlots() {
    try {
      const ac = this.authClient || window.cheddaAuthClient;
      if (!ac || !(await ac.isAuthenticated())) return 0;
      this.identity = ac.getIdentity();
      await this._createActor({ identity: this.identity });
      const slots = await this.actor.getRemainingGameSlots();
      return Number(slots);
    } catch (e) {
      console.error("[CheddaBoards] Get remaining slots failed:", e);
      return 0;
    }
  }

  // =================== AUTH: Internet Identity ===================
  async loginChedda(nickname = null) {
  console.log("[CheddaBoards] Starting Chedda ID login...");

  this.authClient = window.cheddaAuthClient || (await AuthClient.create());

  if (this._iiInFlight) {
    console.warn("[CheddaBoards] II login already in progress");
    return Promise.reject("login_in_flight");
  }
  this._iiInFlight = true;

  return new Promise((resolve, reject) => {
    this.authClient.login({
      identityProvider: "https://identity.ic0.app",
      derivationOrigin: topOrigin(),
      maxTimeToLive: 7n * 24n * 60n * 60n * 1_000_000_000n,

      onSuccess: async () => {
        try {
          console.log("[CheddaBoards] ✅ II authentication successful");
          this.identity = this.authClient.getIdentity();
          const principalText = this.identity.getPrincipal().toText();
          console.log("[CheddaBoards] Principal:", principalText);

          await this._createActor({ identity: this.identity });

          this.userType = "principal";
          this.userId = principalText;
          this.authType = "cheddaId";
          this.sessionId = null;

          const tempNick = `Chedda${Math.floor(Math.random() * 10000)}`;
          
          const batchResult = await this.actor.iiLoginAndGetProfile(tempNick, this.gameId);
          console.log("[CheddaBoards] Backend login result:", batchResult);

          if (batchResult?.err) throw new Error(batchResult.err);

          const data = batchResult.ok;
          if (!data) throw new Error("No data returned from backend");

          const isNewUser = !data.nickname || data.nickname.startsWith('Chedda') || data.nickname.startsWith('Player_');
          let finalNickname = data.nickname || tempNick;

          console.log("[CheddaBoards] Is new user:", isNewUser, "Current nickname:", finalNickname);

          if (isNewUser && !nickname) {
            const suggestion = await this._getSuggestedNickname();
            const customNick = this._promptForNickname(suggestion);
            if (customNick && customNick.trim() && customNick !== suggestion) {
              console.log("[CheddaBoards] Changing nickname from", finalNickname, "to", customNick.trim());
              
              const changeResult = await this.actor.changeNicknameAndGetProfile(
                "principal",           // userIdType
                principalText,         // userId
                customNick.trim(),     // newNickname
                this.gameId            // gameId
              );
              
              console.log("[CheddaBoards] Change nickname result:", changeResult);
              
              if (changeResult?.ok) {
                finalNickname = changeResult.ok.nickname;
                
                // Update data with returned profile
                if (changeResult.ok.gameProfile) {
                  Object.assign(data, {
                    nickname: changeResult.ok.nickname,
                    gameProfile: changeResult.ok.gameProfile
                  });
                }
              } else {
                console.warn("[CheddaBoards] Nickname change failed, using:", finalNickname);
              }
            } else if (customNick && customNick.trim() === suggestion) {
              // User accepted the suggestion, no need to call backend
              finalNickname = suggestion;
            }
          } else if (nickname) {
            finalNickname = nickname;
          }

          this.authData = {
            userType: "principal",
            userId: principalText,
            authType: "cheddaId",
            nickname: finalNickname,
          };
          sessionStorage.setItem("chedda_auth", JSON.stringify(this.authData));
          sessionStorage.setItem("auth_method", "cheddaId");

          this.profile = {
            nickname: finalNickname,
            score: data.gameProfile ? Number(data.gameProfile.total_score || 0) : 0,
            streak: data.gameProfile ? Number(data.gameProfile.best_streak || 0) : 0,
            achievements: data.gameProfile ? data.gameProfile.achievements : [],
            lastPlayed: data.gameProfile ? data.gameProfile.last_played : undefined,
            playCount: data.gameProfile ? Number(data.gameProfile.play_count || 0) : 0,
            gameId: this.gameId,
            authType: "cheddaId",
          };

          if (typeof window !== "undefined" && window.emitToGodot) {
            window.emitToGodot(
              "chedda_id_login_success",
              this.profile.nickname,
              String(this.profile.score || 0),
              String(this.profile.streak || 0),
              JSON.stringify(this.profile.achievements || [])
            );
          }

          this._iiInFlight = false;
          resolve(this.profile);
        } catch (e) {
          console.error("[CheddaBoards] Chedda ID login error:", e);
          this._iiInFlight = false;
          reject(e);
        }
      },

      onError: (error) => {
        console.error("[CheddaBoards] Chedda ID authentication failed:", error);
        this._iiInFlight = false;
        reject(error);
      },
    });
  });
}

 async loginII2(nickname = null) {
  console.log("[CheddaBoards] Starting Internet Identity 2.0 login...");

  this.authClient = window.cheddaAuthClient || (await AuthClient.create());

  if (this._iiInFlight) {
    console.warn("[CheddaBoards] II 2.0 login already in progress");
    return Promise.reject("login_in_flight");
  }
  this._iiInFlight = true;

  return new Promise((resolve, reject) => {
    this.authClient.login({
      identityProvider: "https://identity.internetcomputer.org",
      derivationOrigin: topOrigin(),
      maxTimeToLive: 7n * 24n * 60n * 60n * 1_000_000_000n,

      onSuccess: async () => {
        try {
          console.log("[CheddaBoards] ✅ II 2.0 authentication successful");
          this.identity = this.authClient.getIdentity();
          const principalText = this.identity.getPrincipal().toText();
          console.log("[CheddaBoards] Principal:", principalText);

          await this._createActor({ identity: this.identity });

          this.userType = "principal";
          this.userId = principalText;
          this.authType = "cheddaId";
          this.sessionId = null;

          const tempNick = `Chedda${Math.floor(Math.random() * 10000)}`;
          
          const batchResult = await this.actor.iiLoginAndGetProfile(tempNick, this.gameId);
          console.log("[CheddaBoards] Backend login result:", batchResult);

          if (batchResult?.err) throw new Error(batchResult.err);

          const data = batchResult.ok;
          if (!data) throw new Error("No data returned from backend");

          const isNewUser = !data.nickname || data.nickname.startsWith('Chedda') || data.nickname.startsWith('Player_');
          let finalNickname = data.nickname || tempNick;

          console.log("[CheddaBoards] Is new user:", isNewUser, "Current nickname:", finalNickname);

          if (isNewUser && !nickname) {
            const suggestion = await this._getSuggestedNickname();
            const customNick = this._promptForNickname(suggestion);
            if (customNick && customNick.trim() && customNick !== suggestion) {
              console.log("[CheddaBoards] Changing nickname from", finalNickname, "to", customNick.trim());
              
              const changeResult = await this.actor.changeNicknameAndGetProfile(
                "principal",           // userIdType
                principalText,         // userId
                customNick.trim(),     // newNickname
                this.gameId            // gameId
              );
              
              console.log("[CheddaBoards] Change nickname result:", changeResult);
              
              if (changeResult?.ok) {
                finalNickname = changeResult.ok.nickname;
                
                // Update data with returned profile
                if (changeResult.ok.gameProfile) {
                  Object.assign(data, {
                    nickname: changeResult.ok.nickname,
                    gameProfile: changeResult.ok.gameProfile
                  });
                }
              } else {
                console.warn("[CheddaBoards] Nickname change failed, using:", finalNickname);
              }
            } else if (customNick && customNick.trim() === suggestion) {
              // User accepted the suggestion
              finalNickname = suggestion;
            }
          } else if (nickname) {
            finalNickname = nickname;
          }

          this.authData = {
            userType: "principal",
            userId: principalText,
            authType: "cheddaId",
            nickname: finalNickname,
          };
          sessionStorage.setItem("chedda_auth", JSON.stringify(this.authData));
          sessionStorage.setItem("auth_method", "cheddaId");

          this.profile = {
            nickname: finalNickname,
            score: data.gameProfile ? Number(data.gameProfile.total_score || 0) : 0,
            streak: data.gameProfile ? Number(data.gameProfile.best_streak || 0) : 0,
            achievements: data.gameProfile ? data.gameProfile.achievements : [],
            lastPlayed: data.gameProfile ? data.gameProfile.last_played : undefined,
            playCount: data.gameProfile ? Number(data.gameProfile.play_count || 0) : 0,
            gameId: this.gameId,
            authType: "cheddaId",
          };

          if (typeof window !== "undefined" && window.emitToGodot) {
            window.emitToGodot(
              "chedda_id_login_success",
              this.profile.nickname,
              String(this.profile.score || 0),
              String(this.profile.streak || 0),
              JSON.stringify(this.profile.achievements || [])
            );
          }

          console.log("[CheddaBoards] II 2.0 login complete:", this.profile.nickname);
          this._iiInFlight = false;
          resolve(this.profile);
        } catch (e) {
          console.error("[CheddaBoards] II 2.0 login error:", e);
          this._iiInFlight = false;
          reject(e);
        }
      },

      onError: (error) => {
        console.error("[CheddaBoards] II 2.0 authentication failed:", error);
        this._iiInFlight = false;
        reject(error);
      },
    });
  });
}

async loginGoogle(googleCredential, nickname = null) {
  try {
    console.log("[CheddaBoards] Google login via CheddaAuth…");

    const state = crypto.randomUUID();
    const nonce = crypto.randomUUID();

    const resp = await fetch(VERIFIER_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        provider: "google",
        id_token: googleCredential,
        state,
        nonce
      }),
    });

    const data = await resp.json();
    if (!data || !data.ok || !data.session || !data.session.sessionId) {
      console.error("[CheddaBoards] Verifier error:", data);
      throw new Error(data?.error || "Google verify failed");
    }

    const sessionId = data.session.sessionId;
    const email = data.session.email;

    this.identity = new AnonymousIdentity();
    await this._createActor({ identity: this.identity });

    this.userType  = "email";
    this.userId    = sessionId;
    this.authType  = "google";
    this.sessionId = sessionId;

    // Call backend to create/get profile
    const tempNick = nickname || `Chedda${Math.floor(Math.random() * 10000)}`;
    
    const profileResult = await this.actor.socialLoginAndGetProfile(
      email,
      tempNick,
      "google",
      this.gameId
    );

    if (profileResult?.err) throw new Error(profileResult.err);

    const profileData = profileResult.ok;
    
    // Check if new user needs nickname
    const isNewUser = profileData.isNewUser || 
                      profileData.nickname.includes('@') || 
                      profileData.nickname.startsWith('Chedda') ||
                      profileData.nickname.startsWith('Player_');
    
    let finalNickname = profileData.nickname;

    console.log("[CheddaBoards] Is new user:", isNewUser, "Current nickname:", finalNickname);

    if (isNewUser && !nickname) {
      const suggestion = await this._getSuggestedNickname();
      const customNick = this._promptForNickname(suggestion);
      if (customNick && customNick.trim() && customNick !== suggestion) {
        console.log("[CheddaBoards] Changing nickname from", finalNickname, "to", customNick.trim());
        
        const changeResult = await this.changeNickname(customNick.trim());
        console.log("[CheddaBoards] Change nickname result:", changeResult);
        
        if (changeResult?.success) {
          finalNickname = customNick.trim();
        }
      } else if (customNick && customNick.trim() === suggestion) {
        // User accepted the suggestion
        finalNickname = suggestion;
      }
    }

    // Build profile
    this.profile = {
      nickname: finalNickname,
      score: profileData.gameProfile ? Number(profileData.gameProfile.total_score || 0) : 0,
      streak: profileData.gameProfile ? Number(profileData.gameProfile.best_streak || 0) : 0,
      achievements: profileData.gameProfile ? profileData.gameProfile.achievements : [],
      lastPlayed: profileData.gameProfile ? profileData.gameProfile.last_played : undefined,
      playCount: profileData.gameProfile ? Number(profileData.gameProfile.play_count || 0) : 0,
      gameId: this.gameId,
      authType: "google",
    };

    this.authData = {
      userType: "email",
      userId: sessionId,
      authType: "google",
      nickname: finalNickname,
      sessionId
    };
    
    sessionStorage.setItem("chedda_auth", JSON.stringify(this.authData));
    sessionStorage.setItem("auth_method", "google");

    if (typeof window !== "undefined" && window.emitToGodot) {
      window.emitToGodot(
        "google_login_success",
        this.profile.nickname || "",
        String(this.profile.score || 0),
        String(this.profile.streak || 0),
        JSON.stringify(this.profile.achievements || [])
      );
    }

    console.log("[CheddaBoards] Google login complete:", finalNickname);
    return this.profile;
  } catch (e) {
    console.error("Google login failed:", e);
    throw e;
  }
}

async loginApple(appleResponse, providedNonce = null) {
  try {
    console.log("[CheddaBoards] Apple login via CheddaAuth…");

    if (!appleResponse || !appleResponse.id_token) {
      throw new Error("Invalid Apple sign-in response (missing id_token)");
    }

    if (!providedNonce) {
      console.warn("[CheddaBoards] No nonce provided for Apple login");
    }

    const state = crypto.randomUUID();

    const resp = await fetch(VERIFIER_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        provider: "apple",
        id_token: appleResponse.id_token,
        state,
        nonce: providedNonce || undefined
      }),
    });

    const data = await resp.json();
    if (!data || !data.ok || !data.session || !data.session.sessionId) {
      console.error("[CheddaBoards] Verifier error:", data);
      throw new Error(data?.error || "Apple verify failed");
    }

    const sessionId = data.session.sessionId;
    const email = data.session.email;

    this.identity = new AnonymousIdentity();
    await this._createActor({ identity: this.identity });

    this.userType  = "email";
    this.userId    = sessionId;
    this.authType  = "apple";
    this.sessionId = sessionId;

    const tempNick = `Chedda${Math.floor(Math.random() * 10000)}`;
    
    const profileResult = await this.actor.socialLoginAndGetProfile(
      email,
      tempNick,
      "apple",
      this.gameId
    );

    if (profileResult?.err) throw new Error(profileResult.err);

    const profileData = profileResult.ok;
    
    // Check if new user needs nickname
    const isNewUser = profileData.isNewUser || 
                      profileData.nickname.includes('@') || 
                      profileData.nickname.startsWith('Chedda') ||
                      profileData.nickname.startsWith('Player_');
    
    let finalNickname = profileData.nickname;

    console.log("[CheddaBoards] Is new user:", isNewUser, "Current nickname:", finalNickname);

    if (isNewUser) {
      const suggestion = await this._getSuggestedNickname();
      const customNick = this._promptForNickname(suggestion);
      if (customNick && customNick.trim() && customNick !== suggestion) {
        console.log("[CheddaBoards] Changing nickname from", finalNickname, "to", customNick.trim());
        
        const changeResult = await this.changeNickname(customNick.trim());
        console.log("[CheddaBoards] Change nickname result:", changeResult);
        
        if (changeResult?.success) {
          finalNickname = customNick.trim();
        }
      } else if (customNick && customNick.trim() === suggestion) {
        // User accepted the suggestion
        finalNickname = suggestion;
      }
    }

    // Build profile
    this.profile = {
      nickname: finalNickname,
      score: profileData.gameProfile ? Number(profileData.gameProfile.total_score || 0) : 0,
      streak: profileData.gameProfile ? Number(profileData.gameProfile.best_streak || 0) : 0,
      achievements: profileData.gameProfile ? profileData.gameProfile.achievements : [],
      lastPlayed: profileData.gameProfile ? profileData.gameProfile.last_played : undefined,
      playCount: profileData.gameProfile ? Number(profileData.gameProfile.play_count || 0) : 0,
      gameId: this.gameId,
      authType: "apple",
    };

    this.authData = {
      userType: "email",
      userId: sessionId,
      authType: "apple",
      nickname: finalNickname,
      sessionId
    };
    
    sessionStorage.setItem("chedda_auth", JSON.stringify(this.authData));
    sessionStorage.setItem("auth_method", "apple");

    if (typeof window !== "undefined" && window.emitToGodot) {
      window.emitToGodot(
        "apple_login_success",
        this.profile.nickname || "",
        String(this.profile.score || 0),
        String(this.profile.streak || 0),
        JSON.stringify(this.profile.achievements || [])
      );
    }

    console.log("[CheddaBoards] Apple login complete:", finalNickname);
    return this.profile;
  } catch (e) {
    console.error("Apple login failed:", e);
    throw e;
  }
}

  // =================== Logout ===================
  async logout() {
    try {
      if (this.sessionId) {
        await this.actor.destroySession(this.sessionId).catch((e) => {
          console.warn("[CheddaBoards] Session destroy failed:", e);
        });
      }

      if (this.authClient) {
        await this.authClient.logout().catch(() => {});
      }

      this.identity = new AnonymousIdentity();
      this.userType = null;
      this.userId = null;
      this.authType = null;
      this.authData = null;
      this.profile = null;
      this.sessionId = null;

      sessionStorage.removeItem("chedda_auth");
      sessionStorage.removeItem("auth_method");

      await this._createActor({ identity: this.identity });
      return true;
    } catch (e) {
      console.error("Logout failed:", e);
      return false;
    }
  }

  // =================== Game Methods ===================
  async submitScore(score, streak, roundsPlayed = null) {

      if (score < 0 || streak < 0) {
    throw new Error('Score and streak must be non-negative');
  }
  if (typeof score !== 'number' || typeof streak !== 'number') {
    throw new Error('Score and streak must be numbers');
  }
  if (isNaN(score) || isNaN(streak)) {
    throw new Error('Score and streak cannot be NaN');
  }
  
  try {
    if (!this.actor) await this._createActor({ identity: this.identity });
    if (!this.userType) {
      console.error("❌ No userType!");
      return { success: false, error: "Not authenticated" };
    }

    let userIdType, userId;

    if (this.userType === "principal") {
      const ac = this.authClient || window.cheddaAuthClient;
      if (ac && (await ac.isAuthenticated())) {
        this.identity = ac.getIdentity();
        await this._createActor({ identity: this.identity });
      }
      userIdType = "principal";
      userId = this.userId;
      
      console.log("📍 Principal auth:");
      console.log("  userIdType:", userIdType);
      console.log("  userId:", userId);
      
    } else if (this.userType === "email") {
      userIdType = "email";
      userId = this.sessionId;
      
     // console.log("📍 Email auth:");
      //console.log("  userIdType:", userIdType);
     // console.log("  userId:", userId);
      
    } else {
      console.error("❌ Invalid userType:", this.userType);
      return { success: false, error: "Invalid user type" };
    }

    if (!userIdType || userIdType === "null" || userIdType === null) {
      console.error("❌ userIdType is null/undefined!");
      return { success: false, error: "Missing user type" };
    }
    
    if (!userId || userId === "null" || userId === null) {
      console.error("❌ userId is null/undefined!");
      return { success: false, error: "Missing user ID" };
    }
    
    if (!this.gameId || this.gameId === "null" || this.gameId === null) {
      console.error("❌ gameId is null/undefined!");
      return { success: false, error: "Missing game ID" };
    }

    const result = await this.actor.submitScore(
      userIdType,
      userId,
      this.gameId,
      Math.floor(score),
      Math.floor(streak),
      roundsPlayed !== null ? [roundsPlayed] : []
    );

    console.log("✅ Backend response:", result);

    if (result?.ok) {
      this.loadProfile().catch((err) =>
        console.error("[CheddaBoards] Background profile refresh failed:", err)
      );
      
      if (typeof window !== "undefined" && window.emitToGodot) {
        window.emitToGodot("score_submitted", String(score), String(streak));
      }
      return { success: true, message: result.ok };
    }

    if (result?.err) {
      return { success: false, error: result.err };
    }

    return { success: false, error: "Unknown error" };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

  async getLeaderboard(sortBy = "score", limit = 10000) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const sortByVariant = sortBy === "streak" ? { streak: null } : { score: null };
      let results = await this.actor.getLeaderboard(this.gameId, sortByVariant, limit);

      if (Array.isArray(results) && results.length === 1 && Array.isArray(results[0])) {
        results = results[0];
      }
      if (!Array.isArray(results)) return [];

      return results.map((entry, index) => ({
  nickname: entry[0] || "Unknown",
  score: Number(entry[1] || 0),
  streak: Number(entry[2] || 0),
  rank: index + 1,
  authType: entry[3] || "unknown",
}));
    } catch (e) {
      console.error("Leaderboard fetch failed:", e);
      return [];
    }
  }

 async getLeaderboardByAuth(authType, sortBy = "score", limit = 10000) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });

      const backendAuthType =
        authType === "cheddaId" || authType === "internetIdentity"
          ? { internetIdentity: null }
          : authType === "google"
          ? { google: null }
          : authType === "apple"
          ? { apple: null }
          : { apple: null };

      const sortByVariant = sortBy === "streak" ? { streak: null } : { score: null };

      let results = await this.actor.getLeaderboardByAuth(
        this.gameId,
        backendAuthType,
        sortByVariant,
        limit
      );

      while (Array.isArray(results) && 
             results.length === 1 && 
             Array.isArray(results[0]) &&
             results[0].length !== 4) { 
        results = results[0];
      }

      if (!Array.isArray(results)) return [];

      return results.map((entry, index) => {
        if (!Array.isArray(entry) || entry.length < 4) {
          return null;
        }

        return {
          nickname: String(entry[0] || "Unknown"),
          score: Number(entry[1] || 0),
          streak: Number(entry[2] || 0),
          rank: index + 1,
          authType: String(entry[3] || "unknown"),
        };
      }).filter(e => e !== null);
      
    } catch (e) {
      console.error("Leaderboard by auth fetch failed:", e);
      return [];
    }
  }

  async getPlayerRank(sortBy = "score", userIdType = null, userId = null) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });

      let finalUserIdType = userIdType;
      let finalUserId = userId;

      if (!finalUserIdType) {
        if (this.userType === "principal") {
          finalUserIdType = "principal";
          finalUserId = this.userId;
        } else if (this.userType === "email") {
          finalUserIdType = "email";
          finalUserId = this.userId;
        } else {
          return null;
        }
      }

      const sortByVariant = sortBy === "streak" ? { streak: null } : { score: null };

      const result = await this.actor.getPlayerRank(
        this.gameId,
        sortByVariant,
        finalUserIdType,
        finalUserId
      );

      if (result && result[0]) {
        return {
          rank: Number(result[0].rank || 0),
          score: Number(result[0].score || 0),
          streak: Number(result[0].streak || 0),
          totalPlayers: Number(result[0].totalPlayers || 0),
        };
      }
      return null;
    } catch (e) {
      console.error("Player rank fetch failed:", e);
      return null;
    }
  }

  async getGameAuthStats() {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const backendStats = await this.actor.getGameAuthStats(this.gameId);
      return {
        cheddaId: Number(backendStats.internetIdentity || 0),
        google: Number(backendStats.google || 0),
        apple: Number(backendStats.apple || 0),
        total: Number(backendStats.total || 0),
      };
    } catch (e) {
      console.error("Game auth stats fetch failed:", e);
      return null;
    }
  }

  // =================== Profile ===================

async getProfile() {
  try {
    if (!this.actor) await this._createActor({ identity: this.identity });
    if (!this.userType) return null;

    const userIdType = this.userType === "principal" ? "principal" : "session";
    const userId = this.userType === "principal" ? this.userId : this.sessionId;
    
    const result = await this.actor.getGameProfile(userIdType, userId, this.gameId);

    if (result?.ok) {
      const gp = result.ok;
      return {
        nickname: this.authData?.nickname || "Player",
        score: Number(gp.total_score || 0),
        streak: Number(gp.best_streak || 0),
        achievements: gp.achievements || [],
        lastPlayed: gp.last_played,
        playCount: Number(gp.play_count || 0),
        gameId: this.gameId,
        authType: this.authType,
      };
    }
    
    return null;
  } catch (e) {
    console.error("Profile fetch failed:", e);
    return null;
  }
}

// ✅ Get ALL games for user (dashboard use)
async getAllGameProfiles() {
  try {
    if (!this.actor) await this._createActor({ identity: this.identity });
    if (!this.userType) return null;

    const userIdType = this.userType === "principal" ? "principal" : "session";
    const userId = this.userType === "principal" ? this.userId : this.sessionId;
    
    const result = await this.actor.getUserProfile(userIdType, userId);

    if (result?.ok) {
      const profile = result.ok;
      return {
        nickname: profile.nickname,
        authType: this.authType,
        games: profile.gameProfiles.map(([gameId, gp]) => ({
          gameId,
          score: Number(gp.total_score || 0),
          streak: Number(gp.best_streak || 0),
          achievements: gp.achievements || [],
          lastPlayed: gp.last_played,
          playCount: Number(gp.play_count || 0),
        })),
        created: profile.created,
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
      if (window.emitToGodot) {
        window.emitToGodot(
          "profile_loaded",
          this.profile.nickname || "Player",
          String(this.profile.score || 0),
          String(this.profile.streak || 0),
          JSON.stringify(this.profile.achievements || [])
        );
      }
    }
    return this.profile;
  }

  getCachedProfile() {
    return this.profile;
  }

  async refreshProfile() {
    return await this.loadProfile();
  }

async getMyFullProfile() {
  try {
    if (!this.actor) await this._createActor({ identity: this.identity });
    if (!this.userType) return null;

    let result;
    
    if (this.sessionId) {
      result = await this.actor.getMyProfileBySession(this.sessionId);
    } else if (this.userType === "principal") {
      const ac = this.authClient || window.cheddaAuthClient;
      if (ac && (await ac.isAuthenticated())) {
        this.identity = ac.getIdentity();
        await this._createActor({ identity: this.identity });
      }
      result = await this.actor.getMyProfile();
    } else {
      return null;
    }

    if (result?.ok) {
      return result.ok;
    }
    
    return null;
  } catch (e) {
    console.error("Full profile fetch failed:", e);
    return null;
  }
}

  async changeNickname(newNickname) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      if (!this.userType) return { success: false, error: "Not authenticated" };
      if (!newNickname || newNickname.length < 2 || newNickname.length > 12) {
        return { success: false, error: "Nickname must be 2-12 characters" };
      }

      let userIdType, userId;

      if (this.userType === "principal") {
        const ac = this.authClient || window.cheddaAuthClient;
        if (ac && (await ac.isAuthenticated())) {
          this.identity = ac.getIdentity();
          await this._createActor({ identity: this.identity });
        }
        userIdType = "principal";
        userId = this.userId;
      } else {
        userIdType = "email";
        userId = this.sessionId;
      }

      const result = await this.actor.changeNicknameAndGetProfile(
        userIdType,
        userId,
        newNickname,
        this.gameId
      );

      if (result?.ok) {
        const data = result.ok;

        if (this.profile) {
          this.profile.nickname = data.nickname;
          if (data.gameProfile) {
            this.profile.score = Number(data.gameProfile.total_score || this.profile.score || 0);
            this.profile.streak = Number(data.gameProfile.best_streak || this.profile.streak || 0);
            this.profile.achievements = data.gameProfile.achievements || this.profile.achievements;
            this.profile.lastPlayed = data.gameProfile.last_played ?? this.profile.last_played;
            this.profile.playCount = Number(
              data.gameProfile.play_count || this.profile.playCount || 0
            );
          }
        }

        if (this.authData) {
          this.authData.nickname = data.nickname;
          sessionStorage.setItem("chedda_auth", JSON.stringify(this.authData));
        }

        if (typeof window !== "undefined") {
          window.dispatchEvent(
            new CustomEvent("chedda:nickname_changed", { detail: { nickname: data.nickname } })
          );
          if (window.emitToGodot) window.emitToGodot("nickname_changed", data.nickname);
        }

        return { success: true, nickname: data.nickname };
      }

      if (result?.err) return { success: false, error: result.err };
      return { success: true, nickname: newNickname };
    } catch (e) {
      console.error("Nickname change failed:", e);
      return { success: false, error: e.message };
    }
  }

  async promptNicknameChange(currentNickname = "") {
    return new Promise((resolve) => {
      const overlay = document.createElement("div");
      overlay.style.cssText =
        "position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.7);z-index:9999;display:flex;align-items:center;justify-content:center;font-family:Arial,sans-serif;";

      const dialog = document.createElement("div");
      dialog.style.cssText =
        "background:#2a2a2a;border:3px solid #4a4a4a;border-radius:10px;padding:30px;width:320px;text-align:center;box-shadow:0 0 20px rgba(0,0,0,0.5);";

      const title = document.createElement("h2");
      title.textContent = "Change Nickname";
      title.style.cssText = "color:#fff;margin:0 0 15px 0;font-size:24px;";
      dialog.appendChild(title);

      if (currentNickname) {
        const currentLabel = document.createElement("p");
        currentLabel.textContent = `Current: ${currentNickname}`;
        currentLabel.style.cssText = "color:#aaa;margin:0 0 15px 0;font-size:14px;";
        dialog.appendChild(currentLabel);
      }

      const input = document.createElement("input");
      input.type = "text";
      input.value = currentNickname;
      input.maxLength = 12;
      input.placeholder = "Enter new nickname...";
      input.style.cssText =
        "width:100%;padding:12px;background:#1a1a1a;border:2px solid #4a4a4a;color:#fff;font-size:16px;border-radius:5px;box-sizing:border-box;margin-bottom:5px;";
      dialog.appendChild(input);

      const counter = document.createElement("div");
      counter.textContent = `${input.value.length}/12`;
      counter.style.cssText = "color:#888;font-size:12px;text-align:right;margin-bottom:15px;";
      dialog.appendChild(counter);

      input.addEventListener("input", () => {
        counter.textContent = `${input.value.length}/12`;
      });

      const btnContainer = document.createElement("div");
      btnContainer.style.cssText = "display:flex;gap:15px;justify-content:center;";

      const confirmBtn = document.createElement("button");
      confirmBtn.textContent = "CHANGE";
      confirmBtn.style.cssText =
        "padding:12px 25px;background:#4CAF50;color:#fff;border:none;border-radius:5px;cursor:pointer;font-weight:bold;font-size:14px;transition:all 0.2s;";
      confirmBtn.onmouseover = function () {
        this.style.background = "#45a049";
      };
      confirmBtn.onmouseout = function () {
        this.style.background = "#4CAF50";
      };

      const cancelBtn = document.createElement("button");
      cancelBtn.textContent = "CANCEL";
      cancelBtn.style.cssText =
        "padding:12px 25px;background:#666;color:#fff;border:none;border-radius:5px;cursor:pointer;font-weight:bold;font-size:14px;transition:all 0.2s;";
      cancelBtn.onmouseover = function () {
        this.style.background = "#777";
      };
      cancelBtn.onmouseout = function () {
        this.style.background = "#666";
      };

      btnContainer.appendChild(confirmBtn);
      btnContainer.appendChild(cancelBtn);
      dialog.appendChild(btnContainer);

      overlay.appendChild(dialog);
      document.body.appendChild(overlay);

      input.focus();
      input.select();

      confirmBtn.onclick = () => {
        const value = input.value.trim();
        document.body.removeChild(overlay);
        resolve(value);
      };
      cancelBtn.onclick = () => {
        document.body.removeChild(overlay);
        resolve(null);
      };
      input.onkeydown = (e) => {
        if (e.key === "Enter") confirmBtn.click();
        else if (e.key === "Escape") cancelBtn.click();
      };
      overlay.onclick = (e) => {
        if (e.target === overlay) cancelBtn.click();
      };
    });
  }

  async changeNicknameWithPrompt() {
    try {
      const currentNickname = this.profile?.nickname || this.authData?.nickname || "";
      const newNickname = await this.promptNicknameChange(currentNickname);
      if (!newNickname || newNickname === currentNickname) {
        return { success: false, cancelled: true };
      }
      return await this.changeNickname(newNickname);
    } catch (e) {
      console.error("[CheddaBoards] Nickname change with prompt failed:", e);
      return { success: false, error: e.message };
    }
  }

  async unlockAchievement(achievementId) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      if (!this.userType) return { success: false, error: "Not authenticated" };

      let userIdType, userId;
      if (this.userType === "principal") {
        userIdType = "principal";
        userId = this.userId;
      } else if (this.userType === "email") {
        userIdType = "email";
        userId = this.sessionId;
      } else {
        return { success: false, error: "Invalid user type" };
      }

      const result = await this.actor.unlockAchievement(
        userIdType,
        userId,
        this.gameId,
        achievementId
      );

      if (result?.ok) {
        await this.loadProfile();
        return { success: true, message: result.ok };
      }
      if (result?.err) return { success: false, error: result.err };
      return { success: true };
    } catch (e) {
      console.error("Achievement unlock failed:", e);
      return { success: false, error: e.message };
    }
  }

  // =================== Analytics ===================
  async trackEvent(eventType, metadata = {}) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });

      metadata.gameId = this.gameId;
      metadata.authType = this.authType || "none";
      const metadataArray = Object.entries(metadata).map(([k, v]) => [k, String(v)]);

      if (!this.userType) {
        return { success: false, error: "Not authenticated" };
      }

      let userIdType = this.userType;
      let userId;
      
      if (this.userType === "email" || this.userType === "session") {
        userId = this.sessionId; // ← Changed from this.userId
      } else if (this.userType === "principal") {
        const ac = this.authClient || window.cheddaAuthClient;
        if (ac && (await ac.isAuthenticated())) {
          this.identity = ac.getIdentity();
          await this._createActor({ identity: this.identity });
        }
        userId = this.userId;      } 
        else {
        userId = "";
      }

      await this.actor.trackEvent(userIdType, userId, eventType, this.gameId, metadataArray);
      return { success: true };
    } catch (e) {
      console.error("Event tracking failed:", e);
      return { success: false, error: e.message };
    }
  }

  async getDailyStats(date) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const stats = await this.actor.getDailyStats(date, this.gameId);
      return stats || null;
    } catch (e) {
      console.error("Daily stats fetch failed:", e);
      return null;
    }
  }

  async getPlayerAnalytics(_identifier) {
    return null; // future
  }

  async getAnalyticsSummary() {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const summary = await this.actor.getAnalyticsSummary();
      return {
        totalEvents: Number(summary.totalEvents || 0),
        uniquePlayers: Number(summary.uniquePlayers || 0),
        totalGames: Number(summary.totalGames || 0),
        totalDays: Number(summary.totalDays || 0),
      };
    } catch (e) {
      console.error("Analytics fetch failed:", e);
      return null;
    }
  }

  // =================== Game Management ===================
  async listGames() {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const games = await this.actor.listGames();
      return games || [];
    } catch (e) {
      console.error("List games failed:", e);
      return [];
    }
  }

  async getGameInfo() {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const game = await this.actor.getGame(this.gameId);
      return game || null;
    } catch (e) {
      console.error("Get game info failed:", e);
      return null;
    }
  }

  async getSystemInfo() {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const info = await this.actor.getSystemInfo();
      return info;
    } catch (e) {
      console.error("System info fetch failed:", e);
      return null;
    }
  }

  // =================== File Management ===================
  async uploadFile(filename, data) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });

      let blob;
      if (data instanceof Blob) {
        blob = data;
      } else if (typeof data === "string") {
        blob = new Blob([data], { type: "text/plain" });
      } else if (data instanceof ArrayBuffer) {
        blob = new Blob([data]);
      } else {
        blob = new Blob([JSON.stringify(data)], { type: "application/json" });
      }

      const arrayBuffer = await blob.arrayBuffer();
      const result = await this.actor.uploadFile(filename, [...new Uint8Array(arrayBuffer)]);

      if (result?.ok) return { success: true, message: result.ok };
      if (result?.err) return { success: false, error: result.err };
      return { success: true };
    } catch (e) {
      console.error("File upload failed:", e);
      return { success: false, error: e.message };
    }
  }

  async listFiles() {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
      const files = await this.actor.listFiles();
      return files || [];
    } catch (e) {
      console.error("List files failed:", e);
      return [];
    }
  }

  async getFile(filename) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });
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

  async updateGameRules(maxScorePerRound, maxStreakDelta, absoluteScoreCap, absoluteStreakCap) {
    try {
      if (!this.actor) await this._createActor({ identity: this.identity });

      const result = await this.actor.updateGameRules(
        this.gameId,
        maxScorePerRound ? [maxScorePerRound] : [],
        maxStreakDelta ? [maxStreakDelta] : [],
        absoluteScoreCap ? [absoluteScoreCap] : [],
        absoluteStreakCap ? [absoluteStreakCap] : []
      );

      if (result?.ok) return { success: true, message: result.ok };
      if (result?.err) return { success: false, error: result.err };
      return { success: true };
    } catch (e) {
      console.error("[CheddaBoards] Update game rules failed:", e);
      return { success: false, error: e.message };
    }
  }

  // =================== Helper getters ===================
  _authTypeToString(authType) {
    if (!authType) return "unknown";
    if (authType.internetIdentity !== undefined) return "cheddaId";
    if (authType.google !== undefined) return "google";
    if (authType.apple !== undefined) return "apple";
    return "unknown";
  }

  _stringToAuthType(authString) {
    switch ((authString || "").toLowerCase()) {
      case "cheddaid":
      case "chedda":
        return { internetIdentity: null };
      case "google":
        return { google: null };
      case "apple":
        return { apple: null };
      default:
        return null;
    }
  }

  isAuthenticated() {
    return (
      this.userType !== null && (this.sessionId !== null || this.userId !== null)
    );
  }

  getAuthType() {
    return this.authType === "internetIdentity" ? "cheddaId" : this.authType;
  }

  getGameId() {
    return this.gameId;
  }

  getPrincipal() {
    if (this.userType === "principal") return this.userId;
    if (this.userType === "email") return "email:" + this.userId;
    return null;
  }

  getAuthData() {
    return this.authData;
  }

  getSessionId() {
    return this.sessionId;
  }
}

// DEVELOPERS: Replace with your OAuth verifier endpoint
const VERIFIER_URL = "YOUR_VERIFIER_ENDPOINT_HERE";

const CheddaAPI = {
  init: async (canisterId, config = {}) => {
    if (!config.gameId) {
      throw new Error(
        '[CheddaBoards] gameId is required. Usage: CheddaBoards.init(canisterId, { gameId: "your-game-id" })'
      );
    }

    const instance = new CheddaBoards({ canisterId, ...config });
    await instance.init();

    return {
  // =================== AUTH ===================
  login: {
    chedda: (nickname) => instance.loginChedda(nickname),
    ii2: (nickname) => instance.loginII2(nickname),
    google: (cred, nickname) => instance.loginGoogle(cred, nickname),
    apple: (resp, nickname) => instance.loginApple(resp, nickname),
  },
  
  // Direct methods (keep for backwards compatibility)
  loginChedda: (nickname) => instance.loginChedda(nickname),
  loginII2: (nickname) => instance.loginII2(nickname),
  loginGoogle: (cred, nickname) => instance.loginGoogle(cred, nickname),
  loginApple: (resp, nickname) => instance.loginApple(resp, nickname),
  logout: () => instance.logout(),
  isAuthenticated: () => instance.isAuthenticated(),
  getAuthType: () => instance.getAuthType(),


      // =================== GAME REGISTRATION ===================
      registerGame: (name, desc, rules) => instance.registerGame(name, desc, rules),
      getMyGameCount: () => instance.getMyGameCount(),
      getRemainingGameSlots: () => instance.getRemainingGameSlots(),

      // =================== GAMEPLAY ===================
      submitScore: (score, streak, rounds) => instance.submitScore(score, streak, rounds),
      unlockAchievement: (id) => instance.unlockAchievement(id),

      // =================== LEADERBOARDS ===================
      getLeaderboard: (sortBy, limit) => instance.getLeaderboard(sortBy, limit),
      getLeaderboardByAuth: (authType, sortBy, limit) => 
        instance.getLeaderboardByAuth(authType, sortBy, limit),
      getPlayerRank: (sortBy) => instance.getPlayerRank(sortBy),
      getGameAuthStats: () => instance.getGameAuthStats(),

      // =================== PROFILES ===================
      getProfile: () => instance.getProfile(),
      getAllGameProfiles: () => instance.getAllGameProfiles(),
      getCachedProfile: () => instance.getCachedProfile(),
      refreshProfile: () => instance.refreshProfile(),
      changeNickname: (name) => instance.changeNickname(name),
      changeNicknameWithPrompt: () => instance.changeNicknameWithPrompt(),

      // =================== GAME MANAGEMENT ===================
      listGames: () => instance.listGames(),
      getGameInfo: () => instance.getGameInfo(),
      updateGameRules: (a, b, c, d) => instance.updateGameRules(a, b, c, d),

      // =================== ANALYTICS ===================
      trackEvent: (type, data) => instance.trackEvent(type, data),
      getDailyStats: (date) => instance.getDailyStats(date),
      getAnalyticsSummary: () => instance.getAnalyticsSummary(),

      // =================== FILES ===================
      uploadFile: (name, data) => instance.uploadFile(name, data),
      listFiles: () => instance.listFiles(),
      getFile: (name) => instance.getFile(name),

      // =================== SYSTEM ===================
      getSystemInfo: () => instance.getSystemInfo(),
      
      // =================== METADATA ===================
      gameId: instance.gameId,
      getPrincipal: () => instance.getPrincipal(),

      // =================== ADVANCED ===================
      instance,
    };
  },
};

export default CheddaAPI;

// UMD-ish exposure
if (typeof window !== "undefined") window.CheddaBoards = CheddaAPI;
if (typeof module !== "undefined" && module.exports) module.exports = CheddaAPI;
