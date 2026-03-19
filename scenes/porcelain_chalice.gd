extends Area2D

@export var picked_up := false
@export var item_data: InventoryItem
@export var inventory_path: NodePath

var inventory: InventoryManager

func _ready() -> void:
	if inventory_path != NodePath():
		inventory = get_node_or_null(inventory_path) as InventoryManager

func interact(player: Node) -> void:
	print("[CHALICE] interact called")
	if picked_up:
		print("[CHALICE] already picked up, ignoring")
		return
		
	print("[CHALICE] inventory =", inventory)
	print("[CHALICE] item_data =", item_data)

	if inventory == null:
		push_warning("Porcelain Chalice could not find InventoryManager.")
		return

	if item_data == null:
		push_warning("Porcelain Chalice has no item_data assigned.")
		return

	var added := inventory.add_item(item_data, 1)
	if not added:
		print("Inventory full. Could not pick up Porcelain Chalice.")
		return

	picked_up = true
	
	var security = get_tree().current_scene.get_node_or_null("SecuritySystem")
	if security:
		security.trigger_alert(global_position)
		
	print("Beanbag picks up the Porcelain Chalice.")
	trigger_memory_flashback(player)
	queue_free()

func trigger_memory_flashback(player: Node) -> void:
	print("Flashback triggered: cold water, a dying young man, a coat of arms.")
	if player.has_method("trigger_flashback"):
		player.trigger_flashback()
