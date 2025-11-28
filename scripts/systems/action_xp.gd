\
extends Node
class_name ActionXP

# maps actions to XP values and which skill to increment
var action_map = {
    "chop_wood": {"xp":10, "skill":"strength"},
    "mine_stone": {"xp":12, "skill":"endurance"},
    "kill_animal": {"xp":25, "skill":"hunting"}
}

func award_action(net_id:int, action:String):
    if not action_map.has(action): return
    var info = action_map[action]
    var pp = get_node_or_null("/root/PlayerProgression")
    if pp:
        pp.add_xp(net_id, info.xp)
        pp.add_skill_xp(net_id, info.skill, info.xp * 0.5)
