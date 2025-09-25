# CheddaBoards Integration for Godot
# Version 1.0.0
# 
# Setup Instructions:
# 1. Add this script to your Godot project
# 2. Go to Project Settings > AutoLoad
# 3. Add this script with Node Name: "CheddaLogin"
# 4. Use the provided HTML template for HTML5 export
# 5. Configure your game ID and auth providers in the HTML template
#
# Example Usage:
#   CheddaLogin.login_internet_identity("PlayerName")
#   CheddaLogin.submit_score(score, streak)
#   CheddaLogin.get_leaderboard()
#
# Connect to signals in your game scripts:
#   CheddaLogin.connect("login_success", self, "_on_login_success")
#   CheddaLogin.connect("score_submitted", self, "_on_score_submitted")

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
var poll_timer = null
var init_complete = false

const POLL_INTERVAL = 0.1  # Poll for JavaScript responses
const RESPONSE_KEY = "chedda_response"

# ============================================================
# INITIALIZATION
# ============================================================

func _ready():
	is_web = OS.get_name() == "HTML5"
	if not is_web:
		push_error("[CheddaLogin] Only works in HTML5 exports")
		return
	
	print("[CheddaLogin] Singleton initialized")
	
	# Start polling for responses from JavaScript
	_start_polling()
	
	# Wait for JavaScript to be ready
	yield(get_tree().create_timer(2.0), "timeout")
	
	# Check if CheddaBoards is ready
	_check_chedda_ready()

func _check_chedda_ready():
	if not is_web:
		return
		
	var js_check = """
		(function() {
			if (window.CheddaBoards && window.chedda) {
				console.log('[Godot] CheddaBoards is ready');
				return true;
			}
			console.log('[Godot] CheddaBoards not ready yet');
			return false;
		})();
	"""
	
	var ready = JavaScript.eval(js_check, true)
	
	if ready:
		print("[CheddaLogin] CheddaBoards confirmed ready")
		init_complete = true
		# Do initial auth check
		yield(get_tree().create_timer(0.5), "timeout")
		force_check_events()
	else:
		print("[CheddaLogin] CheddaBoards not ready, retrying...")
		yield(get_tree().create_timer(1.0), "timeout")
		_check_chedda_ready()

func _start_polling():
	if poll_timer:
		return
		
	poll_timer = Timer.new()
	poll_timer.wait_time = POLL_INTERVAL
	poll_timer.autostart = true
	poll_timer.connect("timeout", self, "_check_for_responses")
	add_child(poll_timer)
	print("[CheddaLogin] Started polling timer")

func _check_for_responses():
	if not is_web or not init_complete:
		return
		
	# Check for responses from JavaScript
	var response_str = JavaScript.eval("chedda_get_response()", true)
	
	if response_str and response_str != null and response_str != "null":
		# Parse JSON response
		var response = parse_json(str(response_str))
		if response:
			print("[CheddaLogin] Got response: ", response.get("action", "unknown"))
			_handle_response(response)

func _handle_response(response: Dictionary):
	var action = response.get("action", "")
	var success = response.get("success", false)
	
	print("[CheddaLogin] Handling response: ", action, " success: ", success)
	
	match action:
		"init":
			if success:
				var authenticated = response.get("authenticated", false)
				if authenticated:
					auth_type = response.get("authType", "")
					var profile = response.get("profile", {})
					if profile and not profile.empty():
						print("[CheddaLogin] Init with existing profile")
						_update_cached_profile(profile)
				else:
					print("[CheddaLogin] Init - not authenticated")
					emit_signal("no_profile")
		
		"loginInternetIdentity", "loginGoogle", "loginApple":
			if success:
				auth_type = response.get("authType", "")
				var profile = response.get("profile", {})
				if profile:
					print("[CheddaLogin] Login successful with profile:", profile)
					_update_cached_profile(profile)
					var nickname = profile.get("nickname", "Player")
					emit_signal("login_success", nickname)
				else:
					print("[CheddaLogin] Login successful but no profile")
					emit_signal("login_success", "Player")
			else:
				var error = response.get("error", "Unknown error")
				print("[CheddaLogin] Login failed:", error)
				emit_signal("login_failed", error)
		
		"submitScore":
			if success:
				var score = response.get("score", 0)
				var streak = response.get("streak", 0)
				print("[CheddaLogin] Score submitted:", score, "/", streak)
				emit_signal("score_submitted", score, streak)
				# Update cached profile if provided
				if response.has("profile"):
					_update_cached_profile(response.get("profile"))
			else:
				var error = response.get("error", "Unknown error")
				print("[CheddaLogin] Score submission failed:", error)
				emit_signal("score_error", error)
		
		"getProfile":
			if success:
				var profile = response.get("profile", {})
				if profile and not profile.empty():
					print("[CheddaLogin] Profile fetched:", profile)
					_update_cached_profile(profile)
				else:
					print("[CheddaLogin] Empty profile returned")
					emit_signal("no_profile")
			else:
				print("[CheddaLogin] Profile fetch failed")
				emit_signal("no_profile")
		
		"getLeaderboard":
			if success:
				var leaderboard = response.get("leaderboard", [])
				print("[CheddaLogin] Leaderboard loaded, entries:", leaderboard.size())
				emit_signal("leaderboard_loaded", leaderboard)
		
		"logout":
			if success:
				print("[CheddaLogin] Logout successful")
				cached_profile = {}
				auth_type = ""
				emit_signal("logout_success")

