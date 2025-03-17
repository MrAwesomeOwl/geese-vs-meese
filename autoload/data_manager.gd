extends Node

var leaderboard_cached_level: String

signal on_lb_player_info_loaded()
var    is_lb_player_info_loaded:=false

var lb_player_info = {
	"id": "",
	"token": "",
	"username": "",
}

# silentwolf apparently cannot handle strings that have non base64 characters so....
func sw_serialize(input: Dictionary) -> Dictionary:
	return {"data": Marshalls.utf8_to_base64(JSON.stringify(input))}
	
func sw_deserialie(input: Dictionary) -> Dictionary:
	if !input.has("data"): return {}
	return JSON.parse_string(Marshalls.base64_to_utf8(input.data))

func write_lb_file(file_path: String = "user://lb_account.txt"):
	var file_lb_player_info = FileAccess.open(file_path,FileAccess.WRITE)
	file_lb_player_info.resize(0) #erase previous contents of file
	file_lb_player_info.store_string(lb_player_info.id+"\n"+lb_player_info.token+"\n"+lb_player_info.username)
	file_lb_player_info.flush()
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#= lb player info =#
	LeaderboardClient.connect_to_server()
	
	# create file if not there
	if !FileAccess.file_exists("user://lb_account.txt"):
		FileAccess.open("user://lb_account.txt",FileAccess.WRITE).close()
		
	# read the file
	var file_lb_player_info = FileAccess.open("user://lb_account.txt",FileAccess.READ_WRITE)
	var file_lines = file_lb_player_info.get_as_text().split("\n")
		
	if not LeaderboardClient.connection_open: await LeaderboardClient.on_successfully_connected
	
	var should_register = false
	# if data exists, try using it to log in:
	if file_lines.size() == 3:
		lb_player_info.id = file_lines[0]
		lb_player_info.token = file_lines[1]
		lb_player_info.username = file_lines[2]
		var result = await LeaderboardClient.authenticate(lb_player_info.id,lb_player_info.token)
		if "failed" in result:
			should_register = true
			write_lb_file("user://lb_account_%s.txt"%file_lines[0])
	else: should_register = true
		
	if should_register:
		print("registering new account")
		var result = await LeaderboardClient.register()
		if "failed" in result: push_error("uh oh it failed",result)
		lb_player_info.id = result.id
		lb_player_info.token = result.token
		write_lb_file()
		
	is_lb_player_info_loaded = true
	on_lb_player_info_loaded.emit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
