extends Node
class_name SeedManager

var seed := 0

func set_seed(s:int):
    seed = s

func randomize_seed():
    seed = randi()

func get_seed() -> int:
    return seed
