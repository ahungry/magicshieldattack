extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	printt("Gear was loaded")
	#set_process(true)
	set_process_input(true)

func _process(delta):
	pass

func stop_editing_gear():
	world.goto_scene('res://Main.tscn')

func _input(event):
	printt("Clicked the booton in Gear.gd")
	if event.is_action_pressed('ui_gear'):
		return stop_editing_gear()
