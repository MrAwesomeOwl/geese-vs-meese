extends Label

## the colors will loop every this many seconds
@export var loops_per_second: float = 1.0
@export var colors: GradientTexture1D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var pixel_index = remap(wrapf(Time.get_ticks_msec() / loops_per_second,0,1000),0,1000,0,colors.width)
	modulate = colors.get_image().get_pixel(pixel_index,0)
