extends Node2D

signal swipe

var swipe_start = null
var minimum_drag = 50

func _ready():
	set_process_unhandled_input(true)

func _unhandled_input(event):
	#printt("Handling some unhandled input")
	if event.is_action_pressed("ui_click"):
		#var pos = get_viewport().get_mouse_position()
		var pos = get_global_mouse_pos()
		swipe_start = pos
	if event.is_action_released("ui_click"):
		#var pos = get_viewport().get_mouse_position()
		var pos = get_global_mouse_pos()
		_calculate_swipe(pos)

func _calculate_swipe(swipe_end):
	if swipe_start == null:
		return
	var swipe = swipe_end - swipe_start
	# Fine logic for straight up/down/left/right movement.
	#if abs(swipe.x) > minimum_drag:
	#	if swipe.x > 0:
	#		emit_signal("swipe", "right")
	#	else:
	#		emit_signal("swipe", "left")
	#if abs(swipe.y) > minimum_drag:
	#	if swipe.y > 0:
	#		emit_signal("swipe", "up")
	#	else:
	#		emit_signal("swipe", "down")
	# North is quadrant 1 (NE one)
	if abs(swipe.x) > minimum_drag and abs(swipe.y) > minimum_drag:
		# These all indicate we swiped diagonal up/down/left/right
		if swipe.x > 0 and swipe.y > 0:
			emit_signal("swipe", "right")
		if swipe.x > 0 and swipe.y < 0:
			emit_signal("swipe", "up")
		if swipe.x < 0 and swipe.y > 0:
			emit_signal("swipe", "down")
		if swipe.x < 0 and swipe.y < 0:
			emit_signal("swipe", "left")
	else:
		emit_signal("swipe", "none")
