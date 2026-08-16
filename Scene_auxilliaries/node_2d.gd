extends Control

var current_verb := ""

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in $VerbContainer.get_children():
		if child is Verb:
			child.verb_clicked.connect(_on_verb_clicked)
			
func _on_verb_clicked(verb: String):
	var button = get_tree().get_current_scene().get_node("Node2D/VerbContainer/"+verb+"_verb").button_pressed
	GameState.environment_flags.verb = verb
	$"../Player".finish_movement()
	Inventory.clear_selection()
	get_tree().get_current_scene().get_node("Node2D/VBoxContainer/ScrollContainer/GridContainer").refresh()


func clear_verb():
	current_verb = ""

# Control node
# Node2D (GUI Control)
func _unhandled_input(event):

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_viewport().gui_get_hovered_control():
			return
# Defer the clear — by then interactables will have set the flag if clicked
		await get_tree().process_frame
		if GameState.clicked_interactable:
			GameState.clicked_interactable = false
			return
		get_tree().get_current_scene().clear_interactions()
