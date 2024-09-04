@icon("res://textures/ui/heart.png")
extends Node
class_name HealthStat

signal on_current_changed(new_health: float, old_health: float)
signal on_max_changed(new_max_health: float, old_max_health: float)
signal on_death()

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
		if current <= 0:
			is_dead = true
			on_death.emit()

## how many seconds to be invulnerable for after taking damage
@export var invulnerability_time = 0.0

## true if the player is dead (wow i would have never guessed)
var is_dead: bool = false;

## true if damage cooldown is active
var is_invulnerable: 
	get: 
		return Time.get_ticks_msec() - last_damaged_at < invulnerability_time*1000

## unit: msec
var last_damaged_at = -INF

func damage(amount: float):
	# if it has been long enough since the last damage that you are no longer invulnerable
	if not is_invulnerable:
		current = clampf(current - amount,0,INF)
		last_damaged_at = Time.get_ticks_msec()
