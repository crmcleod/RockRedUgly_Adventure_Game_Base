extends Control

@onready var scroll := $ScrollContainer
@onready var grid := $ScrollContainer/GridContainer

var row_height := 0

func _ready():
	await get_tree().process_frame

	var child = grid.get_child(0)
	var separation = grid.get_theme_constant("v_separation")

	row_height = child.size.y + separation

func _on_up_button_pressed():
	move_scroll(-1)

func _on_down_button_pressed():
	move_scroll(1)

func move_scroll(direction: int):
	var target = scroll.scroll_vertical + (row_height * direction)

	# Clamp so you don't scroll past limits
	target = clamp(
		target,
		0,
		scroll.get_v_scroll_bar().max_value
	)

	create_tween().tween_property(
		scroll,
		"scroll_vertical",
		target,
		0.1
	)
