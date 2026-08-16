extends Button

class_name Verb

@export var verb: String = ""

signal verb_clicked(verb_name: String)

func _ready():
	pressed.connect(func(): verb_clicked.emit(verb))
