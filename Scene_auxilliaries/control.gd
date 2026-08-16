extends Control

@onready var player: CharacterBody2D = $Player
@onready var fade: ColorRect = $Fade/Fade_color_rect
@onready var level_container: Node = $LevelContainer

# Label offsets
var label_offset: Vector2
var base_label_offset: Vector2

var can_use_exits := true
var scene_loading := false


# -------------------------
# Setup
# -------------------------
func _ready() -> void:
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Cache label offsets
	var label = player.get_node("Player/SpeechLabel")
	var base_label = player.get_node("Player/Label")
	label_offset = label.position
	base_label_offset = base_label.position

	can_use_exits = false

	if not GameState.opening_cutscene:
		fade_method(1.0)
		await get_tree().create_timer(0.3).timeout
		fade_method(0.0)

		player.visible = true

		var audio = AudioStreamPlayer.new()
		audio.stream = load("res://narzeky-lucid-dreams-retro-mix-380237.mp3")
		add_child(audio)
		audio.play()

		await get_tree().process_frame
		call_deferred("load_scene", "res://Rooms/QueenStreet/QueenStreet.tscn", "Game_start")

	await get_tree().create_timer(0.3).timeout
	can_use_exits = true


# -------------------------
# Scene / level loading
# -------------------------
func load_scene(scene_path: String, spawn_name: String) -> void:
	if scene_loading:
		print("Ignoring scene load:", scene_path)
		return
		
	scene_loading = true

	fade_method(1.0)
	await get_tree().create_timer(0.3).timeout

	for child in level_container.get_children():

		child.queue_free()

	await get_tree().process_frame

	var scene_resource = load(scene_path)
	if not scene_resource:
		push_error("Cannot load scene: " + scene_path)
		return

	var next_scene = scene_resource.instantiate()
	level_container.add_child(next_scene)

	await get_tree().process_frame

	# Apply scale if present
	var scale := 1.0

	var label = player.get_node("Player/SpeechLabel")
	var base_label = player.get_node("Player/Label")

	if "character_scale" in next_scene:
		scale = float(next_scene.character_scale)

	player.scale = Vector2(scale, scale)
	player.speed = GameState.player_speed * scale

	label.scale = Vector2(1.0 / scale, 1.0 / scale)
	label.position = label_offset / (scale * 1.2)

	base_label.scale = Vector2(1.0 / scale, 1.0 / scale)
	base_label.position = base_label_offset / (scale * 1.2)

	# Move player to spawn
	var spawn = next_scene.find_child(spawn_name, true, false)
	if spawn:
		player.visible = true
		player.global_position = spawn.global_position
	else:
		player.visible = false
		print("Spawn not found:", spawn_name)

	# Reset navigation safely
	var agent = player.get_node("NavigationAgent2D")
	agent.set_target_position(player.global_position)

	if player.state != player.MOVE:
		player.velocity = Vector2.ZERO
		player.change_state(player.IDLE)

	_connect_exits(next_scene)

	fade_method(0.0)
	scene_loading = false

# -------------------------
# Exit system
# -------------------------
func _connect_exits(scene: Node) -> void:
	for exit in scene.get_tree().get_nodes_in_group("exit_areas"):
		if scene.is_ancestor_of(exit):
			if exit.exit_triggered.is_connected(_on_area_2d_exit_triggered):
				exit.exit_triggered.disconnect(_on_area_2d_exit_triggered)

			exit.exit_triggered.connect(_on_area_2d_exit_triggered)


func _on_area_2d_exit_triggered(sender, scene_path: String, next_spawn: String) -> void:
	if scene_loading:
		return
	if not GameState.interaction_locked:
		if not can_use_exits:
			return

		if not get_level().is_ancestor_of(sender):
			return

		can_use_exits = false

		await load_scene(scene_path, next_spawn)

		await get_tree().create_timer(0.3).timeout
		can_use_exits = true


# -------------------------
# Utility
# -------------------------
func get_level() -> Node:
	if level_container.get_child_count() > 0:
		return level_container.get_child(0)
	return null


# -------------------------
# Fade
# -------------------------
func fade_method(target_alpha: float, duration: float = 0.3):
	var keep_state = GameState.interaction_locked
	GameState.interaction_locked = true
	var tween = create_tween()
	tween.tween_property(fade, "color:a", target_alpha, duration)
	GameState.interaction_locked = keep_state
	
func clear_interactions():
	get_tree().get_current_scene().get_node("Node2D/VBoxContainer/ScrollContainer/GridContainer").refresh()
	get_tree().get_current_scene().get_node("Node2D/VerbContainer/walk_verb").grab_focus()
	GameState.current_interaction = null
	GameState.item_in_hand = false
	GameState.environment_flags.verb = "walk"
	Inventory.clear_selection()
	get_tree().get_current_scene().get_node("Node2D").clear_verb()

func _on_station_selected(id):
	var station = StationMappings.mappings[id]

	await get_tree().process_frame

	load_scene(station.scene_path, station.spawn_point)
	ModalManager.close("map")
