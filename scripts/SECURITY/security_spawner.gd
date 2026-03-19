extends Node2D

@onready var security := get_tree().current_scene.get_node("SecuritySystem")

func _ready():
	security.level_changed.connect(_on_security_changed)
	security.alert_triggered.connect(_on_alert)

func _on_security_changed(level: int):
	print("[SPAWNER] Security level:", level)

	match level:
		1:
			spawn_sewer_shark()
		2:
			spawn_drone()
		3:
			spawn_gilded_watch()
		4:
			spawn_bio_brute()
		5:
			spawn_sanitizer()

func _on_alert(pos: Vector2):
	print("[SPAWNER] Responding to alert at:", pos)
	spawn_drone_at(pos)
