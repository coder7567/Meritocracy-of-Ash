extends Node
class_name SecuritySystem

signal level_changed(new_level)
signal alert_triggered(source)

@export var security_level: int = 0
@export var max_level: int = 5
@export var cooldown_rate: float = 10.0

var player: Node = null
var _cooldown_timer: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	print("[SECURITY] Player =", player)

func increase_security(amount: int = 1) -> void:
	var old_level := security_level
	security_level = clamp(security_level + amount, 0, max_level)

	if security_level != old_level:
		print("[SECURITY] Level increased to:", security_level)
		level_changed.emit(security_level)

func decrease_security(amount: int = 1) -> void:
	var old_level := security_level
	security_level = clamp(security_level - amount, 0, max_level)

	if security_level != old_level:
		print("[SECURITY] Level decreased to:", security_level)
		level_changed.emit(security_level)

func trigger_alert(position: Vector2) -> void:
	var shake_amount := 6.0 + (security_level * 3.0)
	print("[SECURITY] Alert triggered at:", position, " level:", security_level)
	alert_triggered.emit(position)
	
	if security_level < max_level:
		if player and player.has_method("add_camera_shake"):
			player.add_camera_shake(shake_amount)
		
	increase_security(1)
	
func _process(delta: float) -> void:
	# Only cooldown if we are above Level 0
	if security_level > 0:
		_cooldown_timer += delta
		if _cooldown_timer >= cooldown_rate:
			decrease_security(1)
			_cooldown_timer = 0.0 # Reset timer
	else:
		_cooldown_timer = 0.0 # Ensure it stays at 0
