extends Node2D

const SDK = preload('SDK.gd')
var sdk

#export (PackedScene) var Player
var pulse = 1.5
var pulse_buffer = 0.5 # Leave a window where we 'lock' player actions.
var seconds = pulse
var step = 0
var Unit = preload('res://Unit.tscn')
var units = []
var player_unit = null
#var show_units = false
var player_name = null
var username = ""
var password = ""
var last_attack_action = 3
var actions = ["move", "magic", "shield", "attack"]
var action_color = [
Color(0, 0, 1),
Color(1, 0.8, 0.3),
Color(0.6, 0.6, 1),
Color(1, 1, 1)
]
var action = 0

const N = 0x1
const E = 0x2
const S = 0x4
const W = 0x8

var cell_walls = {Vector2(0, -1): N, Vector2(1, 0): E,
				  Vector2(0, 1): S, Vector2(-1, 0): W}

onready var Map = $TileMap

func _ready():
	sdk = world.get_sdk()
	sdk.connect("sdk_login", self, "_ack_login", [])
	sdk.connect("sdk_world", self, "_ack_world", [])
	sdk.connect("sdk_world_map", self, "_ack_world_map", [])
	swiper.connect("swipe", self, "_ack_swipe", [])
	$HUD.connect("hud_submit", self, "_hud_submit", [])
	$HUD.hide_chat()

	#$TileMap.visible = false

	fetch_world_map()
	fetch_world()
	#fetch_world()
	var mt = Timer.new()
	mt.process_mode = 1
	mt.wait_time = .1
	mt.one_shot = false
	mt.autostart = true
	mt.connect('timeout', self, 'update_seconds', [])
	add_child(mt)
	# Just make a bunch of cells out of the gate.
	#for x in range(10):
	#	for y in range(10):
	#		Map.set_cell(x, y, 0)

func _process(delta):
	# Lock camera to a player position
	player_name = world.username

	if player_unit:
		$Camera2D.position = player_unit.position
		if player_unit.moving:
			$Dest.position = player_unit.position
			#$Light.position = player_unit.position

func xp_scale(unit, json):
	var ratio = min(2, max(0.5, json.xp / 20))
	unit.scale = Vector2(ratio, ratio)

func animation_event(unit, json):
	if not json.animation_event: return
	var ae = json.animation_event
	unit.animation_event(ae.event, ae.x, ae.y, true, json.dir)
	var mt = Timer.new()
	mt.process_mode = 1
	mt.wait_time = 0.3 # Dependence on ae_speed
	mt.one_shot = true
	mt.autostart = true
	mt.connect('timeout', self, 'call_reset_dest_cursor', [])
	add_child(mt)

func call_reset_dest_cursor():
	reset_dest_cursor(player_unit.dest_x, player_unit.dest_y)

func set_feedback(feedback):
	$HUD/Feedback.text = ''
	# Maybe just show the last 5 messages?
	var lines = 5
	var s = feedback.size()
	var f = max(0, s - lines)
	for i in range(f, s):
		$HUD/Feedback.text += feedback[i] + '\n'

func fetch_world_map():
	sdk.world_map()

func fetch_world():
	sdk.world()

func _hud_submit(chat):
	sdk.chat(chat)

func hud_submit():
	_hud_submit($HUD/Name.text)

func _ack_login(json):
	printt("Received a login event.", json)
	pass

func _ack_world_map(json):
	for x in json.size():
		var xs = json[x]
		for y in xs.size():
			var ys = xs[y]
			if ys > 0:
				Map.set_cell(x, y, ys - 1)
			else:
				$TileMap2.set_cell(x, y, 0)

func reset_dest_cursor(dx, dy):
	var destination = Map.map_to_world(Vector2(dx, dy)) + Vector2(0, 20)
	$Dest.position = destination

func update_seconds():
	seconds = max(0, seconds - .1)
	if seconds <= pulse_buffer:
		#$HUD/Seconds.text = "wait..."
		$HUD/Seconds.text = str(round(100 * seconds) / 100)
	else:
		$HUD/Seconds.text = str(round(100 * seconds) / 100)

func _ack_world(raw_json):
	seconds = pulse
	step = raw_json.step
	sdk.set_step(step)
	var json = raw_json.world
	for i in range(0, json.size()):
		var jr = json[i]

		# See if the unit already exists or not.
		# TODO: Consider using groups and group queue vs tracking.
		var existing = false
		for u in units:
			if u.unit_name == jr.name:
				#printt('FOUND A MATCH')
				existing = u

		if existing:
			existing.hp = jr.hp
			existing.hpm = jr.hpm
			existing.chat = jr.chat
			existing.tween_to(jr.x, jr.y, jr.dir, Map)
			animation_event(existing, jr)
			xp_scale(existing, jr)

			if jr.was_hit:
				existing.got_hit()

			if existing.unit_name == player_name:
				#reset_dest_cursor(jr.x, jr.y)
				player_unit = existing
				set_feedback(jr.feedback)
				#animation_event(jr)
			else:
				# Do not override what the player wants their stance to be.
				existing.set_stance(jr.stance)

		else:
			#printt('Found name: ' + jr.name)
			var m = Unit.instance()
			m.chat = jr.chat
			m.hp = jr.hp
			m.hpm = jr.hpm
			m.boot(jr.name, jr.gear)
			m.map = Map
			m.tween_to(jr.x, jr.y, jr.dir, Map)
			m.set_stance(jr.stance)
			units.push_back(m)
			$TileMap2.add_child(m)
		# else
	# for
	var mt = Timer.new()
	mt.process_mode = 1
	mt.wait_time = 0.5
	mt.one_shot = true
	mt.autostart = true
	mt.connect('timeout', self, 'fetch_world', [])
	add_child(mt)
	#fetch_world()

