# CheddaBoards Integration Guide for Godot 4.x

Complete integration guide for adding CheddaBoards authentication, leaderboards, and achievements to your Godot 4.x game.

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

CheddaBoards provides a complete authentication and leaderboard system for web-based Godot games, featuring:

- **Multiple Authentication Methods**: CheddaID (Internet Identity), Google, Apple, Anonymous
- **Leaderboards**: Global rankings with score and streak tracking
- **Profile Management**: Player profiles with persistent data
- **Achievements**: Track and unlock achievements
- **Analytics**: Custom event tracking
- **Web3 Integration**: Built on Internet Computer Protocol (ICP)

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
│  (JS Functions) │
└────────┬────────┘
         │
         │ HTTP/ICP
         │
┌────────┴────────┐
│ CheddaBoards    │  ← Backend Service
│   Canister      │
└─────────────────┘
```

---

## Quick Start

### 1. Get Your Credentials

Visit [CheddaBoards Dashboard](https://cheddaboards.com) to:
- Register your game
- Get your Canister ID
- (Optional) Configure Google OAuth
- (Optional) Configure Apple Sign-In

### 2. Install Files

Copy these files to your project:

```
YourGame/
├── addons/
│   └── cheddaboards/
│       └── CheddaBoards.gd
└── export_templates/
    └── web/
        └── template.html
```

### 3. Configure Autoload

1. Open **Project Settings** → **Autoload**
2. Add a new autoload:
   - **Path**: `res://addons/cheddaboards/CheddaBoards.gd`
   - **Name**: `CheddaBoards`
   - **Enable**: ✓

### 4. Configure HTML Template

Edit `template.html` and replace placeholders:

```javascript
const CONFIG = {
  GAME_ID: 'your-game-id',
  GAME_NAME: 'Your Game Name',
  CANISTER_ID: 'your-canister-id',
  GOOGLE_CLIENT_ID: 'your-google-client-id',  // Optional
  APPLE_SERVICE_ID: 'your-apple-service-id',  // Optional
  APPLE_REDIRECT_URI: 'https://yourgame.com/auth/apple',  // Optional
  ICP_HOST: window.location.hostname.includes('localhost') 
    ? 'http://localhost:4943' 
    : 'https://icp-api.io'
};
```

### 5. Export Your Game

1. Go to **Project** → **Export**
2. Select **Web** preset (create if needed)
3. Set **Custom HTML Shell** to your `template.html`
4. Export and upload to your web server

---

## Installation

### Detailed Setup

#### Step 1: Download Integration Files

Get the latest files from the CheddaBoards repository or use the provided files:
- `CheddaBoards.gd` - Main singleton script
- `template.html` - Web export template

#### Step 2: Project Structure

Organize your project like this:

```
YourGameProject/
├── addons/
│   └── cheddaboards/
│       ├── CheddaBoards.gd
│       └── plugin.cfg (optional)
├── export_templates/
│   └── web/
│       └── template.html
├── scenes/
│   ├── main_menu.tscn
│   └── game.tscn
└── project.godot
```

#### Step 3: Configure Autoload

**Via Editor:**
1. Project Settings → Autoload tab
2. Click "Add" button
3. Path: `res://addons/cheddaboards/CheddaBoards.gd`
4. Node Name: `CheddaBoards`
5. Enable: ✓ (checked)

**Via project.godot (manual):**
```ini
[autoload]

CheddaBoards="*res://addons/cheddaboards/CheddaBoards.gd"
```

#### Step 4: Verify Installation

Create a test script:

```gdscript
extends Node

func _ready():
	# Connect to signals
	CheddaBoards.login_success.connect(_on_login_success)
	CheddaBoards.no_profile.connect(_on_no_profile)
	
	# Check if running on web
	print("Is Web: ", CheddaBoards.is_ready())

func _on_login_success(nickname: String):
	print("Logged in as: ", nickname)

func _on_no_profile():
	print("No profile - user needs to login")
```

