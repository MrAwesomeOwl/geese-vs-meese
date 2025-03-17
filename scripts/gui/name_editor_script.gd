extends LineEdit

var last_text: String = text

func apply_changes():
	DataManager.lb_player_info.display_name = text
	DataManager.write_lb_file()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = DataManager.lb_player_info.display_name
	last_text = text

func _on_focus_exited() -> void:
	apply_changes()


func _on_text_submitted(new_text: String) -> void:
	release_focus()

func limit_length():
	if $SizeTester.get_rect().size.x > 150:
		var column = caret_column
		text = last_text
		caret_column = column-1
	
	last_text = text
	

func _on_text_changed(new_text: String) -> void:
	$SizeTester.text = text
	call_deferred("limit_length")
