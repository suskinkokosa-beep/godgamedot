
extends Control
class_name MapUI

var player_ref = null

func set_player(p):
    player_ref = p

func _process(delta):
    if not player_ref: return
    $PlayerMarker.position = Vector2(player_ref.global_position.x, -player_ref.global_position.z)
