@tool
extends Button

signal on_value_changed(new_value: bool, old_value: bool)

var check_texture = preload("res://textures/ui/check.png")
var invisible_texture = preload("res://textures/invisible.png")

@export var is_checked: bool = false:
	set(value):
		if $TextureRect:
			$TextureRect.visible = value
		var old_value = value
		is_checked = value
		on_value_changed.emit(value,old_value)
		
func _ready() -> void:
	$TextureRect.visible = is_checked

func _on_pressed() -> void:
	is_checked = not is_checked
