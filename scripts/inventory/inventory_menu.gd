extends Panel
class_name InventoryMenu

@onready var title_label: Label = $TitleLabel
@onready var item_list: ItemList = $ItemList
@onready var description_label: Label = $DescriptionLabel

var inventory: InventoryManager
var is_open: bool = false

func _ready() -> void:
	visible = false
	title_label.text = "Inventory"
	description_label.text = ""

	var root := get_tree().current_scene
	if root != null:
		inventory = root.get_node_or_null("InventoryManager") as InventoryManager

	if inventory == null:
		push_warning("InventoryMenu could not find InventoryManager.")
		title_label.text = "Inventory [NOT FOUND]"
		return

	inventory.inventory_changed.connect(_refresh)
	item_list.item_selected.connect(_on_item_selected)

	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_menu()

func toggle_menu() -> void:
	is_open = not is_open
	visible = is_open
	
	if inventory != null:
		inventory.decay_enabled = not is_open

	if is_open:
		_refresh()
		if item_list.item_count > 0:
			item_list.select(0)
			_show_description(0)
	else:
		description_label.text = ""

func _refresh() -> void:
	if inventory == null:
		return
	
	item_list.clear()
	
	for slot in inventory.slots:
		if slot.item != null and slot.quantity > 0:
			var line := slot.item.display_name
			if slot.quantity > 1:
				line += " x%d" % slot.quantity
			line += "  (%.0f%%)" % slot.item.clarity
			
			# Add the item to get the index
			item_list.add_item(line)
			# Get the index of the item just added
			var current_index := item_list.item_count - 1
			
			var color_to_apply := Color.WHITE

			if slot.item.clarity < 10.0:
				color_to_apply = Color(1.0, 0.2, 0.2, 1.0)
				item_list.set_item_custom_bg_color(current_index, Color(0.30, 0.00, 0.00, 0.85))
			elif slot.item.clarity < 30.0:
				color_to_apply = Color(1.0, 0.35, 0.35, 1.0)
				item_list.set_item_custom_bg_color(current_index, Color(0.20, 0.00, 0.00, 0.55))
			elif slot.item.clarity < 60.0:
				color_to_apply = Color(1.0, 0.9, 0.2, 1.0)
				item_list.set_item_custom_bg_color(current_index, Color(0.22, 0.18, 0.00, 0.40))
			else:
				item_list.set_item_custom_bg_color(current_index, Color(0, 0, 0, 0))

			item_list.set_item_custom_fg_color(current_index, color_to_apply)
	
	if item_list.item_count == 0:
		description_label.text = "Inventory is empty."

func _on_item_selected(index: int) -> void:
	_show_description(index)

func _show_description(index: int) -> void:
	if inventory == null:
		description_label.text = ""
		return

	var filled_slots: Array[InventorySlot] = []

	for slot in inventory.slots:
		if slot.item != null and slot.quantity > 0:
			filled_slots.append(slot)

	if index < 0 or index >= filled_slots.size():
		description_label.text = ""
		return

	var slot := filled_slots[index]
	var item := slot.item

	description_label.text = "%s\n\n%s\n\nClarity: %.0f%%\nWeight: %.1f" % [
		item.display_name,
		item.description,
		item.clarity,
		item.weight
	]
