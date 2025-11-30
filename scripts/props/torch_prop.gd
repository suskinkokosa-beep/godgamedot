extends StaticBody3D
class_name TorchProp

@export var prop_name: String = "Факел"
@export var light_radius: float = 8.0
@export var light_energy: float = 1.5
@export var flicker_intensity: float = 0.2
@export var fuel_time: float = 600.0
@export var is_lit: bool = true

var current_fuel: float
var base_energy: float
var light_node: OmniLight3D
var particles_node: GPUParticles3D
var flicker_timer: float = 0.0

func _ready():
	current_fuel = fuel_time
	add_to_group("interactables")
	add_to_group("props")
	add_to_group("light_sources")
	
	light_node = get_node_or_null("OmniLight3D")
	particles_node = get_node_or_null("FireParticles")
	
	if light_node:
		base_energy = light_node.light_energy
		light_node.omni_range = light_radius
	
	_update_lit_state()

func _process(delta):
	if not is_lit:
		return
	
	current_fuel -= delta
	if current_fuel <= 0:
		extinguish()
		return
	
	flicker_timer += delta
	if light_node:
		var flicker = sin(flicker_timer * 15.0) * flicker_intensity
		flicker += sin(flicker_timer * 7.3) * flicker_intensity * 0.5
		light_node.light_energy = base_energy + flicker

func interact(player) -> bool:
	if is_lit:
		extinguish()
	else:
		var inv = get_node_or_null("/root/Inventory")
		if inv and inv.has_method("has_item"):
			if inv.has_item("flint") or inv.has_item("matches"):
				light_torch()
				return true
			else:
				var notif = get_node_or_null("/root/NotificationSystem")
				if notif:
					notif.show_notification("Нужен огниво или спички", "warning")
				return false
		else:
			light_torch()
	return true

func light_torch():
	is_lit = true
	current_fuel = fuel_time
	_update_lit_state()
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sound"):
		audio.play_sound("fire_ignite", global_position)

func extinguish():
	is_lit = false
	_update_lit_state()
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sound"):
		audio.play_sound("fire_extinguish", global_position)

func _update_lit_state():
	if light_node:
		light_node.visible = is_lit
	if particles_node:
		particles_node.emitting = is_lit

func refuel(amount: float):
	current_fuel = min(current_fuel + amount, fuel_time)
	if not is_lit and current_fuel > 0:
		light_torch()

func get_display_name() -> String:
	if is_lit:
		return prop_name + " (Горит)"
	return prop_name + " (Потух)"

func get_interaction_hint() -> String:
	if is_lit:
		return "Нажмите E чтобы погасить"
	return "Нажмите E чтобы зажечь"

func save_data() -> Dictionary:
	return {
		"is_lit": is_lit,
		"current_fuel": current_fuel,
		"position": global_position
	}

func load_data(data: Dictionary):
	if data.has("is_lit"):
		is_lit = data.is_lit
	if data.has("current_fuel"):
		current_fuel = data.current_fuel
	_update_lit_state()
