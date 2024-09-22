extends Node

@onready var moose_template = preload("res://objects/moose.tscn")
@onready var moose_container = get_node("../Meese")

@export var wave_count: int = 1
var current_wave = 0

var started = false

func spawn_moose(spawnLocation: String):
	var new_moose = moose_template.instantiate()
	var spawn_point = get_node("MooseSpawns/"+str(spawnLocation))
	new_moose.START_DIRECTION = spawn_point.get_meta("start_direction",1)
	moose_container.add_child(new_moose)
	new_moose.global_position = spawn_point.global_position
	
# waits until all meese have been killed
func wait_for_murder():
	while moose_container.get_child_count() > 0:
		await Util.wait(0.1)
	
func do_wave_stuff():
	$AnimationPlayer.play("entrance")
	await $AnimationPlayer.animation_finished
	
	while current_wave < wave_count:
		current_wave += 1
		$AnimationPlayer.play("wave_"+str(current_wave))
		await $AnimationPlayer.animation_finished
		await wait_for_murder()
		
	$AnimationPlayer.play("win")

func _on_start_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not started:
			started = true
			do_wave_stuff()
