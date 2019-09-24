extends Node

# All the SDK / network related stuff here.

signal ack(json)
signal sdk_respawn(json)
signal sdk_chat(json)
signal sdk_login(json)
signal sdk_world(json)
signal sdk_world_map(json)
signal sdk_gear(json)

var stance = "attack"
var step = 0
var attack_queue = []
var move_queue = []
var respawn_queue = []
var username = ""
var password = ""
var headers = ["Content-Type: application/json"]
var use_ssl = false
#var host = "http://api.magicshieldattack.com"
var host = world.host

# For now, auth is just the name.
# TODO: Make auth a proper JWT from a login.
func set_auth(u, p):
	username = u
	password = p

func set_step(s):
	step = s

func set_stance(s):
	stance = s

func _ack(result, response_code, headers, body):
	# gd3 parse
	#var json = JSON.parse(body.get_string_from_utf8())
	# gd2 parse
	var json = Dictionary()
	json.parse_json(body.get_string_from_utf8())
	if not json: return
	if not json.result: return
	emit_signal("ack", json.result)

func parse_response(body):
	# gd3 parse
	#var json = JSON.parse(body.get_string_from_utf8())
	# gd2 parse
	var json = Dictionary()
	json.parse_json(body.get_string_from_utf8())
	#printt("JSON WAS: ", json)
	if not TYPE_DICTIONARY == typeof(json): return
	#if not TYPE_DICTIONARY == typeof(json.result): return
	#printt("Hmm: ", json.size())
	#printt("Hmm: ", json.keys())

	return json
	#return json.result

func cb_attack(result, response_code, headers, body):
	pass

func cb_move(result, response_code, headers, body):
	move_queue = []

func cb_respawn(result, response_code, headers, body):
	respawn_queue = []

func cb_chat(result, response_code, headers, body):
	if TYPE_RAW_ARRAY == typeof(body):
		emit_signal("sdk_chat", parse_response(body))

func cb_login(result, response_code, headers, body):
	if TYPE_RAW_ARRAY == typeof(body):
		emit_signal("sdk_login", parse_response(body))
	else:
		printt("Oops: ", body)

func cb_gear(result, response_code, headers, body):
	if TYPE_RAW_ARRAY == typeof(body):
		emit_signal("sdk_gear", parse_response(body))
	else:
		printt("Oops: ", body)

func cb_world(result, response_code, headers, body):
	if TYPE_RAW_ARRAY == typeof(body):
		emit_signal("sdk_world", parse_response(body))
	else:
		printt("Oops: ", body)

func cb_world_map(result, response_code, headers, body):
	if TYPE_RAW_ARRAY == typeof(body):
		var raw = parse_response(body)
		emit_signal("sdk_world_map", raw.map)
	else:
		printt("Oops: ", body)

func _post(cb, uri, data_to_send):
	printt('In _post')
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", self, cb, [])
	# Convert data to json string:
	# gd3
	#var query = JSON.print(data_to_send)
	# gd2
	var query = data_to_send.to_json()
	var url = host + uri
	printt("Request to: ", url, "With: ", query)
	http.request(url, headers, use_ssl, HTTPClient.METHOD_POST, query)

func _get(cb, uri):
	printt('In _get')
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", self, cb, [])
	var url = host + uri
	printt("Request to: ", url)
	http.request(url)

# TODO: Wire this up to an http callback
func login_save():
	pass
	#var save_game = File.new()
	#save_game.open("user://savegame.save", File.WRITE)
	#save_game.store_line(to_json({"player_name": player}))
	#save_game.close()

func login(n):
	printt("Logging in:", n)
	_post("cb_login", "/login.json", {"name": n})

func input(cb, d):
	d.step = step
	_post(cb, "/input.json", d)

func chat(chat):
	input("cb_chat", {"action": "chat", "chat": chat, "name": username})

func _move(dir):
	input("cb_move", {"action": "move", "dir": dir, "name": username})

func move(dir):
	move_queue.push_back({"action": "move", "dir": dir, "name": username})

func _respawn():
	input("cb_respawn", {"action": "respawn", "name": username})

func respawn():
	respawn_queue.push_back({"action": "respawn", "name": username})

func attack(dir):
	attack_queue.push_back({"action": "attack", "dir": dir, "name":
	username, "stance": stance})

func gear():
	_get("cb_gear", "/gear.json?username=" + str(username))

func world():
	_get("cb_world", "/world.json?step=" + str(step + 1) + '&username=' + str(username))

func world_map(zone):
	_get("cb_world_map", "/world-map-wrapped.json?zone=" + str(zone))

func _process_move_queue():
	if move_queue.size() == 0: return
	input("cb_move", move_queue[0])
	#move_queue = []

func _process_attack_queue():
	if attack_queue.size() == 0: return
	input("cb_attack", attack_queue[0])
	attack_queue = []

func _process_respawn_queue():
	if respawn_queue.size() == 0: return
	input("cb_respawn", respawn_queue[0])
	respawn_queue = []

func process_queues():
	_process_move_queue()
	_process_attack_queue()
	_process_respawn_queue()

func _ready():
	var qt = Timer.new()
	qt.process_mode = 1
	qt.wait_time = .25
	qt.one_shot = false
	qt.autostart = true
	qt.connect('timeout', self, 'process_queues', [])
	add_child(qt)
