extends Node2D

var sdk

func _ready():
	sdk = world.get_sdk()
	$HUD.connect("hud_submit", self, "_hud_submit", [])
	$HUD/NameLabel.text = "Enter your name"

func _hud_submit(username):
	sdk.login(username)
