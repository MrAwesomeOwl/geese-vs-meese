@icon("res://textures/ui/heart.png")
extends Node
class_name HealthStat

signal on_current_changed(new_health: float, old_health: float)
signal on_max_changed(new_max_health: float, old_max_health: float)

## maximum health
@export var maximum = 3.0:
	set(new):
		maximum = new
		current = min(current,maximum)
		on_max_changed.emit(new,max)
		
## current health
@export var current = 3.0:
	set(new):	
		current = new
		on_current_changed.emit(new,current)

## how many seconds to be invulnerable for after taking damage
@export var invulnerability_time = 0.0

## unit: msec
var last_damaged_at = -INF

func damage(amount: float):
	# if it has been long enough since the last damage that you are no longer invulnerable
	if Time.get_ticks_msec() - last_damaged_at > invulnerability_time:
		current = clampf(current - amount,0,INF)
		last_damaged_at = Time.get_ticks_msec()
