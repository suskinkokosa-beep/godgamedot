extends Node
class_name IdleAnimationController

signal idle_started()
signal idle_ended()

@export var idle_trigger_time: float = 5.0
@export var animation_player_path: NodePath

var idle_timer: float = 0.0
var is_idle: bool = false
var last_velocity: Vector3 = Vector3.ZERO
var parent: CharacterBody3D

var animation_player: AnimationPlayer
var idle_animations: Array = ["idle_breathe", "idle_look_around", "idle_stretch"]
var current_idle_animation: String = ""

func _ready():
	parent = get_parent() as CharacterBody3D
	
	if animation_player_path:
		animation_player = get_node_or_null(animation_player_path)
	
	if not animation_player and parent:
		animation_player = parent.get_node_or_null("AnimationPlayer")
		if not animation_player:
			animation_player = parent.get_node_or_null("Model/AnimationPlayer")

func _process(delta):
	if not parent:
		return
	
	var current_velocity = parent.velocity
	var is_moving = current_velocity.length() > 0.1
	
	if is_moving:
		_on_movement_detected()
	else:
		_update_idle_timer(delta)

func _update_idle_timer(delta):
	idle_timer += delta
	
	if idle_timer >= idle_trigger_time and not is_idle:
		_start_idle_animation()

func _on_movement_detected():
	idle_timer = 0.0
	
	if is_idle:
		_stop_idle_animation()

func _start_idle_animation():
	is_idle = true
	emit_signal("idle_started")
	
	if animation_player:
		_play_random_idle_animation()
	else:
		_apply_procedural_idle()

func _stop_idle_animation():
	is_idle = false
	emit_signal("idle_ended")
	
	if animation_player and current_idle_animation != "":
		animation_player.stop()
		current_idle_animation = ""

func _play_random_idle_animation():
	if animation_player.has_animation("Idle"):
		current_idle_animation = "Idle"
		animation_player.play("Idle")
		return
	
	var available_anims = []
	for anim_name in idle_animations:
		if animation_player.has_animation(anim_name):
			available_anims.append(anim_name)
	
	if available_anims.size() > 0:
		current_idle_animation = available_anims[randi() % available_anims.size()]
		animation_player.play(current_idle_animation)

func _apply_procedural_idle():
	if not parent:
		return
	
	var camera = parent.get_node_or_null("Camera3D")
	if camera:
		var tween = create_tween()
		tween.set_loops()
		
		var base_rotation = camera.rotation
		
		tween.tween_property(camera, "rotation:x", base_rotation.x + deg_to_rad(0.5), 2.0)
		tween.tween_property(camera, "rotation:x", base_rotation.x - deg_to_rad(0.5), 2.0)
		tween.tween_property(camera, "rotation:x", base_rotation.x, 1.0)
		
		await get_tree().create_timer(5.0).timeout
		
		if is_idle:
			_apply_procedural_idle()

func is_player_idle() -> bool:
	return is_idle

func get_idle_time() -> float:
	return idle_timer

func reset_idle_timer():
	idle_timer = 0.0
	if is_idle:
		_stop_idle_animation()

func set_idle_trigger_time(time: float):
	idle_trigger_time = max(1.0, time)
