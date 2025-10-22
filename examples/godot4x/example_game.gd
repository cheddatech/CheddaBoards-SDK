# example_game.gd
# A complete example showing CheddaBoards integration in a simple game
# This demonstrates:
# - Login flow with pause/unpause
# - Score submission
# - Leaderboard display
# - Profile management

extends Node2D

# ============================================================
# GAME STATE
# ============================================================
var score = 0
var streak = 0
var game_started = false
var is_logged_in = false

# ============================================================
# UI NODES (Set these in the editor or create in _ready)
# ============================================================
@onready var score_label = $ScoreLabel
@onready var login_button = $LoginButton
@onready var leaderboard_button = $LeaderboardButton
@onready var status_label = $StatusLabel
@onready var leaderboard_panel = $LeaderboardPanel

# ============================================================
# INITIALIZATION
# ============================================================

func _ready():
	print("=== Example Game Starting ===")
	
	# CRITICAL: Make UI work while game is paused
	_setup_ui_process_modes()
	
	# Pause until login
	get_tree().paused = true
	
	# Setup UI
	_setup_ui()
	
	# Connect CheddaLogin signals
	_connect_cheddaboards_signals()
	
	# Wait for CheddaBoards to initialize
	await get_tree().create_timer(2.0).timeout
	
	if CheddaLogin.is_ready():
		print("✅ CheddaBoards ready!")
		_check_existing_session()
	else:
		print("⚠️ CheddaBoards not ready")
		status_label.text = "Loading CheddaBoards..."

func _setup_ui_process_modes():
	"""Make UI elements work while game is paused"""
	login_button.process_mode = Node.PROCESS_MODE_ALWAYS
	leaderboard_button.process_mode = Node.PROCESS_MODE_ALWAYS
	status_label.process_mode = Node.PROCESS_MODE_ALWAYS
	score_label.process_mode = Node.PROCESS_MODE_ALWAYS
	if leaderboard_panel:
		leaderboard_panel.process_mode = Node.PROCESS_MODE_ALWAYS

func _setup_ui():
	"""Setup initial UI state"""
	score_label.text = "Score: 0 | Streak: 0"
	status_label.text = "Please login to play"
	
	login_button.text = "Login with Internet Identity"
	login_button.disabled = false
	login_button.pressed.connect(_on_login_button_pressed)
	
	leaderboard_button.text = "Show Leaderboard"
	leaderboard_button.disabled = false
	leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	
	if leaderboard_panel:
		leaderboard_panel.visible = false

func _connect_cheddaboards_signals():
	"""Connect to all CheddaLogin signals"""
	CheddaLogin.login_success.connect(_on_login_success)
	CheddaLogin.login_failed.connect(_on_login_failed)
	CheddaLogin.profile_loaded.connect(_on_profile_loaded)
	CheddaLogin.score_submitted.connect(_on_score_submitted)
	CheddaLogin.score_error.connect(_on_score_error)
	CheddaLogin.leaderboard_loaded.connect(_on_leaderboard_loaded)
	CheddaLogin.logout_success.connect(_on_logout_success)
	
	print("✅ CheddaBoards signals connected")

func _check_existing_session():
	"""Check if user is already logged in from previous session"""
	if CheddaLogin.is_authenticated():
		print("✅ Already logged in!")
		is_logged_in = true
		login_button.text = "Logged In ✓"
		login_button.disabled = true
		_start_game()
	else:
		print("ℹ️ Not logged in")
		status_label.text = "Login to start playing"

# ============================================================
# AUTHENTICATION HANDLERS
# ============================================================

func _on_login_button_pressed():
	print("🔐 Login button pressed")
	
	login_button.text = "Logging in..."
	login_button.disabled = true
	status_label.text = "Opening Internet Identity..."
	
	# Generate a random nickname (you could prompt user for this)
	var nickname = "Player" + str(randi() % 10000)
	
	# Start login flow
	CheddaLogin.login_ii(nickname)

func _on_login_success(nickname: String):
	print("✅ Login successful! Welcome:", nickname)
	
	is_logged_in = true
	login_button.text = "Logged In ✓"
	login_button.disabled = true
	status_label.text = "Welcome, " + nickname + "!"
	
	# Start the game
	_start_game()

func _on_login_failed(reason: String):
	print("❌ Login failed:", reason)
	
	login_button.text = "Login Failed - Retry"
	login_button.disabled = false
	status_label.text = "Login failed: " + reason

func _on_profile_loaded(nickname: String, high_score: int, best_streak: int, achievements: Array):
	print("📋 Profile loaded:")
	print("  - Nickname:", nickname)
	print("  - High Score:", high_score)
	print("  - Best Streak:", best_streak)
	print("  - Achievements:", achievements.size())
	
	if high_score > 0:
		status_label.text = "Your best: %d points" % high_score

func _on_logout_success():
	print("👋 Logged out")
	
	is_logged_in = false
	game_started = false
	score = 0
	streak = 0
	
	login_button.text = "Login with Internet Identity"
	login_button.disabled = false
	login_button.visible = true
	status_label.text = "Logged out. Login to play again."
	
	get_tree().paused = true

# ============================================================
# GAME FLOW
# ============================================================

func _start_game():
	"""Start the actual game after login"""
	if game_started:
		return
	
	print("🎮 Starting game...")
	
	game_started = true
	score = 0
	streak = 0
	
	# Hide login button
	login_button.visible = false
	
	# Update UI
	score_label.text = "Score: 0 | Streak: 0"
	status_label.text = "Game started! Press SPACE to score"
	
	# Unpause the game
	get_tree().paused = false

