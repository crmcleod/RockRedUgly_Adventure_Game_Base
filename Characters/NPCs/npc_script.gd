extends NPC

@export var second_location: String = ""
@export var second_location_condition: String = ""

func _ready():
	$AnimatedSprite2D.play("default")
	var target = get_tree().get_first_node_in_group(second_location)
	if not target:
		push_warning("No node found in group: " + second_location)
		return

	if second_location_condition in GameState.dialogue_flags:
		if GameState.dialogue_flags[second_location_condition]:
			global_position = target.global_position
			$"../BagpipeAbandoned".visible = true
			$AnimatedSprite2D.play("smoking")
