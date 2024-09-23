extends Button

@export var scene_path: String = ""

var has_been_pressed: bool = false

func _on_pressed():
	if has_been_pressed: return
	has_been_pressed = true
	await Fader.fade(Color(0,0,0),1,Color(0,0,0,0))
	get_tree().call_deferred("change_scene_to_file", LevelTracker.current_level)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
