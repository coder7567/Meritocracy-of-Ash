extends CanvasLayer

@onready var flash: ColorRect = $Flash
@onready var stamina_bar: ProgressBar = $Control/StaminaBar

func _ready() -> void:
	flash.color = Color.WHITE
	flash.modulate = Color(1, 1, 1, 0)
	add_to_group("game_ui")

func flash_screen() -> void:
	print("flash_screen called")
	flash.modulate = Color(1, 1, 1, 0.8)

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.4)
	
func update_stamina(current: float, max_value: float) -> void:
	if stamina_bar == null:
		return

	stamina_bar.max_value = max_value
	stamina_bar.value = current
	
func flash_stamina_red() -> void:
	if stamina_bar == null: return
	var tween:= create_tween()
	tween.tween_property(stamina_bar, "modulate", Color.RED, 0.1)
	tween.tween_property(stamina_bar, "modulate", Color.WHITE, 0.1)
