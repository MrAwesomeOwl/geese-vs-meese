extends Node

class_name UnfadeOnLoad


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var color = Fader.goal_color
	color.a = 0
	Fader.fade(color,1)
