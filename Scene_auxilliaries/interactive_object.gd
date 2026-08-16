extends Sprite2D

@export var object_label: String = ""
@export var conditional: Dictionary = {}
@export var items: Dictionary = {}
@export var interaction_json: String = ""
@export var pickable: bool
@export var optional_pickable_flag:= ""
@export var removable := false
@export var pickable_item : InventoryObject

@onready var label: Label = $Label
@onready var player_label: Label = $"../../../Player/Player/Label"
@onready var player = $"../../../Player"
@onready var interaction_point := $InteractionPoint

func _on_static_body_2d_mouse_entered():
	label.text = object_label
	label.visible = true


func _on_static_body_2d_mouse_exited():
	label.visible = false


func _ready():
	z_index = int(position.y)


func interact():
	pass


func _on_static_body_2d_input_event(viewport, event, shape_idx):
	if not event.is_action_pressed("ui_leftMouseClick"):
		return
	GameState.clicked_interactable = true
	start_interaction()


# -------------------------
# Interaction flow
# -------------------------
func start_interaction():
	
	var starting_action = GameState.environment_flags.verb
	player.move_to_interaction(self, interaction_point.global_position)
	GameState.is_interacting = true
	player_label.visible = false


	# Wait for arrival
	await player.arrived

	var file = FileAccess.open(interaction_json, FileAccess.READ)
	var interactive_data = JSON.parse_string(file.get_as_text())

	match starting_action:
		"talk":
			player.show_interactive_object_dialogue(interactive_data.talkto.dialogue)
		"look":
			if conditional.is_empty():
				player.show_interactive_object_dialogue(items.positive_item)
			else:
				var key = conditional.keys()[0]
				var new_dialogue = items.negative_item

				if key in GameState:
					if typeof(GameState[key]) != TYPE_BOOL:
						if conditional[key] in GameState[key]:
							if GameState[key][conditional[key]]:
								var has_flag = items.item_flag in GameState and GameState[items.item_flag]
								if has_flag:
									new_dialogue = items.tertiary_item
								elif pickable:
									new_dialogue = items.positive_item
									
				player.show_interactive_object_dialogue(new_dialogue)
		"open":
			player.show_interactive_object_dialogue(interactive_data.open.dialogue)
		"move":
			player.show_interactive_object_dialogue(interactive_data.move.dialogue)
		"consume":
			player.show_interactive_object_dialogue(interactive_data.consume.dialogue)
		"pickup":
			if conditional.is_empty():
				player.show_interactive_object_dialogue(items.positive_item)
			else:
				var key = conditional.keys()[0]
				var new_dialogue = interactive_data.pickup.dialogue

				if key in GameState:
					if typeof(GameState[key]) != TYPE_BOOL:
						if conditional[key] in GameState[key]: 
							if GameState[key][conditional[key]]:
								
								# Check progression flags FIRST
								var has_flag = items.item_flag in GameState and GameState[items.item_flag]

								if has_flag:
									new_dialogue = items.tertiary_item
								elif pickable:
									new_dialogue = items.action_dialogue
									GameState[items.item_flag] = true
									GameState.environment_flags[items.item_flag] = true
									pickable = false
									$"../../../Node2D/VBoxContainer/ScrollContainer/GridContainer".add_item_to_inventory(pickable_item, interaction_json)
									if removable:
										self.queue_free()
									
				player.show_interactive_object_dialogue(new_dialogue)
			
		"close":
			player.show_interactive_object_dialogue(interactive_data.close.dialogue)
		"use":
			player.show_interactive_object_dialogue(interactive_data.use.dialogue)
		"give":
			player.show_interactive_object_dialogue(interactive_data.give.dialogue)
		"wear":
			player.show_interactive_object_dialogue(interactive_data.wear.dialogue)
		"remove":
			player.show_interactive_object_dialogue(interactive_data.remove.dialogue)
		_:
			player.show_interactive_object_dialogue(interactive_data.look.dialogue)
			

	get_tree().get_current_scene().get_node("Node2D/VerbContainer/walk_verb").grab_focus()
	GameState.environment_flags.verb = "walk"
