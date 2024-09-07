extends CharacterBody2D

## how fast the moose should move
@export var SPEED = 40.0;

## how much damage to deal to the player when hitting them
@export var DAMAGE = 1;

## how much knockback to deal to the player when hitting them
@export var KNOCKBACK = 250.0

## what direction to start out moving. [br]
## -1 is left, 1 is right
@export_range(-1,1) var START_DIRECTION: int = 1;

@onready var direction = START_DIRECTION	

var last_frame_velocity: Vector2

func take_knockback(kb_velocity: Vector2, seconds: float):
	velocity = kb_velocity
	

func _physics_process(delta: float) -> void:
	if $Health.is_dead:
		modulate.a -= delta*1.5
		modulate.r += delta/2
		$Body/Animations.rotation_degrees += delta*20
	else:
			
		# if moose is touching a wall, flip its move direction
		if is_on_wall(): 
			direction = get_wall_normal().x
			velocity.x = last_frame_velocity.x * -1
			
		# actual movement
		velocity.x = move_toward(velocity.x,direction * SPEED,SPEED * 10 * delta)
		
		# make moose face the correct direction
		$Body.scale.x = direction
		
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	last_frame_velocity = velocity
	move_and_slide()

# runs whenever the damage hitbox touches something
func _on_damage_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not $Health.is_dead:
		body.get_node("Health").damage(DAMAGE)
		body.take_knockback(Vector2(sign(body.global_position.x - global_position.x),-0.5) * KNOCKBACK,0.1)


func _on_death() -> void:
	# let moose fall through the floor
	$CollisionShape2D.disabled = true

	# flip upside-down
	$Body/Animations.rotation_degrees += 180
	$Body/Animations.scale.x *= -1
	
	# launch up
	velocity.y = -200
	
	# despawn once completely faded out
	await Util.wait(1)
	queue_free()

# flash red when taking damage
func _on_health_changed(new_health: float, old_health: float) -> void:
	if new_health < old_health:
		modulate = Color(100,0.5,0.5,1)
		await Util.wait(0.1)
		modulate = Color(1,1,1,1)
