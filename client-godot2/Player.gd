extends Area2D

const SDK = preload('SDK.gd')
var sdk

const N = 0x1
const E = 0x2
const S = 0x4
const W = 0x8

const HEAD = 0x1

var unit_name = 'You'
var animations = {N: 'n',
				  S: 's',
				  E: 'e',
				  W: 'w'}
var moves = {N: Vector2(0, -1),
			 S: Vector2(0, 1),
			 E: Vector2(1, 0),
			 W: Vector2(-1, 0)}
var gear = []
var map = null
var map_pos = Vector2()
var speed = 1
var moving = false

var dest_x = 0
var dest_y = 0

var flip_h = false
var anim = 'knight'
var back = false

func can_move(dir):
	var t = map.get_cellv(map_pos)
	if t & dir:
		return false
	else:
		return true

func _input(event):
	if event.is_action_pressed('scroll_up'):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
	if event.is_action_pressed('scroll_down'):
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1, 0.1)

	if moving:
		return
	if event.is_action_pressed('ui_up'):
		move(N)
		flip_h = false
		#modulate = Color(0.1, 0.1, 0.1)
		anim = 'knight-back'
		back = true
		sdk.move("N")
	if event.is_action_pressed('ui_down'):
		move(S)
		flip_h = false
		#modulate = Color(1, 1, 1)
		anim = 'knight'
		back = false
		sdk.move("S")
	if event.is_action_pressed('ui_right'):
		move(E)
		flip_h = true
		#modulate = Color(1, 1, 1)
		anim = 'knight'
		back = false
		sdk.move("E")
	if event.is_action_pressed('ui_left'):
		move(W)
		flip_h = true
		#modulate = Color(0.1, 0.1, 0.1)
		anim = 'knight-back'
		back = true
		sdk.move("W")

func set_sdk(username, password):
	sdk = SDK.new(username, password)
	add_child(sdk)

func boot(_unit_name, stubs):
	unit_name = _unit_name
	load_gear(stubs)

func load_gear(stubs):
	for stub in stubs:
		var res1 = load('res://assets/IsoUnits/' + stub.default.png + '-0.png')
		var res2 = load('res://assets/IsoUnits/' + stub.default.png + '-1.png')
		var res3 = load('res://assets/IsoUnits/' + stub.back.png + '-0.png')
		var res4 = load('res://assets/IsoUnits/' + stub.back.png + '-1.png')
		var f = SpriteFrames.new()
		f.animations = [
		{'frames': [res3, res4], 'loop': true, 'name': 'back', 'speed': 5.0},
		{'frames': [res1, res2], 'loop': true, 'name': 'default', 'speed': 5.0}
		]
		var s = AnimatedSprite.new()
		s.position = Vector2(0, -25)
		s.frames = f
		s.animation = 'default'
		s.play('default')
		var c = stub.default.color
		s.modulate = Color(c.r, c.g, c.b, 1)
		add_child(s)
		gear.push_back(s)
		#printt('Added the gear')
	# End for loop

func _ready():
	sdk = world.get_sdk()

func mock_gear():
	# Loop over and add the gear
	var stubs = [{'back': '32b-red-scarf', 'default': '32-red-scarf-front'}]
	for stub in stubs:
		var res1 = load('res://assets/IsoUnits/' + stub.default + '-0.png')
		var res2 = load('res://assets/IsoUnits/' + stub.default + '-1.png')
		var res3 = load('res://assets/IsoUnits/' + stub.back + '-0.png')
		var res4 = load('res://assets/IsoUnits/' + stub.back + '-1.png')
		var f = SpriteFrames.new()
		f.animations = [
		{'frames': [res3, res4], 'loop': true, 'name': 'back', 'speed': 5.0},
		{'frames': [res1, res2], 'loop': true, 'name': 'default', 'speed': 5.0}
		]
		var s = AnimatedSprite.new()
		s.position = Vector2(0, -25)
		s.frames = f
		s.animation = 'default'
		s.play('default')
		add_child(s)
		gear.push_back(s)
		#printt('Added the gear')
	# End for loop

func face(facing):
	if facing == "N" or facing == "S":
		flip_h = false
	else:
		flip_h = true

	if facing == "N" or facing == "W":
		anim = 'knight-back'
		back = true
	else:
		anim = 'knight'
		back = false

var was_tweened = false
# I guess just do this once for now, to sync up on map.
# TODO: Maybe have to handle if player is ever out of sync (ugh)
func tween_to(x, y, facing, map):
	if was_tweened: return
	was_tweened = true

	face(facing)
	dest_x = x
	dest_y = y
	#printt('tween time')
	#printt(x)
	#printt(y)
	#printt(map_pos.x)
	#printt(map_pos.y)
	map_pos = Vector2(dest_x, dest_y)
	var destination = map.map_to_world(map_pos) + Vector2(0, 20)
	$Tween.interpolate_property(self, 'position', position, destination, speed,
								Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()

func _process(delta):
	if moving:
		$AnimatedSprite2.set_flip_h(flip_h)
		$AnimatedSprite2.play(anim)

		for g in gear:
			g.set_flip_h(flip_h)
			if back:
				g.play('back')
			else:
				g.play('default')
		# End for
	else:
		for g in gear:
			g.stop()

		$AnimatedSprite2.set_flip_h(flip_h)
		$AnimatedSprite2.stop()

func move(dir):
	if not can_move(dir):
		return
	moving = true
	#$AnimatedSprite.play(animations[dir])
	map_pos += moves[dir]
	# Go to an absolute position
	# map_pos = Vector2(5, 5)
	if map.get_cellv(map_pos) == -1:
		get_parent().generate_tile(map_pos)
	var destination = map.map_to_world(map_pos) + Vector2(0, 20)
	$Tween.interpolate_property(self, 'position', position, destination, speed,
								Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()
	#printt('Debug info for truck')
	#printt(get_position().x)
	#printt(get_position().y)
	#printt(destination)
	#printt(map_pos)
	#printt(map_pos.x)
	#printt(map_pos.y)

func _on_Tween_tween_completed(object, key):
	moving = false
