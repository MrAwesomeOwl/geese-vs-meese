extends Node

func submit():
	if LevelInfo.scene_to_id_map.has(LevelInfo.current_level_path):
		var level_id = LevelInfo.scene_to_id_map[LevelInfo.current_level_path]
		# time is stored as negative since in SilentWolf bigger numbers are better
		print(level_id)
		var sw_result: Dictionary = await SilentWolf.Scores.save_score(DataManager.lb_player_info.player_id, -SpeedrunTimer.current_time, "level_"+level_id).sw_save_score_complete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("submit")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
