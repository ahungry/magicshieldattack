extends CanvasLayer

signal hud_submit(text)

func _ready():
	pass

func show_chat():
	$Feedback2.text = 'Type some text to message others.'
	$Name.visible = true
	$NameLabel.visible = true
	$NameButton.visible = true
	$NameLabel.text = "Chat"
	$Name.grab_focus()
	$Name.text = ""

func hide_chat():
	$Feedback2.text = 'Back to playing'
	$Name.visible = false
	$NameLabel.visible = false
	$NameButton.visible = false

func _on_Button_button_down():
	emit_signal("hud_submit", $Name.text)
	hide_chat()

func _on_UpButton_button_down():
	pass # replace with function body


func _on_LeftButton_button_down():
	pass # replace with function body


func _on_RightButton_button_down():
	pass # replace with function body


func _on_DownButton_button_down():
	pass # replace with function body


func _on_SelectButton_button_down():
	pass # replace with function body
