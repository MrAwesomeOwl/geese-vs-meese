extends Camera2D

@onready var player: CharacterBody2D = get_tree().get_nodes_in_group("player")[0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = Util.smooth_step(position,player.position - Vector2(0,10),0.7,delta)
