extends Node

const game = "Magic, Shield, Attack"
const debug_host = 'http://localhost:3000'
const release_host = 'http://api.magicshieldattack.com'

const SDK = preload('SDK.gd')

var host = null
var current_scene = null

var username = ""
var password = ""
var sdk = null

func set_host():
	# Why does this not work? bla
	if OS.is_debug_build():
		host = debug_host
		#host = release_host
	else:
		host = release_host

# https://docs.godotengine.org/en/3.0/getting_started/step_by_step/singletons_autoload.html
func _ready():
	set_host()
	# Scene stuff
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

	# Auth and sdk / network related
	sdk = SDK.new()
	sdk.connect("sdk_login", self, "_ack_login", [])
	add_child(sdk)
	load_game()
	#sdk.login(auth.username)

# This can be called via world.goto_scene(...), or get_node("/root/world").goto_scene("res://scene_b.tscn")
func goto_scene(path):
	# Usually called from a signal callback
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
	# Immediately free current scene
	current_scene.free()

	# Load new one
	var s = ResourceLoader.load(path)

	# Instance it here
	current_scene = s.instance()

	# Add it to active or as child of root.
	get_tree().get_root().add_child(current_scene)

	# Optional, to make it compatible with SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)

# TODO: Add deferred loading for assets
# https://docs.godotengine.org/en/3.0/tutorials/io/background_loading.html#doc-background-loading

# Handle a bunch of the login state
func load_game():
	var save_game = File.new()
	if not save_game.file_exists('user://savegame.save'):
		goto_scene("res://Login.tscn")
		return # No game to load
	save_game.open('user://savegame.save', File.READ)
	while not save_game.eof_reached():
		var line = parse_json(save_game.get_line())
		if not line or not line.has("username") or not line["username"]:
			continue
		username = line["username"]
	save_game.close()
	var auth =  {"username": username, "password": password}
	# Previous credentials were saved, yay.
	if username:
		sdk.login(username)
	else:
		goto_scene("res://Login.tscn")

	#$HUD.boot(auth.username, auth.password)
	return auth

func save_game(un):
	var save_game = File.new()
	save_game.open('user://savegame.save', File.WRITE)
	save_game.store_line(to_json({"username": un}))
	save_game.close()

func get_sdk():
	return sdk

func _ack_login(json):
	printt(json)
	printt("Someone signed in using the sdk!")
	username = json.name
	save_game(json.name)
	sdk.set_auth(json.name, "")
	goto_scene("res://Main.tscn")

# Start swipe stuff (why didn't swiper autoload work?)
#signal swipe

#var swipe_start = null
#var minimum_drag = 50

#func _unhandled_input(event):
#	if event.is_action_pressed("ui_click"):
#		var pos = get_viewport().get_mouse_position()
# 		swipe_start = pos
# 	if event.is_action_released("ui_click"):
# 		var pos = get_viewport().get_mouse_position()
# 		_calculate_swipe(pos)

# func _calculate_swipe(swipe_end):
# 	if swipe_start == null:
# 		return
# 	var swipe = swipe_end - swipe_start
# 	# Fine logic for straight up/down/left/right movement.
# 	#if abs(swipe.x) > minimum_drag:
# 	#	if swipe.x > 0:
# 	#		emit_signal("swipe", "right")
# 	#	else:
# 	#		emit_signal("swipe", "left")
# 	#if abs(swipe.y) > minimum_drag:
# 	#	if swipe.y > 0:
# 	#		emit_signal("swipe", "up")
# 	#	else:
# 	#		emit_signal("swipe", "down")
# 	# North is quadrant 1 (NE one)
# 	if abs(swipe.x) > minimum_drag and abs(swipe.y) > minimum_drag:
# 		if swipe.x > 0 and swipe.y > 0:
# 			emit_signal("swipe", "right")
# 		if swipe.x > 0 and swipe.y < 0:
# 			emit_signal("swipe", "up")
# 		if swipe.x < 0 and swipe.y > 0:
# 			emit_signal("swipe", "down")
# 		if swipe.x < 0 and swipe.y < 0:
# 			emit_signal("swipe", "left")


# # End swipe stuff (why didn't swiper autoload work?)
