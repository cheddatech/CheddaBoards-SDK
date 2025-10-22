# CheddaBoards Integration for Godot 4.x
# Version 1.0.0
# 
# Setup Instructions:
# 1. Add this script to your Godot project
# 2. Go to Project Settings > Globals > AutoLoad
# 3. Add this script with Node Name: "CheddaLogin"
# 4. Use the provided HTML template for HTML5 export
#
# Example Usage:
#   CheddaLogin.login_internet_identity("PlayerName")
#   CheddaLogin.submit_score(score, streak)
#   CheddaLogin.get_leaderboard()
#
# Connect to signals in your game scripts:
#   CheddaLogin.login_success.connect(_on_login_success)
#   CheddaLogin.score_submitted.connect(_on_score_submitted)

extends Node

# ============================================================
# SIGNALS
# ============================================================

# Authentication signals
signal profile_loaded(nickname, score, streak, achievements)
signal login_success(nickname)
signal login_failed(reason)
signal logout_success()
signal auth_error(reason)
signal no_profile()

# Game action signals
signal score_submitted(score, streak)
signal score_error(reason)
signal leaderboard_loaded(entries)

# Nickname management
signal nickname_changed(new_nickname)
signal nickname_error(reason)

# ============================================================
# STATE VARIABLES
# ============================================================

var is_web = false
var cached_profile = {}
var auth_type = ""
var is_checking = false
var init_complete = false

const POLL_INTERVAL = 0.1  # Poll for JavaScript responses

# ============================================================
# INITIALIZATION
# ============================================================

func _ready():
	# Make sure this works while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	is_web = OS.has_feature("web")
	if not is_web:
		push_error("[CheddaLogin] Only works in HTML5 exports")
		return
	
	print("[CheddaLogin] Singleton initialized")
	
	# Wait for JavaScript to be ready
	await get_tree().create_timer(2.0).timeout
	
	# Check if CheddaBoards is ready
	_check_chedda_ready()

func _check_chedda_ready():
	if not is_web:
		return
		
	var ready = JavaScriptBridge.eval("window.chedda_is_ready ? window.chedda_is_ready() : false")
	
	if ready:
		print("[CheddaLogin] ✅ CheddaBoards confirmed ready")
		init_complete = true
		# Do initial auth check
		await get_tree().create_timer(0.5).timeout
		force_check_events()
	else:
		print("[CheddaLogin] CheddaBoards not ready, retrying...")
		await get_tree().create_timer(1.0).timeout
		_check_chedda_ready()

func _process(delta):
	if not is_web or not init_complete:
		return
	
	# Poll for responses from JavaScript
	_check_for_responses()

func _check_for_responses():
	if not is_web or not init_complete:
		return
		
	# Check for responses from JavaScript
	var response = JavaScriptBridge.eval("window.chedda_poll_response()")
	
	if response != null:
		print("[CheddaLogin] 📨 Got response:", response)
		_handle_response(response)

func _handle_response(response):
	if typeof(response) != TYPE_DICTIONARY:
		print("[CheddaLogin] ⚠️ Response is not a dictionary:", typeof(response))
		return
	
	var action = response.get("action", "")
	var success = response.get("success", false)
	
	print("[CheddaLogin] Handling:", action, "success:", success)
	
	match action:
		"init":
			if success:
				var authenticated = response.get("authenticated", false)
				if authenticated:
					auth_type = response.get("authType", "")
					var profile = response.get("profile", {})
					if profile and not profile.is_empty():
						print("[CheddaLogin] Init with existing profile")
						_update_cached_profile(profile)
				else:
					print("[CheddaLogin] Init - not authenticated")
					no_profile.emit()
		
		"login":
			if success:
				auth_type = response.get("authType", "")
				var profile = response.get("profile", {})
				if profile:
					print("[CheddaLogin] ✅ Login successful with profile:", profile)
					_update_cached_profile(profile)
					var nickname = profile.get("nickname", "Player")
					login_success.emit(nickname)
				else:
					print("[CheddaLogin] Login successful but no profile")
					login_success.emit("Player")
			else:
				var error = response.get("error", "Unknown error")
				print("[CheddaLogin] ❌ Login failed:", error)
				login_failed.emit(error)
		
		"submit_score":
			if success:
				print("[CheddaLogin] ✅ Score submitted")
				score_submitted.emit(0, 0)
				# Refresh profile after score submission
				refresh_profile()
			else:
				var error = response.get("error", "Unknown error")
				print("[CheddaLogin] ❌ Score submission failed:", error)
				score_error.emit(error)
		
		"leaderboard":
			if success:
				var leaderboard = response.get("data", [])
				print("[CheddaLogin] 📊 Leaderboard loaded, entries:", leaderboard.size())
				leaderboard_loaded.emit(leaderboard)
			else:
				print("[CheddaLogin] ❌ Leaderboard failed")
				leaderboard_loaded.emit([])
		
		"logout":
			if success:
				print("[CheddaLogin] ✅ Logout successful")
				cached_profile = {}
				auth_type = ""
				logout_success.emit()

