extends Node

var game_config := {"dialogue_timing": 150}
var reaction_constants := {}
var player_speed = 160
var interaction_locked = false
var map_open = false
var is_interacting = false
var clicked_interactable := false

var dialogue_flags := {}
var environment_flags := {}
var counters := {}

var current_interaction = {}
var item_in_hand = false

var interactions = {
	"give": {},
	"move": {},
	"walk": {},
	"talkto": {},
	"consumer": {},
	"look": {},
	"pickup": {},
	"remove": {},
	"wear": {},
	"use": {},
	"close": {},
	"open": {}
}
var current_scene = "queen_street"

func dialogue_timer(text: String):
	var wpm = game_config.dialogue_timing
	var interval = 60.0/wpm
	return (text.split(' ', false).size() * interval) + 1.0
