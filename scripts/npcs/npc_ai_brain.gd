extends Node
class_name NPCAIBrain

signal state_changed(new_state)
signal action_completed(action_type)
signal dialogue_requested(npc, player)

enum AIState {
	IDLE,
	WANDERING,
	WORKING,
	PATROLLING,
	HUNTING,
	TRADING,
	SOCIALIZING,
	FLEEING,
	COMBAT,
	SLEEPING,
	EATING,
	GATHERING
}

enum NPCProfession {
	NONE,
	GUARD,
	TRADER,
	FARMER,
	HUNTER,
	CRAFTSMAN,
	MINER,
	CITIZEN,
	PRIEST,
	SOLDIER
}

@export var npc_name: String = "NPC"
@export var profession: NPCProfession = NPCProfession.CITIZEN
@export var home_settlement_id: int = -1
@export var faction: String = "neutral"

var current_state: AIState = AIState.IDLE
var previous_state: AIState = AIState.IDLE
var parent_npc: CharacterBody3D

var needs := {
	"hunger": 100.0,
	"thirst": 100.0,
	"rest": 100.0,
	"safety": 100.0,
	"social": 100.0
}

var schedule := {
	6: AIState.WORKING,
	12: AIState.EATING,
	13: AIState.WORKING,
	18: AIState.SOCIALIZING,
	21: AIState.SLEEPING,
	23: AIState.SLEEPING
}

var inventory: Array = []
var max_inventory: int = 20
var gold: int = 0
var trade_goods: Array = []
var trade_prices: Dictionary = {}

var current_target: Node = null
var current_path: Array = []
var path_index: int = 0
var home_position: Vector3 = Vector3.ZERO
var work_position: Vector3 = Vector3.ZERO
var patrol_points: Array = []
var patrol_index: int = 0

var state_timer: float = 0.0
var action_timer: float = 0.0
var decision_interval: float = 2.0
var aggression: float = 0.5
var courage: float = 0.5
var sociability: float = 0.5

var known_locations := {}
var relationships := {}
var memories := []
var max_memories: int = 50

func _ready():
	parent_npc = get_parent() as CharacterBody3D
	if parent_npc:
		home_position = parent_npc.global_position
	
	_setup_profession()
	_generate_personality()

func _process(delta):
	_update_needs(delta)
	
	state_timer += delta
	if state_timer >= decision_interval:
		state_timer = 0.0
		_make_decision()
	
	_process_current_state(delta)

func _update_needs(delta):
	needs.hunger -= delta * 0.05
	needs.thirst -= delta * 0.08
	needs.rest -= delta * 0.03
	needs.social -= delta * 0.02
	
	var danger_nearby = _check_danger()
	if danger_nearby:
		needs.safety = max(0, needs.safety - delta * 10)
	else:
		needs.safety = min(100, needs.safety + delta * 5)
	
	for key in needs:
		needs[key] = clamp(needs[key], 0, 100)

func _make_decision():
	var most_urgent_need = _get_most_urgent_need()
	
	if needs.safety < 30:
		_change_state(AIState.FLEEING)
		return
	
	if current_state == AIState.COMBAT:
		if not is_instance_valid(current_target) or needs.safety < 20:
			_change_state(AIState.IDLE)
		return
	
	if most_urgent_need == "hunger" and needs.hunger < 30:
		if _has_food():
			_change_state(AIState.EATING)
		else:
			_change_state(AIState.HUNTING if profession == NPCProfession.HUNTER else AIState.GATHERING)
		return
	
	if most_urgent_need == "rest" and needs.rest < 20:
		_change_state(AIState.SLEEPING)
		return
	
	if most_urgent_need == "social" and needs.social < 30:
		_change_state(AIState.SOCIALIZING)
		return
	
	var hour = _get_game_hour()
	for schedule_hour in schedule.keys():
		if hour >= schedule_hour:
			var scheduled_state = schedule[schedule_hour]
			if current_state != scheduled_state:
				_change_state(scheduled_state)
				return

func _process_current_state(delta):
	match current_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.WANDERING:
			_process_wandering(delta)
		AIState.WORKING:
			_process_working(delta)
		AIState.PATROLLING:
			_process_patrolling(delta)
		AIState.HUNTING:
			_process_hunting(delta)
		AIState.TRADING:
			_process_trading(delta)
		AIState.SOCIALIZING:
			_process_socializing(delta)
		AIState.FLEEING:
			_process_fleeing(delta)
		AIState.COMBAT:
			_process_combat(delta)
		AIState.SLEEPING:
			_process_sleeping(delta)
		AIState.EATING:
			_process_eating(delta)
		AIState.GATHERING:
			_process_gathering(delta)

