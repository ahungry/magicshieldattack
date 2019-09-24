extends Node2D

var gear = []

func _ready():
  # Called every time the node is added to the scene.
  # Initialization here
  printt("Gear was loaded")
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

func boot(items):
  load_gear(items)

# Straight copy of Unit.gd func, not ideal, but it'll work for now.
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
    var dol_pos = get_node('Doll').get_pos()
    #s.set_pos(Vector2(0, -20))
    s.set_pos(Vector2(dol_pos.x, dol_pos.y))
    s.frames = f
    s.animation = 'default'
    s.play('default')
    var c = stub.default.color
    s.modulate = Color(c.r, c.g, c.b)
    #get_node('Doll').add_child(s)
    add_child(s)
    gear.push_back(s)
    #printt('Added the gear')
  # End for loop

func stop_editing_gear():
  world.goto_scene('res://Main.tscn')

func _input(event):
  printt("Clicked the booton in Gear.gd")
  if event.is_action_pressed('ui_gear'):
    return stop_editing_gear()
