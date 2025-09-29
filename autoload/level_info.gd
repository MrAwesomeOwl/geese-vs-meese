extends Node

const levels := {
	"desert": {
		"display_name": "Desert",
		"author": "Pritha & Joey",
		"scene_path": "res://scenes/levels/desert.tscn"
	},
	"arena": {
		"display_name": "Arena",
		"author": "Pritha & Joey",
		"scene_path": "res://scenes/levels/castle.tscn"
	},
	"why_just_why": {
		"display_name": "WHY JUST WHY",
		"author": "Eshan",
		"scene_path": "res://scenes/levels/submitted/why_just_why.tscn"
	},
	"cavern": {
		"display_name": "Cavern",
		"author": "Ram",
		"scene_path": "res://scenes/levels/submitted/cavern.tscn"
	},
	"classic": {
		"display_name": "Classic",
		"author": "Ram",
		"scene_path": "res://scenes/levels/submitted/classic.tscn"
	},
	"the_drop": {
		"display_name": "The Drop",
		"author": "Alan",
		"scene_path": "res://scenes/levels/submitted/the_drop.tscn"
	},
	"worst_level_ever": {
		"display_name": "oh god no",
		"author": "Tori",
		"scene_path": "res://scenes/levels/submitted/worst_level_ever.tscn"
	},
	"castle": {
		"display_name": "Castle",
		"author": "Eshan",
		"scene_path": "res://scenes/levels/submitted/castle.tscn"
	},
	"tower_of_torment": {
		"display_name": "Torment :(",
		"author": "Pritha & Joey",
		"scene_path": "res://scenes/levels/tower_of_torment.tscn"
	},
	"volcano": {
		"display_name": "Volcano",
		"author": "Pritha & Joey",
		"scene_path": "res://scenes/levels/volcano.tscn"
	}
}

const level_order = [
	"desert",
	"arena",
	"volcano",
	"the_drop",
	"classic",
	"why_just_why",
	"cavern",
	"castle",
	"worst_level_ever",
	"tower_of_torment",
]

var scene_to_id_map := {}

## the scene path of the level you're playing
var current_level_path: String

var loaded_files: Dictionary = {}

func _ready():
	for id in levels.keys():
		scene_to_id_map[levels[id].scene_path] = id
		
	#for folder_path in ["res://scenes/","res://objects","res://textures"]:
		#for file_path in DirAccess.get_files_at(folder_path):  
			#loaded_files[file_path] = load(file_path)
