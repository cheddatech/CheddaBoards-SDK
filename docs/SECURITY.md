# 🛡️ Security & Fair Play

CheddaBoards protects your leaderboards and player data automatically.  
All games include validation, rate limiting, and real-time monitoring.

---

## ⚔️ Validation Rules

Each game defines its own trusted score boundaries:

| Setting | Purpose | Default |
|----------|----------|----------|
| `maxScorePerRound` | Prevents sudden huge jumps | 5,000 |
| `maxStreakDelta` | Prevents streak exploits | 200 |
| `absoluteScoreCap` | Hard cap on total score | 100,000 |
| `absoluteStreakCap` | Hard cap on total streak | 2,000 |

If a submission exceeds these values, it’s automatically rejected.

---

## ⏱ Rate Limiting

Players can submit scores **once every two seconds**.  
This stops bots and spam attacks without affecting gameplay flow.

---

## 🔍 Suspicious Activity Detection

CheddaBoards continuously logs anomalies such as:
- Unusual submission frequency  
- Sudden value spikes  
- Invalid authentication patterns  

Developers can review flagged entries from analytics.

---

## 🔐 Authentication Integrity

- Passwordless login only (no anonymous access)  
- Player sessions last 7 days  
- Tokens automatically expire and renew silently  

---

## 🧩 Developer Controls

You can adjust rules anytime via the SDK:

```js
await chedda.updateGameRules({ maxScorePerRound: 3000 });
