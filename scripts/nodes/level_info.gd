extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelInfo.current_level_path = get_tree().current_scene.scene_file_path
	SpeedrunTimer.start_timer()
	Fader.fade(Color(0,0,0,0),1)
