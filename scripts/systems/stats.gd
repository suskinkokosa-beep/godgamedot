extends Node
class_name StatsSystem

signal stats_changed(player_id, stats)

# Basic stats and leveling per player (server authoritative)
# For alpha: store stats in a dict keyed by player net_id or peer id

var players = {} # id -> {level:int, xp:float, stats: {str:..., agi:..., end:..., int:..., surv:...}, perk_points:int}

func create_player(id:int):
    var base = {
        "level": 1,
        "xp": 0.0,
        "perk_points": 0,
        "stats": {"strength":5, "agility":5, "endurance":5, "intelligence":5, "survival":5}
    }
    players[id] = base
    emit_signal("stats_changed", id, base["stats"])
    return base

func add_xp(id:int, amount:float):
    if not players.has(id):
        players[id] = create_player(id)
    players[id].xp += amount
    # level up simple: every 100 xp = level
    while players[id].xp >= 100.0:
        players[id].xp -= 100.0
        players[id].level += 1
        players[id].perk_points += 1
    emit_signal("stats_changed", id, players[id].stats)

func spend_perk(id:int, stat_key:String, points:int=1) -> bool:
    if not players.has(id): return false
    if players[id].perk_points < points: return false
    if not players[id].stats.has(stat_key): return false
    players[id].stats[stat_key] += points
    players[id].perk_points -= points
    emit_signal("stats_changed", id, players[id].stats)
    return true

func get_stats(id:int):
    if players.has(id):
        return players[id]
    return null
