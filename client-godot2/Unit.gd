extends Area2D

#var UnitHud = preload('res://UnitHud.tscn')

const N = 0x1
const E = 0x2
const S = 0x4
const W = 0x8

const HEAD = 0x1

var chat = ''
var unit_name = ''
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
var speed = 0.5
var moving = false

var dest_x = 0
var dest_y = 0
var hp = 50
var hpm = 50

var flip_h = false
var anim = 'knight'
var back = false

func _input(event):
	pass

func boot(_unit_name, stubs):
	unit_name = _unit_name
	get_node('Name').text = unit_name
	#$Name.text = unit_name
	load_gear(stubs)

	# Loop over and add the gear
	#var stubs = [{'back': '32b-red-scarf', 'default': '32-red-scarf-front'}]

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
		s.set_pos(Vector2(0, -20))
		s.frames = f
		s.animation = 'default'
		s.play('default')
		var c = stub.default.color
		s.modulate = Color(c.r, c.g, c.b)
		add_child(s)
		gear.push_back(s)
		#printt('Added the gear')
	# End for loop

func _ready():
	set_process(true)

func face(facing):
	printt('FACING:')
	printt(facing)
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

func fast_position(x, y, facing, map):
	face(facing)
	dest_x = x
	dest_y = y
	map_pos = Vector2(dest_x, dest_y)
	var destination = map.map_to_world(map_pos) + Vector2(0, 20)
	# gd3
	#position = destination
	# gd2
	set_pos(destination)

func tween_to(dx, dy, facing, map):
	#if moving: return
	if dx == dest_x and dy == dest_y: return
	moving = true
	face(facing)
	dest_x = dx
	dest_y = dy
	map_pos = Vector2(dest_x, dest_y)
	# gd3
	#var pos = position
	# gd2
	var pos = get_pos()
	var destination = map.map_to_world(map_pos) + Vector2(0, 20)
	get_node('Tween').interpolate_property(self, 'transform/pos', pos, destination, speed,
								Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	get_node('Tween').start()

func _is_dead():
	#rotation = deg2rad(90)
	set_rot(deg2rad(90))

func _is_alive():
	#rotation = deg2rad(0)
	set_rot(deg2rad(0))

func _process(delta):
	if hp < 1:
		_is_dead()
	if hp > 0:
		_is_alive()

	get_node('Chat').text = chat
	var hp_format = "%s / %s"
	get_node('HP').text = hp_format % [hp, hpm]
	if moving:
		get_node('AnimatedSprite2').set_flip_h(flip_h)
		get_node('AnimatedSprite2').play(anim)

		#$AnimatedSprite3.modulate = Color(1, 1, .1)
		#$AnimatedSprite4.modulate = Color(0, .1, 1)

		for g in gear:
			g.set_flip_h(flip_h)
			if back:
				g.play('back')
			else:
				g.play('default')
		# End for

		#$AnimatedSprite4.play('default')
		#$AnimatedSprite5.play('default')
		#$AnimatedSprite4.set_flip_h(flip_h)
		#$AnimatedSprite5.set_flip_h(flip_h)
	else:
		for g in gear:
			g.stop()

		get_node('AnimatedSprite2').set_flip_h(flip_h)
		get_node('AnimatedSprite2').stop()
		#$AnimatedSprite4.stop()
		#$AnimatedSprite5.stop()

var ae_goback = false

func _on_Tween_tween_completed(object, key):
	moving = false
	if ae_goback:
		animation_event('attack', dest_x, dest_y, false, "same")

func set_stance(stance):
	if stance == "move":
		get_node('StanceMove').set_hidden(false)
		get_node('StanceMagic').set_hidden(true)
		get_node('StanceShield').set_hidden(true)
		get_node('StanceAttack').set_hidden(true)
	if stance == "magic":
		get_node('StanceMove').set_hidden(true)
		get_node('StanceMagic').set_hidden(false)
		get_node('StanceShield').set_hidden(true)
		get_node('StanceAttack').set_hidden(true)
	if stance == "shield":
		get_node('StanceMove').set_hidden(true)
		get_node('StanceMagic').set_hidden(true)
		get_node('StanceShield').set_hidden(false)
		get_node('StanceAttack').set_hidden(true)
	if stance == "attack":
		get_node('StanceMove').set_hidden(true)
		get_node('StanceMagic').set_hidden(true)
		get_node('StanceShield').set_hidden(true)
		get_node('StanceAttack').set_hidden(false)

func animation_event(which, x, y, aegb, face_dir):
	moving = true
	if face_dir != "same":
		face(face_dir)
	var goto = Vector2(x, y)
	var ae_speed = 0.2
	var destination = map.map_to_world(goto) + Vector2(0, 20)
	ae_goback = aegb
	var pos = get_pos()
	get_node('Tween').interpolate_property(self, 'transform/pos', pos, destination, ae_speed,
								Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	get_node('Tween').start()

var got_hit_counter = 0

func got_hit():
	got_hit_counter = 0
	_got_hit()

func _got_hit():
	if got_hit_counter > 5: return
	got_hit_counter += 1
	get_node('AnimatedSprite2').set_modulate(Color(0.8, 0, 0))
	var got_hit_timer = Timer.new()
	got_hit_timer.wait_time = 0.05
	got_hit_timer.process_mode = 1
	got_hit_timer.one_shot = true
	got_hit_timer.autostart = true
	got_hit_timer.connect('timeout', self, '_not_hit', [])
	add_child(got_hit_timer)

func _not_hit():
	get_node('AnimatedSprite2').set_modulate(Color(1, 1, 1))
	var not_hit_timer = Timer.new()
	not_hit_timer.wait_time = 0.05
	not_hit_timer.process_mode = 1
	not_hit_timer.one_shot = true
	not_hit_timer.autostart = true
	not_hit_timer.connect('timeout', self, '_got_hit', [])
	add_child(not_hit_timer)
