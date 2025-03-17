extends Node

# super secret api key = aqhOBCzVc5pqCRllqQ7j5uZ6xRHDhx04zSYpqMQ8

var leaderboard_cached_level: String

signal lb_player_info_loaded()

var lb_player_info = {
	"player_id": "",
	"display_name": "",
	"debug_string": ""
}

# silentwolf apparently cannot handle strings that have non base64 characters so....
func sw_serialize(input: Dictionary) -> Dictionary:
	return {"data": Marshalls.utf8_to_base64(JSON.stringify(input))}
	
func sw_deserialie(input: Dictionary) -> Dictionary:
	if !input.has("data"): return {}
	return JSON.parse_string(Marshalls.base64_to_utf8(input.data))

func write_lb_file():
	var file_lb_player_info = FileAccess.open("user://lb_player_info.txt",FileAccess.WRITE)
	file_lb_player_info.resize(0) #erase previous contents of file
	file_lb_player_info.store_string(lb_player_info.player_id+"\n"+lb_player_info.display_name+"\n"+lb_player_info.debug_string)
	file_lb_player_info.flush()
	SilentWolf.Players.save_player_data(lb_player_info.player_id, sw_serialize({"display_name": lb_player_info.display_name, "debug_string": lb_player_info.debug_string}))
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#= set up silentwolf =#
	SilentWolf.configure({
		"api_key": "aqhOBCzVc5pqCRllqQ7j5uZ6xRHDhx04zSYpqMQ8",
		"game_id": "Geesevs.Meese",
		"log_level": 1
	})
	
	#= lb player info =#
	
	# create file if not there
	if !FileAccess.file_exists("user://lb_player_info.txt"):
		FileAccess.open("user://lb_player_info.txt",FileAccess.WRITE).close()
		
	# read the file
	var file_lb_player_info = FileAccess.open("user://lb_player_info.txt",FileAccess.READ_WRITE)
	var file_lines = file_lb_player_info.get_as_text().split("\n")
		
	# if data has not been set up yet or is wrong, initialize it
	if file_lines.size() != 3:
		lb_player_info.player_id = UUID.as_string().replace("-","").substr(0,30)
		lb_player_info.debug_string = ObjectNameGenerator.generate_name()
		write_lb_file()
	# otherwise just load what's there
	else:
		lb_player_info.player_id = file_lines[0]
		lb_player_info.display_name = file_lines[1]
		lb_player_info.debug_string = file_lines[2]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
