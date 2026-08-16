extends CanvasLayer

@onready var choices_container = $Panel/Choices
@onready var panel = $Panel
@onready var cursor = $Cursor
@onready var player: CharacterBody2D = get_tree().get_current_scene().get_node("Player")

var waiting_for_choice := false

var virtual_mouse := Vector2.ZERO
var use_virtual_mouse := false

var hovered_button: Button = null

var choice_delay := 0.4
var cursor_delay := 0.3

# Save/restore REAL mouse position
var saved_real_mouse_pos := Vector2.ZERO

# Token system (prevents async bugs)
var update_token := 0

func _ready():
	hide()
	cursor.visible = false

	choices_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	choices_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	DialogueManager.dialogue_started.connect(_on_started)
	DialogueManager.dialogue_updated.connect(_on_updated)
	DialogueManager.dialogue_ended.connect(_on_ended)


func _input(event):
	if not visible:
		return

	if use_virtual_mouse and event is InputEventMouseMotion:
		virtual_mouse += event.relative

		var rect = panel.get_global_rect()
		virtual_mouse = virtual_mouse.clamp(rect.position, rect.end)

		cursor.global_position = virtual_mouse
		_update_hover()

	if use_virtual_mouse and event is InputEventMouseButton and event.pressed:
		_cancel_timers()
		_handle_virtual_click()
		get_viewport().set_input_as_handled()
		return

	if waiting_for_choice:
		return

	if event is InputEventMouseButton and event.pressed:
		_cancel_timers()
		DialogueManager.next()
		get_viewport().set_input_as_handled()

func _on_started():
	player.input_enabled = false
	show()

	# SAVE the real cursor position BEFORE capture
	saved_real_mouse_pos = DisplayServer.mouse_get_position()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	use_virtual_mouse = false
	cursor.visible = false

func _on_updated(node: Dictionary):
	update_token += 1
	var my_token = update_token

	_clear_all_speech()

	for child in choices_container.get_children():
		child.queue_free()

	var speaker_key = node.get("speaker", "")
	var text = node.get("text", "")

	var actor = DialogueManager.actor.get(speaker_key)

	if actor != null:
		var color = DialogueManager.speaker_colors.get(speaker_key, Color.WHITE)

		if actor.has_method("say"):
			actor.say(speaker_key, text, color)

	var choices = node.get("choices", [])
	waiting_for_choice = choices.size() > 0

	# -------------------------
	# Choices
	# -------------------------
	if waiting_for_choice:
		use_virtual_mouse = false
		cursor.visible = false
		hovered_button = null

		await get_tree().create_timer(choice_delay).timeout
		if my_token != update_token:
			return

		for i in range(choices.size()):
			var choice = choices[i]

			var button = Button.new()
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size = Vector2(0, 20)
			button.flat = true

			var label = Label.new()
			label.text = choice.get("text", "")
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label.add_theme_font_size_override("font_size", 10)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			button.add_child(label)

			var choice_index = i

			button.pressed.connect(func():
				_cancel_timers()
				DialogueManager.next(choice_index)
			)

			choices_container.add_child(button)

		await get_tree().create_timer(cursor_delay).timeout
		if my_token != update_token:
			return

		use_virtual_mouse = true

		var rect = panel.get_global_rect()
		virtual_mouse = rect.get_center()

		cursor.global_position = virtual_mouse
		cursor.visible = true

		_update_hover()

	# -------------------------
	# Auto progression
	# -------------------------
	else:
		use_virtual_mouse = false
		cursor.visible = false
		hovered_button = null

		var t = my_token
		var timer = get_tree().create_timer(GameState.dialogue_timer(text))

		timer.timeout.connect(func():
			if t != update_token:
				return
			_on_auto_advance()
		)

# -------------------------
# End
# -------------------------
func _on_ended():
	hide()
	_clear_all_speech()

	_cancel_timers()

	use_virtual_mouse = false
	cursor.visible = false
	hovered_button = null

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# restore mouse safely
	await get_tree().process_frame
	DisplayServer.warp_mouse(saved_real_mouse_pos)

	# wait for verb bar + scene to settle
	await get_tree().process_frame
	await get_tree().process_frame

	player.input_enabled = true
# -------------------------
# Auto
# -------------------------
func _on_auto_advance():
	if waiting_for_choice:
		return

	DialogueManager.next()

func _cancel_timers():
	update_token += 1

# -------------------------
# Click
# -------------------------
func _handle_virtual_click():
	if waiting_for_choice:
		if hovered_button:
			hovered_button.emit_signal("pressed")
	else:
		DialogueManager.next()

# -------------------------
# Hover
# -------------------------
func _update_hover():
	var new_hover: Button = null

	for button in choices_container.get_children():
		if button is Button:
			if button.get_global_rect().has_point(virtual_mouse):
				new_hover = button
				break

	if new_hover != hovered_button:
		# Reset old
		if hovered_button and hovered_button.get_child_count() > 0:
			var old_label = hovered_button.get_child(0)
			if old_label is Label:
				old_label.remove_theme_color_override("font_color")

		hovered_button = new_hover

		# Apply new
		if hovered_button and hovered_button.get_child_count() > 0:
			var label = hovered_button.get_child(0)
			if label is Label:
				label.add_theme_color_override("font_color", Color.YELLOW)

# -------------------------
# Helpers
# -------------------------
func _clear_all_speech():
	for actor in DialogueManager.actor.values():
		if is_instance_valid(actor) and actor.has_method("clear_speech"):
				actor.clear_speech()
