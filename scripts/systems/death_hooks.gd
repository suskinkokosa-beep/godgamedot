\
# This script is to be called by server-side death handlers when an entity dies
func on_player_death(net_id:int):
    var pp = get_node_or_null("/root/PlayerProgression")
    if pp:
        pp.apply_death_penalties(net_id)
