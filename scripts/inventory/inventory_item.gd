extends Resource
class_name InventoryItem

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1

# Future systems
@export var clarity: float = 100.0
@export var weight: float = 1.0
@export var key_item: bool = false
