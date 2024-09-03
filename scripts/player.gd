extends CharacterBody2D


@export var SPEED = 150.0
@export_range(0,10) var SNAPPINESS = 5
@export var JUMP_VELOCITY = -300.0

var facing_direction = 1.0

var knockback_vector: Vector2 = Vector2(0,0)
var time_knockback_expire: int = 0 #msec

@onready var animation_tree: AnimationTree = $AnimationTree

## knocks back the player
func knockback(velocity: Vector2,seconds: float):
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
		if Time.get_ticks_msec() < $Health.last_damaged_at + $Health.invulnerability_time*1000:
			modulate = Color(1,1,1,0.1) # modulate = funny word for color
		await Util.wait(0.1)
		modulate = Color(1,1,1,1)
		await Util.wait(0.1)

func _ready():
	damage_flash_loop()

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# left/right movement
	var direction := Input.get_axis("left", "right")
	if direction:
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
