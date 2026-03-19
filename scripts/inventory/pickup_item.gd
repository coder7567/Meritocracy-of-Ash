extends Area2D

@export var item_data: InventoryItem
@export var pickup_prompt: String = "Pick up"
@export var auto_pickup: bool = false

var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if auto_pickup and player_in_range:
		_try_pickup()

	if player_in_range and Input.is_action_just_pressed("interact"):
		_try_pickup()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _try_pickup() -> void:
	if item_data == null:
		return

	var inventory := get_tree().get_first_node_in_group("inventory_manager") as InventoryManager
	if inventory == null:
		push_warning("No InventoryManager found in group 'inventory_manager'.")
		return

	var added := inventory.add_item(item_data, 1)
	if added:
		queue_free()
