# ⚙️ Advanced Deployment Guide

For developers who prefer full control, CheddaBoards can run on your own distributed backend instance.

---

## 🧭 Overview

CheddaBoards uses a decentralized compute network under the hood.  
This lets you host your own backend while keeping the same SDK and API interface.

Running your own instance provides:
- Independent data ownership  
- Custom validation rules  
- Guaranteed uptime and isolation  
- Cost of roughly **$7/year for 100K users**

---

## 🧰 Requirements

- Node.js environment or compatible runtime  
- Access to the CheddaBoards backend source (`/src/backend`)  
- A deployment CLI (provided in the repo)

---

## 🚀 Deploy Your Backend

```bash
# Clone the repository
git clone https://github.com/cheddatech/CheddaBoards-SDK.git
cd CheddaBoards-SDK

# Deploy your backend instance
npm run deploy
When deployment completes, note your backend ID.
Use it during initialization:

js
Copy code
const chedda = await CheddaBoards.init('your-backend-id', {
  gameId: 'your-game'
});
💵 Cost Model
Backend instances operate on resource credits.
At typical usage, the equivalent cost is under $10 per year for 100K players.

🔄 Updating Rules or Code
You can redeploy updates at any time:

bash
Copy code
npm run update
All player data remains intact — updates are applied atomically.