func _process_idle(delta):
	action_timer += delta
	if action_timer > 5.0:
		action_timer = 0.0
		if randf() < 0.3:
			_change_state(AIState.WANDERING)

func _process_wandering(delta):
	if current_path.is_empty():
		var random_offset = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		_navigate_to(home_position + random_offset)
	else:
		_follow_path(delta)
	
	action_timer += delta
	if action_timer > 15.0:
		action_timer = 0.0
		_change_state(AIState.IDLE)

func _process_working(delta):
	if work_position == Vector3.ZERO:
		work_position = home_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	
	if parent_npc and parent_npc.global_position.distance_to(work_position) > 2.0:
		_navigate_to(work_position)
		_follow_path(delta)
	else:
		action_timer += delta
		if action_timer > 2.0:
			action_timer = 0.0
			_do_work()

func _process_patrolling(delta):
	if patrol_points.is_empty():
		_generate_patrol_points()
	
	if current_path.is_empty() and patrol_points.size() > 0:
		var target = patrol_points[patrol_index]
		_navigate_to(target)
		patrol_index = (patrol_index + 1) % patrol_points.size()
	else:
		_follow_path(delta)
	
	_check_for_threats()

func _process_hunting(delta):
	if not is_instance_valid(current_target):
		current_target = _find_prey()
	
	if current_target:
		var prey_pos = current_target.global_position
		if parent_npc and parent_npc.global_position.distance_to(prey_pos) < 2.0:
			_attack_target(current_target)
		else:
			_navigate_to(prey_pos)
			_follow_path(delta)
	else:
		action_timer += delta
		if action_timer > 10.0:
			action_timer = 0.0
			_change_state(AIState.WANDERING)

func _process_trading(delta):
	if not is_instance_valid(current_target):
		_change_state(AIState.WANDERING)
		return
	
	var dist = parent_npc.global_position.distance_to(current_target.global_position)
	if dist < 3.0:
		emit_signal("dialogue_requested", parent_npc, current_target)
	else:
		_navigate_to(current_target.global_position)
		_follow_path(delta)

func _process_socializing(delta):
	var nearby_npcs = _find_nearby_npcs(15.0)
	if nearby_npcs.is_empty():
		_change_state(AIState.WANDERING)
		return
	
	if not is_instance_valid(current_target) or current_target not in nearby_npcs:
		current_target = nearby_npcs[randi() % nearby_npcs.size()]
	
	if current_target:
		var dist = parent_npc.global_position.distance_to(current_target.global_position)
		if dist < 3.0:
			action_timer += delta
			if action_timer > 1.0:
				action_timer = 0.0
				_socialize_with(current_target)
				needs.social = min(100, needs.social + 5)
		else:
			_navigate_to(current_target.global_position)
			_follow_path(delta)

func _process_fleeing(delta):
	var threats = _find_threats()
	if threats.is_empty():
		needs.safety = min(100, needs.safety + 20)
		_change_state(AIState.IDLE)
		return
	
	var flee_direction = Vector3.ZERO
	for threat in threats:
		var away = parent_npc.global_position - threat.global_position
		flee_direction += away.normalized()
	
	flee_direction = flee_direction.normalized()
	var flee_target = parent_npc.global_position + flee_direction * 20.0
	_navigate_to(flee_target)
	_follow_path(delta)

func _process_combat(delta):
	if not is_instance_valid(current_target):
		_change_state(AIState.IDLE)
		return
	
	var dist = parent_npc.global_position.distance_to(current_target.global_position)
	
	if dist < 2.0:
		action_timer += delta
		if action_timer > 1.0:
			action_timer = 0.0
			_attack_target(current_target)
	else:
		_navigate_to(current_target.global_position)
		_follow_path(delta)

func _process_sleeping(delta):
	needs.rest = min(100, needs.rest + delta * 2)
	
	if needs.rest >= 100:
		_change_state(AIState.IDLE)

func _process_eating(delta):
	if _has_food():
		action_timer += delta
		if action_timer > 3.0:
			action_timer = 0.0
			_consume_food()
			needs.hunger = min(100, needs.hunger + 30)
	else:
		_change_state(AIState.GATHERING)

