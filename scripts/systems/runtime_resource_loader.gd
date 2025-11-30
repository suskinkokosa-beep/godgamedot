extends Node

signal resource_scan_complete(total_models: int, total_textures: int)
signal model_imported(model_id: String, success: bool)
signal texture_imported(texture_id: String, success: bool)

const ART_PACK2_PATH = "res://assets/art_pack2/"
const SCAN_PATHS := {
	"fantasy_props": "Fantasy Props MegaKit/Exports/glTF/",
	"medieval_village": "Medieval Village MegaKit[Standard]/glTF/",
	"stylized_nature": "Stylized Nature MEGAKIT/glTF/",
	"characters": "Characters/"
}

var gltf_document: GLTFDocument
var gltf_state: GLTFState

var runtime_models := {}
var runtime_textures := {}
var scan_complete := false

func _ready():
	gltf_document = GLTFDocument.new()
	gltf_state = GLTFState.new()
	call_deferred("_initialize_runtime_loading")

func _initialize_runtime_loading():
	print("[RuntimeResourceLoader] Инициализация системы автозагрузки ресурсов...")
	_scan_all_resources()
	print("[RuntimeResourceLoader] Готово! Найдено моделей: ", runtime_models.size(), ", текстур: ", runtime_textures.size())
	scan_complete = true
	emit_signal("resource_scan_complete", runtime_models.size(), runtime_textures.size())

func _scan_all_resources():
	for pack_name in SCAN_PATHS:
		var full_path = ART_PACK2_PATH + SCAN_PATHS[pack_name]
		_scan_directory(full_path, pack_name)

