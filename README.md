# 🧀 CheddaBoards SDK

> Decentralized leaderboard and player profile SDK for Internet Computer games.  
> Built for developers who want simple, secure, and flexible score tracking in Web3 or hybrid games.

---

## 🚀 Features

- 🎮 Easy integration with Godot, HTML5, or JavaScript-based games
- 🔐 Authentication via Internet Identity, email, or API key
- 📊 Submit scores, view leaderboards, manage player profiles
- 🧠 Caching and local storage support
- 🌐 Built for the Internet Computer using DFINITY agent + auth tools

---

## 📦 Installation

```bash
npm install cheddaboards-sdk
```

> **Peer dependencies required:**
>
> - `@dfinity/agent`
> - `@dfinity/auth-client`

---

## ⚙️ Basic Usage

```js
import { CheddaBoards } from "cheddaboards-sdk";
import { idlFactory } from "./declarations/your_canister";

const chedda = new CheddaBoards({
  canisterId: "your-canister-id",
  idlFactory,
  gameId: "my-game-id",
});
```

Initialize and log in (if using Internet Identity):

```js
await chedda.init();
await chedda.login();
```

---

## 🔐 Authentication Options

**1. Internet Identity (Web3)**

```js
await chedda.login();
```

**2. Email / Web2 Auth**

```js
localStorage.setItem("auth_method", "email");
localStorage.setItem("email_user", "user@example.com");
```

**3. API Key (server-side or admin use)**

```js
const chedda = new CheddaBoards({
  canisterId,
  idlFactory,
  gameId,
  apiKey: "your-api-key",
});
```

---

## 📈 Submitting Scores

```js
await chedda.submitScore(4500, 12); // score, streak
```

**Smart Mode** (auto-detects auth method):

```js
await chedda.submitScoreSmart({ score: 4500, streak: 12 });
```

---

## 🧾 Profile Management

```js
const profile = await chedda.getProfile();
await chedda.changeNickname("NewNickname");
await chedda.refreshProfile(); // Triggers browser and Godot events
```

---

## 🏆 Leaderboards

```js
const leaderboard = await chedda.getLeaderboard();
```

Or get scores by auth type:

```js
const web2 = await chedda.getWeb2Scores(); // Email users
const web3 = await chedda.getWeb3Scores(); // II users
```

Use cached data if available:

```js
const scores = chedda.getCached("web3");
chedda.clearCache(); // Clears all cached scores
```

---

## 🕹️ Game Registration (API Key Mode)

```js
await chedda.registerApiKey("your-api-key", "Your Studio");
await chedda.registerGame("Cool Game", "An addictive leaderboard game.");
const games = await chedda.listGames();
```

---

## 🧪 Godot Integration (Events)

CheddaBoards emits browser events that can be intercepted by Godot:

```js
window.godot?.emit_signal("profile_loaded", nickname, totalScore, bestStreak, achievementsJSON);
window.godot?.emit_signal("scores_updated", "web2", JSON.stringify(scores));
```

---

## 🔓 Logout

```js
await chedda.logout();
```

This clears the auth session and localStorage.

---

## 📁 Local Storage Keys Used

| Key              | Purpose                           |
|------------------|-----------------------------------|
| `auth_method`     | `'ii'` or `'email'`               |
| `ii_login_result` | Principal ID (Internet Identity) |
| `player_name`     | Player's nickname                |
| `email_user`      | Email address (Web2 login)       |

---

## 🛠 Dev Tips

- Ensure your `idlFactory` matches your deployed canister interface.
- Use `isAuthenticated()` and `isLoggedIn()` to check auth state.
- For local dev, call `agent.fetchRootKey()` if needed.

---

## 📄 License

MIT

---

## 🙌 Contributing

Pull requests welcome! Submit an issue or PR if you'd like to help improve the SDK.

---

## 💸 Grants & Roadmap

This SDK is part of a broader effort to bring rich, decentralized game mechanics to the Internet Computer.

Planned improvements include:

- Unity plugin support
- Offline score queueing
- Dev dashboard for managing games and players

Funding from DFINITY or Web3 grants will support those next steps.
