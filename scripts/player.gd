extends CharacterBody2D

@export var SPEED = 150.0
## lower values result in slipperier movement (like ice)
@export_range(0,10) var SNAPPINESS = 5
@export var JUMP_STRENGTH = 325.0
@export var DAMAGE = 1.0
@export var KNOCKBACK = 300.0

@export_group("Internal stuff (ignore)")
## if true, facing_direction won't automatically change
@export var facing_direction_locked: bool

var facing_direction = 1.0
var knockback_vector: Vector2 = Vector2(0,0)
var time_knockback_expire: int = 0 #msec
var time_last_walk_sound_played = 0 #msec
var time_jump_buffered_until = 0 #msec
var poison_time_remaining = 0.0
var max_poison_time = 0.0
var has_won = false
var poison_bar_enabled = false
var queued_facing_direction

@onready var last_is_on_floor = is_on_floor()
@onready var tile_map: TileMapLayer = get_tree().get_current_scene().get_node("TileMapLayer")
@onready var animation_tree: AnimationTree = $AnimationTree

## knocks back the player
func take_knockback(velocity: Vector2,seconds: float):
	# apply knockback
	knockback_vector = velocity
	
	# wait to remove it
	var this_expire_time = Time.get_ticks_msec() + seconds*1000
	time_knockback_expire = this_expire_time
	await Util.wait(seconds)
	
	# if another knockback event has happened after this one, don't stop
	if this_expire_time == time_knockback_expire:
		knockback_vector = Vector2(0,0)

func damage_flash_loop():
	while true:
		# only go transparent if invulnerability is active
		if $Health.is_invulnerable:
			$Body.modulate = Color(1,1,1,0.1) # modulate = funny word for color
		await Util.wait(0.1)
		$Body.modulate = Color(1,1,1,1)
		await Util.wait(0.1)
		
func jump():
	#apply upward velocity
	velocity.y = -JUMP_STRENGTH
	
	# make player squash
	# this scale change is canceled out in _process()
	$Body.scale.y += 0.25
	
	time_jump_buffered_until = -INF
	
## main attack code	
func attack():
	# for everything the damage hitbox is touching
	for hit_body in $Body/DamageHitbox.get_overlapping_bodies():
		var hit_health: HealthStat = hit_body.get_node("Health")
			
		# if the thing has health, damage it
		if hit_health:
			hit_health.damage(DAMAGE)
		
		# if the thing can take knockback, do that
		if hit_body.has_method("take_knockback") and not (hit_health and hit_health.is_dead):
			hit_body.take_knockback(Vector2(sign(hit_body.global_position.x - global_position.x),-0.5) * KNOCKBACK,0.2)
			
		# if the thing can be poisoned (and you have poison active), poison it
		if "queued_poison_damage" in hit_body and poison_time_remaining > 0:
			hit_body.queued_poison_damage += 2

func _ready():
	damage_flash_loop()
	
func _process(delta: float) -> void:
	# make player face correct direction
	$Body.scale.x = Util.smooth_step($Body.scale.x,facing_direction,0.5,delta)
	$Body.scale.y = Util.smooth_step($Body.scale.y,1,0.8,delta)
	
	if Time.get_ticks_msec() > 2000:
		var player_tile_coord = tile_map.local_to_map(tile_map.to_local(global_position + Vector2(0,-2)))
		#var floor_tile_data = tile_map.get_cell_tile_data(player_tile_coord + Vector2i(0,1))
		if (tile_map.get_cell_tile_data(player_tile_coord + Vector2i(0,1)) or tile_map.get_cell_tile_data(player_tile_coord + Vector2i(-1,1)) or tile_map.get_cell_tile_data(player_tile_coord + Vector2i(1,1))) and $StuckDetector.get_overlapping_bodies().size() > 0:
			var layerBit:int = 1<<16
			global_position += Vector2(0,1)
			#tile_map.tile_set["physics_layer_1/collision_mask"] = tile_map.tile_set["physics_layer_1/collision_mask"]# | (1<<16)
			print("COLLISION DETECTED! ")
		#else:
			#tile_map.tile_set["physics_layer_1/collision_mask"] = tile_map.tile_set["physics_layer_1/collision_mask"]# & ~(1<<16)
			#print()
	
	# restart button
	if Input.is_action_just_pressed("restart") && !has_won:
		get_tree().call_deferred("change_scene_to_file", LevelInfo.current_level_path)
	
	# poison powerup stuff
	poison_time_remaining = max(poison_time_remaining - delta, 0)
	if poison_time_remaining > 0:
		# if its just now being enabled, play enable animation
		if poison_bar_enabled == false: $PoisonBar/AnimationPlayer.play("enable")
		poison_bar_enabled = true
		
		$PoisonBar/Fill.region_rect.size.x = ceil(remap(poison_time_remaining,0.0,max_poison_time,0,12))
		$PoisonBar/Fill.position.x = 3 - (12 - $PoisonBar/Fill.region_rect.size.x)/2.0
		$PoisonBar/Fill.visible = true
		$PoisonParticles.emitting = true
	else:
		# if its just now being disabled, play disable animation
		if poison_bar_enabled == true: $PoisonBar/AnimationPlayer.play("disable")
		poison_bar_enabled = false
		
		$PoisonBar/Fill.visible = false
		$PoisonParticles.emitting = false
		
		max_poison_time = 0
	

