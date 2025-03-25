extends Node

func submit():
	if LevelInfo.scene_to_id_map.has(LevelInfo.current_level_path):
		var level_id = LevelInfo.scene_to_id_map[LevelInfo.current_level_path]
		DataManager.submit_score(level_id,SpeedrunTimer.current_time)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("submit")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
