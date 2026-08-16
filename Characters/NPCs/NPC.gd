extends CharacterBody2D

class_name NPC

@onready var player: CharacterBody2D = get_tree().get_current_scene().get_node("Player")
@onready var interaction_point: Node2D = $InteractionPoint
@onready var speech_label_npc: Label = $AnimatedSprite2D/SpeechLabel
@onready var speech_label_player: Label = $AnimatedSprite2D/SpeechLabel_player

@export var npc_id := ""
@export var dialogue_file := ""
@export var look_description := ""
@export var start_id := "start"

# Called AFTER player arrives
func interact():
	get_viewport().set_input_as_handled()
	start_id = "start"
	if GameState.item_in_hand:
		var target = null

		if GameState.current_interaction != null:
			if ["give", "use"].has(GameState.current_interaction.verb):
				if GameState.interactions[GameState.current_interaction.verb].has(GameState.current_interaction.item):
					if GameState.interactions[GameState.current_interaction.verb][GameState.current_interaction.item].recipient == npc_id:
						target = true

		if target:
			start_id = GameState.current_interaction.item
			await get_tree().create_timer(1.0).timeout
			speech_label_player.text = ""
			GameState.environment_flags.verb = 'talk'
			GameState.interactions[GameState.current_interaction.verb][GameState.current_interaction.item].complete = true
			get_tree() \
			.get_current_scene() \
			.get_node("Node2D/VBoxContainer/ScrollContainer/GridContainer") \
			.remove_item_from_inventory(GameState.current_interaction.item)
			#GameState.current_interaction = null
			
	# interaction matches
	var verb = GameState.environment_flags.verb
	get_tree().get_current_scene().get_node("Node2D/VerbContainer/walk_verb").grab_focus()
	GameState.environment_flags.verb = "walk"
	if verb == 'talk':
		DialogueManager.load_dialogue(dialogue_file)

		DialogueManager.start(start_id, {
			"player": self,
			"npc": self
		})
	elif verb == 'look':
		say("player", look_description)
		await get_tree().create_timer(2.0).timeout
		clear_speech()
	elif verb == 'walk':
		return
	else:
		say("player", "That doesn't make sense")
		await get_tree().create_timer(2.0).timeout
		clear_speech()
		
	
# NPC and InteractiveObject _on_static_body_2d_input_event
func _on_static_body_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		GameState.clicked_interactable = true
		player.move_to_interaction(self, interaction_point.global_position)

func say(speaker: String, text: String, color: Color = Color.WHITE):
	var label: Label

	if speaker == "npc":
		label = speech_label_npc
	elif speaker == "player":
		label = speech_label_player
	else:
		return

	label.text = text
	label.modulate = color
	label.show()


func clear_speech():
	speech_label_npc.text = ""
	speech_label_player.text = ""
