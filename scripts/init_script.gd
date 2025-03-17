extends CanvasLayer

func _ready():
	if OS.get_name() != "Web":
		get_tree().change_scene_to_file("res://scenes/menus/title.tscn")
		return
	
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request("https://api.github.com/repos/MrAwesomeOwl/geese-vs-meese-web-upload")

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var description: String = json["description"]
	if description[0] == "$":
		description = description.substr(1)
		var entries = description.split(";")
		if entries[0] == "disabled":
			$TextureRect.visible = false
			$Label.visible = true
			return
			
	get_tree().change_scene_to_file("res://scenes/menus/title.tscn")
	
			
