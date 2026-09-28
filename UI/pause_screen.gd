extends Control

@onready var _blur_color_rect: ColorRect = %BlurColorRect
@onready var _ui_panel_container: PanelContainer = %UIPanelContainer
@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton

@export_range(0, 1.0) var menu_opened_amount := 0.0:
	set = set_menu_opened_amount
@export_range(0.1,10,0.01, "or_greater") var animation_duration := 2.3

var _tween : Tween
var _is_currently_opening := false

func _ready() -> void:
	menu_opened_amount = 0.0

func set_menu_opened_amount(amount: float) -> void:
	if not Engine.is_editor_hint():
		get_tree().paused = amount > 0.1
	menu_opened_amount = amount
	visible = amount > 0
	if _ui_panel_container == null or _blur_color_rect == null:
		return
	_blur_color_rect.material.set_shader_parameter("blur_amount", lerp(0.0, 1.5, amount))
	_blur_color_rect.material.set_shader_parameter("saturation", lerp(1.0, 0.3, amount))
	_ui_panel_container.modulate.a = amount

func toggle() -> void:
	# Switch the flag to the opposite value
	_is_currently_opening = not _is_currently_opening

	var duration := animation_duration
	# If there's a tween, and it is animating, we want to kill it.
	# This stops the previous animation.
	if _tween != null:
		if not _is_currently_opening:
			# If the previous tween was animating, we want to animate back
			# from the current point in the animation.
			duration = _tween.get_total_elapsed_time()
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)

	var target_amount := 1.0 if _is_currently_opening else 0.0
	print(target_amount)
	_tween.tween_property(self, "menu_opened_amount", target_amount, duration)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): toggle()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_resume_button_pressed() -> void:
	toggle()
