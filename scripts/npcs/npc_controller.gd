extends CharacterBody3D
class_name NPCController

signal interacted(player)
signal died()
signal damaged(amount, source)

@export var npc_name: String = "Гражданин"
@export var max_health: float = 100.0
@export var move_speed: float = 3.0
@export var run_speed: float = 5.0
@export var gravity: float = 20.0

var health: float = 100.0
var is_dead: bool = false
var target_velocity: Vector3 = Vector3.ZERO

var ai_brain: Node
var nav_agent: NavigationAgent3D
var name_label: Label3D
var interaction_area: Area3D

func _ready():
        health = max_health
        add_to_group("npcs")
        add_to_group("interactables")
        
        ai_brain = get_node_or_null("NPCAIBrain")
        nav_agent = get_node_or_null("NavigationAgent3D")
        name_label = get_node_or_null("NameLabel")
        interaction_area = get_node_or_null("InteractionArea")
        
        _generate_proper_name()
        
        if name_label:
                _update_name_label()
        
        if ai_brain:
                ai_brain.parent_npc = self
                if ai_brain.npc_name.is_empty():
                        ai_brain.npc_name = npc_name
        
        if interaction_area:
                interaction_area.body_entered.connect(_on_body_entered)

func _generate_proper_name():
        if npc_name != "Гражданин" and npc_name != "Citizen":
                return
        
        var gm = get_node_or_null("/root/GameManager")
        if gm:
                var role = "citizen"
                if ai_brain:
                        match ai_brain.profession:
                                1: role = "guard"
                                2: role = "trader"
                                3: role = "farmer"
                                4: role = "hunter"
                                5: role = "builder"
                npc_name = gm.generate_npc_name(role)

func _update_name_label():
        if not name_label:
                return
        
        var profession_title := ""
        var gm = get_node_or_null("/root/GameManager")
        var lang = "ru"
        if gm:
                lang = gm.get_language()
        
        if ai_brain:
                match ai_brain.profession:
                        1: profession_title = "Стражник" if lang == "ru" else "Guard"
                        2: profession_title = "Торговец" if lang == "ru" else "Trader"
                        3: profession_title = "Фермер" if lang == "ru" else "Farmer"
                        4: profession_title = "Охотник" if lang == "ru" else "Hunter"
                        5: profession_title = "Ремесленник" if lang == "ru" else "Craftsman"
                        _: profession_title = "Житель" if lang == "ru" else "Citizen"
        else:
                profession_title = "Житель" if lang == "ru" else "Citizen"
        
        name_label.text = npc_name
        
        var title_label = get_node_or_null("TitleLabel")
        if title_label and title_label is Label3D:
                title_label.text = profession_title
        
        match ai_brain.profession if ai_brain else 0:
                1:
                        name_label.modulate = Color(0.7, 0.7, 1.0)
                2:
                        name_label.modulate = Color(1.0, 0.85, 0.4)
                3:
                        name_label.modulate = Color(0.5, 0.9, 0.5)
                _:
                        name_label.modulate = Color(0.9, 0.9, 0.9)

func _physics_process(delta):
        if is_dead:
                return
        
        if not is_on_floor():
                velocity.y -= gravity * delta
        
        if nav_agent and not nav_agent.is_navigation_finished():
                var next_pos = nav_agent.get_next_path_position()
                var direction = (next_pos - global_position).normalized()
                direction.y = 0
                velocity.x = direction.x * move_speed
                velocity.z = direction.z * move_speed
        
        move_and_slide()
        
        _update_facing()

func _process(delta):
        if is_dead:
                return
        
        if ai_brain and ai_brain.has_method("_process"):
                ai_brain._process(delta)

func _update_facing():
        if velocity.length() > 0.1:
                var look_dir = Vector3(velocity.x, 0, velocity.z).normalized()
                if look_dir.length() > 0.1:
                        var target_rotation = atan2(look_dir.x, look_dir.z)
                        rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

func navigate_to(target: Vector3):
        if nav_agent:
                nav_agent.target_position = target

func interact(player) -> bool:
        emit_signal("interacted", player)
        
        if ai_brain and ai_brain.can_trade():
                _open_trade_menu(player)
                return true
        
        _start_dialogue(player)
        return true

func _open_trade_menu(player):
        var trade_goods = ai_brain.get_trade_goods() if ai_brain else []
        var dialogue_sys = get_node_or_null("/root/DialogueSystem")
        
        if dialogue_sys:
                dialogue_sys.start_trade_dialogue(self, player, trade_goods)

