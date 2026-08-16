extends TextureButton
class_name InventoryButton

@export var id: String = ""
@export var interaction_json: String

var has_modal: bool = false


func _ready() -> void:
	button_down.connect(_on_button_down)


func _on_button_down() -> void:
	GameState.is_interacting = true

	var scene := get_tree().current_scene
	var player := scene.get_node("Player")
	var verb : String = GameState.environment_flags.verb

	scene.get_node("Node2D/VerbContainer/%s_verb" % verb).grab_focus()

	if verb == "walk":
		return

	if has_modal:
		ModalManager.open(id)
		return

	var current_verb := "talkto" if verb == "talk" else verb
	var interaction_data := _load_interaction_data()

	GameState.current_interaction = {
		"verb": verb,
		"item": id
	}
	GameState.item_in_hand = true

	await _show_interaction_dialogue(
		player,
		interaction_data,
		current_verb
	)

	if verb not in ["give", "use"]:
		scene.clear_interactions()
		return

	if verb == "use" and GameState.item_in_hand:
		await _handle_use_interaction(player)


func _load_interaction_data() -> Dictionary:
	var file := FileAccess.open(interaction_json, FileAccess.READ)

	if file == null:
		push_error("Unable to open interaction file: %s" % interaction_json)
		return {}

	var data = JSON.parse_string(file.get_as_text())

	if data is Dictionary:
		return data

	push_error("Invalid interaction JSON: %s" % interaction_json)
	return {}


func _show_interaction_dialogue(
	player: Node,
	interaction_data: Dictionary,
	current_verb: String
) -> void:
	var show_dialogue: Callable = player.show_interactive_object_dialogue

	if interaction_data.has(current_verb):
		await show_dialogue.call(interaction_data[current_verb].dialogue)

func _handle_use_interaction(player: Node) -> void:
	var scene := get_tree().current_scene
	var current_item: String = GameState.current_interaction.item
	var combo := get_sorted_item_combo(current_item, id)

	# Handle using an item on itself / at a location.
	if not check_item_combination(current_item, id):
		await _handle_self_use(current_item)
		return

	# The combination has already been completed.
	if check_combo_completion(current_item, id):
		await player.show_interactive_object_dialogue.call(
			GameState.reaction_constants.already_combined
		)
		player.end_dialogue.call()
		return

	var interaction: Dictionary = GameState.interactions.use[combo]

	if not interaction.combine_once:
		return

	interaction.complete = true

	_add_combined_item_to_inventory(scene, interaction)

	scene.get_node("Node2D/VBoxContainer").move_scroll(-10)

	await player.show_interactive_object_dialogue.call(
		interaction.success_dialogue
	)


func _handle_self_use(current_item: String) -> void:
	var use_interactions: Dictionary = GameState.interactions.use

	if not use_interactions.has(current_item):
		return

	var interaction: Dictionary = use_interactions[current_item]

	if not interaction.get("self_use", false):
		return

	if not interaction.has("location"):
		return

	if interaction.location != GameState.current_scene:
		return

	GameState[interaction.set_flag] = true

	if interaction.get("destructive", false):
		_remove_item_from_inventory(current_item)

	CutScene.start_cutscene(
		interaction.cut_scene,
		interaction.set_flag
	)


func _add_combined_item_to_inventory(
	scene: Node,
	interaction: Dictionary
) -> void:
	var inventory = scene.get_node(
		"Node2D/VBoxContainer/ScrollContainer/GridContainer"
	)

	inventory.add_item_to_inventory(
		load(interaction.path),
		""
	)


func _remove_item_from_inventory(current_item: String) -> void:
	var scene := get_tree().current_scene
	var inventory = scene.get_node(
		"Node2D/VBoxContainer/ScrollContainer/GridContainer"
	)

	inventory.remove_item_from_inventory(current_item)


func check_item_combination(item1: String, item2: String) -> bool:
	return GameState.interactions.use.has(
		get_sorted_item_combo(item1, item2)
	)


func check_combo_completion(item1: String, item2: String) -> bool:
	var combo := get_sorted_item_combo(item1, item2)

	if not GameState.interactions.use.has(combo):
		return false

	return GameState.interactions.use[combo].get("complete", false)


func get_sorted_item_combo(item1: String, item2: String) -> String:
	var items := [item1, item2]
	items.sort()

	return "+".join(items)
