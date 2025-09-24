# CheddaBoards 🧀

A decentralized leaderboard and achievement system built on the Internet Computer Protocol (ICP). CheddaBoards provides developers with a simple, secure way to add persistent player profiles, scores, achievements, and analytics to their games.

## Features

- **Multi-Auth Support**: Google, Apple, Internet Identity, and anonymous logins
- **Cross-Platform**: Works in browsers, Unity, Godot, and any JavaScript environment
- **Decentralized**: Data stored permanently on the ICP blockchain
- **Simple Integration**: One-line initialization, straightforward API
- **Rich Analytics**: Track player behavior, game metrics, and engagement
- **Achievement System**: Unlock and track player achievements
- **File Storage**: Store game assets and player data (up to 5MB per file)

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

// Initialize with your game ID
const chedda = await CheddaBoards.init(null, {
  gameId: 'my-awesome-game',
  gameName: 'My Awesome Game',
  gameDescription: 'The best game ever made'
});

// Login options
await chedda.login.anonymous('Player123');
// or
await chedda.login.google(googleCredential, 'PlayerNickname');
// or
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

## Authentication Methods

### Anonymous Login
Perfect for casual play without requiring sign-up:
```javascript
await chedda.login.anonymous('GuestPlayer');
```

### Google Sign-In
```javascript
// After Google OAuth flow
await chedda.login.google(googleIdToken, 'PlayerNickname');
```

### Apple Sign-In
```javascript
// After Apple OAuth flow
await chedda.login.apple(appleResponse, 'PlayerNickname');
```

### Internet Identity
Secure, privacy-preserving authentication:
```javascript
await chedda.login.ii('PlayerNickname');
```

## API Reference

### Core Methods

#### Initialization
```javascript
CheddaBoards.init(canisterId, options)
```
- `canisterId`: (optional) Custom canister ID, defaults to mainnet
- `options.gameId`: (required) Unique identifier for your game
- `options.gameName`: Display name for your game
- `options.gameDescription`: Brief description
- `options.host`: (optional) Custom ICP host

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

## Unity Integration

```csharp
// In your Unity script
[DllImport("__Internal")]
private static extern void InitCheddaBoards(string gameId);

[DllImport("__Internal")]
private static extern void SubmitScore(int score, int streak);

void Start() {
    InitCheddaBoards("my-unity-game");
}

void GameOver(int finalScore, int streak) {
    SubmitScore(finalScore, streak);
}
```

Include the CheddaBoards Unity bridge in your WebGL template.

## Godot Integration

```gdscript
# In your Godot script
extends Node

var chedda

func _ready():
    if OS.has_feature("HTML5"):
        var window = JavaScript.get_interface("window")
        chedda = window.CheddaBoards
        chedda.init(null, {
            "gameId": "my-godot-game"
        })

func submit_score(score: int, streak: int):
    if chedda:
        chedda.submitScore(score, streak)
```

## Data Structure

### User Profile
```typescript
{
  nickname: string;
  score: number;
  streak: number;
  achievements: Achievement[];
  authType: 'anonymous' | 'google' | 'apple' | 'internetIdentity';
  gameId: string;
  playCount: number;
  lastPlayed: number;
}
```

### Leaderboard Entry
```typescript
{
  nickname: string;
  score: number;
  streak: number;
  authType: string;
}
```

## Security Considerations

- **Rate Limiting**: 2-second minimum between score submissions
- **Score Validation**: Maximum score per round: 1,500 points
- **Streak Validation**: Maximum streak increase: 80 per round
- **Session Management**: 7-day session duration for social logins
- **Principal-based Auth**: Internet Identity uses cryptographic authentication

## Configuration Options

### Custom Canister Deployment

Deploy your own CheddaBoards canister for complete control:

```bash
dfx deploy --network ic
```

Then initialize with your canister ID:
```javascript
const chedda = await CheddaBoards.init('your-canister-id', {
  gameId: 'your-game'
});
```

### Local Development

For local testing with dfx:
```javascript
const chedda = await CheddaBoards.init('your-local-canister', {
  gameId: 'test-game',
  host: 'http://localhost:4943'
});
```

## Browser Events

CheddaBoards emits custom events you can listen to:

```javascript
window.addEventListener('chedda:profile', (e) => {
  console.log('Profile loaded:', e.detail);
});

window.addEventListener('chedda:google_login', (e) => {
  console.log('Google login successful:', e.detail);
});
```

## Error Handling

```javascript
try {
  const result = await chedda.submitScore(1000, 5);
  if (result.success) {
    console.log('Score submitted!');
  } else {
    console.error('Failed:', result.error);
  }
} catch (error) {
  console.error('Network error:', error);
}
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [https://docs.cheddaboards.com](https://docs.cheddaboards.com)
- **Discord**: [Join our community](https://discord.gg/cheddaboards)
- **GitHub Issues**: [Report bugs or request features](https://github.com/cheddaboards/sdk/issues)

## Acknowledgments

Built on the Internet Computer Protocol by the DFINITY Foundation.
