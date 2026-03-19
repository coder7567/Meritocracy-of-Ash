extends Label

var inventory: InventoryManager

func _ready() -> void:
	print("[UI] InventoryDebugLabel _ready called")

	visible = true
	text = "DEBUG LABEL STARTED"
	position = Vector2(20, 20)
	size = Vector2(500, 300)

	var root := get_tree().current_scene
	print("[UI] current_scene =", root)

	if root != null:
		inventory = root.get_node_or_null("InventoryManager") as InventoryManager
		print("[UI] inventory found =", inventory)

	if inventory == null:
		text = "Inventory NOT FOUND"
		print("[UI] ERROR: InventoryManager not found")
		return

	print("[UI] SUCCESS: InventoryManager connected")

	inventory.inventory_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	print("[UI] Refresh called")

	if inventory == null:
		text = "Inventory NULL"
		print("[UI] ERROR: inventory is null in refresh")
		return

	var lines: Array[String] = []

	for slot in inventory.slots:
		print("[UI] Checking slot:", slot)

		if slot.item != null and slot.quantity > 0:
			print("[UI] Found item:", slot.item.display_name)
			lines.append(slot.item.display_name)

	if lines.is_empty():
		text = "Inventory: Empty"
	else:
		text = "Inventory:\n- " + "\n- ".join(lines)

	print("[UI] Label text now =", text)
