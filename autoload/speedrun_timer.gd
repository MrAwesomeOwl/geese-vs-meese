extends CanvasLayer

var is_running: bool = false
var started_at_time_msec: int = 0

@onready var label: RichTextLabel = $Main/Label

enum TIMER_COLOR {
	PAUSE,
	RUNNING,
	LOST,
	WON
}

var color_map = {
	TIMER_COLOR.PAUSE: Color("#bababa"),
	TIMER_COLOR.RUNNING: Color("#5eff89"),
	TIMER_COLOR.LOST: Color("#ff5252"),
	TIMER_COLOR.WON: Color("#61c2ff"),
}

func _ready():
	label.modulate = color_map[TIMER_COLOR.PAUSE]

func start_timer():
	started_at_time_msec = Time.get_ticks_msec()
	is_running = true
	label.modulate = color_map[TIMER_COLOR.RUNNING]
	
func end_timer(color: TIMER_COLOR):
	is_running = false
	label.modulate = color_map[color]

func _process(delta: float) -> void:
	if is_running:
		var msec = Time.get_ticks_msec() - started_at_time_msec
		# create time string
		var time_sec = floorf(msec / 1000.0)
		
		var minutes = floorf(time_sec/60)
		var seconds = time_sec - (minutes*60)
		var subsecs = 99-floorf((time_sec*1000+1000 - msec)/10)
		
		var strmin = str(minutes)
		var strsec = str(seconds)
		var strsub = str(subsecs)
		
		if minutes > 0 and strsec.length() < 2: strsec = "0"+strsec
		if strsub.length() < 2: strsub = "0"+strsub
		
		label.text = strsec+"[font_size=9]."+strsub
		if minutes > 0:
			label.text = strmin+":"+label.text
