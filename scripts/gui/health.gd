extends HBoxContainer

const heart_template = preload("res://scenes/heart_template.tscn")

@onready var player: CharacterBody2D = get_tree().get_nodes_in_group("player")[0]
@onready var health: HealthStat = player.get_node("Health")

var current_heart_amount = 0

func update_heart_amount():
	# if hearts need to be added
	if health.maximum > current_heart_amount:
		# add new hearts until we have the right amount
		while current_heart_amount < health.maximum:
			current_heart_amount += 1
			var new_heart = heart_template.instantiate() #creates a clone of the heart template
			
			# add new heart to the row
			add_child(new_heart)
			new_heart.owner = self
			
			#make it show up in the right place
			new_heart.name = "Heart" + str(current_heart_amount) 
			
			# make the new heart is in the right state
			update_heart_state(current_heart_amount)
			
			
	# if hearts need to be removed
	elif health.maximum < current_heart_amount:
		# remove existing hearts until we have the right amount
		while current_heart_amount > health.maximum:
			# removes the heart all the way to the right
			get_node("Heart"+str(current_heart_amount)).queue_free()
			current_heart_amount -= 1
			
		
	
func update_heart_state(heart_number: int):
	var heart = get_node("Heart" + str(heart_number))
	var current_heart_state = heart.get_meta("state","just_created")
	
	# figure out if this heart should be full or empty
	var should_be_full = health.current >= heart_number

	
	# if this heart was just added, dont bother to do animations
	if current_heart_state == "just_created":
		# self modulate is just a fancy way of saying color
		if should_be_full:
			heart.get_node("BackgroundFull").self_modulate = Color(1,1,1,1)
			heart.get_node("Heart").visible = true
		else:
			heart.get_node("BackgroundFull").self_modulate = Color(1,1,1,0)
			heart.get_node("Heart").visible = false
		current_heart_state = "full" if should_be_full else "empty"
	# if the fill animation needs to be played
	elif current_heart_state == "empty" and should_be_full == true:
		heart.get_node("AnimationPlayer").play("fill")
		current_heart_state = "full"
	# if the empty animation needs to bee played
	elif current_heart_state == "full" and should_be_full == false:
		heart.get_node("AnimationPlayer").play("empty")
		current_heart_state = "empty"
			
	# make sure to re-store the state
	heart.set_meta("state",current_heart_state)
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_heart_amount()
	
	# whenever max health changes, update how many hearts are shown
	health.on_max_changed.connect(func(new,old):
		update_heart_amount()	
	)
	
	# whenever current health changes, update whether hearts are filled or not
	health.on_current_changed.connect(func(new,old):
		# loop through all hearts
		for i in range(1,current_heart_amount+1):
			update_heart_state(i)
	)
