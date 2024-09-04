extends CharacterBody2D


@export var SPEED = 150.0
## lower values result in slipperier movement (like ice)
@export_range(0,10) var SNAPPINESS = 5
@export var JUMP_STRENGTH = 300.0
@export var DAMAGE = 1.0
@export var KNOCKBACK = 300.0

@export_group("Internal stuff (ignore)")
var facing_direction = 1.0
## if true, facing_direction won't automatically change
@export var facing_direction_locked: bool

var knockback_vector: Vector2 = Vector2(0,0)
var time_knockback_expire: int = 0 #msec

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
			modulate = Color(1,1,1,0.1) # modulate = funny word for color
		await Util.wait(0.1)
		modulate = Color(1,1,1,1)
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

func _ready():
	damage_flash_loop()

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -JUMP_STRENGTH

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
		
	# make player face correct direction
	$Body.scale.x = Util.smooth_step($Body.scale.x,facing_direction,0.5,delta)
	
	move_and_slide()
	
	# fix player appearing to float above the floor
	if is_on_floor():
		position.y = Util.round_multiple(position.y,0.1)
