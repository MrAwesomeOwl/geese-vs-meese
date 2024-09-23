extends Button

func _on_pressed():
	get_tree().quit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
