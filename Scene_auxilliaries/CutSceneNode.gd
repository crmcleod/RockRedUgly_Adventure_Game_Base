extends Node

class_name CutSceneNode

@export var current_cutscene_state := ""
@export var script_json := ""

func _ready() -> void:
	if not GameState[current_cutscene_state]:
		CutScene.start_cutscene(script_json, current_cutscene_state)
