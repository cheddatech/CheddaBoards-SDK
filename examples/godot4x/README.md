# CheddaBoards Integration for Godot 4.x

Add blockchain-based leaderboards and authentication to your Godot web games using the Internet Computer Protocol (ICP).

## Features

- 🎮 **Easy Integration** - Simple JavaScript bridge between Godot and CheddaBoards
- 🔐 **Internet Identity Auth** - Secure blockchain authentication
- 🏆 **Global Leaderboards** - Store and retrieve player scores on-chain
- 👤 **User Profiles** - Track player progress and achievements
- 📊 **Score Tracking** - Submit scores with streak bonuses
- 🌐 **Decentralized** - No centralized servers required

## Quick Start

### 1. Setup CheddaBoards

First, you need a CheddaBoards canister ID. Either:
- Use the public CheddaBoards service (get canister ID from [cheddaboards.com](https://cheddaboards.com))
- Deploy your own canister (see [CheddaBoards deployment guide](https://github.com/yourusername/cheddaboards))

### 2. Add Files to Your Project

#### GDScript Files

Add these scripts to your Godot project:

1. **CheddaLogin.gd** - The main singleton (AutoLoad)
2. **GameManager.gd** - (Optional) Example integration helper
3. **Your game scripts** - Connect to CheddaLogin signals

#### Set up AutoLoad

1. Go to **Project → Project Settings → Globals → AutoLoad**
2. Click the folder icon and select `CheddaLogin.gd`
3. Set **Node Name** to `CheddaLogin`
4. Click **Add**

### 3. Configure HTML Template

When exporting your game to HTML5:

1. Copy `index-template-generic.html` to your project
2. **Open the file and configure these values:**

```javascript
const CONFIG = {
  GAME_ID: 'your-game-id',           // Your unique game identifier
  GAME_NAME: 'Your Game Name',        // Display name
  CANISTER_ID: 'xxxxx-xxxxx-xxxxx',   // Your CheddaBoards canister ID
};
```

3. In Godot: **Project → Export → HTML5 → Custom HTML Shell**
4. Select your configured template

### 4. Export and Test

1. Export your game: **Project → Export → HTML5**
2. Serve locally: `python3 -m http.server 8000`
3. Open: `http://localhost:8000`

## Usage Examples

### Basic Authentication

```gdscript
extends Node2D

func _ready():
    # Connect to signals
    CheddaLogin.login_success.connect(_on_login_success)
    CheddaLogin.login_failed.connect(_on_login_failed)
    
    # Wait for initialization
    await get_tree().create_timer(2.0).timeout
    
    if CheddaLogin.is_ready():
        print("CheddaBoards ready!")

func _on_login_button_pressed():
    var nickname = "Player" + str(randi() % 1000)
    CheddaLogin.login_ii(nickname)

func _on_login_success(nickname: String):
    print("✅ Logged in as:", nickname)
    # Start your game here

func _on_login_failed(reason: String):
    print("❌ Login failed:", reason)
```

### Submit Scores

```gdscript
func game_over():
    var final_score = 150
    var final_streak = 5
    
    if CheddaLogin.is_authenticated():
        CheddaLogin.submit_score(final_score, final_streak)
    else:
        print("Not logged in - score not saved")

func _on_score_submitted(score: int, streak: int):
    print("✅ Score submitted successfully!")
    # Load leaderboard to see new ranking
    CheddaLogin.get_leaderboard()
```

### Display Leaderboard

```gdscript
func show_leaderboard():
    CheddaLogin.leaderboard_loaded.connect(_on_leaderboard_loaded)
    CheddaLogin.get_leaderboard("score", 10)

func _on_leaderboard_loaded(entries: Array):
    print("📊 Top Players:")
    
    for i in range(entries.size()):
        var entry = entries[i]
        # CheddaBoards returns: [principal, score, streak, nickname]
        var nickname = str(entry[3])
        var score = int(entry[1])
        var streak = int(entry[2])
        
        print("%d. %s - %d points (streak: %d)" % [i+1, nickname, score, streak])
```

### Check Profile

```gdscript
func _ready():
    CheddaLogin.profile_loaded.connect(_on_profile_loaded)

func _on_profile_loaded(nickname: String, score: int, streak: int, achievements: Array):
    print("Player:", nickname)
    print("High Score:", score)
    print("Best Streak:", streak)
    print("Achievements:", achievements)
```

## API Reference

### CheddaLogin (Singleton)

#### Signals

```gdscript
# Authentication
signal profile_loaded(nickname: String, score: int, streak: int, achievements: Array)
signal login_success(nickname: String)
signal login_failed(reason: String)
signal logout_success()
signal no_profile()

# Game Actions
signal score_submitted(score: int, streak: int)
signal score_error(reason: String)
signal leaderboard_loaded(entries: Array)
```

#### Methods

```gdscript
# Authentication
CheddaLogin.login_ii(nickname: String)           # Login with Internet Identity
CheddaLogin.logout()                             # Logout current user
CheddaLogin.is_authenticated() -> bool           # Check if logged in

# Game Actions
CheddaLogin.submit_score(score: int, streak: int)        # Submit score to leaderboard
CheddaLogin.get_leaderboard(sort_by: String, limit: int) # Get top players
CheddaLogin.refresh_profile()                            # Refresh user profile

# Helpers
CheddaLogin.is_ready() -> bool                   # Check if initialized
CheddaLogin.get_cached_profile() -> Dictionary   # Get local profile data
CheddaLogin.debug_status()                       # Print debug info
```

### JavaScript Bridge Functions

These are automatically exposed to GDScript:

```gdscript
# Check if CheddaBoards is ready
JavaScriptBridge.eval("window.chedda_is_ready()")

# Check authentication status
JavaScriptBridge.eval("window.chedda_is_auth()")

# Get current profile
JavaScriptBridge.eval("window.chedda_get_profile()")

# Poll for responses
JavaScriptBridge.eval("window.chedda_poll_response()")

# Login with Internet Identity
JavaScriptBridge.eval("window.chedda_login_ii('PlayerName')")

# Submit score
JavaScriptBridge.eval("window.chedda_submit_score(100, 5)")

# Get leaderboard
JavaScriptBridge.eval("window.chedda_get_leaderboard('score', 10)")

# Logout
JavaScriptBridge.eval("window.chedda_logout()")
```

## Advanced Features

### Pause Game Until Login

```gdscript
func _ready():
    # Make UI work while paused
    login_button.process_mode = Node.PROCESS_MODE_ALWAYS
    
    # Pause until login
    get_tree().paused = true
    
    # Connect signals
    CheddaLogin.login_success.connect(_on_login_success)

func _on_login_success(nickname: String):
    # Unpause and start game
    get_tree().paused = false
    print("Game started!")
```

### Handle Reconnection

```gdscript
func _ready():
    await get_tree().create_timer(2.0).timeout
    
    if CheddaLogin.is_ready() and CheddaLogin.is_authenticated():
        # User still logged in from previous session
        print("Welcome back!")
        _load_existing_profile()
    else:
        # Show login screen
        _show_login_ui()
```

### Custom Leaderboard Display

```gdscript
@onready var leaderboard_list = $LeaderboardList

func _on_leaderboard_loaded(entries: Array):
    # Clear existing entries
    for child in leaderboard_list.get_children():
        child.queue_free()
    
    # Add entries
    for i in range(entries.size()):
        var entry = entries[i]
        var label = Label.new()
        
        var nickname = str(entry[3])
        var score = int(entry[1])
        var medal = ["🥇", "🥈", "🥉"][i] if i < 3 else "  "
        
        label.text = "%s #%d  %s - %d pts" % [medal, i+1, nickname, score]
        leaderboard_list.add_child(label)
```

## Troubleshooting

### Game won't start / buttons don't work

**Problem:** Game is paused but UI isn't responding

**Solution:** Set `process_mode` to `ALWAYS` for UI elements:

```gdscript
func _ready():
    login_button.process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = true
```

### Login button does nothing

**Problem:** CheddaBoards not initialized yet

**Solution:** Wait for initialization before enabling buttons:

```gdscript
func _ready():
    login_button.disabled = true
    await get_tree().create_timer(3.0).timeout
    
    if CheddaLogin.is_ready():
        login_button.disabled = false
```

### Scores not submitting

**Problem:** User not authenticated or game not registered

**Solutions:**
1. Check authentication: `CheddaLogin.is_authenticated()`
2. Register your game with CheddaBoards canister
3. Check console for error messages

### "Game not registered" error

**Problem:** Your game isn't registered in the CheddaBoards canister

**Solution:** Register your game first (do this once):

```javascript
// In browser console after logging in with II
const result = await window.chedda.registerGame(
  'Your Game Name',
  'Game description',
  {}  // Optional rules
);
console.log(result);
```

## Browser Console Debug Commands

```javascript
// Check CheddaBoards status
debugChedda()

// Check if authenticated
window.chedda_is_auth()

// Get current profile
window.chedda_get_profile()

// View response queue
window.chedda.responseQueue
```

## Best Practices

1. ✅ **Always check `is_authenticated()` before submitting scores**
2. ✅ **Handle `login_failed` signal gracefully**
3. ✅ **Show loading states during async operations**
4. ✅ **Cache profile data locally to reduce API calls**
5. ✅ **Test thoroughly in web browsers before deployment**
6. ✅ **Use meaningful game IDs (lowercase, hyphens)**
7. ✅ **Validate user input before sending to blockchain**

## Example Project Structure

```
YourGame/
├── scenes/
│   ├── main.tscn
│   ├── menu.tscn
│   └── leaderboard.tscn
├── scripts/
│   ├── CheddaLogin.gd          # AutoLoad singleton
│   ├── GameManager.gd          # Optional helper
│   ├── main.gd
│   └── leaderboard.gd
├── export/
│   └── index-template.html     # Custom HTML template
└── project.godot
```

## Requirements

- **Godot 4.x** (tested on 4.5.1)
- **HTML5 Export Template** installed
- **CheddaBoards Canister** deployed or access to public instance
- **Modern web browser** (Chrome, Firefox, Safari, Edge)

## License

This integration code is provided as-is for use with CheddaBoards. See CheddaBoards license for SDK terms.

## Support

- 📚 [CheddaBoards Documentation](https://docs.cheddaboards.com)
- 💬 [Discord Community](https://discord.gg/cheddaboards)
- 🐛 [Report Issues](https://github.com/yourusername/cheddaboards-godot/issues)

## Credits

Developed for use with [CheddaBoards](https://cheddaboards.com) - Leaderboards for web games.
