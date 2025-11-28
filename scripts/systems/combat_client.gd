
extends Node
class_name CombatClient

signal request_light()
signal request_heavy()
signal request_block(state)

var blocking = false

func light():
    emit_signal("request_light")

func heavy():
    emit_signal("request_heavy")

func block(state:bool):
    blocking = state
    emit_signal("request_block", state)
