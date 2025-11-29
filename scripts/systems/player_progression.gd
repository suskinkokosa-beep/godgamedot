extends Node

signal player_updated(net_id)
signal stat_critical(net_id, stat_name, value)
signal xp_gained(net_id, amount)
signal level_up(net_id, new_level)

var players = {}

func ensure_player(id:int):
    if not players.has(id):
        players[id] = {
            "level":1,
            "xp":0.0,
            "perk_points":0,
            "stats": {
                "max_health": 100.0,
                "health": 100.0,
                "max_stamina": 100.0,
                "stamina": 100.0,
                "hunger": 100.0,
                "thirst": 100.0,
                "temperature": 37.0,
                "sanity": 100.0,
                "blood": 100.0,
                "radiation": 0.0,
                "poison": 0.0,
                "carry_capacity": 80.0
            },
            "attributes": {
                "strength": 5,
                "agility": 5,
                "endurance": 5,
                "intelligence": 5,
                "charisma": 5,
                "perception": 5
            },
            "skills": {
                "melee": 1, "ranged": 1, "axes": 1, "spears": 1,
                "blacksmith": 1, "alchemy": 1, "building": 1,
                "hunting": 1, "gathering": 1, "medicine": 1
            },
            "skill_xp": {},
            "debuffs": {},
            "death_weakness_timer": 0.0
        }
    return players[id]

func add_xp(id:int, amount:float):
    var p = ensure_player(id)
    p.xp += amount
    emit_signal("xp_gained", id, amount)
    # level up threshold: 100 * level
    var threshold = 100.0 * p.level
    while p.xp >= threshold:
        p.xp -= threshold
        p.level += 1
        p.perk_points += 1
        emit_signal("level_up", id, p.level)
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
    p.xp = max(0, p.xp * 0.9)
    for s in p.skill_xp.keys():
        p.skill_xp[s] = max(0, p.skill_xp[s] * 0.85)
    p.stats.carry_capacity = max(10.0, p.stats.carry_capacity * 0.85)
    p.stats.max_health = max(50.0, p.stats.max_health * 0.9)
    p.stats.max_stamina = max(50.0, p.stats.max_stamina * 0.9)
    p.death_weakness_timer = 1800.0
    add_debuff(id, "weakness", 1800.0, {"speed_mult": 0.8, "damage_mult": 0.85})
    emit_signal("player_updated", id)

func get_player(id:int) -> Dictionary:
    return players.get(id, {})

func modify_stat(id:int, stat:String, delta:float):
    var p = ensure_player(id)
    if not p.stats.has(stat):
        return
    p.stats[stat] = clamp(p.stats[stat] + delta, 0.0, 100.0)
    if p.stats[stat] <= 10.0:
        emit_signal("stat_critical", id, stat, p.stats[stat])
    emit_signal("player_updated", id)

func set_stat(id:int, stat:String, value:float):
    var p = ensure_player(id)
    if p.stats.has(stat):
        p.stats[stat] = clamp(value, 0.0, 100.0)
        emit_signal("player_updated", id)

func get_stat(id:int, stat:String) -> float:
    var p = ensure_player(id)
    return p.stats.get(stat, 0.0)

func add_debuff(id:int, debuff_name:String, duration:float, effects:Dictionary):
    var p = ensure_player(id)
    p.debuffs[debuff_name] = {"duration": duration, "effects": effects}
    emit_signal("player_updated", id)

func remove_debuff(id:int, debuff_name:String):
    var p = ensure_player(id)
    if p.debuffs.has(debuff_name):
        p.debuffs.erase(debuff_name)
        emit_signal("player_updated", id)

func get_debuff_modifier(id:int, modifier:String) -> float:
    var p = ensure_player(id)
    var total = 1.0
    for d in p.debuffs.values():
        if d.effects.has(modifier):
            total *= d.effects[modifier]
    return total

func process_survival(id:int, delta:float):
    var p = ensure_player(id)
    modify_stat(id, "hunger", -0.05 * delta)
    modify_stat(id, "thirst", -0.08 * delta)
    
    if p.stats.hunger <= 0:
        modify_stat(id, "health", -0.5 * delta)
    if p.stats.thirst <= 0:
        modify_stat(id, "health", -1.0 * delta)
    if p.stats.blood < 50:
        modify_stat(id, "health", -0.3 * delta)
    if p.stats.sanity < 20:
        add_debuff(id, "insanity", 10.0, {"perception_mult": 0.5})
    
    if p.stats.blood < 100:
        modify_stat(id, "blood", 0.1 * delta)
    
    for debuff_name in p.debuffs.keys():
        p.debuffs[debuff_name].duration -= delta
        if p.debuffs[debuff_name].duration <= 0:
            remove_debuff(id, debuff_name)
    
    if p.death_weakness_timer > 0:
        p.death_weakness_timer -= delta
        if p.death_weakness_timer <= 0:
            p.stats.max_health = 100.0
            p.stats.max_stamina = 100.0
            p.stats.carry_capacity = 80.0
            remove_debuff(id, "weakness")

func get_attribute(id:int, attr:String) -> int:
    var p = ensure_player(id)
    return p.attributes.get(attr, 5)

func modify_attribute(id:int, attr:String, delta:int):
    var p = ensure_player(id)
    if p.attributes.has(attr):
        p.attributes[attr] = max(1, p.attributes[attr] + delta)
        emit_signal("player_updated", id)

func get_carry_capacity(id:int) -> float:
    var p = ensure_player(id)
    var base = p.stats.carry_capacity
    var strength_bonus = p.attributes.strength * 5.0
    return base + strength_bonus
