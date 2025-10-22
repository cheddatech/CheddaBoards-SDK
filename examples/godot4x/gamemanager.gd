# GameManager.gd - Godot 4.x Version
# Example showing how to integrate CheddaBoards in your Godot game
#
# This example demonstrates:
# - Connecting to CheddaLogin signals
# - Handling authentication
# - Submitting scores
# - Loading leaderboards

extends Node

# ============================================================
# UI REFERENCES
# ============================================================
# Connect these in your scene
@export var login_button_path: NodePath
@export var logout_button_path: NodePath
@export var player_name_label_path: NodePath
@export var high_score_label_path: NodePath
@export var status_label_path: NodePath
@export var leaderboard_container_path: NodePath

# Optional UI elements
@onready var login_button = get_node_or_null(login_button_path)
@onready var logout_button = get_node_or_null(logout_button_path)
@onready var player_name_label = get_node_or_null(player_name_label_path)
@onready var high_score_label = get_node_or_null(high_score_label_path)
@onready var status_label = get_node_or_null(status_label_path)
@onready var leaderboard_container = get_node_or_null(leaderboard_container_path)

# ============================================================
# GAME STATE
# ============================================================
var current_score = 0
var current_streak = 0
var is_logged_in = false
var player_nickname = "Guest"
var player_high_score = 0
var player_best_streak = 0

# ============================================================
# INITIALIZATION
# ============================================================
func _ready():
	print("[GameManager] Initializing CheddaBoards integration...")
	
	# Connect to CheddaLogin signals
	_connect_signals()
	
	# Wait for CheddaLogin to be ready
	await get_tree().create_timer(3.0).timeout
	
	# Check initial authentication status
	if CheddaLogin.is_ready():
		print("[GameManager] CheddaLogin is ready")
		_check_initial_auth()
	else:
		print("[GameManager] Waiting for CheddaLogin...")
		_show_status("Connecting to CheddaBoards...")

func _connect_signals():
	"""Connect all CheddaLogin signals"""
	
	# Authentication signals
	CheddaLogin.profile_loaded.connect(_on_profile_loaded)
	CheddaLogin.login_success.connect(_on_login_success)
	CheddaLogin.login_failed.connect(_on_login_failed)
	CheddaLogin.logout_success.connect(_on_logout_success)
	CheddaLogin.no_profile.connect(_on_no_profile)
	
	# Game action signals
	CheddaLogin.score_submitted.connect(_on_score_submitted)
	CheddaLogin.score_error.connect(_on_score_error)
	CheddaLogin.leaderboard_loaded.connect(_on_leaderboard_loaded)
	
	print("[GameManager] Signals connected")

func _check_initial_auth():
	"""Check if user is already authenticated from previous session"""
	if CheddaLogin.is_authenticated():
		print("[GameManager] User already authenticated")
		is_logged_in = true
		_update_ui_state()
		CheddaLogin.force_check_events()
	else:
		print("[GameManager] User not authenticated")
		_show_status("Please login to save your score")
		_update_ui_state()

# ============================================================
# AUTHENTICATION HANDLERS
# ============================================================
func _on_profile_loaded(nickname: String, score: int, streak: int, achievements: Array):
	"""Called when profile data is loaded"""
	print("[GameManager] Profile loaded: ", nickname, " Score: ", score, " Streak: ", streak)
	
	player_nickname = nickname
	player_high_score = score
	player_best_streak = streak
	
	_update_player_display()
	_show_status("Welcome back, " + nickname + "!")
	
	# Check for new high score
	if current_score > player_high_score:
		print("[GameManager] New high score available to submit!")

func _on_login_success(nickname: String):
	"""Called when login is successful"""
	print("[GameManager] Login successful: ", nickname)
	
	is_logged_in = true
	player_nickname = nickname
	
	_update_ui_state()
	_show_status("Logged in as " + nickname)
	
	# Load leaderboard after login
	CheddaLogin.get_leaderboard()

func _on_login_failed(reason: String):
	"""Called when login fails"""
	print("[GameManager] Login failed: ", reason)
	
	is_logged_in = false
	_show_status("Login failed: " + reason)
	_update_ui_state()

func _on_logout_success():
	"""Called when logout is successful"""
	print("[GameManager] Logged out")
	
	is_logged_in = false
	player_nickname = "Guest"
	player_high_score = 0
	player_best_streak = 0
	
	_update_ui_state()
	_update_player_display()
	_show_status("Logged out successfully")

func _on_no_profile():
	"""Called when no profile exists"""
	print("[GameManager] No profile found")
	_show_status("No profile - please login")

# ============================================================
# SCORE HANDLERS
# ============================================================
func _on_score_submitted(score: int, streak: int):
	"""Called when score is successfully submitted"""
	print("[GameManager] Score submitted successfully: ", score, "/", streak)
	
	_show_status("Score submitted: " + str(score))
	
	# Update local high score if needed
	if score > player_high_score:
		player_high_score = score
		player_best_streak = max(player_best_streak, streak)
		_update_player_display()
	
	# Refresh leaderboard
	CheddaLogin.get_leaderboard()

