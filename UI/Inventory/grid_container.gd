extends GridContainer

@onready var Inventory = get_node("/root/Inventory")

var items: Array = []
var selected_button: InventoryButton = null

func _ready():
	set_anchors_preset(Control.PRESET_TOP_LEFT)

	columns = 5

	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 0)

	refresh()

func check_if_item_in_inventory(item_id):
	return items.any(func(item): return item.id == item_id)


func add_item_to_inventory(item, json):
	items.push_front(item)
	refresh()

func remove_item_from_inventory(item):
	items = items.filter(func(i): return i.id != item)
	refresh()
	
func refresh():
	for child in get_children():
		child.queue_free()

	for item in items:
		add_child(create_slot(item))


func create_slot(item) -> PanelContainer:
	var slot = PanelContainer.new()

	# -------------------------
	# BASE (invisible)
	# -------------------------
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	slot.add_theme_stylebox_override("panel", transparent_style)

	slot.custom_minimum_size = Vector2(25, 25)

	var button = InventoryButton.new()
	button.focus_mode = Control.FOCUS_ALL

	button.ignore_texture_size = true
	button.custom_minimum_size = Vector2(25, 25)

	button.texture_normal = item.icon
	button.id = item.id
	button.interaction_json = item.interaction_json
	button.has_modal = item.has_modal
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	button.set_anchors_preset(Control.PRESET_FULL_RECT)

	# -------------------------
	# STYLE FUNCTIONS (LAMBDA FIX)
	# -------------------------

	var apply_default = func():
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0)
		slot.add_theme_stylebox_override("panel", s)

	var apply_focus = func():
		var s = StyleBoxFlat.new()
		s.bg_color = Color(1.4, 0.25, 0.6)
		slot.add_theme_stylebox_override("panel", s)

	var apply_selected = func():
		var s = StyleBoxFlat.new()
		s.bg_color = Color(1.6, 0.65, 0.5)
		slot.add_theme_stylebox_override("panel", s)

	# -------------------------
	# FOCUS
	# -------------------------

	button.focus_entered.connect(func():
		if button != selected_button:
			apply_focus.call()
	)

	button.focus_exited.connect(func():
		if button != selected_button:
			apply_default.call()
	)

	# -------------------------
	# CLICK
	# -------------------------

	button.button_down.connect(func():
		Inventory.select_item(item)

		if selected_button and is_instance_valid(selected_button):
			var old_slot = selected_button.get_parent()
			var reset = StyleBoxFlat.new()
			reset.bg_color = Color(0, 0, 0, 0)
			old_slot.add_theme_stylebox_override("panel", reset)

		selected_button = button

		apply_selected.call()
	)

	slot.add_child(button)
	return slot
