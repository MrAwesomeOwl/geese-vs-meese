@icon("res://textures/powerups/heart.png")
extends Area2D

@export var HEALTH_REWARD = 1

var has_been_collected = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not has_been_collected:
		has_been_collected = true
		var health: HealthStat = body.get_node("Health")
		
		health.maximum += HEALTH_REWARD
		health.current += HEALTH_REWARD
		
		# play pickup sound
		$CollectSound.play()
	
		# play despawn animation
		$AnimationPlayer.play("collect")
