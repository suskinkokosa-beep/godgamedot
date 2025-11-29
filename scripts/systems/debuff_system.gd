extends Node

signal debuff_applied(player_id: int, debuff_id: String)
signal debuff_removed(player_id: int, debuff_id: String)
signal debuff_tick(player_id: int, debuff_id: String, remaining: float)

var player_debuffs := {}

var debuff_database := {
	"starving": {
		"name": "Голодание",
		"description": "Вы голодаете! Здоровье медленно падает.",
		"icon": "🍽️",
		"duration": -1,
		"effects": {"health_drain": 2.0, "stamina_mult": 0.7},
		"condition": "hunger_low"
	},
	"dehydrated": {
		"name": "Обезвоживание", 
		"description": "Вы обезвожены! Здоровье и выносливость падают.",
		"icon": "🏜️",
		"duration": -1,
		"effects": {"health_drain": 3.0, "stamina_mult": 0.5, "speed_mult": 0.8},
		"condition": "thirst_low"
	},
	"freezing": {
		"name": "Замерзание",
		"description": "Вы замерзаете! Здоровье падает.",
		"icon": "❄️",
		"duration": -1,
		"effects": {"health_drain": 4.0, "stamina_drain": 1.0, "speed_mult": 0.7},
		"condition": "temp_cold"
	},
	"overheating": {
		"name": "Перегрев",
		"description": "Вы перегреваетесь! Выносливость падает быстрее.",
		"icon": "🔥",
		"duration": -1,
		"effects": {"thirst_drain": 2.0, "stamina_mult": 0.6},
		"condition": "temp_hot"
	},
	"bleeding": {
		"name": "Кровотечение",
		"description": "Вы истекаете кровью!",
		"icon": "🩸",
		"duration": 60.0,
		"effects": {"blood_drain": 5.0, "health_drain": 1.0},
		"condition": "blood_low"
	},
	"exhausted": {
		"name": "Истощение",
		"description": "Вы истощены! Восстановление замедлено.",
		"icon": "😴",
		"duration": -1,
		"effects": {"stamina_regen_mult": 0.3, "speed_mult": 0.85},
		"condition": "stamina_depleted"
	},
	"insane": {
		"name": "Безумие",
		"description": "Ваш рассудок на грани! Странные видения...",
		"icon": "😵",
		"duration": -1,
		"effects": {"damage_mult": 0.8, "accuracy_mult": 0.6, "hallucinations": true},
		"condition": "sanity_low"
	},
	"death_weakness": {
		"name": "Слабость после смерти",
		"description": "Вы ослаблены после недавней смерти.",
		"icon": "💀",
		"duration": 300.0,
		"effects": {"health_mult": 0.8, "stamina_mult": 0.8, "damage_mult": 0.7}
	},
	"poisoned": {
		"name": "Отравление",
		"description": "Яд разъедает ваше тело.",
		"icon": "☠️",
		"duration": 120.0,
		"effects": {"health_drain": 2.0, "stamina_mult": 0.5}
	},
	"radiation": {
		"name": "Радиация",
		"description": "Вы подверглись радиационному облучению.",
		"icon": "☢️",
		"duration": 180.0,
		"effects": {"health_drain": 1.0, "sanity_drain": 0.5}
	},
	"well_fed": {
		"name": "Сытость",
		"description": "Вы хорошо поели. Бонус к восстановлению.",
		"icon": "🍖",
		"duration": 120.0,
		"effects": {"health_regen": 1.0, "stamina_regen_mult": 1.3}
	},
	"hydrated": {
		"name": "Увлажнённость",
		"description": "Вы хорошо напились. Бонус к выносливости.",
		"icon": "💧",
		"duration": 120.0,
		"effects": {"stamina_regen_mult": 1.2, "thirst_drain_mult": 0.7}
	}
}

func _ready():
	pass

func _process(delta):
	for player_id in player_debuffs.keys():
		_update_player_debuffs(player_id, delta)

func _update_player_debuffs(player_id: int, delta: float):
	var to_remove := []
	
	for debuff_id in player_debuffs[player_id].keys():
		var debuff = player_debuffs[player_id][debuff_id]
		
		if debuff.duration > 0:
			debuff.duration -= delta
			emit_signal("debuff_tick", player_id, debuff_id, debuff.duration)
			
			if debuff.duration <= 0:
				to_remove.append(debuff_id)
	
	for debuff_id in to_remove:
		remove_debuff(player_id, debuff_id)

