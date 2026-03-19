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

@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 10.0
@export var dash_stamina_cost: float = 35.0
@export var stamina_regen_delay: float = 1.0

var is_dashing := false
var can_move := true
var dash_timer := 0.0
var cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var facing_direction := Vector2.RIGHT

var trail_timer := 0.0
var current_shake_strength := 0.0

var nearby_interactables: Array[Node] = []

var stamina: float = 100.0
var stamina_regen_delay_timer: float = 0.0

var ui: Node = null

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	print("Player ready")
	print("Interaction area node: ", interaction_area)
	stamina = max_stamina
	ui = get_tree().get_first_node_in_group("game_ui")
	print("UI node: ", ui)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	update_stamina_ui()
	
func update_stamina_ui() -> void:
	if ui and ui.has_method("update_stamina"):
		ui.update_stamina(stamina, max_stamina)

func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	if Input.is_action_just_pressed("interact"):
		interact()

	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	if stamina_regen_delay_timer > 0.0:
		stamina_regen_delay_timer -= delta
	else:
		stamina = min(stamina + stamina_regen_rate * delta, max_stamina)
	update_stamina_ui()

	# --- UPDATED DASH INPUT LOGIC ---
	if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0 and input_vector != Vector2.ZERO:
		if stamina >= dash_stamina_cost:
			start_dash(input_vector)
		else:
			# FAILED DASH: Just shake the camera and flash the bar red
			add_camera_shake(6.0) # A smaller "frustration" shake
			if ui and ui.has_method("flash_stamina_red"):
				ui.flash_stamina_red()


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
			
	if can_move:
		move_and_slide()
		update_facing(delta)
		
	update_camera_shake(delta)

func start_dash(direction: Vector2) -> void:
	stamina -= dash_stamina_cost
	stamina = max(stamina, 0.0)
	stamina_regen_delay_timer = stamina_regen_delay
	update_stamina_ui()
	
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

func interact() -> void:
	if nearby_interactables.is_empty():
		return

	var closest = get_closest_interactable()
	if closest and closest.has_method("interact"):
		closest.interact(self)

func get_closest_interactable() -> Node:
	var closest: Node = null
	var closest_distance := INF

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue

		var distance = global_position.distance_to(interactable.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = interactable

	return closest

func _on_interaction_area_entered(area: Area2D) -> void:
	print("Entered area: ", area.name)
	print("Groups: ", area.get_groups())
	if area.is_in_group("interactable"):
		print("Interactable detected")
		nearby_interactables.append(area)

func _on_interaction_area_exited(area: Area2D) -> void:
	print("Exited area: ", area.name)
	if area.is_in_group("interactable"):
		nearby_interactables.erase(area)
		
func trigger_flashback() -> void:
	can_move = false
	
	if ui and ui.has_method("flash_screen"):
		ui.flash_screen()
	
	add_camera_shake(18.0)
	
	# simple delay before restoring control
	await get_tree().create_timer(1.2).timeout
	
	can_move = true
