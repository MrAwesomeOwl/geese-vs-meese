extends Camera2D

@export var locked_to_player: bool = true

var offset_from_player: Vector2 = Vector2(0,-10)
@onready var player: CharacterBody2D = get_tree().get_nodes_in_group("player")[0]

func _ready():
	# teleport to player BEFORE enabling smoothing
	position_smoothing_enabled = false
	global_position = player.global_position + offset_from_player
	
	
	position_smoothing_speed = 10;


func _process(delta: float) -> void:
	if locked_to_player:
		global_position = player.global_position + offset_from_player
		position_smoothing_enabled = true
