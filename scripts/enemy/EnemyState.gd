class_name EnemyState
extends Node

# Reference to the state machine and enemy
var state_machine = null
var enemy = null

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
