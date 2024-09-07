@icon("res://textures/powerups/poison.png")
extends Area2D

## unit: seconds
@export var EFFECT_LENGTH = 20

var has_been_collected = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not has_been_collected:
		has_been_collected = true
		var health: HealthStat = body.get_node("Health")
		
		body.max_poison_time = max(body.poison_time_remaining,0) + EFFECT_LENGTH
		body.poison_time_remaining += EFFECT_LENGTH
			
		# play despawn animation
		$AnimationPlayer.play("collect")
