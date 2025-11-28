extends Node
class_name PlayerAttackController

var combo := null
var attack_scene := preload("res://scenes/props/attack_hit.tscn")

# timing windows per attack type (light/heavy)
var attack_windows = {"light":0.25, "heavy":0.5}

func _ready():
    combo = ComboChain.new() if Engine.has_singleton("ComboChain") == false else null
    # alternatively, create local ComboChain instance
    combo = preload("res://scripts/combat/combo_chain.gd").new()

func perform_attack(attacker_node, attack_type:String, weapon:Dictionary):
    # register combo
    combo.push(attack_type)
    # spawn attack hit in front of player
    var inst = attack_scene.instantiate()
    inst.attacker = attacker_node
    inst.weapon = weapon
    var forward = attacker_node.global_transform.basis.z * -1
    inst.global_transform.origin = attacker_node.global_transform.origin + forward * 1.2 + Vector3(0,1.0,0)
    # rotate to face same direction as player
    inst.global_transform.basis = attacker_node.global_transform.basis
    attacker_node.get_tree().current_scene.add_child(inst)
    # no animation resources included: callers should play AnimationPlayer if they have one
