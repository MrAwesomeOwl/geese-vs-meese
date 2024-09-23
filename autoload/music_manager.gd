extends AudioStreamPlayer

var is_muted = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_music"):
		is_muted = not is_muted
		
	var target_volume_offset = 0 if is_muted else 1
	
	volume_db = linear_to_db(Util.smooth_step(db_to_linear(volume_db),target_volume_offset,0.9,delta))