func _process_gathering(delta):
	var resource = _find_nearest_resource()
	if resource:
		var dist = parent_npc.global_position.distance_to(resource.global_position)
		if dist < 2.0:
			action_timer += delta
			if action_timer > 2.0:
				action_timer = 0.0
				_gather_resource(resource)
		else:
			_navigate_to(resource.global_position)
			_follow_path(delta)
	else:
		_change_state(AIState.WANDERING)

func _change_state(new_state: AIState):
	previous_state = current_state
	current_state = new_state
	action_timer = 0.0
	current_path.clear()
	emit_signal("state_changed", new_state)

func _navigate_to(target: Vector3):
	current_path = [target]
	path_index = 0

func _follow_path(delta):
	if current_path.is_empty() or not parent_npc:
		return
	
	var target = current_path[path_index]
	var direction = (target - parent_npc.global_position).normalized()
	direction.y = 0
	
	parent_npc.velocity = direction * 3.0
	parent_npc.move_and_slide()
	
	if parent_npc.global_position.distance_to(target) < 1.0:
		path_index += 1
		if path_index >= current_path.size():
			current_path.clear()
			emit_signal("action_completed", "navigation")

func _setup_profession():
	match profession:
		NPCProfession.GUARD:
			schedule = {6: AIState.PATROLLING, 14: AIState.EATING, 15: AIState.PATROLLING, 22: AIState.SLEEPING}
			aggression = 0.7
			courage = 0.8
		NPCProfession.TRADER:
			schedule = {7: AIState.TRADING, 12: AIState.EATING, 13: AIState.TRADING, 19: AIState.SOCIALIZING, 22: AIState.SLEEPING}
			_generate_trade_goods()
		NPCProfession.HUNTER:
			schedule = {5: AIState.HUNTING, 12: AIState.EATING, 13: AIState.HUNTING, 18: AIState.WORKING, 21: AIState.SLEEPING}
			aggression = 0.6
		NPCProfession.FARMER:
			schedule = {5: AIState.WORKING, 12: AIState.EATING, 13: AIState.WORKING, 18: AIState.SOCIALIZING, 20: AIState.SLEEPING}

func _generate_personality():
	aggression = randf_range(0.2, 0.8)
	courage = randf_range(0.3, 0.9)
	sociability = randf_range(0.3, 0.9)

func _generate_trade_goods():
	var possible_goods = ["food", "wood", "stone", "iron", "cloth", "leather", "tools", "weapons"]
	var num_goods = randi_range(3, 6)
	
	for i in range(num_goods):
		var good = possible_goods[randi() % possible_goods.size()]
		trade_goods.append({"type": good, "quantity": randi_range(5, 20)})
		trade_prices[good] = randi_range(5, 50)

func _generate_patrol_points():
	patrol_points.clear()
	var ss = get_node_or_null("/root/SettlementSystem")
	if ss and home_settlement_id >= 0:
		var settlement = ss.get_settlement(home_settlement_id)
		if settlement:
			var center = settlement.get("position", home_position)
			var radius = settlement.get("territory_radius", 30.0)
			for i in range(4):
				var angle = i * PI / 2
				var point = center + Vector3(cos(angle) * radius * 0.8, 0, sin(angle) * radius * 0.8)
				patrol_points.append(point)
	
	if patrol_points.is_empty():
		for i in range(4):
			var offset = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
			patrol_points.append(home_position + offset)

func _check_danger() -> bool:
	var threats = _find_threats()
	return not threats.is_empty()

func _find_threats() -> Array:
	var threats = []
	var mobs = get_tree().get_nodes_in_group("mobs")
	
	for mob in mobs:
		if is_instance_valid(mob) and mob.has_method("is_hostile"):
			if mob.is_hostile() and parent_npc.global_position.distance_to(mob.global_position) < 20.0:
				threats.append(mob)
	
	return threats

func _check_for_threats():
	var threats = _find_threats()
	for threat in threats:
		if courage > 0.6:
			current_target = threat
			_change_state(AIState.COMBAT)
		elif needs.safety < 50:
			_change_state(AIState.FLEEING)

func _find_prey() -> Node:
	var animals = get_tree().get_nodes_in_group("animals")
	var nearest = null
	var nearest_dist = 50.0
	
	for animal in animals:
		if is_instance_valid(animal):
			var dist = parent_npc.global_position.distance_to(animal.global_position)
			if dist < nearest_dist:
				nearest = animal
				nearest_dist = dist
	
	return nearest