func _update_cached_profile(profile: Dictionary):
	if profile.empty():
		print("[CheddaLogin] Warning: Empty profile provided to update")
		return
		
	print("[CheddaLogin] Updating cached profile:", profile)
	cached_profile = profile
	
	# Extract fields with fallbacks
	var nickname = str(profile.get("nickname", profile.get("username", "Player")))
	var score = int(profile.get("score", profile.get("highScore", 0)))
	var streak = int(profile.get("streak", profile.get("bestStreak", 0)))
	var achievements = profile.get("achievements", [])
	
	print("[CheddaLogin] Profile parsed - Name:", nickname, " Score:", score, " Streak:", streak)
	
	# Emit signal with parsed data
	emit_signal("profile_loaded", nickname, score, streak, achievements)

# ============================================================
# PUBLIC API - AUTHENTICATION
# ============================================================

func login_internet_identity(nickname = null):
	"""Login with Internet Identity - blockchain authentication"""
	if not is_web or not init_complete:
		print("[CheddaLogin] Cannot login - not ready")
		emit_signal("login_failed", "System not ready")
		return
		
	var nick = str(nickname) if nickname else ""
	# Escape quotes in nickname
	nick = nick.replace("'", "\\'").replace('"', '\\"')
	
	var js_code = "chedda_login_ii('%s')" % nick
	JavaScript.eval(js_code, true)
	print("[CheddaLogin] II login initiated with nickname:", nick)

# Alias for convenience
func login_ii(nickname = null):
	login_internet_identity(nickname)

func login_google(credential = null):
	"""Login with Google OAuth"""
	if not is_web or not init_complete:
		print("[CheddaLogin] Cannot login - not ready")
		emit_signal("login_failed", "System not ready")
		return
		
	var js_code = "chedda_login_google()"
	JavaScript.eval(js_code, true)
	print("[CheddaLogin] Google login initiated")

func login_apple(token = null):
	"""Login with Apple Sign-In"""
	if not is_web or not init_complete:
		print("[CheddaLogin] Cannot login - not ready")
		emit_signal("login_failed", "System not ready")
		return
		
	var js_code = "chedda_login_apple()"
	JavaScript.eval(js_code, true)
	print("[CheddaLogin] Apple login initiated")

func logout():
	"""Logout current user"""
	if not is_web:
		return
		
	JavaScript.eval("chedda_logout()", true)
	cached_profile = {}
	auth_type = ""
	print("[CheddaLogin] Logout initiated")

# ============================================================
# PUBLIC API - GAME ACTIONS
# ============================================================

func submit_score(score: int, streak: int):
	"""Submit a score and streak to the leaderboard"""
	if not is_web or not init_complete:
		emit_signal("score_error", "Not in web environment or not ready")
		return
		
	# Check if authenticated first
	if not is_authenticated():
		print("[CheddaLogin] Not authenticated, cannot submit score")
		emit_signal("score_error", "Not authenticated")
		return
		
	var js_code = "chedda_submit(%d, %d)" % [score, streak]
	JavaScript.eval(js_code, true)
	print("[CheddaLogin] Score submission: %d, streak: %d" % [score, streak])