func _scan_directory(path: String, pack_name: String):
	var dir = DirAccess.open(path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			var full_path = path + file_name
			var extension = file_name.get_extension().to_lower()
			
			match extension:
				"gltf", "glb":
					_register_model(file_name, full_path, pack_name)
				"png", "jpg", "jpeg", "webp":
					_register_texture(file_name, full_path, pack_name)
		else:
			if not file_name.begins_with("."):
				_scan_directory(path + file_name + "/", pack_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _register_model(file_name: String, full_path: String, pack_name: String):
	var model_id = file_name.get_basename().to_snake_case()
	
	var category = "misc"
	var type = "prop"
	
	match pack_name:
		"fantasy_props":
			type = "prop"
			category = _categorize_prop(model_id)
		"medieval_village":
			type = "building"
			category = _categorize_building(model_id)
		"stylized_nature":
			type = "nature"
			category = _categorize_nature(model_id)
		"characters":
			type = "character"
			category = "character"
	
	runtime_models[model_id] = {
		"path": full_path,
		"file_name": file_name,
		"pack": pack_name,
		"type": type,
		"category": category,
		"cached_scene": null
	}

func _register_texture(file_name: String, full_path: String, pack_name: String):
	var texture_id = file_name.get_basename().to_snake_case()
	
	var tex_type = "base"
	if "_normal" in file_name.to_lower() or "_nor_" in file_name.to_lower():
		tex_type = "normal"
	elif "_rough" in file_name.to_lower():
		tex_type = "roughness"
	elif "_metal" in file_name.to_lower():
		tex_type = "metallic"
	elif "_alpha" in file_name.to_lower():
		tex_type = "alpha"
	elif "_orm" in file_name.to_lower():
		tex_type = "orm"
	elif "_diff" in file_name.to_lower() or "_basecolor" in file_name.to_lower():
		tex_type = "base"
	
	var base_id = texture_id.replace("_normal", "").replace("_rough", "").replace("_metal", "").replace("_alpha", "").replace("_orm", "").replace("_diff", "").replace("_basecolor", "")
	
	if not runtime_textures.has(base_id):
		runtime_textures[base_id] = {
			"pack": pack_name,
			"textures": {}
		}
	
	runtime_textures[base_id]["textures"][tex_type] = full_path

func _categorize_prop(model_id: String) -> String:
	if "anvil" in model_id or "cauldron" in model_id or "pot" in model_id:
		return "crafting"
	elif "barrel" in model_id or "bucket" in model_id or "crate" in model_id or "chest" in model_id:
		return "container"
	elif "bed" in model_id or "chair" in model_id or "table" in model_id or "bench" in model_id:
		return "furniture"
	elif "candle" in model_id or "lantern" in model_id or "torch" in model_id:
		return "light"
	elif "sword" in model_id or "axe" in model_id or "hammer" in model_id:
		return "weapon"
	elif "book" in model_id or "scroll" in model_id:
		return "decoration"
	elif "coin" in model_id or "key" in model_id or "chalice" in model_id:
		return "treasure"
	elif "food" in model_id or "carrot" in model_id or "apple" in model_id:
		return "food"
	else:
		return "misc"

func _categorize_building(model_id: String) -> String:
	if "wall" in model_id:
		return "wall"
	elif "door" in model_id:
		return "door"
	elif "window" in model_id:
		return "window"
	elif "floor" in model_id:
		return "floor"
	elif "roof" in model_id or "chimney" in model_id:
		return "roof"
	elif "stairs" in model_id:
		return "stairs"
	elif "balcony" in model_id or "overhang" in model_id:
		return "balcony"
	elif "fence" in model_id:
		return "fence"
	else:
		return "prop"

func _categorize_nature(model_id: String) -> String:
	if "tree" in model_id or "pine" in model_id:
		return "tree"
	elif "bush" in model_id:
		return "bush"
	elif "grass" in model_id:
		return "grass"
	elif "flower" in model_id or "petal" in model_id:
		return "flower"
	elif "rock" in model_id or "pebble" in model_id:
		return "rock"
	elif "mushroom" in model_id:
		return "mushroom"
	elif "fern" in model_id or "clover" in model_id or "plant" in model_id:
		return "plant"
	elif "path" in model_id:
		return "path"
	else:
		return "misc"

func load_model_runtime(model_id: String) -> Node3D:
	if not runtime_models.has(model_id):
		push_warning("[RuntimeResourceLoader] Модель не найдена: " + model_id)
		return _create_placeholder_model(model_id)
	
	var model_data = runtime_models[model_id]
	
	if model_data.cached_scene != null:
		return model_data.cached_scene.instantiate()
	
	var path = model_data.path
	
	var resource = load(path)
	if resource != null and resource is PackedScene:
		model_data.cached_scene = resource
		emit_signal("model_imported", model_id, true)
		return resource.instantiate()
	
	var node = _load_gltf_runtime(path)
	if node != null:
		emit_signal("model_imported", model_id, true)
		return node
	
	push_warning("[RuntimeResourceLoader] Не удалось загрузить модель: " + model_id)
	emit_signal("model_imported", model_id, false)
	return _create_placeholder_model(model_id)

func _load_gltf_runtime(path: String) -> Node3D:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	
	var gltf_doc = GLTFDocument.new()
	var gltf_st = GLTFState.new()
	
	var error: Error
	
	if path.ends_with(".glb"):
		var buffer = file.get_buffer(file.get_length())
		file.close()
		error = gltf_doc.append_from_buffer(buffer, "", gltf_st)
	else:
		file.close()
		error = gltf_doc.append_from_file(path, gltf_st)
	
	if error != OK:
		return null
	
	var scene = gltf_doc.generate_scene(gltf_st)
	return scene

func _create_placeholder_model(model_id: String) -> Node3D:
	var node = Node3D.new()
	node.name = model_id + "_placeholder"
	
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.3, 0.8, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	node.add_child(mesh_instance)
	
	return node

func load_texture_runtime(texture_id: String, texture_type: String = "base") -> Texture2D:
	if not runtime_textures.has(texture_id):
		return null
	
	var tex_data = runtime_textures[texture_id]
	if not tex_data.textures.has(texture_type):
		if tex_data.textures.has("base"):
			texture_type = "base"
		else:
			return null
	
	var path = tex_data.textures[texture_type]
	
	var texture = load(path) as Texture2D
	if texture != null:
		emit_signal("texture_imported", texture_id, true)
	else:
		emit_signal("texture_imported", texture_id, false)
	
	return texture

func create_material_runtime(texture_id: String) -> StandardMaterial3D:
	if not runtime_textures.has(texture_id):
		return null
	
	var tex_data = runtime_textures[texture_id]
	var textures = tex_data.textures
	
	var material = StandardMaterial3D.new()
	
	if textures.has("base"):
		var tex = load(textures.base) as Texture2D
		if tex:
			material.albedo_texture = tex
	
	if textures.has("normal"):
		var tex = load(textures.normal) as Texture2D
		if tex:
			material.normal_enabled = true
			material.normal_texture = tex
	
	if textures.has("roughness"):
		var tex = load(textures.roughness) as Texture2D
		if tex:
			material.roughness_texture = tex
	
	if textures.has("metallic"):
		var tex = load(textures.metallic) as Texture2D
		if tex:
			material.metallic_texture = tex
	
	if textures.has("alpha"):
		var tex = load(textures.alpha) as Texture2D
		if tex:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = 0.5
	
	if textures.has("orm"):
		var tex = load(textures.orm) as Texture2D
		if tex:
			material.ao_enabled = true
			material.ao_texture = tex
			material.roughness_texture = tex
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			material.metallic_texture = tex
			material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	
	return material

func get_models_by_type(type: String) -> Array:
	var result := []
	for model_id in runtime_models:
		if runtime_models[model_id].type == type:
			result.append(model_id)
	return result

func get_models_by_category(category: String) -> Array:
	var result := []
	for model_id in runtime_models:
		if runtime_models[model_id].category == category:
			result.append(model_id)
	return result

func get_all_model_ids() -> Array:
	return runtime_models.keys()

func get_all_texture_ids() -> Array:
	return runtime_textures.keys()

func has_model(model_id: String) -> bool:
	return runtime_models.has(model_id)

func has_texture(texture_id: String) -> bool:
	return runtime_textures.has(texture_id)

func get_model_info(model_id: String) -> Dictionary:
	if runtime_models.has(model_id):
		return runtime_models[model_id].duplicate()
	return {}

func get_texture_info(texture_id: String) -> Dictionary:
	if runtime_textures.has(texture_id):
		return runtime_textures[texture_id].duplicate()
	return {}

func print_available_resources():
	print("=== ДОСТУПНЫЕ МОДЕЛИ ===")
	var types := {}
	for model_id in runtime_models:
		var model = runtime_models[model_id]
		if not types.has(model.type):
			types[model.type] = []
		types[model.type].append(model_id)
	
	for type in types:
		print("  ", type.to_upper(), ": ", types[type].size(), " моделей")
	
	print("\n=== ДОСТУПНЫЕ ТЕКСТУРЫ ===")
	print("  Всего: ", runtime_textures.size(), " наборов текстур")
