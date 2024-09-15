extends Node2D

@export var float_amount = 2.0
@export var float_speed = 4.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#position.y = Util.smooth_step(position.y,sin(Time.get_ticks_msec()/1000.0*float_speed) * float_amount,0.9,delta)
	position.y = sin(Time.get_ticks_msec()/1000.0*float_speed) * float_amount
