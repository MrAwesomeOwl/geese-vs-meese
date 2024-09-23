extends Area2D

@export var scene_path: String
var is_triggered = false

func _on_body_entered(body: Node2D) -> void:
	if is_triggered: return
	is_triggered = true
	if body.is_in_group("player"):
		await Fader.fade(Color(0,0,0),1,Color(0,0,0,0))
		get_tree().call_deferred("change_scene_to_file", scene_path)

func _ready():
	body_entered.connect(_on_body_entered)
