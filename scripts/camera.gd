extends Camera2D

var offset_from_player: Vector2 = Vector2(0,-10)
@onready var player: CharacterBody2D = get_tree().get_nodes_in_group("player")[0]

func _ready():
	# teleport to player BEFORE enabling smoothing
	global_position = player.global_position + offset_from_player
	
	position_smoothing_speed = 10;
	position_smoothing_enabled = true


func _process(delta: float) -> void:
	global_position = player.global_position + offset_from_player
