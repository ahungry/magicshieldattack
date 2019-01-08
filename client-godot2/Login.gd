extends Node2D

var sdk

func _ready():
	sdk = world.get_sdk()
	get_node('HUD').connect("hud_submit", self, "_hud_submit", [])
	get_node('HUD/NameLabel').text = "Enter your name"

func _hud_submit(username):
	printt("Logging in via hud with: ", username)
	sdk.login(username)
