extends LineEdit

var last_text: String = text

func apply_changes():
	DataManager.lb_player_info.username = text
	DataManager.write_lb_file()
	LeaderboardClient.send_packet({"type":"changeName","newName":text})

func update_connection_state():
	if LeaderboardClient.connection_open:
		if text == "" && has_meta("stored_text"):
			text = get_meta("stored_text")
		placeholder_text = "Your Name (Click)"
		editable = true
	else:
		set_meta("stored_text",text)
		text = ""
		placeholder_text = "(Not Connected)"
		editable = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_connection_state()
	LeaderboardClient.on_disconnected.connect(update_connection_state)
	LeaderboardClient.on_successfully_connected.connect(update_connection_state)
	
	if !DataManager.is_lb_player_info_loaded:
		await DataManager.on_lb_player_info_loaded
	text = DataManager.lb_player_info.username
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
