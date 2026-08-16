extends Node2D

class_name BaseScene

@export var min_y := 0.0
@export var max_y := 800.0
@export var min_scale := 0.7
@export var max_scale := 1.2
@export var character_scale := ''

@onready var game = get_node("/root/Game")
