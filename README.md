# CheddaBoards 🧀  
**Post-Infrastructure gaming backend for indie developers. Zero DevOps.**

Drop-in leaderboards, achievements, player profiles, and analytics - all powered by ICP canisters.  
**No servers. No databases. No maintenance.**

[![Live Demo](https://img.shields.io/badge/demo-The%20Cheese%20Game-yellow)](https://thecheesegame.online)
[![Website](https://img.shields.io/badge/website-cheddaboards.com-blue)](https://cheddaboards.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 🎮 What is CheddaBoards?

CheddaBoards provides **permanent, serverless backend features** for browser-based games:

- 🏆 **Server-validated leaderboards**
- 👤 **Cross-game player profiles**
- 🎯 **Achievements**
- 📊 **Analytics**
- 🔐 **Multi-auth:** Google, Apple, Internet Identity (via CheddaID)

Built entirely on the **Internet Computer**, with predictable costs and no DevOps overhead.

> **Free Tier:** 3 games per developer — *unlimited players*.

---

## ⚡ Quick Start

### 1. Include the SDK

```html
<!-- CDN -->
<script src="https://cdn.jsdelivr.net/npm/cheddaboards_v1@1.0.3/cheddaboards.min.js"></script>

```

### 2. Initialize & Use

```javascript
// Initialize
const chedda = await CheddaBoards.init(null, {
  gameId: 'my-game-id'
});

// Login (Google, Apple, or CheddaID)
await chedda.loginGoogle(googleCredential, 'Nickname');

// Submit score
await chedda.submitScore(1000, 50);

// Fetch leaderboard
const leaders = await chedda.getLeaderboard('score', 10);
```

That’s it - **no backend setup, no database, no scaling issues.**

---

## 🚀 Features

- ✅ **Multi-Auth:** Google, Apple, CheddaID (passwordless + II-backed)  
- ✅ **Godot 3/4 HTML5 support**  
- 🚧 Unity SDK (in development)  
- 🚧 REST API (in development)  
- 🛡️ **Anti-cheat validation + rate limiting**  
- 🔓 **Open source + self-hostable**  
- 🧪 **One-line initialization**  
- 🆓 **Free forever tier (3 games, unlimited players)**  

---

## 📦 Repository Structure

```
cheddaboards/
├── dist/               # Production-ready JS SDK
├── src/                
│   ├── sdk/            # SDK source
│   └── backend/        # Motoko canister backend
├── examples/           # HTML5 & Godot examples
└── README.md
```

---

## 🎯 How It Works

```
Your Game → CheddaBoards SDK → ICP Canisters → Permanent Storage
```

1. You call `CheddaBoards.init()`.  
2. The SDK connects to the hosted or self-hosted canister.  
3. All leaderboard/achievements/auth logic runs on-chain.  
4. Players keep a unified profile across all CheddaBoards-powered games.

---

## 🔐 Authentication

### CheddaID (II-Backed Passwordless Login)

```javascript
await chedda.loginChedda('Nickname');

```

No passwords, no email required.  
Uses Internet Identity under the hood.

### Google Login
```javascript
await chedda.loginGoogle(googleCredential, 'Nickname');
```

### Apple Login
```javascript
await chedda.loginApple(appleResponse, 'Nickname');
```

---

## 📊 Pricing

### **Free Forever**
- 3 games per developer  
- Unlimited players  
- All auth types included  
- 30-day analytics retention  

For extended plans:  
📧 **info@cheddaboards.com**

---

## 🛠️ Self-Hosting on ICP

```bash
git clone https://github.com/cheddatech/cheddaboards.git
cd cheddaboards
dfx deploy --network ic
```

```javascript
const chedda = await CheddaBoards.init('your-canister-id', {
  gameId: 'your-game'
});
```

---

## 🎮 Live Example

**The Cheese Game**  
Retro chaos powered entirely by CheddaBoards.

👉 https://thecheesegame.online

---

## 📚 Documentation

- Website: https://cheddaboards.com  
- Docs: https://docs.cheddaboards.com (coming this week)
- Examples: `/examples`  
- Issues: GitHub issue tracker  

---

## 🤝 Contributing

Contributions welcome!  
CheddaBoards is open source because gaming infrastructure should be transparent and community-owned.

---

## 📜 License

MIT License — see `LICENSE`.

---

## 🔗 Links

- Website — cheddaboards.com  
- Company — cheddatech.com  
- Games — cheddagames.com  
- Twitter — @cheddatech  
- Email — info@cheddaboards.com  

---

**Built by CheddaTech Ltd on the Internet Computer.**