func _input(event):
	"""Handle game input (example: space bar to score)"""
	if not game_started:
		return
	
	if event.is_action_pressed("ui_accept"):  # Space bar or Enter
		_add_score(10)

func _add_score(points: int):
	"""Add points and increase streak"""
	score += points
	streak += 1
	
	score_label.text = "Score: %d | Streak: %d" % [score, streak]
	status_label.text = "+%d points! Streak: %d" % [points, streak]
	
	print("📊 Score: %d | Streak: %d" % [score, streak])

func _game_over():
	"""End the game and submit score"""
	print("🏁 Game Over!")
	
	game_started = false
	get_tree().paused = true
	
	status_label.text = "Game Over! Final Score: %d" % score
	
	# Submit score if logged in
	if is_logged_in:
		print("📤 Submitting score...")
		CheddaLogin.submit_score(score, streak)
	else:
		status_label.text = "Game Over! Login to save your score."

# ============================================================
# SCORE SUBMISSION HANDLERS
# ============================================================

func _on_score_submitted(submitted_score: int, submitted_streak: int):
	print("✅ Score submitted successfully!")
	print("  - Score:", submitted_score)
	print("  - Streak:", submitted_streak)
	
	status_label.text = "Score saved! Loading leaderboard..."
	
	# Auto-load leaderboard after score submission
	CheddaLogin.get_leaderboard("score", 10)

func _on_score_error(reason: String):
	print("❌ Failed to submit score:", reason)
	status_label.text = "Failed to save score: " + reason

# ============================================================
# LEADERBOARD HANDLERS
# ============================================================

func _on_leaderboard_button_pressed():
	print("📊 Loading leaderboard...")
	
	leaderboard_button.text = "Loading..."
	leaderboard_button.disabled = true
	status_label.text = "Loading leaderboard..."
	
	CheddaLogin.get_leaderboard("score", 10)

func _on_leaderboard_loaded(entries: Array):
	print("📊 Leaderboard loaded with %d entries" % entries.size())
	
	# Re-enable button
	leaderboard_button.text = "Show Leaderboard"
	leaderboard_button.disabled = false
	
	if leaderboard_panel:
		_display_leaderboard_in_panel(entries)
	else:
		_display_leaderboard_in_console(entries)

func _display_leaderboard_in_panel(entries: Array):
	"""Display leaderboard in a UI panel"""
	leaderboard_panel.visible = true
	
	# Clear existing entries (assuming panel has a VBoxContainer child)
	var container = leaderboard_panel.get_node_or_null("VBoxContainer")
	if not container:
		print("⚠️ No VBoxContainer in leaderboard panel")
		return
	
	for child in container.get_children():
		if child is Label:
			child.queue_free()
	
	# Add title
	var title = Label.new()
	title.text = "🏆 TOP PLAYERS 🏆"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	container.add_child(title)
	
	# Add entries
	if entries.size() == 0:
		var empty = Label.new()
		empty.text = "No scores yet! Be the first!"
		container.add_child(empty)
	else:
		for i in range(min(entries.size(), 10)):
			var entry = entries[i]
			
			# CheddaBoards returns: [principal, score, streak, nickname]
			var nickname = str(entry[3])
			var entry_score = int(entry[1])
			var entry_streak = int(entry[2])
			
			# Medal for top 3
			var medal = ""
			match i:
				0: medal = "🥇 "
				1: medal = "🥈 "
				2: medal = "🥉 "
			
			var label = Label.new()
			label.text = "%s%d. %s - %d pts (streak: %d)" % [medal, i+1, nickname, entry_score, entry_streak]
			container.add_child(label)
	
	# Hide after 10 seconds
	await get_tree().create_timer(10.0).timeout
	leaderboard_panel.visible = false

func _display_leaderboard_in_console(entries: Array):
	"""Display leaderboard in console (fallback)"""
	print("\n=== 🏆 TOP PLAYERS 🏆 ===")
	
	if entries.size() == 0:
		print("No scores yet!")
	else:
		for i in range(min(entries.size(), 10)):
			var entry = entries[i]
			var nickname = str(entry[3])
			var entry_score = int(entry[1])
			var entry_streak = int(entry[2])
			
			var medal = ["🥇", "🥈", "🥉"][i] if i < 3 else "  "
			print("%s #%d  %s - %d pts (streak: %d)" % [medal, i+1, nickname, entry_score, entry_streak])
	
	print("========================\n")
	
	status_label.text = "Leaderboard shown in console (F12)"

# ============================================================
# OPTIONAL: GAME TIMER EXAMPLE
# ============================================================

func _start_timed_game(duration: float = 30.0):
	"""Example: Start a timed game"""
	_start_game()
	
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	_game_over()

# ============================================================
# DEBUG FUNCTIONS
# ============================================================

func _debug_print_status():
	"""Print debug information"""
	print("\n=== Game Status ===")
	print("  Game Started:", game_started)
	print("  Logged In:", is_logged_in)
	print("  Score:", score)
	print("  Streak:", streak)
	print("  CheddaBoards Ready:", CheddaLogin.is_ready())
	print("  Authenticated:", CheddaLogin.is_authenticated())
	print("==================\n")
	
	# Print CheddaLogin debug info
	CheddaLogin.debug_status()
