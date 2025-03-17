extends Control

@export var LevelsVBox: VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for level_id in LevelInfo.level_order:
		var level = LevelInfo.levels[level_id]
		var button = $ButtonTemplate.duplicate()
		button.get_node("Control/Name").text = level.display_name
		button.get_node("Control/Author").text = level.author
		button.scene_path = level.scene_path
		LevelsVBox.add_child(button)
		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