func ensure_player(player_id: int):
	if not player_debuffs.has(player_id):
		player_debuffs[player_id] = {}

func apply_debuff(player_id: int, debuff_id: String, duration_override: float = -1):
	if not debuff_database.has(debuff_id):
		return
	
	ensure_player(player_id)
	
	var base = debuff_database[debuff_id]
	var duration = duration_override if duration_override > 0 else base.duration
	
	player_debuffs[player_id][debuff_id] = {
		"id": debuff_id,
		"duration": duration,
		"effects": base.effects.duplicate()
	}
	
	emit_signal("debuff_applied", player_id, debuff_id)

func remove_debuff(player_id: int, debuff_id: String):
	if not player_debuffs.has(player_id):
		return
	if not player_debuffs[player_id].has(debuff_id):
		return
	
	player_debuffs[player_id].erase(debuff_id)
	emit_signal("debuff_removed", player_id, debuff_id)

func has_debuff(player_id: int, debuff_id: String) -> bool:
	if not player_debuffs.has(player_id):
		return false
	return player_debuffs[player_id].has(debuff_id)

func get_active_debuffs(player_id: int) -> Array:
	if not player_debuffs.has(player_id):
		return []
	return player_debuffs[player_id].keys()

func get_effect_multiplier(player_id: int, effect_name: String) -> float:
	var mult = 1.0
	if not player_debuffs.has(player_id):
		return mult
	
	for debuff_id in player_debuffs[player_id].keys():
		var effects = player_debuffs[player_id][debuff_id].effects
		if effects.has(effect_name):
			mult *= effects[effect_name]
	
	return mult

func get_effect_drain(player_id: int, drain_type: String) -> float:
	var total = 0.0
	if not player_debuffs.has(player_id):
		return total
	
	for debuff_id in player_debuffs[player_id].keys():
		var effects = player_debuffs[player_id][debuff_id].effects
		if effects.has(drain_type):
			total += effects[drain_type]
	
	return total

func check_conditions(player_id: int, player):
	ensure_player(player_id)
	
	if player.get("hunger") != null:
		if player.hunger < 10:
			if not has_debuff(player_id, "starving"):
				apply_debuff(player_id, "starving")
		else:
			remove_debuff(player_id, "starving")
		
		if player.hunger > 80:
			if not has_debuff(player_id, "well_fed"):
				apply_debuff(player_id, "well_fed")
	
	if player.get("thirst") != null:
		if player.thirst < 10:
			if not has_debuff(player_id, "dehydrated"):
				apply_debuff(player_id, "dehydrated")
		else:
			remove_debuff(player_id, "dehydrated")
		
		if player.thirst > 80:
			if not has_debuff(player_id, "hydrated"):
				apply_debuff(player_id, "hydrated")
	
	if player.get("body_temperature") != null:
		if player.body_temperature < 35.0:
			if not has_debuff(player_id, "freezing"):
				apply_debuff(player_id, "freezing")
		else:
			remove_debuff(player_id, "freezing")
		
		if player.body_temperature > 38.5:
			if not has_debuff(player_id, "overheating"):
				apply_debuff(player_id, "overheating")
		else:
			remove_debuff(player_id, "overheating")
	
	if player.get("blood") != null:
		if player.blood < 50:
			if not has_debuff(player_id, "bleeding"):
				apply_debuff(player_id, "bleeding")
		else:
			remove_debuff(player_id, "bleeding")
	
	if player.get("sanity") != null:
		if player.sanity < 20:
			if not has_debuff(player_id, "insane"):
				apply_debuff(player_id, "insane")
		else:
			remove_debuff(player_id, "insane")
	
	if player.get("stamina") != null and player.get("max_stamina") != null:
		if player.stamina < player.max_stamina * 0.05:
			if not has_debuff(player_id, "exhausted"):
				apply_debuff(player_id, "exhausted")
		elif player.stamina > player.max_stamina * 0.2:
			remove_debuff(player_id, "exhausted")

func get_debuff_info(debuff_id: String) -> Dictionary:
	return debuff_database.get(debuff_id, {})
