@icon("res://textures/ui/heart.png")
extends Node
class_name HealthStat

signal on_current_changed(new_health: float, old_health: float)
signal on_max_changed(new_max_health: float, old_max_health: float)

@export var maximum = 3.0:
	set(new):
		maximum = new
		current = min(current,maximum)
		on_max_changed.emit(new,max)
		
@export var current = 3.0:
	set(new):	
		current = new
		on_current_changed.emit(new,current)
