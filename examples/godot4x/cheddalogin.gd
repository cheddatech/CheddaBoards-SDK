# CheddaBoards.gd
# Generic CheddaBoards integration for Godot 4.x
# Add to Project Settings > Autoload as "CheddaBoards"

extends Node

## Emitted when a user successfully logs in
signal login_success(nickname: String)
## Emitted when login fails
signal login_failed(reason: String)
## Emitted when user logs out
signal logout_success()
## Emitted when profile data is loaded
signal profile_loaded(nickname: String, score: int, streak: int, achievements: Array) # use Array[Dictionary] if you want stricter typing
## Emitted when no profile is available
signal no_profile()
## Emitted when nickname is changed
signal nickname_changed(new_nickname: String)
## Emitted when nickname change fails
signal nickname_error(reason: String)
## Emitted when score is successfully submitted
signal score_submitted(score: int, streak: int)
## Emitted when score submission fails
signal score_error(reason: String)
## Emitted when leaderboard data is loaded
signal leaderboard_loaded(entries: Array)
## Emitted when player rank is loaded
signal player_rank_loaded(rank: int, score: int, streak: int, total_players: int)
## Emitted when rank fetch fails
signal rank_error(reason: String)
## Emitted for general authentication errors
signal auth_error(reason: String)

# Configuration
var _is_web: bool = false
var _init_complete: bool = false
var _auth_type: String = ""
var _cached_profile: Dictionary = {}

# Performance optimization flags
var _is_checking_auth: bool = false
var _is_refreshing_profile: bool = false
var _is_submitting_score: bool = false
var _last_response_check: float = 0.0
var _profile_refresh_cooldown: float = 0.0
var _submission_timeout_timer: SceneTreeTimer = null

# Polling configuration
var _poll_timer: Timer = null
const POLL_INTERVAL: float = 0.1
const MIN_RESPONSE_CHECK_INTERVAL: float = 0.3
const PROFILE_REFRESH_COOLDOWN: float = 2.0
const SUBMISSION_TIMEOUT: float = 5.0

func _ready() -> void:
	_is_web = OS.get_name() == "Web"

	if not _is_web:
		push_error("[CheddaBoards] This plugin only works in HTML5/Web exports")
		return

	print("[CheddaBoards] Initializing...")
	_start_polling()
	_check_chedda_ready()


func _check_chedda_ready() -> void:
	"""Check if CheddaBoards SDK is loaded and ready"""
	if not _is_web or _is_checking_auth:
		return

	_is_checking_auth = true

	var js_check: String = """
		(function() {
			if (window.CheddaBoards && window.chedda) {
				console.log('[Godot] CheddaBoards is ready');
				return true;
			}
			console.log('[Godot] CheddaBoards not ready yet');
			return false;
		})();
	"""

	var ready: Variant = JavaScriptBridge.eval(js_check, true)

	if ready == true:
		print("[CheddaBoards] SDK confirmed ready")
		_init_complete = true
		_is_checking_auth = false
		force_check_events()
	else:
		print("[CheddaBoards] SDK not ready, retrying...")
		_is_checking_auth = false
		await get_tree().create_timer(0.1).timeout
		_check_chedda_ready()


func _start_polling() -> void:
	"""Start polling for responses from JavaScript"""
	if _poll_timer:
		return

	_poll_timer = Timer.new()
	_poll_timer.wait_time = POLL_INTERVAL
	_poll_timer.autostart = true
	_poll_timer.timeout.connect(_check_for_responses)
	add_child(_poll_timer)
	print("[CheddaBoards] Started polling timer (interval: %s)" % POLL_INTERVAL)


func _check_for_responses() -> void:
	"""Poll JavaScript for queued responses"""
	if not _is_web or not _init_complete:
		return

	# Rate limiting
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - _last_response_check < MIN_RESPONSE_CHECK_INTERVAL:
		return

	_last_response_check = current_time

	# Get response from JavaScript
	var resp: Variant = JavaScriptBridge.eval("chedda_get_response()", true)
	if resp == null:
		return
	var response_str: String = str(resp)
	if response_str == "" or response_str.to_lower() == "null":
		return

	var json := JSON.new()
	var parse_result: int = json.parse(response_str)
	if parse_result == OK:
		var response: Dictionary = json.data
		# Optional: print minimal info
		# print("[CheddaBoards] Got response: ", response.get("action", "unknown"))
		_handle_response(response)


