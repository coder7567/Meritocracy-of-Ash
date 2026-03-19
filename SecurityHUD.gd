extends Control
class_name SecurityHUD

@export var inactive_color: Color = Color(0.2, 0.2, 0.2, 0.7)
@export var active_color: Color = Color(1.0, 0.2, 0.2, 1.0)

# Reference the container, not just the icons, to hide everything at once
@onready var container: HBoxContainer = $HBoxContainer
@onready var level_icons: Array[TextureRect] = [
	$HBoxContainer/Level1,
	$HBoxContainer/Level2,
	$HBoxContainer/Level3,
	$HBoxContainer/Level4,
	$HBoxContainer/Level5
]

var security_system: SecuritySystem = null
var _pulse_time: float = 0.0

func _ready() -> void:
	var root := get_tree().current_scene
	if root != null:
		security_system = root.find_child("SecuritySystem", true, false) as SecuritySystem

	if security_system == null:
		push_warning("SecurityHUD could not find SecuritySystem.")
		# Hide initially if no system found
		visible = false 
		return

	security_system.level_changed.connect(_on_security_level_changed)
	# Set initial state
	_refresh_icons(security_system.security_level)

func _on_security_level_changed(level: int) -> void:
	_refresh_icons(level)

func _refresh_icons(level: int) -> void:
	print("[HUD] Refreshing to level: ", level)
	
	# --- ADDED: Show/Hide based on level ---
	if level > 0:
		show()
	else:
		hide()
	# ----------------------------------------

	for i in range(level_icons.size()):
		if i < level:
			level_icons[i].modulate = active_color
		else:
			level_icons[i].modulate = inactive_color
			
func _process(delta: float) -> void:
	# Only pulse if we are at Level 4 or 5
	if security_system and security_system.security_level >= 4:
		_pulse_time += delta * 10.0 # Speed of the flash
		var pulse = (sin(_pulse_time) + 1.0) / 2.0
		# Blend between bright red and dark red
		container.modulate = Color(1.0, 0.2, 0.2, 1.0).lerp(Color(0.5, 0, 0, 1.0), pulse)
	else:
		container.modulate = Color.WHITE # Reset to normal
