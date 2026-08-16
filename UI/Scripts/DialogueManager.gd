extends Node

signal dialogue_started
signal dialogue_updated(node)
signal dialogue_ended

var dialogue_data: Dictionary = {}
var current_id: String = ""

var actor := {}  # {"player": Node, "npc": Node}

var speaker_colors := {
	"player": Color(0.4, 0.8, 1.0),
	"npc": Color(0.6, 0.5, 0.0)
}

# -------------------------
# Setup
# -------------------------
func load_dialogue(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	dialogue_data = JSON.parse_string(file.get_as_text())

func start(start_id: String, actor_map: Dictionary):
	$"../Game/Node2D".visible = false
	actor = actor_map
	current_id = start_id

	dialogue_started.emit()
	_go_to(current_id)
	GameState.interaction_locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# -------------------------
# Core navigation
# -------------------------
func _go_to(id: String):
	var next_id = id

	while next_id != "" and dialogue_data.has(next_id):
		var node = dialogue_data.get(next_id)
		if node == null:
			break

		# -------------------------
		# 1. PROGRESSION CHECK
		# -------------------------
		var temp_condition = node.get('override', {}).get('dialogue_condition',false)
		if node.has("override") and temp_condition in GameState.dialogue_flags and GameState.dialogue_flags[temp_condition]:
			next_id = node.override.next
			continue
	
		elif node.has("condition"):
			var key = node["condition"]

			if GameState.dialogue_flags.get(key, false):
				next_id = node.get("conditional_next", "")
				continue

		# -------------------------
		# 2. ENVIRONMENT / RETRIES
		# -------------------------
		if node.has("environment_condition"):
			var key = node["environment_condition"]

			# already satisfied
			if GameState.dialogue_flags.get(key, false):
				next_id = node.get("conditional_next", "")
				continue

			# retries logic
			if node.has("retries"):
				var count = GameState.counters.get(key, 0)

				if count >= node["retries"]:
					GameState.dialogue_flags[key] = true
					next_id = node.get("conditional_next", "")
					continue
				else:
					GameState.counters[key] = count + 1
					break

			# fallback environment flag
			if GameState.environment_flags.get(key, false):
				GameState.dialogue_flags[key] = true
				next_id = node.get("conditional_next", "")
				continue
			else:
				break

		break

	current_id = next_id

	if current_id == "" or not dialogue_data.has(current_id):
		end()
		return

	var final_node = dialogue_data.get(current_id)

	# -------------------------
	# APPLY DATA-DRIVEN FLAGS
	# -------------------------
		
	if final_node.has("receive_item"):
		var key = final_node["set_flag"]
		if key not in GameState.dialogue_flags:
			var item_path = "res://UI/Inventory/Inventory_Items/%s.tres" % final_node.receive_item
			var item = load(item_path)
			get_tree()\
			.get_current_scene()\
			.get_node("Node2D/VBoxContainer/ScrollContainer/GridContainer")\
			.add_item_to_inventory(item, item.interaction_json)
	
	if final_node.has("set_flag"):
		var key = final_node["set_flag"]
		GameState.dialogue_flags[key] = !GameState.dialogue_flags.get(key, false)
		
	if final_node.has("action"):
		if final_node.action.has('show'):
			get_tree().get_current_scene().get_node(final_node.action[1]).visible = true
		if final_node.action.has('start_cutscene'):
			CutScene.start_cutscene(final_node.action.start_cutscene, final_node.action.gamestate)

	if final_node.has("fade"):
		$"../Game".fade_method(1.0)
		await get_tree().create_timer(0.3).timeout
		if final_node.has("update_animation"):
			get_tree().get_current_scene().get_node("Player").change_animation(final_node.update_animation)
		elif final_node.has("move_character"):
			var character = get_tree().get_current_scene().get_node(final_node.move_character.character)
		
			var target = get_tree().get_current_scene().get_node(final_node.move_character.location)
			character.global_position = target.global_position
		
		# Hi future Craig - enjoy when this bites you in the ass :)
				
		$"../Game".fade_method(0.0)

	dialogue_updated.emit(final_node)


# -------------------------
# Flow
# -------------------------
func next(choice_index := -1):
	var node = dialogue_data.get(current_id)
	if node == null:
		end()
		return

	var next_id := ""

	if choice_index >= 0:
		var choices = node.get("choices", [])
		if choice_index < choices.size():
			next_id = choices[choice_index].get("next", "")
	else:
		next_id = node.get("next", "")

	_go_to(next_id)

func end():
	dialogue_ended.emit()
	current_id = ""
	actor.clear()
	GameState.interaction_locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$"../Game/Node2D".visible = true
