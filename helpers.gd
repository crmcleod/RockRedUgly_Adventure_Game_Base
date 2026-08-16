extends Node


func get_json(interaction_json):
	var file = FileAccess.open(interaction_json, FileAccess.READ)
	var interactive_data = JSON.parse_string(file.get_as_text())
	return interactive_data
	
func wait(time):
	await get_tree().create_timer(time).timeout
