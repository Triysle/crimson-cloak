class_name State
extends Node

# Reference to the state machine and player
var state_machine = null
var player = null

# Virtual functions to be overridden by child states
func enter():
	pass

func exit():
	pass
	
func handle_input(_event):
	pass
	
func update(_delta):
	pass
	
func physics_update(_delta):
	pass
