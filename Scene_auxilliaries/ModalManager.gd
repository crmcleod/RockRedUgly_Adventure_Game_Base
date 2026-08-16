extends Node

@onready var modals = {}

func open(id):
	if modals[id].always_in_scene:
		modals[id].visible = true
		GameState.map_open = true
		
func close(id):
	if modals[id].always_in_scene:
		modals[id].visible = false
		GameState.map_open = false
