extends Node

signal trade_route_created(from_id, to_id)
signal trade_route_removed(from_id, to_id)
signal caravan_departed(route_id, goods)
signal caravan_arrived(route_id, goods)
signal trade_completed(settlement_a, settlement_b, goods, profit)

var trade_routes := {}
var active_caravans := []
var market_prices := {}
var price_history := {}

var base_prices := {
        "food": 5,
        "wood": 3,
        "stone": 4,
        "iron": 15,
        "copper": 12,
        "gold_ore": 50,
        "silver": 30,
        "cloth": 8,
        "leather": 10,
        "tools": 25,
        "weapons": 40,
        "armor": 60,
        "potions": 20,
        "gems": 100,
        "magic_materials": 200
}

var supply_demand := {}

func _ready():
        _initialize_market()

func _process(delta):
        _update_caravans(delta)
        _update_prices(delta)
        _auto_create_routes()

func _initialize_market():
        for item in base_prices:
                market_prices[item] = base_prices[item]
                price_history[item] = [base_prices[item]]

func create_trade_route(from_settlement_id: int, to_settlement_id: int, goods: Array = []) -> int:
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return -1
        
        var from_s = ss.get_settlement(from_settlement_id)
        var to_s = ss.get_settlement(to_settlement_id)
        
        if not from_s or not to_s:
                return -1
        
        if from_s.faction != to_s.faction:
                var faction_sys = get_node_or_null("/root/FactionSystem")
                if faction_sys:
                        var relation = faction_sys.get_relation(from_s.faction, to_s.faction)
                        if relation < -25:
                                return -1
        
        var route_id = _generate_route_id()
        var distance = from_s.position.distance_to(to_s.position)
        var travel_time = distance / 10.0
        
        trade_routes[route_id] = {
                "id": route_id,
                "from": from_settlement_id,
                "to": to_settlement_id,
                "goods": goods if goods.size() > 0 else _determine_trade_goods(from_s, to_s),
                "distance": distance,
                "travel_time": travel_time,
                "profit_margin": 0.0,
                "active": true,
                "last_trade_time": 0.0,
                "trade_interval": travel_time * 2 + 60.0
        }
        
        emit_signal("trade_route_created", from_settlement_id, to_settlement_id)
        return route_id

func remove_trade_route(route_id: int):
        if trade_routes.has(route_id):
                var route = trade_routes[route_id]
                emit_signal("trade_route_removed", route.from, route.to)
                trade_routes.erase(route_id)

func _determine_trade_goods(from_settlement: Dictionary, to_settlement: Dictionary) -> Array:
        var goods = []
        var from_resources = from_settlement.get("resources", {})
        var to_resources = to_settlement.get("resources", {})
        
        for res_type in from_resources:
                var from_amount = from_resources.get(res_type, 0)
                var to_amount = to_resources.get(res_type, 0)
                
                if from_amount > to_amount * 2 and from_amount > 50:
                        var trade_amount = int(from_amount * 0.2)
                        goods.append({
                                "type": res_type,
                                "quantity": trade_amount,
                                "price": get_price(res_type)
                        })
        
        return goods

func dispatch_caravan(route_id: int):
        if not trade_routes.has(route_id):
                return
        
        var route = trade_routes[route_id]
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var from_s = ss.get_settlement(route.from)
        if not from_s:
                return
        
        var goods_to_trade = []
        for good in route.goods:
                var available = from_s.resources.get(good.type, 0)
                if available >= good.quantity:
                        from_s.resources[good.type] -= good.quantity
                        goods_to_trade.append(good.duplicate())
        
        if goods_to_trade.is_empty():
                return
        
        var caravan = {
                "route_id": route_id,
                "goods": goods_to_trade,
                "progress": 0.0,
                "travel_time": route.travel_time,
                "returning": false
        }
        
        active_caravans.append(caravan)
        emit_signal("caravan_departed", route_id, goods_to_trade)

