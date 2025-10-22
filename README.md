# CheddaBoards 🧀

**Post-Infastructure gaming backend for indie developers. Zero DevOps.**

Drop-in SDK for leaderboards, achievements, and player profiles built on Internet Computer Protocol.

[![Live Demo](https://img.shields.io/badge/demo-The%20Cheese%20Game-yellow)](https://thecheesegame.online)
[![Website](https://img.shields.io/badge/website-cheddaboards.com-blue)](https://cheddaboards.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 🎮 What is CheddaBoards?

CheddaBoards gives indie game developers **permanent, serverless infrastructure** for:
- 🏆 **Leaderboards** (global & filtered by auth type)
- 👤 **Player profiles** (persistent across games)
- 🎯 **Achievements** (unlock & track)
- 📊 **Analytics** (player behavior & engagement)

**Free tier:** 3 games per developer, unlimited players.  
**No servers.** No databases. No maintenance.

---

## ⚡ Quick Start

### 1. Install the SDK

```html
<!-- Option 1: CDN -->
<script src="https://cdn.jsdelivr.net/npm/cheddaboards_v1@1/cheddaboards.min.js"></script>

<!-- Option 2: Local -->
<script src="./js/cheddaboards.min.js"></script>
```

### 2. Initialize & Play

```javascript
// Initialize (one line!)
const chedda = await CheddaBoards.init(null, {
  gameId: 'my-cheese-game'  // Your registered game ID
});

// Player login (Google, Apple, or Quick Start)
await chedda.login.google(googleCredential);

// Submit scores
await chedda.submitScore(1000, 50);

// Get leaderboard
const leaders = await chedda.getLeaderboard('score', 10);
```

**That's it!** No backend setup. No database config. Just works.

---

## 🚀 Features

✅ **Multi-auth:** Google, Apple, Quick Start (passwordless, ii)
✅ **Cross-platform:** Godot 3x/4x, HTML5, JavaScript, Unity(in development)
✅ **One-line init:** No complex setup  
✅ **Open source:** Infrastructure you can audit & self-host  
✅ **Anti-cheat:** Built-in validation & rate limiting  
✅ **Free tier:** 3 games, unlimited players  

---

## 📦 What's Included

```
CheddaBoards-SDK/
├── dist/
│   └── cheddaboards.min.js    # Ready-to-use SDK
├── src/
│   ├── sdk/
│   │   └── index.js           # SDK source code
│   └── backend/
│       └── main.mo            # Backend canister (Motoko)
├── examples/
│   ├── html/                  # Browser game example
│   ├── godot/                 # Godot integration
│   └── unity/                 # Unity (in development)
└── README.md
```

---

## 🎯 How It Works

```
Your Game → CheddaBoards SDK → Backend → Permanent Storage
```

1. **You:** Integrate SDK with one line of code
2. **We:** Provide serverless backend infrastructure
3. **ICP:** Handles permanent, distributed storage
4. **Players:** Get unified profiles across all CheddaBoards games

---

## 🔐 Authentication Options

### Quick Start (Passwordless)
```javascript
await chedda.login.ii('PlayerNickname');
```
No passwords. No setup. Works like FaceID/TouchID for web.

### Google Sign-In
```javascript
await chedda.login.google(googleCredential, 'PlayerNickname');
```
Requires your own Google OAuth credentials.

### Apple Sign-In
```javascript
await chedda.login.apple(appleResponse, 'PlayerNickname');
```
Requires your own Apple Developer account.

---

## 📊 Pricing

### Free Tier (Forever)
- ✅ **3 games** per developer
- ✅ **Unlimited players** per game
- ✅ **All auth types** included
- ✅ **30-day analytics** retention
- ✅ **No credit card** required

### Need More?
- 📧 Contact: [info@cheddaboards.com](mailto:info@cheddaboards.com)
- 🌐 Visit: [cheddaboards.com](https://cheddaboards.com)

---

## 🛠️ Self-Hosting

Want to run your own backend? Deploy to ICP:

```bash
# Clone the repo
git clone https://github.com/cheddatech/CheddaBoards-SDK.git
cd CheddaBoards-SDK

# Deploy to ICP with your cycles
dfx deploy --network ic

# Use your canister
const chedda = await CheddaBoards.init('your-canister-id', {
  gameId: 'your-game'
});
```

**All backend code is open source.** No vendor lock-in.

---

## 🎮 Live Example

**The Cheese Game** — Pac-Man meets modern retro chaos, powered by CheddaBoards.

👉 [Play it now](https://thecheesegame.online)

See CheddaBoards working in production with real leaderboards, achievements, and player profiles.

---

## 📚 Documentation

- 🌐 **Website:** [cheddaboards.com](https://cheddaboards.com)
- 📖 **Full API Docs:** [github.com/cheddatech/CheddaBoards-SDK](https://github.com/cheddatech/CheddaBoards-SDK)
- 🎮 **Examples:** See `/examples` folder
- 💬 **Support:** [GitHub Issues](https://github.com/cheddatech/CheddaBoards-SDK/issues)

---

## 🤝 Contributing

We welcome contributions! CheddaBoards is open source because we believe gaming infrastructure should be transparent and community-owned.

1. Fork the repo
2. Create a feature branch
3. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## ❓ FAQ

### Is this really free?
Yes! Free forever for 3 games per developer with unlimited players. The SDK is open source and infrastructure runs on ICP's serverless compute.

### What if CheddaBoards shuts down?
Your data lives on permanent ICP infrastructure. You can self-host the backend (it's open source) or use any community deployment. No vendor lock-in.

### How is this different from Firebase/PlayFab?
- **Cost:** Free tier vs. $50-5000/mo
- **Lock-in:** Self-hostable vs. proprietary
- **Storage:** Permanent distributed compute vs. centralized servers

### What platforms are supported?
- ✅ **Godot** (HTML5 export)
- ✅ **JavaScript/HTML5** (any framework)
- 🚧 **Unity** (WebGL, in development)
- 🚧 **React** (coming soon)

---

## 📜 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🔗 Links

- 🌐 **Website:** [cheddaboards.com](https://cheddaboards.com)
- 🏢 **Company:** [cheddatech.com](https://cheddatech.com)
- 🎮 **Games:** [cheddagames.com](https://cheddagames.com)
- 🧀 **Demo:** [thecheesegame.online](https://thecheesegame.online)
- 🐦 **Twitter:** [@cheddatech](https://x.com/cheddatech) • [@chedda86](https://x.com/chedda86)
- 📧 **Email:** [info@cheddaboards.com](mailto:info@cheddaboards.com)

---

**Built by [CheddaTech Ltd](https://cheddatech.com) on Internet Computer Protocol.**
