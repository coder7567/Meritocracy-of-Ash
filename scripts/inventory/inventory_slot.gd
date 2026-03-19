extends Resource
class_name InventorySlot

@export var item: InventoryItem
@export var quantity: int = 0

func is_empty() -> bool:
	return item == null or quantity <= 0
