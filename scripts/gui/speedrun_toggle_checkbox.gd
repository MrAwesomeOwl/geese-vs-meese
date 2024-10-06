@tool

extends "res://scripts/gui/checkbox.gd"

func _ready() -> void:
	is_checked = SpeedrunTimer.visible

func _on_value_changed(new_value: bool, old_value: bool) -> void:
	SpeedrunTimer.visible = new_value