func _update_cached_profile(profile):
	if typeof(profile) != TYPE_DICTIONARY or profile.is_empty():
		print("[CheddaLogin] ⚠️ Empty profile provided")
		return
		
	print("[CheddaLogin] Updating cached profile:", profile)
	cached_profile = profile
	
	# Extract fields with fallbacks
	var nickname = str(profile.get("nickname", "Player"))
	var score = int(profile.get("score", 0))
	var streak = int(profile.get("streak", 0))
	var achievements = profile.get("achievements", [])
	
	print("[CheddaLogin] Profile parsed - Name:", nickname, " Score:", score, " Streak:", streak)
	
	# Emit signal with parsed data
	profile_loaded.emit(nickname, score, streak, achievements)

# ============================================================
# PUBLIC API - AUTHENTICATION
# ============================================================

func login_internet_identity(nickname: String = ""):
	"""Login with Internet Identity - blockchain authentication"""
	if not is_web or not init_complete:
		print("[CheddaLogin] Cannot login - not ready")
		login_failed.emit("System not ready")
		return
	
	var safe_nick = nickname if nickname else "Player"
	print("[CheddaLogin] Starting II login with nickname:", safe_nick)
	
	var js_code = "window.chedda_login_ii('%s')" % safe_nick
	JavaScriptBridge.eval(js_code)

# Alias for convenience
func login_ii(nickname: String = ""):
	login_internet_identity(nickname)

func logout():
	"""Logout current user"""
	if not is_web:
		return
		
	JavaScriptBridge.eval("window.chedda_logout()")
	cached_profile = {}
	auth_type = ""
	print("[CheddaLogin] Logout initiated")

# ============================================================
# PUBLIC API - GAME ACTIONS
# ============================================================

func submit_score(score: int, streak: int):
	"""Submit a score and streak to the leaderboard"""
	if not is_web or not init_complete:
		score_error.emit("Not in web environment or not ready")
		return
		
	# Check if authenticated first
	if not is_authenticated():
		print("[CheddaLogin] ❌ Not authenticated, cannot submit score")
		score_error.emit("Not authenticated")
		return
		
	print("[CheddaLogin] Submitting score:", score, " streak:", streak)
	
	var js_code = "window.chedda_submit_score(%d, %d)" % [score, streak]
	JavaScriptBridge.eval(js_code)

func refresh_profile():
	"""Refresh the current user's profile"""
	if not is_web or not init_complete:
		print("[CheddaLogin] Cannot refresh profile - not ready")
		return
	
	print("[CheddaLogin] Refreshing profile...")
	var profile = JavaScriptBridge.eval("window.chedda_get_profile()")
	
	if profile and typeof(profile) == TYPE_DICTIONARY and not profile.is_empty():
		_update_cached_profile(profile)

func get_leaderboard(sort_by: String = "score", limit: int = 10):
	"""Get the leaderboard entries"""
	if not is_web or not init_complete:
		return
		
	print("[CheddaLogin] Requesting leaderboard...")
	
	var js_code = "window.chedda_get_leaderboard('%s', %d)" % [sort_by, limit]
	JavaScriptBridge.eval(js_code)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func is_authenticated() -> bool:
	"""Check if a user is currently authenticated"""
	if not is_web or not init_complete:
		return false
		
	var result = JavaScriptBridge.eval("window.chedda_is_auth()")
	return result == true

func get_cached_profile() -> Dictionary:
	"""Returns the cached profile dictionary"""
	return cached_profile

func get_auth_type() -> String:
	"""Get the current authentication type"""
	return auth_type

func is_ready() -> bool:
	"""Check if CheddaLogin is fully initialized"""
	return is_web and init_complete

func force_check_events():
	"""Force check for any pending events or auth status"""
	if not is_web or is_checking or not init_complete:
		print("[CheddaLogin] Cannot force check - not ready")
		return
		
	is_checking = true
	print("[CheddaLogin] 🔍 Force checking auth status...")
	
	# Check authentication status
	var is_auth = is_authenticated()
	
	if is_auth:
		print("[CheddaLogin] ✅ User is authenticated, getting profile...")
		refresh_profile()
	else:
		print("[CheddaLogin] ❌ User not authenticated")
		no_profile.emit()
	
	is_checking = false

func debug_status():
	"""Print debug information about the current state"""
	print("\n========== CheddaLogin Debug Status ==========")
	print("  - Is Web: ", is_web)
	print("  - Init Complete: ", init_complete)
	print("  - Auth Type: ", auth_type)
	print("  - Is Authenticated: ", is_authenticated())
	print("  - Cached Profile: ", cached_profile)
	print("==============================================\n")
