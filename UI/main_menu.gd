extends Control

@onready var _playButton : Button = %PlayButton
@onready var _settingsButton : Button = %SettingsButton
@onready var _quitButton : Button = %QuitButton

func _ready() -> void:
	_playButton.grab_focus()
	
	
func _on_play_button_focus_entered() -> void:
	_playButton.offset_transform_enabled = true

func _on_play_button_focus_exited() -> void:
	_playButton.offset_transform_enabled = false

func _on_quit_button_focus_entered() -> void:
	_quitButton.offset_transform_enabled = true

func _on_quit_button_focus_exited() -> void:
	_quitButton.offset_transform_enabled = false


func _on_settings_button_focus_entered() -> void:
	_settingsButton.offset_transform_enabled = true


func _on_settings_button_focus_exited() -> void:
	_settingsButton.offset_transform_enabled = false