func _start_dialogue(player):
        var dialogue_sys = get_node_or_null("/root/DialogueSystem")
        
        if dialogue_sys:
                var dialogue_id = _get_dialogue_id()
                dialogue_sys.start_dialogue(dialogue_id, self, player)
        else:
                _say_random_greeting()

func _get_dialogue_id() -> String:
        if ai_brain:
                match ai_brain.profession:
                        1:
                                return "guard_dialogue"
                        2:
                                return "trader_dialogue"
                        3:
                                return "farmer_dialogue"
                        4:
                                return "hunter_dialogue"
        return "citizen_dialogue"

func _say_random_greeting():
        var greetings = [
                "Приветствую, путник!",
                "Добро пожаловать в наше поселение.",
                "Чем могу помочь?",
                "Прекрасный день, не так ли?",
                "Будьте осторожны, в лесу водятся монстры."
        ]
        
        var notif = get_node_or_null("/root/NotificationSystem")
        if notif:
                notif.show_notification(npc_name + ": " + greetings[randi() % greetings.size()], "info")

func take_damage(amount: float, source = null):
        if is_dead:
                return
        
        health -= amount
        emit_signal("damaged", amount, source)
        
        if ai_brain:
                ai_brain.needs.safety -= 20
                if source and source.is_in_group("players"):
                        ai_brain._change_state(ai_brain.AIState.FLEEING)
        
        var vfx = get_node_or_null("/root/VFXManager")
        if vfx:
                vfx.spawn_hit_effect(global_position + Vector3(0, 1, 0))
        
        if health <= 0:
                _die()

func heal(amount: float):
        health = min(health + amount, max_health)

func _die():
        is_dead = true
        emit_signal("died")
        
        var loot_drop = get_node_or_null("/root/LootDropSystem")
        if loot_drop and ai_brain:
                for item in ai_brain.inventory:
                        loot_drop.spawn_drop(item, global_position + Vector3(0, 0.5, 0))
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys and ai_brain:
                faction_sys.modify_relation("player", ai_brain.faction, -10)
        
        queue_free()

func _on_body_entered(body):
        if body.is_in_group("players"):
                pass

func set_profession(profession: int):
        if ai_brain:
                ai_brain.profession = profession
                _update_appearance()

func _update_appearance():
        if not ai_brain:
                return
        
        var mesh = get_node_or_null("MeshInstance3D")
        var mat: StandardMaterial3D = null
        
        if mesh:
                if mesh.material_override:
                        mat = mesh.material_override
                else:
                        mat = StandardMaterial3D.new()
                        mesh.material_override = mat
        
        match ai_brain.profession:
                1:
                        if mat: mat.albedo_color = Color(0.3, 0.3, 0.5)
                2:
                        if mat: mat.albedo_color = Color(0.6, 0.5, 0.3)
                3:
                        if mat: mat.albedo_color = Color(0.4, 0.5, 0.3)
                4:
                        if mat: mat.albedo_color = Color(0.5, 0.4, 0.3)
                5:
                        if mat: mat.albedo_color = Color(0.45, 0.35, 0.3)
                _:
                        if mat: mat.albedo_color = Color(0.5, 0.45, 0.4)
        
        _generate_proper_name()
        _update_name_label()

func get_display_name() -> String:
        return npc_name

func get_interaction_hint() -> String:
        if ai_brain and ai_brain.can_trade():
                return "Нажмите E для торговли с " + npc_name
        return "Нажмите E для разговора с " + npc_name

func get_state() -> String:
        if ai_brain:
                return ai_brain.get_state_name()
        return "idle"

func is_hostile() -> bool:
        return false

func save_data() -> Dictionary:
        var data = {
                "npc_name": npc_name,
                "health": health,
                "position": global_position,
                "rotation": rotation
        }
        
        if ai_brain:
                data["ai_data"] = ai_brain.save_data()
        
        return data

func load_data(data: Dictionary):
        if data.has("npc_name"):
                npc_name = data.npc_name
        if data.has("health"):
                health = data.health
        if data.has("position"):
                global_position = data.position
        if data.has("rotation"):
                rotation = data.rotation
        if data.has("ai_data") and ai_brain:
                ai_brain.load_data(data.ai_data)
        
        if name_label:
                name_label.text = npc_name
