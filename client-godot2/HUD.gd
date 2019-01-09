extends CanvasLayer

signal hud_submit(text)

var is_chat_visible = false

func _ready():
	pass

func show_chat():
	is_chat_visible = true
	get_node('Feedback2').text = 'Type some text to message others.'
	get_node('Name').set_hidden(false)
	get_node('NameLabel').set_hidden(false)
	get_node('NameButton').set_hidden(false)
	get_node('NameLabel').text = "Chat"
	get_node('Name').grab_focus()
	get_node('Name').set_text("")

func hide_chat():
	is_chat_visible = false
	get_node('Feedback2').set_text("Back to playing")
	get_node('Name').set_hidden(true)
	get_node('NameLabel').set_hidden(true)
	get_node('NameButton').set_hidden(true)

func _on_Button_button_down():
	emit_signal("hud_submit", get_node('Name').get_text())
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


func _on_NameButton_button_down():
	pass # replace with function body


func _on_StartButton_button_down():
	pass # replace with function body
