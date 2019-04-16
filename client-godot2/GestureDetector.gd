# Mobile gesture detection helper
extends Node2D

signal double_tap
signal tap

signal twisted
signal pinched
signal dragged

# Debounced events, as in, only emitted after its clear that its not
# part of any other more complicated event system
signal single_tap
signal single_drag

#signal multi_twist
#signal multi_pinch
#signal multi_drag

signal touches_changed

export(int, 0, 1000) var drag_threshhold = 10
export(int, 1, 2000) var double_tap_thresh_ms = 500
export(int, 0, 1000) var double_tap_thresh_distance = 100

# All the events to check for
export(bool) var listen_for_multi_drag = true
export(bool) var listen_for_multi_pinch = true
export(bool) var listen_for_multi_twist = true
export(bool) var listen_for_debounced_drag = true setget set_listen_for_debounced_drag
export(bool) var listen_for_debounced_tap = true setget set_listen_for_debounced_tap
export(bool) var trigger_last_debounce_only = true

# Debug mode to check for
export(bool) var debug_right_click_enabled = false
export(bool) var debug_show_clicks_and_drag = false

export (int, 1, 1000) var twist_precision = 150
export (int, 1, 1000) var pinch_precision = 70
export (int, 1, 1000) var drag_precision = 215

export (int, 1, 2000) var debounce_time_ms = 600

var touch_count = 0
var touches = {}
var drags = {}

var is_pinching
var is_dragging
var is_twisting
var twisting_votes
var pinching_votes
var dragging_votes

var is_pinch_in
var is_twist_cw
var drag_vec
var last_positions = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]

func _ready():
    set_process_input(true)
    _reset_multi_state()
    _reset_debounce()

#
# Resets multi interaction state, votes and booleans
func _reset_multi_state():
    is_pinching = false
    is_dragging = false
    is_twisting = false
    pinching_votes = 0
    dragging_votes = 0
    twisting_votes = 0
    is_pinch_in = false
    is_twist_cw = false
    drag_vec = Vector2(0, 0)

#
# Resets debounce state, and applies set_process as applicable
func _reset_debounce():
    in_debounce = false
    debounce_event_queue = []
    debounce_time = 0
    if listen_for_debounced_drag or listen_for_debounced_tap:
        set_process(true)
    else:
        set_process(false)


func set_listen_for_debounced_drag(value):
    listen_for_debounced_drag = value
    _reset_debounce()

func set_listen_for_debounced_tap(value):
    listen_for_debounced_tap = value
    _reset_debounce()

func _debugspot(pos, symbol):
    if not debug_show_clicks_and_drag:
        return null
    # Add a debugging character
    var spot = Label.new()
    get_parent().add_child(spot)
    spot.set_text(symbol)
    spot.set_global_pos(pos)
    return spot

func _index_warn():
    print("GestureDetector: WARNING: Touch event indices not consistent.")

func get_second_index(index):
    # In rare situations, where a third finger goes down and the first
    # is released, and the gesture occurs with #2 and #3, then we need
    # to only pick two 2 relevant fingers down.
    # In most cases, this returns 0
    var indices = touches.keys()
    for other_index in indices:
        if other_index != index:
            return other_index
    return null # Error situation

func check_for_drag_events(d1, origin2, d2, origin):
    var pivot = origin2
    if d2 != null:
        # Create a pivot "half-way" through the stroke
        pivot = (origin2 + d2.pos) / Vector2(2.0, 2.0)
        _debugspot(pivot, 'o')

    # Check if the rel pos of each is pretty similar
    if listen_for_multi_drag and d2 != null:
        # Require 2 simultaneous drag events for multidrags
        var rel_pos2 = d2.pos - origin2
        var rel_pos1 = d1.pos - origin
        var diff = rel_pos1.distance_to(rel_pos2)
        if diff < drag_precision: # Together, so drag event
            is_dragging = true
            drag_vec = (rel_pos2 + rel_pos1) / 2
            dragging_votes += drag_vec.length()

    if listen_for_multi_pinch:
        # Convoluted logic that looks for pinching motions. Basically,
        # the distance between the two events should change
        # considerably, whether it be "in" or "out"
        var diff_signed = pivot.distance_to(origin) - pivot.distance_to(d1.pos)
        var diff = abs(diff_signed)
        if diff > pinch_precision:
            is_pinching = true
            is_pinch_in = diff_signed > 0
            pinching_votes += diff - pinch_precision

    if listen_for_multi_twist:
        # convoluted logic that looks for twist motion
        var pos = d1.pos
        var diff = abs(pivot.distance_to(origin) - pivot.distance_to(pos))
        if diff < twist_precision:
            # Distance around pivot remains mostly unchanged, implying
            # that a "semi-circle" is being traced. Now check if we
            # cross an axis.
            if origin.x > pivot.x:
                if pos.x < pivot.x:
                    is_twisting = true
                    is_twist_cw = pos.y > pivot.y
            elif origin.x < pivot.x:
                if pos.x > pivot.x:
                    is_twisting = true
                    is_twist_cw = pos.y < pivot.y
            if origin.y < pivot.y:
                if pos.y > pivot.y:
                    is_twisting = true
                    is_twist_cw = pos.x > pivot.x
            elif origin.y > pivot.y:
                if pos.y < pivot.y:
                    is_twisting = true
                    is_twist_cw = pos.x < pivot.x
            if is_twisting:
                twisting_votes += twist_precision - diff

func _in_doubletap():
    var is_2nd = last_tap_pos != null and last_tap_time != null
    return is_2nd and (OS.get_ticks_msec() - last_tap_time) < double_tap_thresh_ms

