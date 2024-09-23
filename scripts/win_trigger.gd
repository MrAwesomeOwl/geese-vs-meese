@icon("res://textures/apple_fritter.png")

extends Area2D

var is_triggered = false

func _on_body_entered(body: Node2D) -> void:
	if is_triggered: return
	is_triggered = true
	if body.is_in_group("player"):
		await Fader.fade(Color("#fef3c0"),4,Color("#fef3c0",0))
		get_tree().call_deferred("change_scene_to_file", "res://scenes/menus/win.tscn")
		
func _ready():
	body_entered.connect(_on_body_entered)
