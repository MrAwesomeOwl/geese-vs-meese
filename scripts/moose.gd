extends CharacterBody2D

## how fast the moose should move
@export var SPEED = 100.0;

## how much damage to deal to the player when hitting them
@export var DAMAGE = 1;

## what direction to start out moving. [br]
## -1 is left, 1 is right
@export_range(-1,1) var START_DIRECTION: int = 1;

@onready var direction = START_DIRECTION

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# if moose is touching a wall, flip its move direction
	print(is_on_wall())
	if is_on_wall(): 
		direction *= -1
		
	# actual movement
	velocity.x = direction * SPEED
	
	# make moose face the correct direction
	$Visuals.scale.x = direction
	
	move_and_slide()

# runs whenever the damage hitbox touches something
func _on_damage_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.get_node("Health").current -= 1
