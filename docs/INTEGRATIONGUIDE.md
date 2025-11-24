# CheddaBoards Integration Guide for Godot 4.x

**Complete integration guide for adding CheddaBoards authentication, leaderboards, and achievements to your Godot 4.x game.**

---

## Table of Contents

### Getting Started
- [Overview](#overview)
- [Quick Start (10 Minutes)](#quick-start-10-minutes)
- [Installation](#installation)
- [Configuration](#configuration)

### Development
- [API Reference](#api-reference)
- [Signals Reference](#signals-reference)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)

### Advanced
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

### Resources
- [Support & Resources](#support--resources)

---

## Overview

CheddaBoards provides a complete authentication and leaderboard system for web-based Godot games, featuring:

- **Multiple Authentication Methods**: Internet Identity, Google, Apple, Anonymous
- **Leaderboards**: Global rankings with score and streak tracking
- **Profile Management**: Player profiles with persistent data across games
- **Achievements**: Track and unlock achievements (beta)
- **Analytics**: Custom event tracking (alpha)
- **Web3 Integration**: Built on Internet Computer Protocol (ICP)
- **Zero Server Management**: Serverless infrastructure, $0 for indie devs

### Architecture

```
┌─────────────────┐
│   Godot Game    │
│   (GDScript)    │
└────────┬────────┘
         │
         │ Signals & Method Calls
         │
┌────────┴────────┐
│  CheddaBoards.gd│  ← Autoload Singleton
│   (Bridge)      │
└────────┬────────┘
         │
         │ JavaScript Bridge
         │
┌────────┴────────┐
│  template.html  │  ← Web Export Template
│  (CDN Loaded)   │
└────────┬────────┘
         │
         │ HTTPS/ICP
         │
┌────────┴────────┐
│ CheddaBoards    │  ← Backend Service (ICP)
│   Canister      │
└─────────────────┘
```

**Key Point:** Everything loads from CDN - **no npm install required!**

---

## Quick Start (10 Minutes)

### Step 1: Register Your Game (Required!)

**You MUST do this first!**

1. Go to **https://cheddaboards.com**
2. Click **"Register Game"** (top right)
3. **Sign in with Internet Identity** (~2 minutes if new)
   - Passwordless authentication (like FaceID for web)
   - Creates a cryptographic identity in your browser
4. Fill in the registration form:
   - **Game ID:** `my-awesome-game` (unique, lowercase, hyphens only)
   - **Game Name:** `My Awesome Game`
   - **Description:** Brief description of your game
   - **Anti-Cheat Rules:** (optional) Set score/streak limits
5. Click **"✨ Register Game"**
6. **SAVE YOUR GAME ID** - you'll need it in Step 4!

**Your Canister ID:** `fdvph-sqaaa-aaaap-qqc4a-cai` (same for all CheddaBoards users)

---

### Step 2: Download Template Files

Get the CheddaBoards Godot 4 template:

**From GitHub:**
```bash
git clone https://github.com/cheddatech/CheddaBoards-SDK
cd CheddaBoards-SDK/godot4
```

**Or download directly:**
- `CheddaBoards.gd` - Core integration script
- `cheddaboards.html` - Custom HTML export template
- Example scenes (optional)

**GitHub:** https://github.com/cheddatech/CheddaBoards-SDK

---

### Step 3: Add CheddaBoards Autoload

1. Copy `CheddaBoards.gd` to your project:
   ```
   YourGame/
   ├── addons/
   │   └── cheddaboards/
   │       └── CheddaBoards.gd  ← Put it here
   ```

2. In Godot: **Project → Project Settings → Autoload**

3. Add new autoload:
   - **Path:** `res://addons/cheddaboards/CheddaBoards.gd`
   - **Node Name:** `CheddaBoards` (must be exact!)
   - ✅ **Enable** the checkbox
   - Click **"Close"**

**Verify:** You should now see `CheddaBoards` in the Autoload list.

---

### Step 4: Configure HTML Template

1. Copy `cheddaboards.html` to your project:
   ```
   YourGame/
   ├── export_templates/
   │   └── web/
   │       └── cheddaboards.html  ← Put it here
   ```

2. Open `cheddaboards.html` in a text editor

3. Find this section (around line 35-40):

```javascript
// ⚠️ CONFIGURE YOUR GAME HERE ⚠️
const game = await CheddaBoards.init('fdvph-sqaaa-aaaap-qqc4a-cai', {
    gameId: 'YOUR-GAME-ID',              // ⬅️ PUT YOUR GAME ID FROM STEP 1
    gameName: 'My Awesome Game',          // ⬅️ YOUR GAME NAME
    gameDescription: 'A cool game'        // ⬅️ YOUR DESCRIPTION
});
```

4. Replace:
   - `YOUR-GAME-ID` → Your Game ID from Step 1
   - `gameName` → Your game's name
   - `gameDescription` → Your description

5. **Save** the file

6. In Godot: **Project → Export → Web (HTML5)**
   - Under **HTML** section:
   - Set **Custom HTML Shell:** `res://export_templates/web/cheddaboards.html`

---

### Step 5: Test It!

```bash
# 1. Export your game from Godot as HTML5

# 2. Run a local server (REQUIRED - don't just open the HTML!):
cd path/to/your/exported/game
python -m http.server 8000

# Or use Node:
npx http-server

# 3. Open in browser:
# http://localhost:8000
```

**✅ Done! Your game now has:**
- Authentication (Google, Apple, Internet Identity)
- Leaderboards
- Player profiles
- Achievements
- Analytics

---

## Installation

### Detailed Setup

#### Project Structure

Organize your project like this:

```
YourGameProject/
├── addons/
│   └── cheddaboards/
│       ├── CheddaBoards.gd
│       └── plugin.cfg (optional)
├── export_templates/
│   └── web/
│       └── cheddaboards.html
├── scenes/
│   ├── main_menu.tscn
│   ├── game.tscn
│   ├── game_over.tscn
│   └── leaderboard.tscn
└── project.godot
```

#### Verify Installation

Create a test script to verify everything works:

```gdscript
# test_cheddaboards.gd
extends Node

func _ready():
	print("=== CheddaBoards Installation Test ===")
	
	# 1. Check if autoload exists
	if has_node("/root/CheddaBoards"):
		print("✅ Autoload found")
	else:
		print("❌ Autoload NOT found - check Project Settings")
		return
	
	# 2. Check if running on web
	print("Is Web:", OS.get_name() == "Web")
	
	# 3. Connect to signals
	CheddaBoards.login_success.connect(func(nick): print("✅ Login works:", nick))
	CheddaBoards.no_profile.connect(func(): print("ℹ️  No profile (not logged in)"))
	
	# 4. Wait for initialization
	await get_tree().create_timer(0.5).timeout
	
	# 5. Check readiness
	if CheddaBoards.is_ready():
		print("✅ CheddaBoards is ready!")
	else:
		print("⚠️  CheddaBoards not ready yet")
	
	print("=== Test Complete ===")
```

---

## Configuration

### Required Configuration

#### CheddaBoards Credentials

In `cheddaboards.html`:

```javascript
const game = await CheddaBoards.init('fdvph-sqaaa-aaaap-qqc4a-cai', {
    gameId: 'my-game-v1',           // Required: From dashboard
    gameName: 'My Awesome Game',     // Required: Display name
    gameDescription: 'A cool game',  // Optional but recommended
    autoInit: true                   // Optional: Auto-initialize on load
});
```

#### Optional: Google Sign-In

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Add authorized JavaScript origins:
   - `https://yourdomain.com`
   - `http://localhost:8000` (for testing)
4. Get Client ID and add to `cheddaboards.html`:

```html
<script src="https://accounts.google.com/gsi/client" async defer></script>
<script>
  window.GOOGLE_CLIENT_ID = '123456789-abc.apps.googleusercontent.com';
</script>
```

#### Optional: Apple Sign-In

1. Go to [Apple Developer](https://developer.apple.com/)
2. Create Service ID
3. Configure domains and return URLs
4. Add to `cheddaboards.html`:

```html
<script src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"></script>
<script>
  window.APPLE_CLIENT_ID = 'com.yourgame.service';
  window.APPLE_REDIRECT_URI = 'https://yourdomain.com/auth/apple';
</script>
```

### Advanced Configuration

#### Performance Tuning

In `CheddaBoards.gd`, adjust these constants:

```gdscript
const POLL_INTERVAL: float = 0.1              # Response polling frequency
const MIN_RESPONSE_CHECK_INTERVAL: float = 0.3 # Rate limiting
const PROFILE_REFRESH_COOLDOWN: float = 2.0   # Profile refresh cooldown
const LOGIN_TIMEOUT_DURATION: float = 35.0    # Login timeout
```

#### Custom Styling

Modify the loading screen in `cheddaboards.html`:

```css
#preload {
  background: linear-gradient(135deg, #your-color-1 0%, #your-color-2 100%);
  color: #your-accent-color;
}
```

---

## API Reference

### Authentication Methods

#### login_chedda_id(nickname: String = "")

Log in with Internet Identity (passwordless authentication).

```gdscript
# Let user choose nickname
CheddaBoards.login_chedda_id("")

# Or provide default nickname
CheddaBoards.login_chedda_id("Player123")
```

**Parameters:**
- `nickname` (String): Optional initial nickname. Empty string prompts user.

**Signals:**
- `login_success(nickname)` - On successful login
- `login_failed(reason)` - On failure
- `login_timeout()` - If login takes too long

---

#### login_google()

Log in with Google account.

```gdscript
CheddaBoards.login_google()
```

**Requirements:**
- Google Client ID configured in `cheddaboards.html`
- User must have Google account

**Signals:**
- `login_success(nickname)` - On successful login
- `login_failed(reason)` - On failure

---

#### login_apple()

Log in with Apple ID.

```gdscript
CheddaBoards.login_apple()
```

**Requirements:**
- Apple Service ID configured in `cheddaboards.html`
- User must have Apple ID

**Signals:**
- `login_success(nickname)` - On successful login
- `login_failed(reason)` - On failure

---

#### logout()

Log out the current user.

```gdscript
CheddaBoards.logout()
```

**Signals:**
- `logout_success()` - On successful logout

**Note:** Clears cached profile and authentication state.

---

#### is_authenticated() -> bool

Check if user is currently authenticated.

```gdscript
if CheddaBoards.is_authenticated():
	print("User is logged in")
	submit_score_button.disabled = false
else:
	print("User needs to login")
	show_login_panel()
```

**Returns:** `bool` - True if authenticated, false otherwise

---

#### get_auth_type() -> String

Get the authentication method used.

```gdscript
var auth_type = CheddaBoards.get_auth_type()
match auth_type:
	"google":
		print("Logged in with Google")
	"apple":
		print("Logged in with Apple")
	"cheddaId":
		print("Logged in with Internet Identity")
	_:
		print("Not logged in")
```

**Returns:** `String` - `"google"`, `"apple"`, `"cheddaId"`, or `""`

---

### Profile Methods

#### refresh_profile()

Refresh profile data from server.

```gdscript
CheddaBoards.refresh_profile()

# Wait for response
await CheddaBoards.profile_loaded
```

**Signals:**
- `profile_loaded(nickname, score, streak, achievements)` - On success
- `no_profile()` - On failure

**Note:** Has built-in 2-second cooldown to prevent spam.

---

#### get_cached_profile() -> Dictionary

Get locally cached profile data (instant access).

```gdscript
var profile = CheddaBoards.get_cached_profile()

if not profile.is_empty():
	print("Nickname:", profile.get("nickname", "Unknown"))
	print("High Score:", profile.get("score", 0))
	print("Best Streak:", profile.get("streak", 0))
	print("Achievements:", profile.get("achievements", []))
```

**Returns:** `Dictionary` with keys:
- `nickname` (String)
- `score` (int) - Total score
- `streak` (int) - Best streak
- `achievements` (Array)
- `authType` (String)
- `playCount` (int) - Number of games played
- `lastPlayed` (int) - Timestamp

---

#### change_nickname()

Open nickname change prompt.

```gdscript
CheddaBoards.change_nickname()
```

**Signals:**
- `nickname_changed(new_nickname)` - On success
- `nickname_error(reason)` - On failure

**Note:** Shows browser prompt to user for new nickname.

---

### Score & Leaderboard Methods

#### submit_score(score: int, streak: int)

Submit player score and streak to leaderboard.

```gdscript
var final_score = 1500
var current_streak = 25

CheddaBoards.submit_score(final_score, current_streak)

# Wait for confirmation
await CheddaBoards.score_submitted
```

**Parameters:**
- `score` (int): Player's total score
- `streak` (int): Player's current streak

**Signals:**
- `score_submitted(score, streak)` - On success
- `score_error(reason)` - On failure

**Features:**
- Automatic duplicate prevention
- 5-second timeout protection
- Profile auto-refresh after submission
- Validates authentication before submitting

---

#### get_leaderboard(sort_by: String = "score", limit: int = 100)

Fetch leaderboard entries.

```gdscript
# Get top 10 by score
CheddaBoards.get_leaderboard("score", 10)

# Get top 20 by streak
CheddaBoards.get_leaderboard("streak", 20)

# Wait for data
await CheddaBoards.leaderboard_loaded
```

**Parameters:**
- `sort_by` (String): Sort field - `"score"` or `"streak"`
- `limit` (int): Number of entries to fetch (1-100)

**Signals:**
- `leaderboard_loaded(entries)` - On success

**Entry Structure:**
```gdscript
# Each entry is an Array: [nickname, score, streak]
var entries = await CheddaBoards.leaderboard_loaded
for entry in entries:
	var nickname = entry[0]
	var score = entry[1]
	var streak = entry[2]
	print("%s: %d points" % [nickname, score])
```

---

#### get_player_rank(sort_by: String = "score")

Get current player's rank on the leaderboard.

```gdscript
CheddaBoards.get_player_rank("score")

# Wait for result
await CheddaBoards.player_rank_loaded
```

**Parameters:**
- `sort_by` (String): Sort field - `"score"` or `"streak"`

**Signals:**
- `player_rank_loaded(rank, score, streak, total_players)` - On success
- `rank_error(reason)` - On failure

---

### Achievement Methods

#### unlock_achievement(achievement_id: String, achievement_name: String, achievement_desc: String)

Unlock a single achievement.

```gdscript
CheddaBoards.unlock_achievement(
	"first_win",
	"First Victory",
	"Win your first game"
)
```

**Parameters:**
- `achievement_id` (String): Unique identifier
- `achievement_name` (String): Display name
- `achievement_desc` (String): Description

**Note:** Achievements are saved to player profile and persist across games.

---

#### submit_score_with_achievements(score: int, streak: int, achievements: Array)

Submit score and achievements together (more efficient than separate calls).

```gdscript
var achievements = [
	{"id": "first_win", "name": "First Win", "description": "Win first game"},
	{"id": "10_wins", "name": "Veteran", "description": "Win 10 games"}
]

CheddaBoards.submit_score_with_achievements(1500, 25, achievements)
```

**Parameters:**
- `score` (int): Player's score
- `streak` (int): Player's streak
- `achievements` (Array): Array of achievement dictionaries

**Signals:**
- `score_submitted(score, streak)` - On success
- `score_error(reason)` - On failure

---

### Analytics Methods

#### track_event(event_type: String, metadata: Dictionary = {})

Track custom game events for analytics.

```gdscript
# Simple event
CheddaBoards.track_event("level_completed")

# Event with metadata
CheddaBoards.track_event("item_purchased", {
	"item_id": "sword_legendary",
	"price": 1000,
	"currency": "gold"
})

# Gameplay event
CheddaBoards.track_event("boss_defeated", {
	"boss_name": "Dragon",
	"attempts": 3,
	"time_seconds": 245
})
```

**Parameters:**
- `event_type` (String): Event identifier
- `metadata` (Dictionary): Additional event data

**Note:** Events are visible in the CheddaBoards dashboard analytics.

---

### Utility Methods

#### is_ready() -> bool

Check if CheddaBoards is fully initialized.

```gdscript
func _ready():
	# Wait for CheddaBoards to be ready
	while not CheddaBoards.is_ready():
		await get_tree().create_timer(0.1).timeout
	
	# Now safe to use
	if CheddaBoards.is_authenticated():
		load_player_profile()
```

**Returns:** `bool` - True if ready, false otherwise

---

#### force_check_events()

Force check for pending events or authentication status.

```gdscript
# Use after scene changes or when recovering from errors
func _enter_tree():
	if CheddaBoards.is_ready():
		CheddaBoards.force_check_events()
```

**Use Cases:**
- After scene transitions
- Recovering from network errors
- Manual refresh when UI seems out of sync

---

#### debug_status()

Print comprehensive debug information to console.

```gdscript
# Press F9 or call manually
func _input(event):
	if event is InputEventKey and event.keycode == KEY_F9 and event.pressed:
		CheddaBoards.debug_status()
```

**Output Example:**
```
========== CheddaBoards Debug Status ==========
 - Is Web: true
 - Init Complete: true
 - Auth Type: google
 - Is Authenticated: true
 - Cached Profile: {nickname:Player123, score:1500, ...}
 - Is Checking Auth: false
 - Is Refreshing Profile: false
 - Is Submitting Score: false
 - Login Timeout Active: false
 - JS Status: {"cheddaReady":true,"cheddaInstance":true,...}
==============================================
```

---

## Signals Reference

### Authentication Signals

```gdscript
# Emitted when login succeeds
signal login_success(nickname: String)

# Emitted when login fails
signal login_failed(reason: String)

# Emitted when login times out (after 35 seconds)
signal login_timeout()

# Emitted when user logs out
signal logout_success()

# Emitted for general authentication errors
signal auth_error(reason: String)

# Emitted when no profile is available (user not logged in)
signal no_profile()
```

### Profile Signals

```gdscript
# Emitted when profile data is loaded/updated
signal profile_loaded(nickname: String, score: int, streak: int, achievements: Array)

# Emitted when nickname is changed
signal nickname_changed(new_nickname: String)

# Emitted when nickname change fails
signal nickname_error(reason: String)
```

### Score & Leaderboard Signals

```gdscript
# Emitted when score is successfully submitted
signal score_submitted(score: int, streak: int)

# Emitted when score submission fails
signal score_error(reason: String)

# Emitted when leaderboard data is loaded
signal leaderboard_loaded(entries: Array)

# Emitted when player rank is loaded
signal player_rank_loaded(rank: int, score: int, streak: int, total_players: int)

# Emitted when rank fetch fails
signal rank_error(reason: String)
```

---

## Usage Examples

### Example 1: Main Menu with Login

```gdscript
# MainMenu.gd
extends Control

@onready var login_panel = $LoginPanel
@onready var main_panel = $MainPanel
@onready var nickname_label = $MainPanel/NicknameLabel
@onready var score_label = $MainPanel/ScoreLabel

@onready var google_btn = $LoginPanel/GoogleButton
@onready var apple_btn = $LoginPanel/AppleButton
@onready var chedda_btn = $LoginPanel/CheddaButton

func _ready():
	# Connect signals
	CheddaBoards.login_success.connect(_on_login_success)
	CheddaBoards.login_failed.connect(_on_login_failed)
	CheddaBoards.profile_loaded.connect(_on_profile_loaded)
	CheddaBoards.no_profile.connect(_on_no_profile)
	
	# Connect buttons
	google_btn.pressed.connect(_on_google_pressed)
	apple_btn.pressed.connect(_on_apple_pressed)
	chedda_btn.pressed.connect(_on_chedda_pressed)
	
	# Wait for CheddaBoards to initialize
	await get_tree().create_timer(0.5).timeout
	
	# Check initial auth state
	_check_auth_status()

func _check_auth_status():
	if CheddaBoards.is_authenticated():
		var profile = CheddaBoards.get_cached_profile()
		if not profile.is_empty():
			_show_main_menu(profile)
		else:
			CheddaBoards.refresh_profile()
	else:
		_show_login_panel()

func _show_login_panel():
	login_panel.visible = true
	main_panel.visible = false

func _show_main_menu(profile: Dictionary):
	login_panel.visible = false
	main_panel.visible = true
	nickname_label.text = "Welcome, %s!" % profile.get("nickname", "Player")
	score_label.text = "High Score: %d" % profile.get("score", 0)

func _on_google_pressed():
	google_btn.disabled = true
	CheddaBoards.login_google()

func _on_apple_pressed():
	apple_btn.disabled = true
	CheddaBoards.login_apple()

func _on_chedda_pressed():
	chedda_btn.disabled = true
	CheddaBoards.login_chedda_id("")

func _on_login_success(nickname: String):
	print("Welcome, ", nickname)
	var profile = CheddaBoards.get_cached_profile()
	_show_main_menu(profile)

func _on_login_failed(reason: String):
	print("Login failed: ", reason)
	# Re-enable buttons
	google_btn.disabled = false
	apple_btn.disabled = false
	chedda_btn.disabled = false

func _on_profile_loaded(nickname: String, score: int, streak: int, achievements: Array):
	_show_main_menu(CheddaBoards.get_cached_profile())

func _on_no_profile():
	_show_login_panel()
```

---

### Example 2: Game Over with Score Submission

```gdscript
# GameOver.gd
extends Control

@onready var score_label = $ScoreLabel
@onready var submit_button = $SubmitButton
@onready var status_label = $StatusLabel

var final_score: int = 0
var final_streak: int = 0

func _ready():
	CheddaBoards.score_submitted.connect(_on_score_submitted)
	CheddaBoards.score_error.connect(_on_score_error)
	
	submit_button.pressed.connect(_on_submit_pressed)

func show_game_over(score: int, streak: int):
	final_score = score
	final_streak = streak
	score_label.text = "Score: %d\nStreak: %d" % [score, streak]
	visible = true
	
	# Auto-submit if authenticated
	if CheddaBoards.is_authenticated():
		_submit_score()
	else:
		status_label.text = "Login to submit score"
		submit_button.text = "Login"

func _submit_score():
	submit_button.disabled = true
	status_label.text = "Submitting..."
	
	CheddaBoards.submit_score(final_score, final_streak)

func _on_submit_pressed():
	if CheddaBoards.is_authenticated():
		_submit_score()
	else:
		# Show login options
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_score_submitted(score: int, streak: int):
	status_label.text = "Score submitted! 🎉"
	submit_button.text = "View Leaderboard"
	submit_button.disabled = false

func _on_score_error(reason: String):
	status_label.text = "Error: %s" % reason
	submit_button.disabled = false
```

---

### Example 3: Leaderboard Display

```gdscript
# Leaderboard.gd
extends Control

@onready var entries_container = $ScrollContainer/VBoxContainer
@onready var loading_label = $LoadingLabel
@onready var sort_by_score_btn = $SortByScore
@onready var sort_by_streak_btn = $SortByStreak

# Preload entry scene
const LeaderboardEntry = preload("res://scenes/LeaderboardEntry.tscn")

func _ready():
	# Connect signals
	CheddaBoards.leaderboard_loaded.connect(_on_leaderboard_loaded)
	CheddaBoards.player_rank_loaded.connect(_on_player_rank_loaded)
	
	# Connect buttons
	sort_by_score_btn.pressed.connect(func(): load_leaderboard("score"))
	sort_by_streak_btn.pressed.connect(func(): load_leaderboard("streak"))
	
	# Load initial leaderboard
	load_leaderboard("score")

func load_leaderboard(sort_by: String):
	# Clear existing entries
	for child in entries_container.get_children():
		child.queue_free()
	
	loading_label.visible = true
	
	# Request top 20
	CheddaBoards.get_leaderboard(sort_by, 20)
	
	# Also get player's rank
	if CheddaBoards.is_authenticated():
		CheddaBoards.get_player_rank(sort_by)

func _on_leaderboard_loaded(entries: Array):
	loading_label.visible = false
	
	# Display each entry
	for i in range(entries.size()):
		var entry_data = entries[i]
		var nickname = entry_data[0]
		var score = entry_data[1]
		var streak = entry_data[2]
		
		var entry = LeaderboardEntry.instantiate()
		entry.set_data(i + 1, nickname, score, streak)
		entries_container.add_child(entry)

func _on_player_rank_loaded(rank: int, score: int, streak: int, total_players: int):
	print("Your rank: #%d of %d players" % [rank, total_players])
	# Highlight player's entry or show "Your Rank" section
```

---

## Best Practices

### 1. Authentication Flow

**✅ DO:**
- Wait 0.5s after `_ready()` before calling CheddaBoards methods
- Check authentication status before submitting scores
- Handle `no_profile` signal for unauthenticated users
- Cache profile data locally for offline access
- Show loading indicators during authentication

**❌ DON'T:**
- Call methods before CheddaBoards is ready
- Assume user is always authenticated
- Block gameplay while waiting for authentication
- Forget to connect error signals

**Example:**
```gdscript
func _ready():
	# ✅ ALWAYS wait for initialization
	await get_tree().create_timer(0.5).timeout
	
	# ✅ Check before using
	if CheddaBoards.is_ready():
		check_authentication()
```

---

### 2. Score Submission

**✅ DO:**
- Submit scores when game ends, not continuously
- Include achievements in score submission when possible
- Handle `score_error` signal gracefully
- Show confirmation when score is submitted
- Implement retry logic for failed submissions

**❌ DON'T:**
- Submit scores too frequently (spam prevention active)
- Submit scores without checking authentication
- Ignore submission errors
- Submit invalid or negative scores

**Example:**
```gdscript
func submit_score_safely(score: int, streak: int):
	# ✅ Validate first
	if not CheddaBoards.is_authenticated():
		show_login_prompt()
		return
	
	if score < 0 or streak < 0:
		push_error("Invalid score values")
		return
	
	# ✅ Then submit
	CheddaBoards.submit_score(score, streak)
```

---

### 3. Profile Management

**✅ DO:**
- Use `get_cached_profile()` for instant UI updates
- Refresh profile after score submissions
- Respect the 2-second cooldown periods
- Handle empty/missing profile gracefully
- Save profile to local storage for offline mode

**❌ DON'T:**
- Refresh profile every frame
- Ignore `profile_loaded` signals
- Assume profile is always available

---

### 4. Error Handling

**✅ DO:**
```gdscript
func attempt_login():
	if not CheddaBoards.is_ready():
		await CheddaBoards.is_ready
	
	if not OS.get_name() == "Web":
		show_error("CheddaBoards only works on web builds")
		return
	
	CheddaBoards.login_google()
```

**❌ DON'T:**
```gdscript
func attempt_login():
	CheddaBoards.login_google()  # No error checking!
```

---

### 5. Performance Optimization

**✅ DO:**
- Use signals instead of polling
- Cache frequently accessed data
- Batch achievement unlocks
- Use `submit_score_with_achievements()` for efficiency
- Implement proper cleanup in `_exit_tree()`

**❌ DON'T:**
- Poll authentication status every frame
- Fetch leaderboard repeatedly
- Submit achievements individually
- Keep unused signals connected

---

### 6. User Experience

**✅ DO:**
- Provide multiple login options
- Show clear feedback for all actions
- Handle network errors gracefully
- Allow offline play where possible
- Preserve game state during authentication

**❌ DON'T:**
- Force users to login immediately
- Block UI while waiting for responses
- Lose game progress during auth
- Show technical error messages to users

**Example:**
```gdscript
func _on_score_error(reason: String):
	# ❌ DON'T show technical errors
	# show_error(reason)
	
	# ✅ DO show friendly messages
	show_error("Couldn't submit score. Please check your connection and try again.")
	enable_retry_button()
```

---

## Advanced Topics

### Session Management

Handle long play sessions with periodic keepalive:

```gdscript
# SessionManager.gd (Autoload)
extends Node

var session_start: float = 0.0
var session_timer: Timer

func _ready():
	session_start = Time.get_unix_time_from_system()
	
	# Periodic session keepalive
	session_timer = Timer.new()
	session_timer.wait_time = 300.0  # Every 5 minutes
	session_timer.timeout.connect(_on_session_tick)
	add_child(session_timer)
	session_timer.start()

func _on_session_tick():
	if CheddaBoards.is_authenticated():
		# Refresh to keep session alive
		CheddaBoards.refresh_profile()
	
	# Track session length
	var session_length = Time.get_unix_time_from_system() - session_start
	CheddaBoards.track_event("session_active", {
		"duration_minutes": int(session_length / 60)
	})
```

---

### Offline Support

Queue scores for submission when back online:

```gdscript
# OfflineManager.gd
extends Node

const SAVE_PATH = "user://pending_scores.save"
var pending_scores: Array = []

func _ready():
	CheddaBoards.login_success.connect(_on_online)
	load_pending_scores()

func submit_score(score: int, streak: int):
	if not CheddaBoards.is_authenticated():
		# Queue for later
		pending_scores.append({"score": score, "streak": streak, "timestamp": Time.get_unix_time_from_system()})
		save_pending_scores()
		print("Score queued for submission")
		return
	
	# Submit immediately
	CheddaBoards.submit_score(score, streak)

func _on_online(nickname: String):
	# Submit all pending scores
	print("Submitting %d pending scores" % pending_scores.size())
	for score_data in pending_scores:
		CheddaBoards.submit_score(score_data["score"], score_data["streak"])
		await get_tree().create_timer(0.5).timeout  # Rate limit
	
	pending_scores.clear()
	save_pending_scores()

func save_pending_scores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(pending_scores)
	file.close()

func load_pending_scores():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	pending_scores = file.get_var()
	file.close()
```

---

### Achievement System

Complete achievement management system:

```gdscript
# AchievementManager.gd (Autoload)
extends Node

# Define your achievements
const ACHIEVEMENTS = {
	"first_win": {
		"name": "First Victory",
		"description": "Win your first game",
		"icon": "res://icons/first_win.png"
	},
	"10_wins": {
		"name": "Veteran",
		"description": "Win 10 games",
		"icon": "res://icons/veteran.png"
	},
	"100_points": {
		"name": "Century",
		"description": "Score 100 points in a single game",
		"icon": "res://icons/century.png"
	}
}

var unlocked_achievements: Array = []
var pending_achievements: Array = []

func _ready():
	# Load saved achievements
	load_achievements()
	
	# Sync with CheddaBoards when logged in
	CheddaBoards.login_success.connect(_on_login_success)

func check_achievement(achievement_id: String) -> bool:
	"""Check if achievement is already unlocked"""
	return achievement_id in unlocked_achievements

func unlock_achievement(achievement_id: String):
	"""Unlock an achievement"""
	if check_achievement(achievement_id):
		return  # Already unlocked
	
	if not ACHIEVEMENTS.has(achievement_id):
		push_error("Unknown achievement: " + achievement_id)
		return
	
	var ach = ACHIEVEMENTS[achievement_id]
	unlocked_achievements.append(achievement_id)
	pending_achievements.append(achievement_id)
	
	# Show notification
	show_achievement_notification(ach)
	
	# Save locally
	save_achievements()
	
	# Sync to CheddaBoards if online
	if CheddaBoards.is_authenticated():
		CheddaBoards.unlock_achievement(
			achievement_id,
			ach["name"],
			ach["description"]
		)

func get_pending_achievements() -> Array:
	"""Get achievements to submit with score"""
	var pending = []
	for id in pending_achievements:
		var ach = ACHIEVEMENTS[id]
		pending.append({
			"id": id,
			"name": ach["name"],
			"description": ach["description"]
		})
	return pending

func clear_pending_achievements():
	"""Clear pending achievements after submission"""
	pending_achievements.clear()

func show_achievement_notification(achievement: Dictionary):
	# Your notification UI here
	print("🏆 Achievement Unlocked: ", achievement["name"])

func _on_login_success(nickname: String):
	# Sync all achievements when user logs in
	for achievement_id in unlocked_achievements:
		var ach = ACHIEVEMENTS[achievement_id]
		CheddaBoards.unlock_achievement(
			achievement_id,
			ach["name"],
			ach["description"]
		)

func save_achievements():
	var file = FileAccess.open("user://achievements.save", FileAccess.WRITE)
	file.store_var(unlocked_achievements)
	file.close()

func load_achievements():
	if not FileAccess.file_exists("user://achievements.save"):
		return
	
	var file = FileAccess.open("user://achievements.save", FileAccess.READ)
	unlocked_achievements = file.get_var()
	file.close()
```

---

## Troubleshooting

### Common Issues

#### Issue: "CheddaBoards not ready" errors

**Symptom:** Methods fail with "not ready" messages

**Solutions:**

1. **Wait for initialization:**
```gdscript
func _ready():
	# ✅ ALWAYS add this wait
	await get_tree().create_timer(0.5).timeout
	
	# Now safe to use
	if CheddaBoards.is_ready():
		print("Ready!")
```

2. **Check platform:**
```gdscript
if OS.get_name() != "Web":
	push_error("CheddaBoards only works on web builds")
	return
```

---

#### Issue: Login popup blocked by browser

**Symptom:** Login window doesn't appear, console shows popup blocked

**Solution:** Login MUST be triggered by direct user click:

```gdscript
# ✅ GOOD - Direct button click
func _on_login_button_pressed():
	CheddaBoards.login_google()

# ❌ BAD - Will be blocked!
func _auto_login():
	await get_tree().create_timer(2.0).timeout
	CheddaBoards.login_google()  # BLOCKED BY BROWSER!
```

---

#### Issue: "Game not registered" error

**Symptom:** Score submission fails with "game not registered"

**Solution:** You forgot Step 1!

1. Go to https://cheddaboards.com
2. Sign in with Internet Identity
3. Click "Register Game"
4. Fill in the form
5. Use that Game ID in your `cheddaboards.html`

---

#### Issue: Scores not submitting

**Symptom:** `score_error` signal fires

**Common Causes:**
1. Not authenticated
2. Network error
3. Invalid score values
4. Duplicate submission in progress

**Solution:**
```gdscript
func submit_score_safely(score: int, streak: int):
	# Check authentication
	if not CheddaBoards.is_authenticated():
		print("User not logged in")
		show_login_prompt()
		return
	
	# Validate values
	if score < 0 or streak < 0:
		print("Invalid score values")
		return
	
	# Check ready
	if not CheddaBoards.is_ready():
		print("CheddaBoards not ready")
		return
	
	# Submit
	CheddaBoards.submit_score(score, streak)
```

---

#### Issue: Profile not loading

**Symptom:** `no_profile` signal constantly fires

**Solutions:**

1. **Check authentication:**
```gdscript
if not CheddaBoards.is_authenticated():
	# Show login screen
	show_login_panel()
else:
	# Authenticated, try refreshing
	CheddaBoards.refresh_profile()
```

2. **Force check events:**
```gdscript
CheddaBoards.force_check_events()
```

---

#### Issue: CORS errors in browser console

**Symptom:** Network requests blocked by browser

**Solutions:**

1. **Use a proper web server** (not file://):
```bash
# ✅ CORRECT
python -m http.server 8000

# ❌ WRONG - causes CORS errors
# Double-clicking the HTML file
```

2. **Check domain whitelist** in CheddaBoards dashboard

---

#### Issue: JavaScript errors in console

**Symptom:** "CheddaBoards is not defined" or similar

**Solutions:**

1. **Verify HTML template** is configured:
   - Project → Export → Web
   - Custom HTML Shell is set correctly

2. **Check SDK loaded:**
```javascript
// In browser console (F12)
console.log(window.CheddaBoards)  // Should be defined
console.log(window.chedda)         // Should be defined
```

---

### Debug Checklist

Run this checklist when troubleshooting:

```gdscript
func debug_checklist():
	print("\n=== CheddaBoards Debug Checklist ===")
	
	# 1. Platform check
	print("1. Platform:", OS.get_name())
	if OS.get_name() != "Web":
		print("   ❌ NOT WEB BUILD")
		return
	print("   ✅ Web build")
	
	# 2. Autoload check
	print("2. Autoload:", has_node("/root/CheddaBoards"))
	if not has_node("/root/CheddaBoards"):
		print("   ❌ AUTOLOAD NOT FOUND")
		return
	print("   ✅ Autoload found")
	
	# 3. Ready check
	print("3. Is Ready:", CheddaBoards.is_ready())
	if not CheddaBoards.is_ready():
		print("   ⚠️  Not ready yet")
	else:
		print("   ✅ Ready")
	
	# 4. Authentication check
	print("4. Authenticated:", CheddaBoards.is_authenticated())
	print("   Auth Type:", CheddaBoards.get_auth_type())
	
	# 5. Profile check
	var profile = CheddaBoards.get_cached_profile()
	print("5. Profile cached:", !profile.is_empty())
	if !profile.is_empty():
		print("   Nickname:", profile.get("nickname"))
		print("   Score:", profile.get("score"))
	
	# 6. Full debug status
	print("\n6. Full Status:")
	CheddaBoards.debug_status()
	
	print("\n=== End Checklist ===\n")
```

---

## Migration Guide

### From Custom Authentication

If you have existing authentication, migrate gradually:

```gdscript
# MigrationManager.gd
extends Node

func migrate_user():
	# 1. Get existing user data
	var old_nickname = OldUserSystem.get_nickname()
	var old_high_score = OldUserSystem.get_high_score()
	var old_achievements = OldUserSystem.get_achievements()
	
	# 2. Login to CheddaBoards
	print("Migrating user: ", old_nickname)
	CheddaBoards.login_chedda_id(old_nickname)
	
	# 3. Wait for login
	await CheddaBoards.login_success
	
	# 4. Submit historical data
	CheddaBoards.submit_score(old_high_score, 0)
	
	# 5. Sync achievements
	for ach_id in old_achievements:
		var ach = AchievementManager.ACHIEVEMENTS[ach_id]
		CheddaBoards.unlock_achievement(ach_id, ach["name"], ach["description"])
		await get_tree().create_timer(0.2).timeout
	
	# 6. Mark as migrated
	OldUserSystem.set_migrated(true)
	OldUserSystem.save()
	
	print("Migration complete!")
```

---

## Support & Resources

### Official Resources

- **Website:** https://cheddaboards.com
- **Dashboard:** https://cheddaboards.com (register games)
- **GitHub:** https://github.com/cheddatech/CheddaBoards-SDK
- **Example Game:** https://thecheesegame.online

### Community

- **Twitter:** @cheddatech
- **Email:** info@cheddaboards.com

### Getting Help

When asking for help, please include:

1. Godot version (4.x)
2. Browser + version
3. Error messages (console + Godot)
4. Debug output from `CheddaBoards.debug_status()`

---

## License

CheddaBoards Godot Integration is provided under MIT License.

```
MIT License

Copyright (c) 2025 CheddaBoards

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

**Questions? Email info@cheddaboards.com**

**Ready to add CheddaBoards to your game? Start at https://cheddaboards.com** 🚀
