extends Node
class_name InventoryManager

signal inventory_changed
signal item_added(item: InventoryItem)
signal item_forgotten(item_name: String)

@export var max_slots: int = 8
@export var clarity_decay_rate: float = 0.5
@export var decay_enabled: bool = true
@export var clarity_tick_interval: float = 1.0

var _clarity_tick_timer: float = 0.0
var slots: Array[InventorySlot] = []

func _ready() -> void:
	set_process(true)
	for i in max_slots:
		var slot := InventorySlot.new()
		slots.append(slot)
		
func _process(delta: float) -> void:
	if not decay_enabled:
		return
		
	_clarity_tick_timer += delta
	if _clarity_tick_timer < clarity_tick_interval:
		return

	_clarity_tick_timer = 0.0

	var changed := false

	for slot in slots:
		if slot.item == null or slot.quantity <= 0:
			continue

		var old_clarity := slot.item.clarity
		slot.item.clarity = max(slot.item.clarity - clarity_decay_rate, 0.0)

		if slot.item.clarity != old_clarity:
			changed = true

		if slot.item.clarity <= 0.0:
			var forgotten_name := slot.item.display_name
			print("[INV] Item forgotten:", forgotten_name)

			slot.item = null
			slot.quantity = 0
			changed = true
			item_forgotten.emit(forgotten_name)

	if changed:
		inventory_changed.emit()

func add_item(new_item: InventoryItem, amount: int = 1) -> bool:
	print("[INV] Trying to add item:", new_item)
	if new_item == null:
		print("[INV] ERROR: new_item is null")
		return false

	# Try stacking first
	if new_item.stackable:
		for slot in slots:
			if slot.item != null and slot.item.item_id == new_item.item_id:
				if slot.quantity < new_item.max_stack:
					print("[INV] Stacking item:", new_item.display_name)
					slot.quantity += amount
					inventory_changed.emit()
					item_added.emit(new_item)
					return true

	# Find empty slot
	for slot in slots:
		if slot.is_empty():
			print("[INV] Placing item in empty slot:", new_item.display_name)
			slot.item = new_item
			slot.quantity = amount
			inventory_changed.emit()
			item_added.emit(new_item)
			return true

	return false

func has_item(item_id: String) -> bool:
	for slot in slots:
		if slot.item != null and slot.item.item_id == item_id:
			return true
	return false

func remove_item(item_id: String, amount: int = 1) -> bool:
	for slot in slots:
		if slot.item != null and slot.item.item_id == item_id:
			slot.quantity -= amount
			if slot.quantity <= 0:
				slot.item = null
				slot.quantity = 0
			inventory_changed.emit()
			return true
	return false

func get_item_names() -> Array[String]:
	var names: Array[String] = []
	for slot in slots:
		if slot.item != null and slot.quantity > 0:
			if slot.quantity > 1:
				names.append("%s x%d" % [slot.item.display_name, slot.quantity])
			else:
				names.append(slot.item.display_name)
	return names
