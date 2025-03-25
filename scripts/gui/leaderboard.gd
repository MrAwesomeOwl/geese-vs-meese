extends Control

@export var LevelsVBox: VBoxContainer
@export var LeaderboardVBox: VBoxContainer

var currently_selected_level = null

var lb_build_req_id: int = 0
var rebuild_disabled_until: int = 0
var dont_force_rebuild_wait = false
var reload_queued_for_reconnect = false
		
func show_failure(error: String, disable_rebuild_for_msec: int = 500):
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
		
	if !LeaderboardClient.is_connected_to_server:
		reload_queued_for_reconnect = true
		show_failure("No connection")
		return
	
	$Loading.visible = true	
	
	# remove old leaderboard contents
	for child in LeaderboardVBox.get_children():
		child.queue_free()
		
	lb_build_req_id += 1
	var this_build_rq_id = lb_build_req_id
		
	#= get leaderboard data =#
	var scores = await LeaderboardClient.get_scores(level_id)
	scores = scores.filter(func(a): return a[0] != "") # remove unnamed players
	
	if scores.size() > 0 && scores[0] is String && scores[0] == "failed":
		show_failure(scores[1])
	
	if this_build_rq_id != lb_build_req_id: return
	
	# if nobody has beaten the level yet, show the skill issue text
	if scores.size() == 0:
		var template = $SkillIssueTemplate.duplicate()
		template.visible = true
		$Loading.visible = false
		LeaderboardVBox.add_child(template)
		return
	else:
		scores.sort_custom(func(a, b):
			return a[1] < b[1]
		)
	
	if this_build_rq_id != lb_build_req_id: 
		return
	
	
	#= acutally build leaderboard #
	
	$Loading.visible = false
	
	var place: int = 0
	for score in scores:
		var username = score[0] as String
		var time = score[1] as float
		place += 1
		#= create info line =#
		var entry
		if   place == 1: entry = $FirstPlaceTemplate.duplicate()
		elif place == 2: entry = $SecondPlaceTemplate.duplicate()
		elif place == 3: entry = $ThirdPlaceTemplate.duplicate()
		else:			 entry = $NthPlaceTemplate.duplicate()
		
		entry.get_node("VBoxContainer/Player/Anchor/Player").text = username
		entry.get_node("VBoxContainer/Time").text = SpeedrunTimer.get_time_string(time,false)
		if place > 3:
			var place_string = str(place)
			entry.get_node("VBoxContainer/Place/Anchor/Place").text = place_string
		
		entry.visible = true
		LeaderboardVBox.add_child(entry)
		
		#= create separator =#
		if place < scores.size():
			var separator
			if   place < 3:  separator = $BigSeparatorTemplate.duplicate()
			elif place == 3: separator = $BigSeparatorBottomTemplate.duplicate()
			else:			 separator = $SeparatorTemplate.duplicate()
			
			separator.visible = true
			LeaderboardVBox.add_child(separator)
		
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
	
	LeaderboardClient.on_successfully_connected.connect(func():
		if reload_queued_for_reconnect:
			show_leaderboard(currently_selected_level)
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