func _handle_response(response: Dictionary) -> void:
	"""Process responses from JavaScript bridge"""
	var action: String = str(response.get("action", ""))
	var success: bool = bool(response.get("success", false))

	# print("[CheddaBoards] Handling response: ", action, " success: ", success)

	match action:
		"init":
			if success:
				var authenticated: bool = bool(response.get("authenticated", false))
				if authenticated:
					_auth_type = str(response.get("authType", ""))
					var profile: Dictionary = response.get("profile", {})
					if profile and not profile.is_empty():
						# print("[CheddaBoards] Init with existing profile")
						_update_cached_profile(profile)
				else:
					# print("[CheddaBoards] Init - not authenticated")
					no_profile.emit()

		"loginGoogle", "loginApple", "loginCheddaId", "loginInternetIdentity", "loginAnonymous":
			if success:
				_auth_type = str(response.get("authType", ""))
				var profile2: Dictionary = response.get("profile", {})
				if profile2 and not profile2.is_empty():
					# print("[CheddaBoards] Login successful with profile")
					_update_cached_profile(profile2)
					var nickname: String = str(profile2.get("nickname", "Player"))
					login_success.emit(nickname)
				else:
					# print("[CheddaBoards] Login successful but no profile")
					login_success.emit("Player")
			else:
				var error: String = str(response.get("error", "Unknown error"))
				# print("[CheddaBoards] Login failed:", error)
				login_failed.emit(error)

		"submitScore":
			_clear_submission_flag()
			if success:
				var scored: int = int(response.get("score", 0))
				var streakd: int = int(response.get("streak", 0))
				# print("[CheddaBoards] ✅ Score submitted:", scored, "/", streakd)
				score_submitted.emit(scored, streakd)
				if response.has("profile"):
					var p: Dictionary = response.get("profile")
					_update_cached_profile(p)
			else:
				var error2: String = str(response.get("error", "Unknown error"))
				# print("[CheddaBoards] ❌ Score submission failed:", error2)
				score_error.emit(error2)

		"getProfile":
			_is_refreshing_profile = false
			if success:
				var profile3: Dictionary = response.get("profile", {})
				if profile3 and not profile3.is_empty():
					# print("[CheddaBoards] Profile fetched")
					_update_cached_profile(profile3)
				else:
					# print("[CheddaBoards] Empty profile returned")
					no_profile.emit()
			else:
				# print("[CheddaBoards] Profile fetch failed")
				no_profile.emit()

		"getLeaderboard":
			if success:
				var leaderboard: Array = response.get("leaderboard", [])
				# print("[CheddaBoards] Leaderboard loaded, entries:", leaderboard.size())
				leaderboard_loaded.emit(leaderboard)

		"getPlayerRank":
			if success:
				var rank: int = int(response.get("rank", 0))
				var score_val: int = int(response.get("score", 0))
				var streak_val: int = int(response.get("streak", 0))
				var total: int = int(response.get("totalPlayers", 0))
				player_rank_loaded.emit(rank, score_val, streak_val, total)
			else:
				var rerr: String = str(response.get("error", "Unknown error"))
				rank_error.emit(rerr)

		"logout":
			if success:
				# print("[CheddaBoards] Logout successful")
				_cached_profile = {}
				_auth_type = ""
				logout_success.emit()

		"changeNickname":
			if success:
				var new_nickname: String = str(response.get("nickname", ""))
				# print("[CheddaBoards] Nickname changed to:", new_nickname)
				if not _cached_profile.is_empty():
					_cached_profile["nickname"] = new_nickname
				nickname_changed.emit(new_nickname)
			elif bool(response.get("cancelled", false)):
				# print("[CheddaBoards] Nickname change cancelled")
				pass
			else:
				var nerr: String = str(response.get("error", "Unknown error"))
				# print("[CheddaBoards] Nickname change failed:", nerr)
				nickname_error.emit(nerr)


