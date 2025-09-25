# CheddaBoards 🧀

Open source SDK for decentralized game leaderboards and achievements on the Internet Computer Protocol.

## What is CheddaBoards?

CheddaBoards provides a **free hosted backend service** for indie game developers to add leaderboards, achievements, and player profiles to their games. Your data is stored permanently on the ICP blockchain.

- **Free Tier**: Up to 1000 players per game
- **Open Source SDK**: This repository
- **Hosted Backend**: We handle the infrastructure
- **No Vendor Lock-in**: Export your data anytime

## Features

- **Multi-Auth Support**: Google, Apple, Internet Identity, and anonymous logins
- **Cross-Platform**: Works in browsers, Unity, Godot, and any JavaScript environment
- **Blockchain Permanent**: Data stored on ICP blockchain
- **Simple Integration**: One-line initialization
- **Rich Analytics**: Track player behavior and engagement
- **Achievement System**: Unlock and track achievements
- **Real-time Leaderboards**: Global and filtered rankings

## Quick Start

### Installation

Download and include the SDK in your project:

```html
<!-- Option 1: Include directly from GitHub -->
<script src="https://cdn.jsdelivr.net/gh/cheddatech/CheddaBoards-SDK/dist/cheddaboards.min.js"></script>

<!-- Option 2: Download and host locally -->
<script src="./js/cheddaboards.min.js"></script>
```

### Basic Usage

```javascript
// Initialize with your game ID (uses hosted service)
const chedda = await CheddaBoards.init(null, {
  gameId: 'my-awesome-game',  // Required: Your unique game ID
  gameName: 'My Awesome Game',
  gameDescription: 'The best game ever made'
});

// Login options
await chedda.login.anonymous('Player123');
// or with Google (requires your own Google OAuth setup)
await chedda.login.google(googleCredential, 'PlayerNickname');
// or with Internet Identity (no setup required!)
await chedda.login.ii('PlayerNickname');

// Submit a score
await chedda.submitScore(1500, 10); // score, streak

// Get leaderboard
const leaders = await chedda.getLeaderboard('score', 10);

// Unlock achievement
await chedda.unlockAchievement(
  'first_win',
  'First Victory',
  'Win your first game'
);
```

## How It Works

```
Your Game → CheddaBoards SDK → Hosted ICP Backend → Blockchain Storage
```

1. **You integrate** the SDK into your game
2. **We provide** the backend infrastructure (free up to limits)
3. **ICP blockchain** ensures permanent data storage
4. **Players** get unified profiles across all CheddaBoards games

## Repository Contents

```
CheddaBoards-SDK/
├── dist/
│   └── cheddaboards.min.js    # Minified SDK - ready to use
├── src/
│   ├── sdk/
│   │   └── index.js           # Source code (for auditing)
│   └── backend/
│       └── main.mo            # Backend canister code (for transparency)
├── examples/
│   ├── html/                  # Browser game example
│   ├── unity/                 # Unity WebGL integration
│   └── godot/                 # Godot HTML5 integration
└── README.md
```

## Authentication Methods

### Anonymous Login
Perfect for casual play without requiring sign-up:
```javascript
await chedda.login.anonymous('GuestPlayer');
```

### Internet Identity (Recommended)
Blockchain-native auth, no configuration needed:
```javascript
await chedda.login.ii('PlayerNickname');
```

### Google Sign-In
Requires your own Google OAuth credentials:
```javascript
// After Google OAuth flow with YOUR credentials
await chedda.login.google(googleIdToken, 'PlayerNickname');
```

### Apple Sign-In
Requires your own Apple Developer account:
```javascript
// After Apple OAuth flow with YOUR credentials
await chedda.login.apple(appleResponse, 'PlayerNickname');
```

## Platform Integration

### Godot HTML5
See [examples/godot](./examples/godot3X) for complete integration guide.


## API Reference

### Core Methods

#### Initialization
```javascript
CheddaBoards.init(canisterId, options)
```
- `canisterId`: null for hosted service, or your own canister ID
- `options.gameId`: (required) Unique identifier for your game
- `options.gameName`: Display name for your game
- `options.gameDescription`: Brief description

#### Score Management
```javascript
submitScore(score, streak)           // Submit score and streak
getLeaderboard(sortBy, limit)        // Get top players
getLeaderboardByAuth(authType, sortBy, limit) // Filter by auth type
```

#### Profile Management
```javascript
getProfile()                          // Get current user profile
getAllGameProfiles()                  // Get all games for user
changeNickname(newNickname)          // Update nickname
```

#### Achievements
```javascript
unlockAchievement(id, name, description)  // Unlock achievement
```

#### Analytics
```javascript
trackEvent(eventType, metadata)       // Track custom events
getDailyStats(date)                  // Get daily statistics
getAnalyticsSummary()                // Get overall analytics
```

## Limits & Fair Use

### Free Tier (Hosted Service)
- ✅ Up to 1000 players per game
- ✅ Up to 10,000 score submissions per month
- ✅ Up to 5 games per developer
- ✅ Unlimited achievements
- ✅ 30-day analytics retention

Need more? Contact us for custom limits or self-hosting options.

## Self-Hosting Option

Want to run your own backend? The canister code is available in `src/backend/`:

```bash
# Deploy to ICP with your own cycles
dfx deploy --network ic

# Use your canister
const chedda = await CheddaBoards.init('your-canister-id', {
  gameId: 'your-game'
});
```

## Security

- **Rate Limiting**: 2-second minimum between score submissions
- **Score Validation**: Maximum 1,500 points per submission
- **Streak Validation**: Maximum 80 streak increase per submission
- **Session Management**: 7-day session duration for social logins
- **Blockchain Security**: Cryptographic verification via ICP

## Local Development

```javascript
// For local testing with dfx
const chedda = await CheddaBoards.init('your-local-canister', {
  gameId: 'test-game',
  host: 'http://localhost:4943'
});
```

## Browser Events

Listen for CheddaBoards events:
```javascript
window.addEventListener('chedda:profile', (e) => {
  console.log('Profile loaded:', e.detail);
});

window.addEventListener('chedda:google_login', (e) => {
  console.log('Google login successful:', e.detail);
});
```

## Why Open Source?

We believe gaming infrastructure shouldn't be gatekept. By open sourcing CheddaBoards:
- Developers can verify there's no vendor lock-in
- The community can contribute improvements
- Games can trust their data is handled transparently
- The ecosystem grows faster through collaboration

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/cheddatech/CheddaBoards-SDK/issues)
- **Discord**: [Join our community](https://discord.gg/cheddaboards)
- **Email**: support@cheddaboards.com

## FAQ

**Q: Is this really free?**  
A: Yes! The SDK is open source and the hosted service has a generous free tier.

**Q: What happens if you shut down?**  
A: Your data is on the ICP blockchain. The backend code is included - deploy your own anytime.

**Q: Do I need cryptocurrency?**  
A: No! We handle all blockchain complexity. It's just an API to you.

**Q: Can I use my own authentication?**  
A: Yes! Provide your own Google/Apple credentials, or use Internet Identity for free.

**Q: How is this different from Firebase/PlayFab?**  
A: Permanent blockchain storage, no vendor lock-in, unified player profiles across games.

## Status

🟢 **Beta** - The service is live and stable. We're gathering feedback for v1.0.
