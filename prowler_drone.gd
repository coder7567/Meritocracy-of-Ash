extends CharacterBody2D

@export var speed: float = 70.0
@export var patrol_distance: float = 140.0
@export var alert_cooldown: float = 2.0
@export var avoid_turn_speed: float = 2.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var searchlight: PointLight2D = $PointLight2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var raycast: RayCast2D = $RayCast2D
@onready var hum: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var suspicion_build_speed: float = 55.0
@export var suspicion_decay_speed: float = 35.0
@export var suspicion_threshold: float = 100.0
@onready var suspicion_bar: ProgressBar = $SuspicionBar

var player: Node2D = null
var security_system: Node = null

var start_position: Vector2
var patrol_dir: float = 1.0
var alert_timer: float = 0.0
var player_in_zone: bool = false
var suspicion: float = 0.0

func _ready() -> void:
	print("[DRONE] Ready")

	start_position = global_position

	player = get_tree().get_first_node_in_group("player") as Node2D
	print("[DRONE] Player =", player)

	var root := get_tree().current_scene
	print("[DRONE] current_scene =", root)

	if root != null:
		security_system = root.find_child("SecuritySystem", true, false)
	print("[DRONE] SecuritySystem =", security_system)

	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)

	if suspicion_bar:
		suspicion_bar.min_value = 0.0
		suspicion_bar.max_value = suspicion_threshold
		suspicion_bar.value = 0.0
		suspicion_bar.visible = false
		suspicion_bar.position = Vector2(-40, -50)
		suspicion_bar.size = Vector2(80, 12)

func _physics_process(delta: float) -> void:
	if alert_timer > 0.0:
		alert_timer -= delta

	_patrol(delta)
	_update_searchlight()
	_update_audio()

	_handle_suspicion(delta)
	move_and_slide()
	
func _handle_suspicion(delta: float) -> void:
	var can_see_player: bool = player_in_zone and _has_line_of_sight_to_player()
	
	if can_see_player and alert_timer <= 0.0:
		suspicion += suspicion_build_speed * delta
		suspicion = min(suspicion, suspicion_threshold)
		searchlight.color = Color(1.0, 0.7, 0.0).lerp(Color.RED, suspicion / suspicion_threshold)
	else:
		suspicion = max(0.0, suspicion - suspicion_decay_speed * delta)
		searchlight.color = searchlight.color.lerp(Color.WHITE, delta * 2.0)
		
	if suspicion_bar:
		suspicion_bar.value = suspicion
		suspicion_bar.visible = suspicion > 0.0
	
	if suspicion >= suspicion_threshold:
		_trigger_full_alert()
		
func _trigger_full_alert() -> void:
	print("[DRONE] SUSPICION MAXED! Player spotted!")
	suspicion = 0.0 # Reset suspicion so it doesn't spam alerts
	alert_timer = alert_cooldown
	
	if security_system and security_system.has_method("trigger_alert"):
		security_system.trigger_alert(player.global_position)

func _patrol(_delta: float) -> void:
	if raycast.is_colliding():
		patrol_dir *= -1.0

	var offset_from_start := global_position.x - start_position.x

	if offset_from_start > patrol_distance:
		patrol_dir = -1.0
	elif offset_from_start < -patrol_distance:
		patrol_dir = 1.0

	velocity = Vector2(speed * patrol_dir, 0.0)

	# Flip visuals only
	if patrol_dir > 0.0:
		sprite.scale.x = 1.0
		searchlight.scale.x = 1.0
		detection_zone.scale.x = 1.0
		raycast.target_position.x = abs(raycast.target_position.x)
	else:
		sprite.scale.x = -1.0
		searchlight.scale.x = -1.0
		detection_zone.scale.x = -1.0
		raycast.target_position.x = -abs(raycast.target_position.x)

func _update_searchlight() -> void:
	# Light and detection zone follow drone rotation automatically as children.
	# This is a good place to animate flicker later if you want.
	searchlight.enabled = true

func _update_audio() -> void:
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	var volume_factor: float = clamp(1.0 - (dist / 500.0), 0.0, 1.0)

	# Range from quiet to louder
	#hum.volume_db = lerpf(-20.0, -4.0, volume_factor)

func _has_line_of_sight_to_player() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		return true

	return result["collider"] == player

func _on_detection_body_entered(body: Node) -> void:
	print("[DRONE] DetectionZone entered by:", body.name)
	if body.is_in_group("player"):
		player_in_zone = true
		print("[DRONE] Player entered detection zone")

func _on_detection_body_exited(body: Node) -> void:
	print("[DRONE] DetectionZone exited by:", body.name)
	if body.is_in_group("player"):
		player_in_zone = false
		print("[DRONE] Player left detection zone")