func _update_cached_profile(profile: Dictionary) -> void:
	"""Update the cached profile and emit signal"""
	if profile.is_empty():
		# print("[CheddaBoards] Warning: Empty profile provided")
		return

	# print("[CheddaBoards] Updating cached profile")
	_cached_profile = profile

	var nickname: String = str(profile.get("nickname", profile.get("username", "Player")))
	var score: int = int(profile.get("score", profile.get("highScore", 0)))
	var streak: int = int(profile.get("streak", profile.get("bestStreak", 0)))
	var achievements: Array = profile.get("achievements", [])

	profile_loaded.emit(nickname, score, streak, achievements)


func _clear_submission_flag() -> void:
	"""Clear submission flag and cancel timeout timer"""
	if _submission_timeout_timer:
		_submission_timeout_timer = null
	_is_submitting_score = false


func _reset_submission_flag_timeout() -> void:
	"""Timeout handler to force reset submission flag"""
	if _is_submitting_score:
		print("[CheddaBoards] ⚠️ Force resetting submission flag (timeout)")
		_is_submitting_score = false
		_submission_timeout_timer = null
		score_error.emit("Submission timeout")


# ============================================================
# PUBLIC API - Authentication
# ============================================================

## Log in with CheddaID / Internet Identity
func login_chedda_id(nickname: String = "") -> void:
	if not _is_web or not _init_complete:
		return

	var safe_nickname: String = nickname.replace("'", "\\'").replace('"', '\\"')
	JavaScriptBridge.eval("chedda_login_ii('%s')" % safe_nickname, true)
	print("[CheddaBoards] CheddaID login requested with nickname:", nickname)


## Log in with Google
func login_google() -> void:
	if not _is_web or not _init_complete:
		return

	JavaScriptBridge.eval("chedda_login_google()", true)
	print("[CheddaBoards] Google login requested")


## Log in with Apple
func login_apple() -> void:
	if not _is_web or not _init_complete:
		return

	JavaScriptBridge.eval("chedda_login_apple()", true)
	print("[CheddaBoards] Apple login requested")


## Log in anonymously
func login_anonymous() -> void:
	if not _is_web or not _init_complete:
		return

	JavaScriptBridge.eval("chedda_login_anonymous()", true)
	print("[CheddaBoards] Anonymous login requested")


## Log out the current user
func logout() -> void:
	if not _is_web or not _init_complete:
		return

	JavaScriptBridge.eval("chedda_logout()", true)
	print("[CheddaBoards] Logout requested")


## Check if user is authenticated
func is_authenticated() -> bool:
	if not _is_web or not _init_complete:
		return false

	var result: Variant = JavaScriptBridge.eval("chedda_is_auth()", true)
	return result == true


## Get the authentication type (google, apple, cheddaId, anonymous)
func get_auth_type() -> String:
	return _auth_type


# ============================================================
# PUBLIC API - Profile Management
# ============================================================

## Refresh profile data from server
func refresh_profile() -> void:
	if not _is_web or not _init_complete:
		return

	if _is_refreshing_profile:
		print("[CheddaBoards] Profile refresh already in progress")
		return

	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - _profile_refresh_cooldown < PROFILE_REFRESH_COOLDOWN:
		print("[CheddaBoards] Profile refresh on cooldown")
		return

	_is_refreshing_profile = true
	_profile_refresh_cooldown = current_time

	JavaScriptBridge.eval("chedda_refresh_profile()", true)
	print("[CheddaBoards] Profile refresh requested")


## Get the cached profile data
func get_cached_profile() -> Dictionary:
	return _cached_profile


## Get profile data directly from JavaScript
func get_profile_direct() -> Dictionary:
	if not _is_web or not _init_complete:
		return {}

	var pvar: Variant = JavaScriptBridge.eval("chedda_get_profile()", true)
	if pvar == null:
		return {}

	var profile_str: String = str(pvar)
	if profile_str == "" or profile_str.to_lower() == "null":
		return {}

	var json := JSON.new()
	var parse_result: int = json.parse(profile_str)
	if parse_result == OK:
		return json.data
	return {}