func generate_tile(cell):
	var cells = find_valid_tiles(cell)
	Map.set_cellv(cell, cells[randi() % cells.size()])

func find_valid_tiles(cell):
	var valid_tiles = []
	# returns all valid tiles for a given cell
	for i in range(16):
		# check target space's neighbors (if they exist)
		var is_match = false
		for n in cell_walls.keys():
			var neighbor_id = Map.get_cellv(cell + n)
			if neighbor_id >= 0:
				if (neighbor_id & cell_walls[-n])/cell_walls[-n] == (i & cell_walls[n])/cell_walls[n]:
					is_match = true
				else:
					is_match = false
					break
		if is_match and not i in valid_tiles:
			valid_tiles.append(i)
	return valid_tiles

var moves = {'N': Vector2(0, -1),
			 'S': Vector2(0, 1),
			 'E': Vector2(1, 0),
			 'W': Vector2(-1, 0)}

func dest_action(dir):
	if not player_unit: return
	#var pos = moves[dir]
	#var pos = Vector2(player_unit.dest_x, player_unit.dest_y) + moves[dir]
	# Move player unit there pre-emptively
	#player_unit.tween_to(pos.x, pos.y, dir, Map)
	#var destination = Map.map_to_world(moves[dir])
	$Dest.visible = true
	$Dest.position = player_unit.position
	var destination = Map.map_to_world(moves[dir])
	$Dest.position += destination
	$Dest.play('default')

func is_ok_to_act():
	if seconds <= pulse_buffer:
		return false
	return true

func call_action_later(cb):
	var mt = Timer.new()
	mt.process_mode = 1
	mt.wait_time = pulse_buffer
	mt.one_shot = true
	mt.autostart = true
	mt.connect('timeout', self, cb, [])
	add_child(mt)

# Ugly ugly ugly - oh well, gets the job done.
func move_N():
	sdk.move('N')
func move_S():
	sdk.move('S')
func move_W():
	sdk.move('W')
func move_E():
	sdk.move('E')

func attack_N():
	sdk.attack('N')
func attack_S():
	sdk.attack('S')
func attack_W():
	sdk.attack('W')
func attack_E():
	sdk.attack('E')

func move(dir):
	dest_action(dir)
	if is_ok_to_act():
		sdk.move(dir)
	else:
		call_action_later('move_' + dir)

func attack(dir):
	dest_action(dir)
	if is_ok_to_act():
		sdk.attack(dir)
	else:
		call_action_later('attack_' + dir)

func next_action():
	if action == 0:
		action = last_attack_action
	else:
		action = 0
	set_active_action()

func set_action(aid):
	action = aid
	if action > 0: last_attack_action = action
	set_active_action()
	sdk.set_stance(actions[action])

func set_active_action():
	var anew = actions[action]
	$Dest.modulate = action_color[action]
	$HUD/Feedback2.text = 'Changed to ' + anew
	$HUD/Feedback2.text += '\nSwipe or press WASD to use'
	if player_unit:
		player_unit.set_stance(anew)
		$Dest.position = player_unit.position

func type_text():
	if $HUD/Name.visible:
		hud_submit()
		$HUD.hide_chat()
	else:
		$HUD.show_chat()

func change_stance(stance):
	if not player_unit: return
	if "move" == stance: set_action(0)
	if "magic" == stance: set_action(1)
	if "shield" == stance: set_action(2)
	if "attack" == stance: set_action(3)

func _input(event):
	if event.is_action_pressed('scroll_up'):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
	if event.is_action_pressed('scroll_down'):
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1, 0.1)

	if event.is_action_pressed('ui_accept'):
		return type_text()

  # Every bind beyond here is disabled if we're typing text.
	if $HUD/Name.visible: return

	if event.is_action_pressed('ui_select'):
		return next_action()

	var move_action = ""
	if actions[action] == "move":
		move_action = "move"
	else:
		move_action = "attack"

	if event.is_action_pressed('move_up'):
		return call(move_action, "N")
	if event.is_action_pressed('move_down'):
		return call(move_action, "S")
	if event.is_action_pressed('move_right'):
		return call(move_action, "E")
	if event.is_action_pressed('move_left'):
		return call(move_action, "W")

	if event.is_action_pressed('ui_up'):
		return change_stance("move")
	if event.is_action_pressed('ui_down'):
		return change_stance("shield")
	if event.is_action_pressed('ui_right'):
		return change_stance("attack")
	if event.is_action_pressed('ui_left'):
		return change_stance("magic")

func _ack_swipe(s):
	var move_action = ""
	if actions[action] == "move":
		move_action = "move"
	else:
		move_action = "attack"

	if "left" == s:
		return call(move_action, "W")
	if "right" == s:
		return call(move_action, "E")
	if "up" == s:
		return call(move_action, "N")
	if "down" == s:
		return call(move_action, "S")
	#if "none" == s:
	#	return next_action()
