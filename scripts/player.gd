extends CharacterBody2D


@export var SPEED = 150.0
@export_range(0,10) var SNAPPINESS = 5
@export var JUMP_VELOCITY = -300.0

var facing_direction = 1.0

@onready var animation_tree: AnimationTree = $AnimationTree

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
		
	# attacking
	if Input.is_action_just_pressed("attack"):
		animation_tree["parameters/playback"].travel("attack")
		
	# make player face correct direction
	$Visuals.scale.x = Util.smooth_step($Visuals.scale.x,facing_direction,0.5,delta)
	
	move_and_slide()
	
	# fix player appearing to float above the floor
	if is_on_floor():
		position.y = Util.round_multiple(position.y,0.1)
