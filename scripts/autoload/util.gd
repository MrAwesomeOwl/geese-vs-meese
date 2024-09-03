extends Node


## framerate-independent lerp for smoothing effects[br]
## alpha works opposite to normal lerp (alpha 1 = no change, alpha 0 = full change)
func smooth_step(start, goal, alpha: float, dt: float):
	alpha = 1 - pow(alpha , (dt * 60))
	
	return start + (goal - start) * alpha
	
## rounds `x` to the nearest multiple of `m`
func round_multiple(x,m):
	return round(x/m) * m
