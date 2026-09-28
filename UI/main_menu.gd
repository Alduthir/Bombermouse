extends Control

enum Device {KEYBOARD, MOUSE, CONTROLLER}

@onready var _playButton : Button = %PlayButton
@onready var _settingsButton : Button = %SettingsButton
@onready var _quitButton : Button = %QuitButton
@onready var _gameScene : PackedScene = preload("res://Levels/Level1.tscn")

@onready var buttons : Array[Button] = [_playButton, _settingsButton, _quitButton]

func _ready() -> void:
	_playButton.grab_focus()	

func _on_play_button_focus_entered() -> void:
	set_focus(_playButton)

func _on_quit_button_focus_entered() -> void:
	set_focus(_quitButton)

func _on_settings_button_focus_entered() -> void:
	set_focus(_settingsButton)


func set_focus(focussedButton: Button)->void:
	for button : Button in buttons:
		if button == focussedButton:
			button.offset_transform_enabled = true
			button.grab_focus()
		else:
			button.offset_transform_enabled = false

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(_gameScene)
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_play_button_mouse_entered() -> void:
	set_focus(_playButton)


func _on_settings_button_mouse_entered() -> void:
	set_focus(_settingsButton)


func _on_quit_button_mouse_entered() -> void:
	set_focus(_quitButton)