func _physics_process(delta: float) -> void:
	if is_on_floor():
		# jump if space is pressed
		if Input.is_action_just_pressed("jump") or Time.get_ticks_msec() - time_jump_buffered_until < 0:
			jump()
	else:
		# let player press space 80ms before hitting the ground and still have them jump
		if Input.is_action_just_pressed("jump"):
			time_jump_buffered_until = Time.get_ticks_msec() + 80
			
		# gravity
		velocity += get_gravity() * delta
		

	# left/right movement
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, SPEED * direction, SPEED*SNAPPINESS * delta)
		
		# change facing direction
		if facing_direction_locked:
			queued_facing_direction = direction
		else:
			facing_direction = direction
			
		# play walk anim
		animation_tree["parameters/movement/playback"].travel("run")
		
		# play step sounds
		if is_on_floor() and Time.get_ticks_msec() - time_last_walk_sound_played > 400:
			$WalkSound.play()
			time_last_walk_sound_played = Time.get_ticks_msec()
	else:
		if not facing_direction_locked && queued_facing_direction:
			facing_direction = queued_facing_direction
			queued_facing_direction = null
		velocity.x = move_toward(velocity.x, 0, SPEED*SNAPPINESS * delta)
		animation_tree["parameters/movement/playback"].travel("idle")

		
	# if the player is taking knockback, override the velocity with that
	if knockback_vector.length() > 0:
		velocity = knockback_vector
		
	# attacking
	if Input.is_action_just_pressed("attack"):
		animation_tree["parameters/playback"].travel("attack")
		
	
	move_and_slide()
	
	# fix player appearing to float above the floor
	if is_on_floor():
		position.y = Util.round_multiple(position.y,0.1)
	
	# squish animation when landing from a fall
	if is_on_floor() and not last_is_on_floor:
		$Body.scale.y = 0.6
		
		# play step sound when landing
		if Time.get_ticks_msec() - time_last_walk_sound_played > 400:
			$WalkSound.play()
			time_last_walk_sound_played = Time.get_ticks_msec()
		
	last_is_on_floor = is_on_floor()

# play scream sound when damaged
func _on_health_changed(new_health: float, old_health: float) -> void:
	if new_health < old_health:
		$DamageSound.play()


func _on_health_on_death():
	SpeedrunTimer.end_timer(SpeedrunTimer.TIMER_COLOR.LOST)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/menus/lose.tscn")


func _on_lava_hitbox_body_entered(body: Node2D) -> void:
	var closest_tile_world_pos: Vector2 = Vector2(99999999,99999999)
	
	var did_damage = 0
	var tile_size = tile_map.tile_set.tile_size.x;
	var tile_pos = tile_map.local_to_map(tile_map.to_local(global_position))
	for x in range(tile_pos.x-1,tile_pos.x+2):
		for y in range(tile_pos.y-2,tile_pos.y+3):
			var tile_data = tile_map.get_cell_tile_data(Vector2i(x,y))
			if tile_data == null: continue
			var damage = tile_data.get_custom_data("damage")
			if damage == 0: continue
			did_damage = 1
			
			# get knockback dir
			var tile_world_pos = tile_map.to_global(tile_map.map_to_local(Vector2(x,y)))
			
			if (tile_world_pos.distance_to($Center.global_position) < closest_tile_world_pos.distance_to($Center.global_position)):
				closest_tile_world_pos = tile_world_pos
				
	if did_damage > 0:
		$Health.damage(did_damage);
		$LavaRaycast.target_position = (closest_tile_world_pos - $Center.global_position) * 1.1
		$LavaRaycast.force_raycast_update()
		var normal = $LavaRaycast.get_collision_normal();
		if normal.y > 0: normal.y = 0;
		if normal.x != 0: velocity.x = normal.x * 250
		velocity.y += normal.y * 250
		#take_knockback(normal * 250,.1);