---

## Configuration

### Required Configuration

#### 1. CheddaBoards Credentials

```javascript
// In template.html
const CONFIG = {
  GAME_ID: 'my-awesome-game',        // Required: Unique game identifier
  GAME_NAME: 'My Awesome Game',      // Required: Display name
  CANISTER_ID: 'xxxxx-xxxxx-xxxxx',  // Required: From CheddaBoards dashboard
  ICP_HOST: 'https://icp-api.io'     // Required: ICP network host
};
```

#### 2. Optional: Google Sign-In

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Add authorized JavaScript origins:
   - `https://yourdomain.com`
   - `http://localhost:8000` (for testing)
4. Get Client ID and add to config:

```javascript
GOOGLE_CLIENT_ID: '123456789-abcdefg.apps.googleusercontent.com'
```

#### 3. Optional: Apple Sign-In

1. Go to [Apple Developer](https://developer.apple.com/)
2. Create Service ID
3. Configure domains and return URLs
4. Add to config:

```javascript
APPLE_SERVICE_ID: 'com.yourgame.service',
APPLE_REDIRECT_URI: 'https://yourdomain.com/auth/apple'
```

### Advanced Configuration

#### Custom Styling

Modify the CSS in `template.html`:

```css
#preload {
  background: linear-gradient(135deg, #your-color-1 0%, #your-color-2 100%);
  color: #your-accent-color;
}
```

#### Loading Screen Customization

```html
<div id="preload">
  <img src="your-logo.png" alt="Logo" />
  <div class="loading-text">Loading Your Game...</div>
  <div id="spin"></div>
</div>
```

#### Performance Tuning

In `CheddaBoards.gd`, adjust these constants:

```gdscript
const POLL_INTERVAL: float = 0.1              # How often to check for responses
const MIN_RESPONSE_CHECK_INTERVAL: float = 0.3 # Rate limiting
const PROFILE_REFRESH_COOLDOWN: float = 2.0   # Profile refresh cooldown
const SUBMISSION_TIMEOUT: float = 5.0          # Score submission timeout
```

---

## API Reference

### Signals

All signals are emitted by the `CheddaBoards` autoload singleton.

#### Authentication Signals

```gdscript
# Emitted when login succeeds
signal login_success(nickname: String)

# Emitted when login fails
signal login_failed(reason: String)

# Emitted when user logs out
signal logout_success()

# Emitted when no profile is available (user not logged in)
signal no_profile()

# Emitted for authentication errors
signal auth_error(reason: String)
```

#### Profile Signals

```gdscript
# Emitted when profile data is loaded/updated
signal profile_loaded(nickname: String, score: int, streak: int, achievements: Array)

# Emitted when nickname is changed
signal nickname_changed(new_nickname: String)

# Emitted when nickname change fails
signal nickname_error(reason: String)
```

#### Score & Leaderboard Signals

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

### Authentication Methods

#### login_chedda_id(nickname: String = "")

Log in with CheddaID (Internet Identity).

```gdscript
CheddaBoards.login_chedda_id("PlayerName")

# Or let user choose nickname:
CheddaBoards.login_chedda_id("")
```

**Parameters:**
- `nickname` (String): Optional initial nickname. Empty string prompts user.

**Signals:**
- `login_success(nickname)` - On successful login
- `login_failed(reason)` - On failure

---

#### login_google()

Log in with Google account.

```gdscript
CheddaBoards.login_google()
```

**Requirements:**
- Google Client ID configured in `template.html`
- User must have Google account

**Signals:**
- `login_success(nickname)` - On successful login
- `login_failed(reason)` - On failure

---

#### login_apple()

Log in with Apple account.

```gdscript
CheddaBoards.login_apple()
```

**Requirements:**
- Apple Service ID configured in `template.html`
- User must have Apple ID

**Signals:**
- `login_success(nickname)` - On successful login
- `login_failed(reason)` - On failure

---

#### login_anonymous()

Log in anonymously (no persistent profile across devices).

```gdscript
CheddaBoards.login_anonymous()
```

**Note:** Anonymous sessions are device-specific and not recoverable.

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

---

#### is_authenticated() -> bool

Check if user is currently authenticated.

```gdscript
if CheddaBoards.is_authenticated():
	print("User is logged in")
else:
	print("User needs to login")
```

**Returns:** `bool` - True if authenticated, false otherwise

---

#### get_auth_type() -> String

Get the authentication method used.

```gdscript
var auth_type = CheddaBoards.get_auth_type()
# Returns: "google", "apple", "cheddaId", "anonymous", or ""
```

**Returns:** `String` - Authentication type

---

### Profile Methods

#### refresh_profile()

Refresh profile data from server.

```gdscript
CheddaBoards.refresh_profile()
```

**Signals:**
- `profile_loaded(nickname, score, streak, achievements)` - On success
- `no_profile()` - On failure

**Note:** Has built-in cooldown of 2 seconds to prevent spam.

---

#### get_cached_profile() -> Dictionary

Get locally cached profile data.

```gdscript
var profile = CheddaBoards.get_cached_profile()
print("Nickname: ", profile.get("nickname", "Unknown"))
print("High Score: ", profile.get("score", 0))
print("Best Streak: ", profile.get("streak", 0))
```

**Returns:** `Dictionary` with keys:
- `nickname` (String)
- `score` (int)
- `streak` (int)
- `achievements` (Array)
- `authType` (String)

---

#### get_profile_direct() -> Dictionary

Get profile directly from JavaScript (bypasses cache).

```gdscript
var profile = CheddaBoards.get_profile_direct()
```

**Returns:** `Dictionary` - Same structure as `get_cached_profile()`

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
CheddaBoards.submit_score(1500, 25)
```

**Parameters:**
- `score` (int): Player's score
- `streak` (int): Player's current streak

**Signals:**
- `score_submitted(score, streak)` - On success
- `score_error(reason)` - On failure

**Features:**
- Automatic duplicate prevention
- 5-second timeout protection
- Profile auto-refresh after submission

---

#### get_leaderboard(sort_by: String = "score", limit: int = 10)

Fetch leaderboard entries.

```gdscript
# Get top 10 by score
CheddaBoards.get_leaderboard("score", 10)

# Get top 20 by streak
CheddaBoards.get_leaderboard("streak", 20)
```

**Parameters:**
- `sort_by` (String): Sort field - `"score"` or `"streak"`
- `limit` (int): Number of entries to fetch (1-100)

**Signals:**
- `leaderboard_loaded(entries)` - On success

**Entry Structure:**
```gdscript
# Each entry is a Dictionary:
{
	"rank": 1,
	"nickname": "PlayerName",
	"score": 1500,
	"streak": 25
}
```

---

#### get_player_rank(sort_by: String = "score")

Get current player's rank.

```gdscript
CheddaBoards.get_player_rank("score")
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

---

#### submit_score_with_achievements(score: int, streak: int, achievements: Array)

Submit score and achievements together (more efficient).

```gdscript
var achievements = ["first_win", "10_wins", "speed_demon"]
CheddaBoards.submit_score_with_achievements(1500, 25, achievements)
```

**Parameters:**
- `score` (int): Player's score
- `streak` (int): Player's streak
- `achievements` (Array): Array of achievement IDs

**Signals:**
- `score_submitted(score, streak)` - On success
- `score_error(reason)` - On failure

---

### Analytics Methods

#### track_event(event_type: String, metadata: Dictionary = {})

Track custom game events.

```gdscript
# Simple event
CheddaBoards.track_event("level_completed")

# Event with metadata
CheddaBoards.track_event("item_purchased", {
	"item_id": "sword_legendary",
	"price": 1000,
	"currency": "gold"
})
```

**Parameters:**
- `event_type` (String): Event identifier
- `metadata` (Dictionary): Additional event data

---

### Utility Methods

#### is_ready() -> bool

Check if CheddaBoards is fully initialized.

```gdscript
func _ready():
	if not CheddaBoards.is_ready():
		await CheddaBoards.profile_loaded
	start_game()
```

**Returns:** `bool` - True if ready, false otherwise

---

#### force_check_events()

Force check for pending events or authentication status.

```gdscript
CheddaBoards.force_check_events()
```

**Use Cases:**
- After scene changes
- Recovering from errors
- Manual refresh

---

#### debug_status()

Print debug information to console.

```gdscript
CheddaBoards.debug_status()
```

**Output Example:**
```
========== CheddaBoards Debug Status ==========
  - Is Web: true
  - Init Complete: true
  - Auth Type: google
  - Is Authenticated: true
  - Cached Profile: {nickname:Player, score:1500, ...}
  - Is Checking Auth: false
  - Is Refreshing Profile: false
  - Is Submitting Score: false
==============================================
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

func _ready():
	# Connect signals
	CheddaBoards.login_success.connect(_on_login_success)
	CheddaBoards.login_failed.connect(_on_login_failed)
	CheddaBoards.profile_loaded.connect(_on_profile_loaded)
	CheddaBoards.no_profile.connect(_on_no_profile)
	
	# Check initial auth state
	if CheddaBoards.is_ready():
		_check_auth_status()
	else:
		await CheddaBoards.profile_loaded
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
	nickname_label.text = profile.get("nickname", "Player")
	score_label.text = "High Score: %d" % profile.get("score", 0)

func _on_login_success(nickname: String):
	print("Welcome, ", nickname)
	var profile = CheddaBoards.get_cached_profile()
	_show_main_menu(profile)

func _on_login_failed(reason: String):
	print("Login failed: ", reason)
	# Show error dialog

func _on_profile_loaded(nickname: String, score: int, streak: int, achievements: Array):
	_show_main_menu(CheddaBoards.get_cached_profile())

func _on_no_profile():
	_show_login_panel()

# Button callbacks
func _on_google_login_pressed():
	CheddaBoards.login_google()

func _on_apple_login_pressed():
	CheddaBoards.login_apple()

func _on_chedda_login_pressed():
	CheddaBoards.login_chedda_id("")

func _on_anonymous_login_pressed():
	CheddaBoards.login_anonymous()

func _on_logout_pressed():
	CheddaBoards.logout()
	_show_login_panel()
```

---

### Example 2: Game Over Screen with Score Submission

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
		get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_score_submitted(score: int, streak: int):
	status_label.text = "Score submitted!"
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
@onready var sort_by_score = $SortByScore
@onready var sort_by_streak = $SortByStreak

var entry_scene = preload("res://scenes/leaderboard_entry.tscn")

func _ready():
	CheddaBoards.leaderboard_loaded.connect(_on_leaderboard_loaded)
	CheddaBoards.player_rank_loaded.connect(_on_player_rank_loaded)
	
	sort_by_score.pressed.connect(func(): load_leaderboard("score"))
	sort_by_streak.pressed.connect(func(): load_leaderboard("streak"))
	
	# Load initial leaderboard
	load_leaderboard("score")

func load_leaderboard(sort_by: String):
	# Clear existing entries
	for child in entries_container.get_children():
		child.queue_free()
	
	loading_label.visible = true
	CheddaBoards.get_leaderboard(sort_by, 20)
	
	# Also get player's rank
	CheddaBoards.get_player_rank(sort_by)

func _on_leaderboard_loaded(entries: Array):
	loading_label.visible = false
	
	for entry_data in entries:
		var entry = entry_scene.instantiate()
		entry.set_data(
			entry_data.get("rank", 0),
			entry_data.get("nickname", "Unknown"),
			entry_data.get("score", 0),
			entry_data.get("streak", 0)
		)
		entries_container.add_child(entry)

func _on_player_rank_loaded(rank: int, score: int, streak: int, total_players: int):
	# Highlight player's entry or show separate "Your Rank" section
	print("Your rank: %d / %d" % [rank, total_players])
```

---

### Example 4: Achievement System

```gdscript
# AchievementManager.gd
extends Node

# Define your achievements
const ACHIEVEMENTS = {
	"first_win": {
		"name": "First Victory",
		"description": "Win your first game"
	},
	"10_wins": {
		"name": "Veteran",
		"description": "Win 10 games"
	},
	"100_points": {
		"name": "Century",
		"description": "Score 100 points in a single game"
	},
	"speed_demon": {
		"name": "Speed Demon",
		"description": "Complete a level in under 30 seconds"
	}
}

var unlocked_achievements: Array = []
var pending_achievements: Array = []

func _ready():
	# Load saved achievements
	unlocked_achievements = load_achievements_from_save()

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
	show_achievement_notification(ach["name"], ach["description"])
	
	# Save locally
	save_achievements()
	
	# Sync to CheddaBoards
	if CheddaBoards.is_authenticated():
		CheddaBoards.unlock_achievement(
			achievement_id,
			ach["name"],
			ach["description"]
		)

func sync_all_achievements():
	"""Sync all unlocked achievements to CheddaBoards"""
	if not CheddaBoards.is_authenticated():
		return
	
	for achievement_id in unlocked_achievements:
		var ach = ACHIEVEMENTS[achievement_id]
		CheddaBoards.unlock_achievement(
			achievement_id,
			ach["name"],
			ach["description"]
		)

func get_pending_achievements() -> Array:
	"""Get achievements to submit with score"""
	return pending_achievements.duplicate()

func clear_pending_achievements():
	"""Clear pending achievements after submission"""
	pending_achievements.clear()

func show_achievement_notification(title: String, description: String):
	# Implement your notification UI here
	print("🏆 Achievement Unlocked: ", title)
	print("   ", description)

func save_achievements():
	# Save to local file/save game
	var save_data = {
		"achievements": unlocked_achievements
	}
	# Your save logic here

func load_achievements_from_save() -> Array:
	# Load from local file/save game
	# Your load logic here
	return []
```

**Using the Achievement Manager:**

```gdscript
# In your game script
extends Node2D

var wins: int = 0

func _on_game_won():
	wins += 1
	
	# Check achievements
	if wins == 1:
		AchievementManager.unlock_achievement("first_win")
	elif wins == 10:
		AchievementManager.unlock_achievement("10_wins")
	
	# Submit score with achievements
	var achievements = AchievementManager.get_pending_achievements()
	CheddaBoards.submit_score_with_achievements(current_score, current_streak, achievements)
	AchievementManager.clear_pending_achievements()
```

---

### Example 5: Handling Scene Transitions

```gdscript
# Global.gd (Autoload)
extends Node

func _ready():
	# Connect to login/logout signals globally
	CheddaBoards.login_success.connect(_on_login_success)
	CheddaBoards.logout_success.connect(_on_logout_success)

func _on_login_success(nickname: String):
	# Sync achievements when user logs in
	if has_node("/root/AchievementManager"):
		AchievementManager.sync_all_achievements()

func _on_logout_success():
	# Clear any sensitive data
	print("User logged out")
```

---

## Best Practices

### 1. Authentication Flow

**✅ DO:**
- Check authentication status in `_ready()`
- Wait for `CheddaBoards.is_ready()` before calling methods
- Handle `no_profile` signal for unauthenticated users
- Cache profile data locally for offline access
- Show loading indicators during authentication

**❌ DON'T:**
- Call methods before CheddaBoards is ready
- Assume user is always authenticated
- Block gameplay while waiting for authentication
- Store sensitive data in plaintext

### 2. Score Submission

**✅ DO:**
- Submit scores when game ends, not continuously
- Include achievements in score submission
- Handle `score_error` signal gracefully
- Show confirmation when score is submitted
- Implement retry logic for failed submissions

**❌ DON'T:**
- Submit scores too frequently (spam prevention)
- Submit scores without checking authentication
- Ignore submission errors
- Submit invalid or negative scores

### 3. Profile Management

**✅ DO:**
- Use cached profile for instant UI updates
- Refresh profile after score submissions
- Respect the cooldown periods
- Handle empty/missing profile gracefully
- Save profile to local storage for offline mode

**❌ DON'T:**
- Refresh profile every frame
- Ignore profile_loaded signals
- Assume profile is always available

### 4. Error Handling

**✅ DO:**
```gdscript
func submit_score():
	if not CheddaBoards.is_authenticated():
		show_login_prompt()
		return
	
	if not CheddaBoards.is_ready():
		show_error("Service not ready, please try again")
		return
	
	CheddaBoards.submit_score(score, streak)
```

**❌ DON'T:**
```gdscript
func submit_score():
	CheddaBoards.submit_score(score, streak)  # No error checking!
```

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

### 6. User Experience

**✅ DO:**
- Provide multiple login options
- Show clear feedback for all actions
- Handle network errors gracefully
- Allow offline play (where possible)
- Preserve game state during authentication

**❌ DON'T:**
- Force users to login immediately
- Block UI while waiting for responses
- Lose game progress during auth
- Show technical error messages to users

---

## Troubleshooting

### Common Issues

#### Issue: "CheddaBoards not ready" errors

**Symptom:** Methods fail with "not ready" messages

**Solutions:**
1. Wait for initialization:
```gdscript
func _ready():
	if not CheddaBoards.is_ready():
		await get_tree().create_timer(1.0).timeout
	# Now ready to use
```

2. Connect to signals:
```gdscript
CheddaBoards.login_success.connect(_on_ready_to_play)
```

---

#### Issue: Login popup blocked by browser

**Symptom:** Login window doesn't appear

**Solutions:**
1. User must click a button (browser popup blocker)
2. Add this to your button:
```gdscript
func _on_login_button_pressed():
	# This MUST be triggered by user interaction
	CheddaBoards.login_google()
```

---

#### Issue: Scores not submitting

**Symptom:** `score_error` signal fires

**Common Causes:**
1. Not authenticated - check before submitting
2. Network error - implement retry logic
3. Invalid score values - validate before submission
4. Duplicate submission - already in progress

**Solution:**
```gdscript
func submit_score_safely(score: int, streak: int):
	if not CheddaBoards.is_authenticated():
		print("User not logged in")
		return
	
	if score < 0 or streak < 0:
		print("Invalid score values")
		return
	
	CheddaBoards.submit_score(score, streak)
```

---

#### Issue: Profile not loading

**Symptom:** `no_profile` signal constantly fires

**Solutions:**
1. Check authentication:
```gdscript
if CheddaBoards.is_authenticated():
	CheddaBoards.refresh_profile()
else:
	# Show login screen
```

2. Force check events:
```gdscript
CheddaBoards.force_check_events()
```

---

#### Issue: Leaderboard not displaying

**Symptom:** `leaderboard_loaded` never fires

**Debugging:**
```gdscript
func _ready():
	CheddaBoards.leaderboard_loaded.connect(_on_leaderboard_loaded)
	
	# Check if authenticated
	if CheddaBoards.is_authenticated():
		CheddaBoards.get_leaderboard("score", 10)
	else:
		print("Must be authenticated to view leaderboard")

func _on_leaderboard_loaded(entries: Array):
	print("Loaded %d entries" % entries.size())
	for entry in entries:
		print(entry)
```

---

#### Issue: CORS errors in browser console

**Symptom:** Network requests blocked by browser

**Solutions:**
1. Ensure you're testing on proper web server (not file://)
2. Use Python simple server for local testing:
```bash
python -m http.server 8000
```
3. Check your domain is whitelisted in CheddaBoards dashboard

---

#### Issue: JavaScript errors in console

**Symptom:** Bridge functions not found

**Solutions:**
1. Verify `template.html` is properly configured
2. Check HTML template is being used in export settings
3. Ensure CheddaBoards SDK is loaded:
```javascript
// In browser console
console.log(window.CheddaBoards)  // Should not be undefined
console.log(window.chedda)         // Should not be undefined
```

---

### Debug Checklist

Use this checklist when troubleshooting:

```gdscript
func debug_integration():
	print("=== CheddaBoards Debug ===")
	print("1. Is Web?", OS.get_name() == "Web")
	print("2. Is Ready?", CheddaBoards.is_ready())
	print("3. Is Authenticated?", CheddaBoards.is_authenticated())
	print("4. Auth Type:", CheddaBoards.get_auth_type())
	print("5. Has Profile?", not CheddaBoards.get_cached_profile().is_empty())
	
	# Call built-in debug
	CheddaBoards.debug_status()
	
	# Check JavaScript side
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("debugChedda()", true)
```

---

### Getting Help

If you're still having issues:

1. **Check Browser Console** (F12)
   - Look for JavaScript errors
   - Check network requests

2. **Use Debug Functions**
   ```gdscript
   CheddaBoards.debug_status()
   ```
   ```javascript
   // In browser console
   debugChedda()
   ```

3. **Contact Support**
   - Discord: [CheddaBoards Community](#)
   - Email: support@cheddaboards.com
   - GitHub Issues: [Report Bug](#)

4. **Provide Debug Info**
   - Godot version
   - Browser + version
   - Error messages
   - Debug output

---

## Advanced Topics

### Custom Event Tracking

Track player behavior for analytics:

```gdscript
# Track level completion
CheddaBoards.track_event("level_completed", {
	"level_id": "world_1_level_5",
	"time": 45.2,
	"deaths": 3
})

# Track purchases
CheddaBoards.track_event("item_purchased", {
	"item": "legendary_sword",
	"price": 1000,
	"currency": "gems"
})

# Track game modes
CheddaBoards.track_event("game_mode_selected", {
	"mode": "survival",
	"difficulty": "hard"
})
```

### Session Management

Handle long play sessions:

```gdscript
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

### Offline Support

Handle offline gameplay:

```gdscript
extends Node

var pending_scores: Array = []

func submit_score(score: int, streak: int):
	if not CheddaBoards.is_authenticated():
		# Queue for later
		pending_scores.append({"score": score, "streak": streak})
		save_pending_scores()
		return
	
	CheddaBoards.submit_score(score, streak)

func _on_login_success(nickname: String):
	# Submit pending scores
	for score_data in pending_scores:
		CheddaBoards.submit_score(
			score_data["score"],
			score_data["streak"]
		)
	pending_scores.clear()
	save_pending_scores()
```

---

## Migration Guide

### From Custom Authentication

If you have existing authentication:

1. **Backup existing user data**
2. **Implement CheddaBoards alongside existing system**
3. **Migrate users gradually:**

```gdscript
func migrate_to_cheddaboards():
	# Get existing user data
	var old_nickname = UserData.nickname
	var old_score = UserData.high_score
	
	# Login to CheddaBoards
	CheddaBoards.login_chedda_id(old_nickname)
	await CheddaBoards.login_success
	
	# Submit historical score
	CheddaBoards.submit_score(old_score, 0)
	
	# Mark as migrated
	UserData.migrated_to_cheddaboards = true
	UserData.save()
```

---

## Support & Resources

- **Documentation**: [https://docs.cheddaboards.com](https://docs.cheddaboards.com)
- **API Reference**: [https://api.cheddaboards.com/docs](https://api.cheddaboards.com/docs)
- **Dashboard**: [https://dashboard.cheddaboards.com](https://dashboard.cheddaboards.com)
- **Discord**: [Join Community](#)
- **GitHub**: [CheddaBoards/godot-integration](#)

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

[Standard MIT License text...]
```


**Need help? Email support@cheddaboards.com**
