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

@onready var direction: int = START_DIRECTION

var queued_poison_damage: int = 0
var active_moose_walk_allowers: int = 0
var last_frame_velocity: Vector2

## really scuffed way to have poison damage flicker green
## since actual damage causes are beyond this project's scope
var damage_caused_by_poison = false

func take_knockback(kb_velocity: Vector2, seconds: float):
	velocity = kb_velocity
	
## loop for taking poison damage
func poison_damage_loop():
	while true:
		# if not poisoned, wait until next frame to check again
		if queued_poison_damage == 0:
			await Util.wait(get_process_delta_time())
			$PoisonDamageParticles.amount_ratio = 0
		# if poisoned, damage and wait longer
		else:
			$PoisonDamageParticles.amount_ratio = 1
			await Util.wait(1)
			damage_caused_by_poison = true
			$Health.current -= 1
			damage_caused_by_poison = false
			queued_poison_damage -= 1

func change_direction():
	if active_moose_walk_allowers < 1:
		direction *= -1
		velocity.x *= -1
			
func _ready():
	$Body.scale.x = direction
	poison_damage_loop()

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
			
		# if moose is about to fall off a platform, flip its move direction
		if is_on_floor() and $Body/FloorCheckHitbox.get_overlapping_bodies().size() == 0:
			# prevent moose from having a stroke when standing on a 1 wide surface
			if $Body/BackFloorCheckHitbox.get_overlapping_bodies().size() > 0:
				# only do that if the moose was not recently damaged
				# that way its easier to fling meese off of platforms
				if Time.get_ticks_msec() - $Health.last_damaged_at > 500:
					change_direction()
			
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


func _on_walk_allower_hitbox_entered(area: Area2D) -> void:
	# re-using the damage hitbox for walk allowers because im lazy
	if area.is_in_group("moose_walk_allower"):
		active_moose_walk_allowers += 1
		
		
func _on_walk_allower_hitbox_exited(area: Area2D) -> void:
	if area.is_in_group("moose_walk_allower"):
		active_moose_walk_allowers -= 1


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

# flash red and play sound when taking damage
func _on_health_changed(new_health: float, old_health: float) -> void:
	if new_health < old_health:
		$DamageSound.play()
		if damage_caused_by_poison:
			$Body.modulate = Color(0.5,2,0.5,1)
		else:
			$Body.modulate = Color(100,0.5,0.5,1)
		await Util.wait(0.1)
		$Body.modulate = Color(1,1,1,1)
