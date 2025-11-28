\
extends Node
class_name PlayerProgression

signal player_updated(net_id)

# Data structure: players[net_id] = {level, xp, stats:{health,stamina,hunger,thirst,temp,carry}, skills:{skill:level}, skill_xp:{skill:xp}}
var players = {}

func ensure_player(id:int):
    if not players.has(id):
        players[id] = {
            "level":1,
            "xp":0.0,
            "perk_points":0,
            "stats": {"max_health":100, "health":100, "max_stamina":100, "stamina":100, "hunger":100, "thirst":100, "temperature":15.0, "carry_capacity":80.0},
            "skills": {"strength":1, "agility":1, "endurance":1, "intelligence":1, "survival":1, "crafting":1, "hunting":1},
            "skill_xp": {"strength":0.0, "agility":0.0, "endurance":0.0, "intelligence":0.0, "survival":0.0, "crafting":0.0, "hunting":0.0}
        }
    return players[id]

func add_xp(id:int, amount:float):
    var p = ensure_player(id)
    p.xp += amount
    # level up threshold: 100 * level
    var threshold = 100.0 * p.level
    while p.xp >= threshold:
        p.xp -= threshold
        p.level += 1
        p.perk_points += 1
        threshold = 100.0 * p.level
    emit_signal("player_updated", id)

func add_skill_xp(id:int, skill:String, amount:float):
    var p = ensure_player(id)
    p.skill_xp[skill] = p.skill_xp.get(skill,0.0) + amount
    # skill level up threshold: 50 * current_level
    var cur = p.skills.get(skill,1)
    var thresh = 50.0 * cur
    while p.skill_xp[skill] >= thresh:
        p.skill_xp[skill] -= thresh
        p.skills[skill] = cur + 1
        cur = p.skills[skill]
        p.perk_points += 1
    emit_signal("player_updated", id)

func apply_death_penalties(id:int):
    var p = ensure_player(id)
    # lose 10% of overall xp, lose some skill xp, apply temporary debuff state record
    p.xp = max(0, p.xp * 0.9)
    for s in p.skill_xp.keys():
        p.skill_xp[s] = max(0, p.skill_xp[s] * 0.85)
    # reduce carry capacity temporarily
    p.stats.carry_capacity = max(10.0, p.stats.carry_capacity * 0.9)
    emit_signal("player_updated", id)

func get_player(id:int) -> Dictionary:
    return players.get(id, null)
