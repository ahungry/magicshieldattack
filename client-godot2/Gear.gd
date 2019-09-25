extends Node2D

var gear = []
var sdk

# Should match indices of what we put in select list
var head_gear = []
var chest_gear = []
var feet_gear = []

# Used for reloading items on change of form
var cached_items = []
var head_selected_id = 0
var chest_selected_id = 0
var feet_selected_id = 0

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
	#var items = [
	#{
	#	'back': {'png': '32b-red-scarf', 'color': {'r': 1, 'g': 1, 'b': 1}},
	#	'default': {'png': '32-red-scarf-front', 'color': {'r': 1, 'g': 1, 'b': 1}}
	#}
	#]
	#boot(items)

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
	cached_items = items
	load_gear(items)

# Straight copy of Unit.gd func, not ideal, but it'll work for now.
# TODO: Ensure we partition gear into the appropriate slot / group by type.
func load_gear(stubs):
	head_gear = []
	chest_gear = []
	feet_gear = []
	var head = get_node('ButtonGroup').get_node('HeadOptionButton')
	var head_i = 0
	head.clear()
	var chest = get_node('ButtonGroup').get_node('ChestOptionButton')
	var chest_i = 0
	chest.clear()
	var feet = get_node('ButtonGroup').get_node('FeetOptionButton')
	var feet_i = 0
	feet.clear()

	# Delete any previously installed gear
	for g in gear:
		remove_child(g)

	gear = []

	for stub in stubs:
		# Track the gear in the appropriate list/slot
		if stub.slot == "head":
			head_gear.push_back(stub)
			head.add_item(stub.name, head_i)
			head_i = head_i + 1
			#Only show worn gear on paper doll
			if stub.worn == false and head_selected_id != head_i - 1: continue

		if stub.slot == "chest":
			chest_gear.push_back(stub)
			chest.add_item(stub.name, chest_i)
			chest_i = chest_i + 1
			#Only show worn gear on paper doll
			if stub.worn == false and chest_selected_id != chest_i - 1: continue

		if stub.slot == "feet":
			feet_gear.push_back(stub)
			feet.add_item(stub.name, feet_i)
			feet_i = feet_i + 1
			#Only show worn gear on paper doll
			if stub.worn == false and feet_selected_id != feet_i - 1: continue

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
		#printt('Added the gear')
	# End for loop
	head.select(head_selected_id)
	chest.select(chest_selected_id)
	feet.select(feet_selected_id)
# End load_gear

func reload_gear():
	load_gear(cached_items)

func stop_editing_gear():
	world.goto_scene('res://Main.tscn')

func _input(event):
	#printt("Clicked the booton in Gear.gd")
	if event.is_action_pressed('ui_gear'):
		return stop_editing_gear()

func _on_HeadOptionButton_item_selected( ID ):
	printt("Head item selected", ID)
	head_selected_id = ID
	reload_gear()

func _on_ChestOptionButton_item_selected( ID ):
	printt("Chest item selected", ID)
	chest_selected_id = ID
	reload_gear()

func _on_FeetOptionButton_item_selected( ID ):
	printt("Feet item selected", ID)
	feet_selected_id = ID
	reload_gear()
