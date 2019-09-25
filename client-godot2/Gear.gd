extends Node2D

var gear = []
var sdk

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	printt("Gear was loaded")
	sdk = world.get_sdk()
	sdk.connect("sdk_gear", self, "_ack_gear", [])
	sdk.gear()
	set_process(true)
	set_process_input(true)
	# TODO: Fetch the items from server and use those
	var items = [
	{
		'back': {'png': '32b-red-scarf', 'color': {'r': 1, 'g': 1, 'b': 1}},
		'default': {'png': '32-red-scarf-front', 'color': {'r': 1, 'g': 1, 'b': 1}}
	}
	]
	boot(items)

func _process(delta):
	get_node('Doll').play('default')
	for g in gear:
		g.play('default')

func _ack_gear(json):
	printt("Gear rec was:", json)
	var gears = json.gear
	boot(gears)
	#for g in range(0, gear.size()):
	# var gear = g[i]

func boot(items):
	load_gear(items)

# Straight copy of Unit.gd func, not ideal, but it'll work for now.
# TODO: Ensure we partition gear into the appropriate slot / group by type.
func load_gear(stubs):
	var head = get_node('ButtonGroup').get_node('HeadOptionButton')
	var head_i = 0
	head.clear()

	# Delete any previously installed gear
	for g in gear:
		remove_child(g)
	gear = []
	for stub in stubs:
		printt("Stub gear is: ", stub)
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
		var dol_pos = get_node('Doll').get_pos()
		#s.set_pos(Vector2(0, -20))
		s.set_pos(Vector2(dol_pos.x, dol_pos.y))
		s.frames = f
		s.animation = 'default'
		s.play('default')
		s.set_flip_h(false)
		var c = stub.default.color
		s.modulate = Color(c.r, c.g, c.b)
		#get_node('Doll').add_child(s)
		add_child(s)
		gear.push_back(s)
		head.add_item(stub.default.png, head_i)
		head_i = head_i + 1
		#printt('Added the gear')

	# End for loop

func stop_editing_gear():
	world.goto_scene('res://Main.tscn')

func _input(event):
	#printt("Clicked the booton in Gear.gd")
	if event.is_action_pressed('ui_gear'):
		return stop_editing_gear()


func _on_HeadOptionButton_item_selected( ID ):
	printt("Item selected", ID);
	pass # replace with function body
