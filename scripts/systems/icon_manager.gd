extends Node

var icon_atlas: Texture2D
var icon_regions := {}
var fallback_icons := {}

const ICON_SIZE := 32

func _ready():
	_create_procedural_icons()

func _create_procedural_icons():
	var categories := {
		"wood": Color(0.55, 0.35, 0.2),
		"stone": Color(0.5, 0.5, 0.5),
		"metal": Color(0.7, 0.7, 0.75),
		"gold": Color(0.9, 0.75, 0.2),
		"food": Color(0.8, 0.3, 0.2),
		"potion": Color(0.3, 0.6, 0.9),
		"tool": Color(0.6, 0.5, 0.4),
		"weapon": Color(0.55, 0.55, 0.6),
		"armor": Color(0.5, 0.45, 0.4),
		"misc": Color(0.6, 0.6, 0.5)
	}
	
	for cat in categories.keys():
		fallback_icons[cat] = _create_icon_texture(categories[cat], cat)

func _create_icon_texture(base_color: Color, category: String) -> ImageTexture:
	var img = Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	
	for y in range(ICON_SIZE):
		for x in range(ICON_SIZE):
			var dist = Vector2(x - ICON_SIZE/2, y - ICON_SIZE/2).length()
			if dist < ICON_SIZE/2 - 2:
				var shade = 1.0 - (dist / (ICON_SIZE/2)) * 0.3
				var c = base_color * shade
				c.a = 1.0
				img.set_pixel(x, y, c)
			elif dist < ICON_SIZE/2:
				img.set_pixel(x, y, base_color.darkened(0.3))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	match category:
		"wood":
			_draw_wood_pattern(img)
		"stone":
			_draw_stone_pattern(img)
		"metal":
			_draw_metal_pattern(img)
		"food":
			_draw_food_pattern(img)
		"potion":
			_draw_potion_pattern(img)
		"tool":
			_draw_tool_pattern(img)
		"weapon":
			_draw_weapon_pattern(img)
	
	var tex = ImageTexture.create_from_image(img)
	return tex

func _draw_wood_pattern(img: Image):
	for i in range(3):
		var y = 8 + i * 6
		for x in range(6, ICON_SIZE - 6):
			if img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, Color(0.4, 0.25, 0.15))

func _draw_stone_pattern(img: Image):
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(5):
		var x = rng.randi_range(8, ICON_SIZE - 8)
		var y = rng.randi_range(8, ICON_SIZE - 8)
		if img.get_pixel(x, y).a > 0:
			img.set_pixel(x, y, Color(0.6, 0.6, 0.6))
			img.set_pixel(x+1, y, Color(0.6, 0.6, 0.6))

func _draw_metal_pattern(img: Image):
	for y in range(10, 22):
		for x in range(14, 18):
			if img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, Color(0.85, 0.85, 0.9))

func _draw_food_pattern(img: Image):
	for y in range(12, 20):
		for x in range(12, 20):
			if img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, Color(0.9, 0.4, 0.3))

func _draw_potion_pattern(img: Image):
	for y in range(8, 14):
		for x in range(13, 19):
			if img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, Color(0.7, 0.7, 0.8))
	for y in range(14, 26):
		for x in range(10, 22):
			var dist = Vector2(x - 16, y - 20).length()
			if dist < 6 and img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, Color(0.2, 0.5, 0.9, 0.9))

func _draw_tool_pattern(img: Image):
	for y in range(6, 26):
		var x = 15 + int((y - 16) * 0.2)
		if x >= 0 and x < ICON_SIZE and img.get_pixel(x, y).a > 0:
			img.set_pixel(x, y, Color(0.45, 0.3, 0.2))

func _draw_weapon_pattern(img: Image):
	for y in range(4, 28):
		var x = 16
		if img.get_pixel(x, y).a > 0:
			img.set_pixel(x, y, Color(0.7, 0.7, 0.75))

func get_icon_for_item(item_id: String) -> Texture2D:
	var category = _get_item_category(item_id)
	if fallback_icons.has(category):
		return fallback_icons[category]
	return fallback_icons.get("misc", null)

func _get_item_category(item_id: String) -> String:
	if item_id.contains("wood") or item_id.contains("log") or item_id.contains("stick") or item_id.contains("plank"):
		return "wood"
	elif item_id.contains("stone") or item_id.contains("rock") or item_id.contains("flint"):
		return "stone"
	elif item_id.contains("iron") or item_id.contains("copper") or item_id.contains("steel") or item_id.contains("metal") or item_id.contains("ingot"):
		return "metal"
	elif item_id.contains("gold") or item_id.contains("silver") or item_id.contains("coin"):
		return "gold"
	elif item_id.contains("apple") or item_id.contains("berry") or item_id.contains("meat") or item_id.contains("bread") or item_id.contains("fish") or item_id.contains("food"):
		return "food"
	elif item_id.contains("potion") or item_id.contains("water") or item_id.contains("drink"):
		return "potion"
	elif item_id.contains("axe") or item_id.contains("pick") or item_id.contains("shovel") or item_id.contains("hammer") or item_id.contains("tool"):
		return "tool"
	elif item_id.contains("sword") or item_id.contains("bow") or item_id.contains("spear") or item_id.contains("knife") or item_id.contains("weapon"):
		return "weapon"
	elif item_id.contains("armor") or item_id.contains("helmet") or item_id.contains("boots") or item_id.contains("gloves") or item_id.contains("shield"):
		return "armor"
	else:
		return "misc"

func get_item_color(item_id: String) -> Color:
	var category = _get_item_category(item_id)
	match category:
		"wood": return Color(0.7, 0.5, 0.3)
		"stone": return Color(0.6, 0.6, 0.6)
		"metal": return Color(0.75, 0.75, 0.8)
		"gold": return Color(1.0, 0.85, 0.3)
		"food": return Color(0.9, 0.5, 0.4)
		"potion": return Color(0.4, 0.7, 1.0)
		"tool": return Color(0.65, 0.55, 0.45)
		"weapon": return Color(0.6, 0.6, 0.65)
		"armor": return Color(0.55, 0.5, 0.45)
		_: return Color(0.7, 0.7, 0.65)
