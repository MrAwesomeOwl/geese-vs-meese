extends CharacterBody2D


@export var SPEED = 150.0
## lower values result in slipperier movement (like ice)
@export_range(0,10) var SNAPPINESS = 5
@export var JUMP_STRENGTH = 300.0
@export var DAMAGE = 1.0
@export var KNOCKBACK = 300.0

@export_group("Internal stuff (ignore)")
## if true, facing_direction won't automatically change
@export var facing_direction_locked: bool

var facing_direction = 1.0
var knockback_vector: Vector2 = Vector2(0,0)
var time_knockback_expire: int = 0 #msec
var poison_time_remaining = 0.0
var max_poison_time = 0.0
var poison_bar_enabled = false

@onready var last_is_on_floor = is_on_floor()

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
	
## main attack code	
func attack():
	# for everything the damage hitbox is touching
	for hit_body in $Body/DamageHitbox.get_overlapping_bodies():
		var hit_health: HealthStat = hit_body.get_node("Health")
			
		# if the thing has health, damage it
		if hit_health:
			hit_health.damage(1)
		
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
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -JUMP_STRENGTH
		# make player squash
		# this scale change is canceled out in _process()
		$Body.scale.y += 0.25

	# left/right movement
	var direction := Input.get_axis("left", "right")
	if direction:
		if not facing_direction_locked:
			facing_direction = direction
		animation_tree["parameters/movement/playback"].travel("run")
		
		velocity.x = move_toward(velocity.x, SPEED * direction, SPEED*SNAPPINESS * delta)
	else:
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
		
	last_is_on_floor = is_on_floor()
