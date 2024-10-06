extends Node
class_name ButtonMover

@export var button_to_follow: Button

@export var update_position: Array[Control] = []
@export var move_amount = 2
@export var update_color_labels: Array[Label] = []

var is_pressed = false
var is_up = true

func go_down():
	if is_up:
		is_up = false
		for node in update_position:
			node.position.y += move_amount
			
		for node in update_color_labels:
			node.set_meta("original_color",node.get_theme_color("font_color"))
			node.add_theme_color_override("font_color",button_to_follow.theme["Button/colors/font_pressed_color"])

func go_up():
	if not is_up:
		is_up = true
		for node in update_position:
			node.position.y -= move_amount
				
		for node in update_color_labels:
			node.add_theme_color_override("font_color",node.get_meta("original_color"))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if button_to_follow == null: button_to_follow = get_parent()
	
	button_to_follow.button_down.connect(func _on_pressed():
		is_pressed = true
		go_down()
	)
	
	button_to_follow.button_up.connect(func _on_released():
		is_pressed = false
		go_up()
	)
	
	button_to_follow.mouse_exited.connect(func _on_mouse_exited():
		if is_pressed:
			go_up()
	)
	
	button_to_follow.mouse_entered.connect(func _on_mouse_exited():
		if is_pressed:
			go_down()
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
