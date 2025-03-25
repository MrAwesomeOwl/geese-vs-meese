extends Node

var leaderboard_cached_level: String

signal on_lb_player_info_loaded()
var    is_lb_player_info_loaded:=false

var has_authed_before = false

var lb_player_info = {
	"id": "",
	"token": "",
	"username": "",
}

var cached_times = {}

func submit_score(level_id: String, time_msec: int):
	if LeaderboardClient.is_connected_to_server:
		LeaderboardClient.send_packet({
			"type": "postScore",
			"levelId": level_id,
			"time": time_msec
		})
	else:
		if !(level_id in cached_times) || cached_times[level_id] > time_msec:
			cached_times[level_id] = time_msec
			write_cached_times_file()
			
func write_cached_times_file(file_path: String = "user://cached_times.txt"):
	var cached_times_strings = []
	for level_id in cached_times:
		cached_times_strings.append(level_id+":"+str(cached_times[level_id])) 
	var file = FileAccess.open(file_path,FileAccess.WRITE)
	file.resize(0) #erase previous contents of file
	file.store_string("\n".join(cached_times_strings))
	file.flush()

func write_lb_file(file_path: String = "user://lb_account.txt"):
	var file_lb_player_info = FileAccess.open(file_path,FileAccess.WRITE)
	file_lb_player_info.resize(0) #erase previous contents of file
	file_lb_player_info.store_string(
		lb_player_info.id+"\n"+
		lb_player_info.token+"\n"+
		lb_player_info.username
	)
	file_lb_player_info.flush()
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#= lb player info =#
	LeaderboardClient.connect_to_server()
	LeaderboardClient.on_successfully_connected.connect(func():
		if has_authed_before == true:
			LeaderboardClient.authenticate(lb_player_info.id,lb_player_info.token)
	)
	LeaderboardClient.on_authenticated.connect(func():
		has_authed_before = true
		if cached_times.size() > 0:
			for level_id in cached_times:
				submit_score(level_id,cached_times[level_id])
			cached_times = {}
			write_cached_times_file()
	)
	
	# create file if not there
	if !FileAccess.file_exists("user://lb_account.txt"):
		FileAccess.open("user://lb_account.txt",FileAccess.WRITE).close()
	if !FileAccess.file_exists("user://cached_times.txt"):
		FileAccess.open("user://cached_times.txt",FileAccess.WRITE).close()
		
	# read the files
	var file_cached_times = FileAccess.open("user://cached_times.txt",FileAccess.READ_WRITE)
	for level_entry: String in file_cached_times.get_as_text().split("\n"):
			if level_entry == '': continue
			var split = level_entry.split(":")
			cached_times[split[0]] = int(split[1])
	
	var file_lb_player_info = FileAccess.open("user://lb_account.txt",FileAccess.READ_WRITE)
	var file_lines = file_lb_player_info.get_as_text().split("\n")
	
		
	if not LeaderboardClient.is_connected_to_server: await LeaderboardClient.on_successfully_connected
	
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
