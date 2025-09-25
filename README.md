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

```bash
npm install @cheddaboards/sdk
```

Or include directly in HTML:
```html
<script src="https://unpkg.com/@cheddaboards/sdk/dist/cheddaboards.min.js"></script>
```

### Basic Usage

```javascript
import CheddaBoards from '@cheddaboards/sdk';

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

### Unity WebGL
See [examples/unity](./examples/unity) for complete integration guide.

### Godot HTML5
See [examples/godot](./examples/godot) for complete integration guide.

### React/Vue/Angular
See [examples/react](./examples/react) for framework examples.

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

Want to run your own backend? The canister code is available for self-deployment:

```bash
# Contact us for backend source code access
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

## Examples

Check out the [examples](./examples) directory for:
- [HTML5 Game](./examples/html) - Simple browser game
- [Unity WebGL](./examples/unity) - Unity integration
- [Godot HTML5](./examples/godot) - Godot integration  
- [React App](./examples/react) - React integration

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

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
git clone https://github.com/cheddaboards/sdk
cd sdk
npm install
npm test
```

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/cheddaboards/sdk/issues)
- **Discord**: [Join our community](https://discord.gg/cheddaboards)
- **Email**: support@cheddaboards.com

## FAQ

**Q: Is this really free?**  
A: Yes! The SDK is open source and the hosted service has a generous free tier.

**Q: What happens if you shut down?**  
A: Your data is on the ICP blockchain. You can deploy your own backend anytime.

**Q: Do I need cryptocurrency?**  
A: No! We handle all blockchain complexity. It's just an API to you.

**Q: Can I use my own authentication?**  
A: Yes! Provide your own Google/Apple credentials, or use Internet Identity for free.

**Q: How is this different from Firebase/PlayFab?**  
A: Permanent blockchain storage, no vendor lock-in, unified player profiles across games.

## Status

🟢 **Beta** - The service is live and stable. We're gathering feedback for v1.0.
