extends CharacterBody2D

signal arrived

@onready var sprite: AnimatedSprite2D = $Player
@onready var label: Label = $Player/Label
@onready var speech_label: Label = $Player/SpeechLabel
@onready var agent: NavigationAgent2D = $NavigationAgent2D

var speed: float
var input_enabled: bool = true

var interaction_target: Node = null
var interaction_position: Vector2

var nav_ready := false

enum { IDLE, MOVE }
var state = IDLE


# -------------------------
# Setup
# -------------------------
func _ready():
	speed = GameState.player_speed
	input_enabled = true

	NavigationServer2D.map_changed.connect(_on_nav_map_ready)


func _on_nav_map_ready(map):
	nav_ready = true


# -------------------------
# INPUT (ONLY MOVEMENT ENTRY POINT)
# -------------------------
func _unhandled_input(event):
	if GameState.interaction_locked or GameState.map_open:
		return
	if not input_enabled:
		return
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		move_to_position(get_global_mouse_position())
		get_tree().get_current_scene().get_node("Node2D/VBoxContainer/ScrollContainer/GridContainer").refresh()

# -------------------------
# Movement
# -------------------------
func move_to_position(target: Vector2):
	if not nav_ready:
		return
	if GameState.map_open:
		return

	agent.set_target_position(target)
	change_state(MOVE)


func _physics_process(delta: float) -> void:
	z_index = int(position.y)
	update_scale()

	match state:
		IDLE:
			velocity = Vector2.ZERO

		MOVE:
			move_with_agent()


func move_with_agent():
	if not nav_ready:
		return

	if agent.is_navigation_finished():
		finish_movement()
		return

	var next_pos = agent.get_next_path_position()
	var direction = next_pos - global_position

	if direction.length() < 2:
		return

	velocity = direction.normalized() * speed
	move_and_slide()

	update_animation(direction)


func finish_movement():
	velocity = Vector2.ZERO
	agent.set_target_position(global_position)
	change_state(IDLE)

	var target = interaction_target
	interaction_target = null

	if target:
		target.interact()
	emit_signal("arrived")


# -------------------------
# Scaling
# -------------------------
var label_offset: Vector2

func update_scale():
	var level = await get_parent().get_node("LevelContainer").get_child(0)

	if not level.has_node("ScaleTop") or not level.has_node("ScaleBottom"):
		return

	var top = level.get_node("ScaleTop")
	var bottom = level.get_node("ScaleBottom")

	var min_scale = 0.5
	var max_scale = 1.0

	var t = clamp(
		(global_position.y - top.global_position.y) /
		(bottom.global_position.y - top.global_position.y),
		0.0,
		1.0
	)

	var scale_value = lerp(min_scale, max_scale, t)
	scale = Vector2.ONE * scale_value
	speech_label.scale = Vector2.ONE / scale_value
	speech_label.position = label_offset / scale_value


# -------------------------
# Animation
# -------------------------
func update_animation(direction: Vector2):
	var clothes := false

	if "passed_clothing_check" in GameState.dialogue_flags:
		if GameState.dialogue_flags.passed_clothing_check:
			clothes = true

	if GameState.you_ve_been_bammed and not clothes:
		if abs(direction.x) > abs(direction.y):
			change_animation("walk_right_pants" if direction.x > 0 else "walk_left_pants")
		else:
			change_animation("walk_down_pants" if direction.y > 0 else "walk_up_pants")
	else:
		if abs(direction.x) > abs(direction.y):
			change_animation("walk_right" if direction.x > 0 else "walk_left")
		else:
			change_animation("walk_down" if direction.y > 0 else "walk_up")
			
func change_state(new_state: int):
	var clothes := false

	if "passed_clothing_check" in GameState.dialogue_flags:
		if GameState.dialogue_flags.passed_clothing_check:
			clothes = true

	state = new_state

	if state == IDLE:
		if GameState.you_ve_been_bammed and not clothes:
			change_animation("idle_pants")
		else:
			change_animation("idle")


func change_animation(anim_name: String):
	if sprite.animation != anim_name:
		sprite.play(anim_name)

# -------------------------
# Interaction movement
# -------------------------
func move_to_interaction(target: Node, position: Vector2):  
	interaction_target = target
	interaction_position = position
	move_to_position(position)

func show_interactive_object_dialogue(text: String):
	label.text = text
	label.visible = true

	await get_tree().create_timer(2.0).timeout

	#if GameState.is_interacting:
	await end_dialogue()
		
func end_dialogue():
	label.visible = false
	#GameState.is_interacting = false
