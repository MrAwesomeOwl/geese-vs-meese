extends Node
class_name LevelInfo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelTracker.current_level = get_tree().current_scene.scene_file_path
	Fader.fade(Color(0,0,0,0),1)