func refresh_profile():
	"""Refresh the current user's profile"""
	if not is_web or not init_complete:
		print("[CheddaLogin] Cannot refresh profile - not ready")
		return
		
	JavaScript.eval("chedda_profile()", true)
	print("[CheddaLogin] Profile refresh requested")

func get_leaderboard(sort_by: String = "score", limit: int = 100):
	"""Get the leaderboard entries"""
	if not is_web or not init_complete:
		return
		
	JavaScript.eval("chedda_leaderboard()", true)
	print("[CheddaLogin] Leaderboard requested")

func change_nickname(new_nickname: String = ""):
	"""Change the current user's nickname (not yet implemented)"""
	if not is_web or not init_complete:
		emit_signal("nickname_error", "System not ready")
		return
		
	# TODO: Implement nickname change via CheddaBoards API
	print("[CheddaLogin] Nickname change requested: ", new_nickname)
	emit_signal("nickname_error", "Nickname change not yet implemented")

func track_event(event_type: String, metadata: Dictionary = {}):
	"""Track a custom analytics event"""
	if not is_web or not init_complete:
		return
		
	# Convert metadata to JavaScript object
	var meta_str = "{"
	var first = true
	for key in metadata:
		if not first:
			meta_str += ","
		meta_str += "'%s':'%s'" % [key, str(metadata[key])]
		first = false
	meta_str += "}"
	
	var js_code = """
		if (window.chedda && window.chedda.trackEvent) {
			window.chedda.trackEvent('%s', %s);
		}
	""" % [event_type, meta_str]
	
	JavaScript.eval(js_code, true)
	print("[CheddaLogin] Event tracked: ", event_type)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func is_authenticated() -> bool:
	"""Check if a user is currently authenticated"""
	if not is_web or not init_complete:
		return false
		
	var result = JavaScript.eval("chedda_is_auth()", true)
	return result == true

func get_cached_profile() -> Dictionary:
	"""Returns the cached profile dictionary"""
	return cached_profile

func get_cached_profile_direct() -> Dictionary:
	"""Get profile directly from JavaScript"""
	if not is_web or not init_complete:
		return {}
		
	var profile_str = JavaScript.eval("chedda_get_profile()", true)
	if profile_str and profile_str != null and profile_str != "null":
		var profile = parse_json(str(profile_str))
		if profile:
			return profile
	return {}

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
	print("[CheddaLogin] Force checking auth status...")
	
	# Check authentication status
	var is_auth = is_authenticated()
	
	if is_auth:
		print("[CheddaLogin] User is authenticated, getting profile...")
		# Try to get profile from JavaScript directly first
		var js_profile = get_cached_profile_direct()
		if js_profile and not js_profile.empty():
			print("[CheddaLogin] Got profile from JS:", js_profile)
			_update_cached_profile(js_profile)
		else:
			print("[CheddaLogin] No JS profile, requesting refresh")
			refresh_profile()
	else:
		print("[CheddaLogin] User not authenticated")
		emit_signal("no_profile")
	
	is_checking = false

func debug_status():
	"""Print debug information about the current state"""
	print("\n========== CheddaLogin Debug Status ==========")
	print("  - Is Web: ", is_web)
	print("  - Init Complete: ", init_complete)
	print("  - Auth Type: ", auth_type)
	print("  - Is Authenticated: ", is_authenticated())
	print("  - Cached Profile: ", cached_profile)
	
	if is_web:
		var js_status = JavaScript.eval("""
			(function() {
				var status = {
					cheddaReady: window.CheddaBoards !== undefined,
					cheddaInstance: window.chedda !== undefined,
					isAuth: window.chedda_is_auth ? window.chedda_is_auth() : false,
					hasProfile: window.chedda_get_profile ? window.chedda_get_profile() : null
				};
				console.log('[Debug Status]', status);
				return status;
			})();
		""", true)
		print("  - JS Status: ", js_status)
	print("==============================================\n")

func _exit_tree():
	"""Cleanup when the node is removed"""
	if poll_timer:
		poll_timer.stop()
		poll_timer.queue_free()