## Open nickname change prompt
func change_nickname() -> void:
	if not _is_web or not _init_complete:
		return

	JavaScriptBridge.eval("chedda_change_nickname_prompt()", true)
	print("[CheddaBoards] Nickname change requested")


# ============================================================
# PUBLIC API - Scores & Leaderboards
# ============================================================

## Submit score and streak to leaderboard
func submit_score(score: int, streak: int) -> void:
	if not _is_web or not _init_complete:
		score_error.emit("Not in web environment or not ready")
		return

	if not is_authenticated():
		print("[CheddaBoards] Not authenticated, cannot submit")
		score_error.emit("Not authenticated")
		return

	if _is_submitting_score:
		print("[CheddaBoards] Score submission already in progress")
		return

	_is_submitting_score = true

	# Set timeout to auto-reset flag
	_submission_timeout_timer = get_tree().create_timer(SUBMISSION_TIMEOUT)
	_submission_timeout_timer.timeout.connect(_reset_submission_flag_timeout)

	var js_code: String = "chedda_submit_score(%d, %d)" % [score, streak]
	JavaScriptBridge.eval(js_code, true)
	print("[CheddaBoards] Score submission: %d, %d" % [score, streak])


## Get leaderboard data
func get_leaderboard(sort_by: String = "score", limit: int = 10) -> void:
	if not _is_web or not _init_complete:
		return

	var js_code: String = "chedda_get_leaderboard('%s', %d)" % [sort_by, limit]
	JavaScriptBridge.eval(js_code, true)
	print("[CheddaBoards] Leaderboard requested: ", sort_by)


## Get player's rank
func get_player_rank(sort_by: String = "score") -> void:
	if not _is_web or not _init_complete:
		return

	var js_code: String = "chedda_get_player_rank('%s')" % sort_by
	JavaScriptBridge.eval(js_code, true)
	print("[CheddaBoards] Player rank requested: ", sort_by)


# ============================================================
# PUBLIC API - Achievements
# ============================================================

## Unlock a single achievement
func unlock_achievement(achievement_id: String, achievement_name: String, achievement_desc: String) -> void:
	if not _is_web or not _init_complete:
		return

	var safe_id: String = achievement_id.replace("'", "\\'").replace('"', '\\"')
	var safe_name: String = achievement_name.replace("'", "\\'").replace('"', '\\"')
	var safe_desc: String = achievement_desc.replace("'", "\\'").replace('"', '\\"')

	var js_code: String = """
		(function() {
			try {
				if (window.chedda && window.chedda.unlockAchievement) {
					window.chedda.unlockAchievement('%s', '%s', '%s')
						.then(result => console.log('[CheddaBoards] Achievement unlocked:', result))
						.catch(error => console.error('[CheddaBoards] Achievement error:', error));
				}
			} catch(e) {
				console.error('[CheddaBoards] Achievement unlock failed:', e);
			}
		})();
	""" % [safe_id, safe_name, safe_desc]

	JavaScriptBridge.eval(js_code, true)
	print("[CheddaBoards] Achievement unlock requested: ", achievement_name)


