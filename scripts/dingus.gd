extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(func(b: Node):
		if b.is_in_group("player"):	
			b.get_node("Health")["current" if str(name)[0] == "c" else "maximum"] += (1 if str(name)[1] == "p" else -1)
	)
