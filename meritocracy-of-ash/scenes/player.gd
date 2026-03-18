extends CharacterBody2D

@export var speed: float = 160.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

@export var dash_speed: float = 450.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.5

@export var turn_speed: float = 10.0

@export var trail_spawn_interval: float = 0.03
@export var trail_lifetime: float = 0.18
@export var trail_scale: float = 0.95

@export var shake_strength: float = 7.0
@export var shake_fade_speed: float = 30.0

var is_dashing := false
var dash_timer := 0.0
var cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var facing_direction := Vector2.RIGHT

var trail_timer := 0.0
var current_shake_strength := 0.0

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var camera: Camera2D = $Camera2D

func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0 and input_vector != Vector2.ZERO:
		start_dash(input_vector)

	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta

		trail_timer -= delta
		if trail_timer <= 0.0:
			spawn_dash_trail()
			trail_timer = trail_spawn_interval

		if dash_timer <= 0.0:
			is_dashing = false
	else:
		var target_velocity := input_vector * speed

		if input_vector != Vector2.ZERO:
			velocity = velocity.move_toward(target_velocity, acceleration * delta)
			facing_direction = input_vector
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	update_facing(delta)
	update_camera_shake(delta)

func start_dash(direction: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_time
	cooldown_timer = dash_cooldown
	dash_direction = direction
	facing_direction = dash_direction
	trail_timer = 0.0
	add_camera_shake(shake_strength)

func update_facing(delta: float) -> void:
	if facing_direction == Vector2.ZERO:
		return

	var target_angle := facing_direction.angle()
	visuals.rotation = lerp_angle(visuals.rotation, target_angle, turn_speed * delta)

func spawn_dash_trail() -> void:
	if sprite.texture == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.frame_coords = sprite.frame_coords

	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.global_scale = sprite.global_scale * trail_scale
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v

	ghost.modulate = Color(1, 1, 1, 0.45)

	get_parent().add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), trail_lifetime)
	tween.parallel().tween_property(ghost, "scale", ghost.scale * 0.9, trail_lifetime)
	tween.tween_callback(ghost.queue_free)

func add_camera_shake(amount: float) -> void:
	current_shake_strength = max(current_shake_strength, amount)

func update_camera_shake(delta: float) -> void:
	if current_shake_strength > 0.0:
		camera.offset = Vector2(
			randf_range(-current_shake_strength, current_shake_strength),
			randf_range(-current_shake_strength, current_shake_strength)
		)
		current_shake_strength = move_toward(current_shake_strength, 0.0, shake_fade_speed * delta)
	else:
		camera.offset = Vector2.ZERO