var last_tap_pos = null
var last_tap_time = null
func check_for_tap_events(pos):
    if _in_doubletap() and abs(pos.distance_to(last_tap_pos)) < double_tap_thresh_distance:
        last_tap_pos = null
        last_tap_time = null
        emit_signal('double_tap', pos)
        # Never allow debounce events after a multi-touch event
        _reset_debounce()
    else:
        last_tap_pos = pos
        last_tap_time = OS.get_ticks_msec()
        emit_signal('tap', pos)

#
# Debounce logic
var debounce_time = 0
var in_debounce = false
var debounce_event_queue = []

#
# Checks if we need to empty the queue emitting the appropriate events
func _process(delta):
    if not in_debounce:
        return
    debounce_time += delta
    # Debounce time has expired
    if debounce_time > (debounce_time_ms / 1000.0):
        # Only go through queue if we are not about to emit a different
        # event
        if not is_multi_step_event_in_progress():
            emit_debounce_queue()
        _reset_debounce()

#
# Return true if its currently detecting a more complicated event
# (double tap, pinching, two finger dragging, or twisting)
func is_multi_step_event_in_progress():
    return _in_doubletap() or is_pinching or is_dragging or is_twisting

func emit_debounce_queue():
    for ev in debounce_event_queue:
        if ev.type == InputEvent.SCREEN_TOUCH:
            emit_signal('single_tap', ev)
        elif ev.type == InputEvent.SCREEN_DRAG:
            emit_signal('single_drag', ev)
        else: # sanity print log, can never get here
            print("error: debounce unknown event")


#
# Reset debounce state for drag events
func check_drag_debounce(ev):
    if not listen_for_debounced_drag:
        return
    if trigger_last_debounce_only:
        debounce_event_queue = [ev]
    else:
        debounce_event_queue.push(ev)
    debounce_time = 0
    in_debounce = true

#
# Reset debounce state for tap events
func check_tap_debounce(ev):
    if not listen_for_debounced_tap:
        return
    if trigger_last_debounce_only:
        debounce_event_queue = [ev]
    else:
        debounce_event_queue.push(ev)
    debounce_time = 0
    in_debounce = true

var _debug_mocked_is_pressed = false
var _debug_circle = null

func _input(ev):
    var thresh_sq = drag_threshhold * drag_threshhold

    # Fakes placing and holding
    if debug_right_click_enabled:
        if ev.type == InputEvent.MOUSE_BUTTON and ev.button_index == BUTTON_RIGHT and !ev.pressed:
            _debug_mocked_is_pressed = not _debug_mocked_is_pressed
            ev = {
                'type': InputEvent.SCREEN_TOUCH,
                'pressed': _debug_mocked_is_pressed,
                'pos': ev.pos,
                'index': 99,
            }
            if _debug_circle != null:
                _debug_circle.queue_free()
                _debug_circle = null

            if _debug_mocked_is_pressed:
                # Add a fake circle
                _debug_circle = _debugspot(ev.pos, 'X')
            print('Faking an "anchoring" event', ev)

    if ev.type == InputEvent.SCREEN_TOUCH:
        if ev.pressed:
            touch_count += 1
            touches[ev.index] = ev
        else:
            touch_count = max(0, touch_count - 1)
            touches.erase(ev.index)
            # A "tap" occurred, check for double tap
            check_tap_debounce(ev)
            check_for_tap_events(ev.pos)
            # Also remove from drag events
            if drags.has(ev.index):
                drags.erase(ev.index)

            if touch_count == 1:
                # Check for 1-off events that are triggered when one
                # finger is released (re-using the same finger triggers
                # multiple). Only emit whichever has the most votes.
                twisting_votes = int(twisting_votes) # round off votes
                pinching_votes = int(pinching_votes)
                dragging_votes = int(dragging_votes)
                var max_votes = max(twisting_votes,
                    max(pinching_votes, dragging_votes))

                # Get average position
                var pos = (last_positions[0] +
                    last_positions[1] + last_positions[2]) / 3.0
                if is_pinching and max_votes == pinching_votes:
                    emit_signal('pinched', pos, is_pinch_in)
                if is_dragging and max_votes == dragging_votes:
                    emit_signal('dragged', pos, drag_vec)
                if is_twisting and max_votes == twisting_votes:
                    emit_signal('twisted', pos, is_twist_cw)
                _reset_multi_state()
                _reset_debounce()

        emit_signal('touches_changed', touch_count)

    if ev.type == InputEvent.SCREEN_DRAG:
        drags[ev.index] = ev
        check_drag_debounce(ev)
        if ev.relative_pos.length_squared() < thresh_sq:
            # Ignore short drags
            return

        if touch_count > 1:
            # more than one finger touching, lets compare this with the
            # first valid touching finger

            var other_index = get_second_index(ev.index)
            if other_index == null:
                _index_warn()
                return # do nothing in error case

            # Use either drag event index or touch event index for
            # "anchor" pos
            var origin2 = touches[other_index].pos

            # Determine if there is another on-going drag event
            var other_drag = null
            var last_input_event = ev
            if drags.has(other_index):
                other_drag = drags[other_index]
                # Always use whichever event has the highest index as
                # the reported event
                if other_index > ev.index and other_drag != null:
                    last_input_event = other_drag

            # check_for_drag_events has the core logic of determining
            # if any gesture events occurred
            var touch_index = get_second_index(other_index)
            var origin = touches[touch_index].pos
            var event = check_for_drag_events(ev, origin2, other_drag, origin)

            # Update last positions in avg array
            last_positions = [origin, ev.pos, origin2]

            #if event != null:
            #    # An event occurred, trigger signal
            #    emit(event, last_input_event)
