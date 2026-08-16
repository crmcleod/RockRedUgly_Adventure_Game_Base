extends Area2D

class_name SceneExit

@export var next_scene_path : String = ""
@export var next_scene_spawn : String = ""
@export var blocked_exit_text : String = ""
@export var scene_id : String = ""
@export var scene_exit : String = ""
@export var redirected : String = ""
@export var redirection_condition : String = ""

signal exit_triggered(sender, scene_path: String, spawn_path: String)

func _ready():
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.name == "Player":
		emit_signal("exit_triggered", self, next_scene_path, next_scene_spawn )