func _on_score_error(reason: String):
	"""Called when score submission fails"""
	print("[GameManager] Score submission failed: ", reason)
	_show_status("Failed to submit score: " + reason)

# ============================================================
# LEADERBOARD HANDLERS
# ============================================================
func _on_leaderboard_loaded(entries: Array):
	"""Called when leaderboard data is received"""
	print("[GameManager] Leaderboard loaded with ", entries.size(), " entries")
	
	if not leaderboard_container:
		return
	
	# Clear existing entries
	for child in leaderboard_container.get_children():
		child.queue_free()
	
	# Add leaderboard entries
	var rank = 1
	for entry in entries:
		var entry_label = Label.new()
		
		# Handle both dictionary and array formats
		var nickname = "Unknown"
		var score = 0
		var streak = 0
		
		if typeof(entry) == TYPE_DICTIONARY:
			nickname = entry.get("nickname", "Unknown")
			score = entry.get("score", 0)
			streak = entry.get("streak", 0)
		elif typeof(entry) == TYPE_ARRAY and entry.size() >= 4:
			# CheddaBoards returns: [principal, score, streak, nickname]
			nickname = str(entry[3])
			score = int(entry[1])
			streak = int(entry[2])
		
		entry_label.text = "#%d - %s: %d (streak: %d)" % [rank, nickname, score, streak]
		leaderboard_container.add_child(entry_label)
		rank += 1
	
	if entries.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No scores yet - be the first!"
		leaderboard_container.add_child(empty_label)

# ============================================================
# UI METHODS
# ============================================================
func _update_ui_state():
	"""Update UI based on authentication state"""
	if login_button:
		login_button.visible = not is_logged_in
	
	if logout_button:
		logout_button.visible = is_logged_in

func _update_player_display():
	"""Update player name and score display"""
	if player_name_label:
		player_name_label.text = player_nickname
	
	if high_score_label:
		high_score_label.text = "High Score: " + str(player_high_score)

func _show_status(message: String):
	"""Show a status message to the player"""
	print("[GameManager] Status: ", message)
	
	if status_label:
		status_label.text = message
		status_label.modulate.a = 1.0
		
		# Fade out after 3 seconds using Tween
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(3.0)
		tween.tween_property(status_label, "modulate:a", 0.0, 1.0)

# ============================================================
# PUBLIC GAME METHODS
# ============================================================
func login_with_ii():
	"""Start Internet Identity login flow"""
	if not CheddaLogin.is_ready():
		_show_status("System not ready")
		return
	
	_show_status("Opening Internet Identity...")
	CheddaLogin.login_internet_identity()

func login_with_google():
	"""Start Google login flow"""
	if not CheddaLogin.is_ready():
		_show_status("System not ready")
		return
	
	_show_status("Opening Google Sign-In...")
	# Note: Google login requires additional setup in the HTML template
	push_warning("[GameManager] Google login not implemented in CheddaLogin singleton yet")

func login_with_apple():
	"""Start Apple login flow"""
	if not CheddaLogin.is_ready():
		_show_status("System not ready")
		return
	
	_show_status("Opening Apple Sign-In...")
	# Note: Apple login requires additional setup in the HTML template
	push_warning("[GameManager] Apple login not implemented in CheddaLogin singleton yet")

func logout():
	"""Logout the current user"""
	CheddaLogin.logout()

func submit_current_score():
	"""Submit the current game score"""
	if not is_logged_in:
		_show_status("Please login to save your score")
		return
	
	if current_score <= 0:
		_show_status("No score to submit")
		return
	
	print("[GameManager] Submitting score: ", current_score, " streak: ", current_streak)
	CheddaLogin.submit_score(current_score, current_streak)
	_show_status("Submitting score...")

func game_over(final_score: int, final_streak: int):
	"""Called when the game ends"""
	print("[GameManager] Game Over - Score: ", final_score, " Streak: ", final_streak)
	
	current_score = final_score
	current_streak = final_streak
	
	if is_logged_in:
		# Automatically submit score if logged in
		submit_current_score()
	else:
		_show_status("Login to save your score!")

func refresh_leaderboard():
	"""Manually refresh the leaderboard"""
	print("[GameManager] Refreshing leaderboard...")
	CheddaLogin.get_leaderboard("score", 10)

# ============================================================
# BUTTON HANDLERS (connect these to your UI buttons)
# ============================================================
func _on_login_button_pressed():
	"""Handle login button press - show login options"""
	# You could show a menu with login options or use a default
	login_with_ii()  # Default to Internet Identity

func _on_logout_button_pressed():
	"""Handle logout button press"""
	logout()

func _on_submit_score_button_pressed():
	"""Handle submit score button press"""
	submit_current_score()

func _on_refresh_leaderboard_pressed():
	"""Handle refresh leaderboard button press"""
	refresh_leaderboard()

# ============================================================
# DEBUG HELPERS
# ============================================================
func debug_chedda_status():
	"""Print debug information"""
	CheddaLogin.debug_status()
	print("[GameManager] Local State:")
	print("  - Logged In: ", is_logged_in)
	print("  - Player: ", player_nickname)
	print("  - High Score: ", player_high_score)
	print("  - Current Score: ", current_score)