## Submit score with achievements in one call
func submit_score_with_achievements(score: int, streak: int, achievements: Array) -> void:
	if not _is_web or not _init_complete:
		score_error.emit("Not in web environment or not ready")
		return

	if not is_authenticated():
		print("[CheddaBoards] Not authenticated, cannot submit")
		score_error.emit("Not authenticated")
		return

	if _is_submitting_score:
		print("[CheddaBoards] Score submission already in progress")
		return

	_is_submitting_score = true

	_submission_timeout_timer = get_tree().create_timer(SUBMISSION_TIMEOUT)
	_submission_timeout_timer.timeout.connect(_reset_submission_flag_timeout)

	var achievements_json: String = JSON.stringify(achievements)

	var js_code: String = """
		(function() {
			try {
				var achievements = %s;
				if (window.chedda && window.chedda.submitScoreWithAchievements) {
					window.chedda.submitScoreWithAchievements(%d, %d, achievements);
					console.log('[CheddaBoards] Score + achievements submitted');
				} else if (window.chedda && window.chedda.submitScore) {
					window.chedda.submitScore(%d, %d);
					if (window.chedda.syncAchievements) {
						window.chedda.syncAchievements(achievements);
					}
					console.log('[CheddaBoards] Score and achievements submitted separately');
				}
			} catch(e) {
				console.error('[CheddaBoards] Error submitting data:', e);
			}
		})();
	""" % [achievements_json, score, streak, score, streak]

	JavaScriptBridge.eval(js_code, true)
	print("[CheddaBoards] Score + achievements: %d, %d, %d achievements" % [score, streak, achievements.size()])


# ============================================================
# PUBLIC API - Analytics
# ============================================================

## Track a custom event
func track_event(event_type: String, metadata: Dictionary = {}) -> void:
	if not _is_web or not _init_complete:
		return

	var meta_str: String = "{"
	var first: bool = true
	for key in metadata.keys():
		var key_str: String = str(key)
		if not first:
			meta_str += ","
		meta_str += "'%s':'%s'" % [key_str, str(metadata[key])]
		first = false
	meta_str += "}"

	var js_code: String = """
		if (window.chedda && window.chedda.trackEvent) {
			window.chedda.trackEvent('%s', %s);
		}
	""" % [event_type, meta_str]

	JavaScriptBridge.eval(js_code, true)
	print("[CheddaBoards] Event tracked: ", event_type)


# ============================================================
# HELPER FUNCTIONS
# ============================================================

## Check if CheddaBoards is fully initialized
func is_ready() -> bool:
	return _is_web and _init_complete


## Force check for pending events or auth status
func force_check_events() -> void:
	if not _is_web or _is_checking_auth or not _init_complete:
		print("[CheddaBoards] Cannot force check - not ready")
		return

	_is_checking_auth = true
	print("[CheddaBoards] Force checking auth status...")

	var is_auth: bool = is_authenticated()

	if is_auth:
		print("[CheddaBoards] User is authenticated, getting profile...")
		var js_profile: Dictionary = get_profile_direct()
		if js_profile and not js_profile.is_empty():
			print("[CheddaBoards] Got profile from JS")
			_update_cached_profile(js_profile)
		else:
			print("[CheddaBoards] No JS profile, requesting refresh")
			refresh_profile()
	else:
		print("[CheddaBoards] User not authenticated")
		no_profile.emit()

	_is_checking_auth = false


## Print debug information to console
func debug_status() -> void:
	print("\n========== CheddaBoards Debug Status ==========")
	print(" - Is Web: ", _is_web)
	print(" - Init Complete: ", _init_complete)
	print(" - Auth Type: ", _auth_type)
	print(" - Is Authenticated: ", is_authenticated())
	print(" - Cached Profile: ", _cached_profile)
	print(" - Is Checking Auth: ", _is_checking_auth)
	print(" - Is Refreshing Profile: ", _is_refreshing_profile)
	print(" - Is Submitting Score: ", _is_submitting_score)
	print(" - Has Timeout Timer: ", _submission_timeout_timer != null)

	if _is_web:
		var js_status: String = str(JavaScriptBridge.eval("""
			(function() {
				var status = {
					cheddaReady: window.CheddaBoards !== undefined,
					cheddaInstance: window.chedda !== undefined,
					isAuth: window.chedda_is_auth ? window.chedda_is_auth() : false,
					hasProfile: window.chedda_get_profile ? window.chedda_get_profile() : null
				};
				return JSON.stringify(status);
			})();
		""", true))
		print(" - JS Status: ", js_status)
	print("==============================================\n")


func _exit_tree() -> void:
	if _poll_timer:
		_poll_timer.stop()
		_poll_timer.queue_free()
	if _submission_timeout_timer:
		_submission_timeout_timer = null