func _update_caravans(delta):
        var completed_caravans = []
        
        for caravan in active_caravans:
                caravan.progress += delta
                
                if caravan.progress >= caravan.travel_time:
                        if caravan.returning:
                                completed_caravans.append(caravan)
                        else:
                                _complete_caravan_delivery(caravan)
                                caravan.returning = true
                                caravan.progress = 0.0
        
        for caravan in completed_caravans:
                active_caravans.erase(caravan)

func _complete_caravan_delivery(caravan: Dictionary):
        if not trade_routes.has(caravan.route_id):
                return
        
        var route = trade_routes[caravan.route_id]
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var to_s = ss.get_settlement(route.to)
        if not to_s:
                return
        
        var total_profit = 0
        for good in caravan.goods:
                var local_price = _get_local_price(route.to, good.type)
                var profit = (local_price - good.price) * good.quantity
                total_profit += profit
                
                if not to_s.resources.has(good.type):
                        to_s.resources[good.type] = 0
                to_s.resources[good.type] += good.quantity
                
                _update_supply_demand(route.to, good.type, good.quantity)
        
        route.profit_margin = total_profit
        route.last_trade_time = Time.get_unix_time_from_system()
        
        emit_signal("caravan_arrived", caravan.route_id, caravan.goods)
        emit_signal("trade_completed", route.from, route.to, caravan.goods, total_profit)

func _update_prices(delta):
        for item in market_prices:
                var demand = supply_demand.get(item, {}).get("demand", 1.0)
                var supply = supply_demand.get(item, {}).get("supply", 1.0)
                
                var ratio = demand / max(supply, 0.1)
                var base = float(base_prices.get(item, 10))
                var new_price = base * ratio
                new_price = clamp(new_price, base * 0.5, base * 3.0)
                
                market_prices[item] = lerpf(float(market_prices[item]), new_price, 0.01)
                
                if price_history[item].size() > 100:
                        price_history[item].pop_front()
                price_history[item].append(market_prices[item])

func _update_supply_demand(settlement_id: int, item_type: String, amount: int):
        if not supply_demand.has(item_type):
                supply_demand[item_type] = {"supply": 1.0, "demand": 1.0}
        
        supply_demand[item_type].supply += amount * 0.01
        supply_demand[item_type].supply = max(0.1, supply_demand[item_type].supply - 0.001)

func _auto_create_routes():
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var settlements = ss.get_all_settlements()
        if settlements.size() < 2:
                return
        
        for i in range(settlements.size()):
                for j in range(i + 1, settlements.size()):
                        var s1 = settlements[i]
                        var s2 = settlements[j]
                        
                        if _has_route_between(s1.id, s2.id):
                                continue
                        
                        if s1.level >= 1 and s2.level >= 1:
                                var distance = s1.position.distance_to(s2.position)
                                if distance < 200:
                                        create_trade_route(s1.id, s2.id)

func _has_route_between(id1: int, id2: int) -> bool:
        for route in trade_routes.values():
                if (route.from == id1 and route.to == id2) or (route.from == id2 and route.to == id1):
                        return true
        return false

func get_price(item_type: String) -> int:
        return int(market_prices.get(item_type, base_prices.get(item_type, 10)))

func _get_local_price(settlement_id: int, item_type: String) -> int:
        var base = get_price(item_type)
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return base
        
        var settlement = ss.get_settlement(settlement_id)
        if not settlement:
                return base
        
        var local_supply = settlement.resources.get(item_type, 0)
        var modifier = 1.0
        
        if local_supply < 10:
                modifier = 1.5
        elif local_supply > 100:
                modifier = 0.7
        
        return int(base * modifier)

func _generate_route_id() -> int:
        var max_id = 0
        for id in trade_routes.keys():
                max_id = max(max_id, id)
        return max_id + 1

func get_route_info(route_id: int) -> Dictionary:
        return trade_routes.get(route_id, {})

func get_all_routes() -> Array:
        return trade_routes.values()

func get_routes_for_settlement(settlement_id: int) -> Array:
        var routes = []
        for route in trade_routes.values():
                if route.from == settlement_id or route.to == settlement_id:
                        routes.append(route)
        return routes

func get_active_caravans() -> Array:
        return active_caravans

func get_price_history(item_type: String) -> Array:
        return price_history.get(item_type, [])
