extends CanvasLayer

@onready var safari_label_pos = $SafariLabel.position

func _ready():
	if OS.get_name() != "Web":
		get_tree().change_scene_to_file("res://scenes/menus/title.tscn")
		return
		
	var user_agent = (JavaScriptBridge.eval("navigator.userAgent") as String)
	if (user_agent.find("Mac") > -1 && user_agent.find("Safari") > -1):
		await Fader.fade("#00000000",0)
		$AnimationPlayer.play("no_safari")
	else:
		$HTTPRequest.request_completed.connect(_on_request_completed)
		$HTTPRequest.request("https://api.github.com/repos/MrAwesomeOwl/geese-vs-meese-web-upload")
		
func _process(delta: float) -> void:
	$SafariLabel.position = safari_label_pos + Vector2(randi_range(-3,3),randi_range(-3,3))

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
	
			