func _find_nearby_npcs(radius: float) -> Array:
	var npcs = []
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	
	for npc in all_npcs:
		if npc != parent_npc and is_instance_valid(npc):
			if parent_npc.global_position.distance_to(npc.global_position) < radius:
				npcs.append(npc)
	
	return npcs

func _find_nearest_resource() -> Node:
	var resources = get_tree().get_nodes_in_group("resources")
	var nearest = null
	var nearest_dist = 30.0
	
	for res in resources:
		if is_instance_valid(res):
			var dist = parent_npc.global_position.distance_to(res.global_position)
			if dist < nearest_dist:
				nearest = res
				nearest_dist = dist
	
	return nearest

func _has_food() -> bool:
	for item in inventory:
		if item.get("type", "") == "food":
			return true
	return false

func _consume_food():
	for i in range(inventory.size()):
		if inventory[i].get("type", "") == "food":
			inventory.remove_at(i)
			return

func _do_work():
	match profession:
		NPCProfession.FARMER:
			var produced = {"type": "food", "quantity": 1}
			add_to_inventory(produced)
		NPCProfession.MINER:
			var produced = {"type": "stone", "quantity": 1}
			add_to_inventory(produced)
		NPCProfession.CRAFTSMAN:
			pass

func _attack_target(target):
	if target and target.has_method("take_damage"):
		var damage = 10.0
		target.take_damage(damage, parent_npc)

func _gather_resource(resource):
	if resource and resource.has_method("gather"):
		var gathered = resource.gather(parent_npc)
		if gathered:
			add_to_inventory(gathered)

func _socialize_with(other_npc):
	if other_npc and other_npc.has_node("NPCAIBrain"):
		var other_brain = other_npc.get_node("NPCAIBrain")
		_remember("socialized", other_npc.name)
		if not relationships.has(other_npc.name):
			relationships[other_npc.name] = 0
		relationships[other_npc.name] += 1

func _remember(event_type: String, data):
	var memory = {
		"type": event_type,
		"data": data,
		"time": Time.get_unix_time_from_system()
	}
	memories.append(memory)
	if memories.size() > max_memories:
		memories.pop_front()

func _get_most_urgent_need() -> String:
	var most_urgent = "hunger"
	var lowest_value = 100.0
	
	for need_name in needs:
		if needs[need_name] < lowest_value:
			lowest_value = needs[need_name]
			most_urgent = need_name
	
	return most_urgent

func _get_game_hour() -> int:
	var dnc = get_node_or_null("/root/DayNightCycle")
	if dnc and dnc.has_method("get_hour"):
		return dnc.get_hour()
	return 12

func add_to_inventory(item: Dictionary) -> bool:
	if inventory.size() >= max_inventory:
		return false
	inventory.append(item)
	return true

func remove_from_inventory(item_type: String) -> Dictionary:
	for i in range(inventory.size()):
		if inventory[i].get("type", "") == item_type:
			return inventory.pop_at(i)
	return {}

func can_trade() -> bool:
	return profession == NPCProfession.TRADER and current_state != AIState.SLEEPING

func get_trade_goods() -> Array:
	return trade_goods

func get_price(item_type: String) -> int:
	return trade_prices.get(item_type, 10)

func buy_from_player(item_type: String, quantity: int, player) -> bool:
	var price = get_price(item_type) * quantity
	if gold >= price:
		gold -= price
		add_to_inventory({"type": item_type, "quantity": quantity})
		return true
	return false

func sell_to_player(item_type: String, quantity: int, player) -> bool:
	for good in trade_goods:
		if good.type == item_type and good.quantity >= quantity:
			good.quantity -= quantity
			var price = get_price(item_type) * quantity
			gold += price
			return true
	return false

func get_state_name() -> String:
	return AIState.keys()[current_state]

func save_data() -> Dictionary:
	return {
		"npc_name": npc_name,
		"profession": profession,
		"faction": faction,
		"home_settlement_id": home_settlement_id,
		"needs": needs,
		"inventory": inventory,
		"gold": gold,
		"trade_goods": trade_goods,
		"relationships": relationships,
		"current_state": current_state
	}

func load_data(data: Dictionary):
	if data.has("needs"):
		needs = data.needs
	if data.has("inventory"):
		inventory = data.inventory
	if data.has("gold"):
		gold = data.gold
	if data.has("trade_goods"):
		trade_goods = data.trade_goods
	if data.has("relationships"):
		relationships = data.relationships
