extends Control

@export var LevelsVBox: VBoxContainer
@export var LeaderboardVBox: VBoxContainer

var currently_selected_level = null

var lb_build_req_id: int = 0
var rebuild_disabled_until: int = 0
var dont_force_rebuild_wait = false

# really cursed function that allows player names to be retrieved in paralell
func get_player_name(player_id: String, player_names: Dictionary, progress: Array):
	var sw_player_result = await (func():
		var p = SilentWolf.new_players_instance()
		var request = p.get_player_data(player_id)
		while true:
			var r = await request.sw_get_player_data_complete
			if !r.success || r.player_name == player_id:
				p.queue_free()
				return r
	).call()
	
	progress[0] -= 1
	
	if !sw_player_result.success: 
		progress[1] = false
		return
	
	var data = DataManager.sw_deserialie(sw_player_result.player_data)
	if data.has("display_name") && data.display_name.length() > 0:
		player_names[player_id] = data.display_name
	else:
		player_names[player_id] = data.debug_string.split(" ")[1]
		player_names[player_id][0] = player_names[player_id][0].to_upper()
		
func show_failure(error: String, disable_rebuild_for_msec: int = 5000):
	# remove old leaderboard contents
	for child in LeaderboardVBox.get_children():
		child.queue_free()
		
	lb_build_req_id += 1
		
	rebuild_disabled_until = Time.get_ticks_msec() + disable_rebuild_for_msec
		
	var node = $ErrorTemplate.duplicate()
	node.get_node("Label").text = "Error: \n"+error
	node.visible = true
	LeaderboardVBox.add_child(node)
	
	$Loading.visible = false

func show_leaderboard(level_id: String):
	if (Time.get_ticks_msec() - rebuild_disabled_until <= 0) || $Loading.visible == true:
		return
	
	$Loading.visible = true	
	
	# remove old leaderboard contents
	for child in LeaderboardVBox.get_children():
		child.queue_free()
		
	lb_build_req_id += 1
	var this_build_rq_id = lb_build_req_id
		
	#= get leaderboard data =#
	var sw_scores_result = await SilentWolf.Scores.get_scores(0, "level_"+level_id).sw_get_scores_complete
	
	# limit number of places displayed to 10
	if !sw_scores_result.success: 
		print("1",sw_scores_result)
		show_failure("Slow down!")
		return
	
	sw_scores_result.scores.resize(min(sw_scores_result.scores.size(),10))
	
	if this_build_rq_id != lb_build_req_id: return
	
	# if nobody has beaten the level yet, show the skill issue text
	if sw_scores_result.scores.size() == 0:
		var template = $SkillIssueTemplate.duplicate()
		template.visible = true
		$Loading.visible = false
		LeaderboardVBox.add_child(template)
		return
	
	var player_names = {} #key: id, value: display name
	var pending_requests = [sw_scores_result.scores.size(),true]
	
	# get player names	
	await (func():
		var i = 0;
		for score in sw_scores_result.scores:
			i += 1
			get_player_name(score.player_name,player_names,pending_requests)
			if i % 5 == 0:
				await Util.wait(.2)
			
		while pending_requests[0] > 0:
			await Engine.get_main_loop().process_frame
			if pending_requests[1] == false: return
			if this_build_rq_id != lb_build_req_id: return
	).call()
	
	if pending_requests[1] == false:
		show_failure("Slow down!")
		return
	
	if this_build_rq_id != lb_build_req_id: 
		return
	
	
	#= acutally build leaderboard #
	
	$Loading.visible = false
	
	var place: int = 0
	for score in sw_scores_result.scores:
		if !player_names.has(score.player_name): continue
		place += 1
		#= create info line =#
		var entry
		if   place == 1: entry = $FirstPlaceTemplate.duplicate()
		elif place == 2: entry = $SecondPlaceTemplate.duplicate()
		elif place == 3: entry = $ThirdPlaceTemplate.duplicate()
		else:			 entry = $NthPlaceTemplate.duplicate()
		
		entry.get_node("VBoxContainer/Player/Anchor/Player").text = player_names[score.player_name]
		# scores are stored as msec * -1 since SilentWolf always puts higher numbers in higher places
		entry.get_node("VBoxContainer/Time").text = SpeedrunTimer.get_time_string(-score.score,false)
		if place > 3:
			var place_string = str(place)
			entry.get_node("VBoxContainer/Place/Anchor/Place").text = place_string
		
		entry.visible = true
		LeaderboardVBox.add_child(entry)
		
		#= create separator =#
		if place < sw_scores_result.scores.size():
			var separator
			if   place < 3:  separator = $BigSeparatorTemplate.duplicate()
			elif place == 3: separator = $BigSeparatorBottomTemplate.duplicate()
			else:			 separator = $SeparatorTemplate.duplicate()
			
			separator.visible = true
			LeaderboardVBox.add_child(separator)
		
	# dont let leaderboard change for a few seconds after this one is loaded
	if !dont_force_rebuild_wait:
		rebuild_disabled_until = Time.get_ticks_msec() + 2000
	dont_force_rebuild_wait = false
		
	#print(" FINAL RESULT = = ",player_names)
		
func reload_state():
	if LevelsVBox.get_node(DataManager.leaderboard_cached_level) != null:
		dont_force_rebuild_wait = true
		LevelsVBox.get_node(DataManager.leaderboard_cached_level).button_pressed = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for id in LevelInfo.level_order:
		var button = $LevelButtonTemplate.duplicate()
		LevelsVBox.add_child(button)
		button.visible = true
		button.get_node("Control/Level").text = LevelInfo.levels[id].display_name
		button.name = id
		button.toggled.connect(func _on_level_button_toggled(toggled_on):
			if toggled_on:
				if (Time.get_ticks_msec() - rebuild_disabled_until <= 0) || $Loading.visible == true: 
					button.button_pressed = false
					return
					
				button.mouse_filter = MOUSE_FILTER_IGNORE
				
				if currently_selected_level:
					LevelsVBox.get_node(currently_selected_level).button_pressed = false
					LevelsVBox.get_node(currently_selected_level).mouse_filter = MOUSE_FILTER_STOP
				
				currently_selected_level = id
				DataManager.leaderboard_cached_level = id
				show_leaderboard(id)
		)
	
	SilentWolf.on_connection_failure.connect(func _on_sw_connection_failure():
		print("Connection failure handled")
		show_failure("Slow down!")	
	)
	
	call_deferred("reload_state")
		#currently_selected_level = DataManager.leaderboard_cached_level
		#show_leaderboard(DataManager.leaderboard_cached_level)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_refresh_pressed() -> void:
	if currently_selected_level:
		show_leaderboard(currently_selected_level)
