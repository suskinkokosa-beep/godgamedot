extends Node

signal model_loaded(model_id: String, node: Node3D)
signal model_load_failed(model_id: String, error: String)

var loaded_models := {}
var model_cache := {}

const FANTASY_PROPS_PATH = "res://assets/art_pack2/Fantasy Props MegaKit/Exports/glTF/"
const MEDIEVAL_VILLAGE_PATH = "res://assets/art_pack2/Medieval Village MegaKit[Standard]/glTF/"
const NATURE_PATH = "res://assets/art_pack2/Stylized Nature MEGAKIT/glTF/"
const CHARACTERS_PATH = "res://assets/art_pack2/Characters/"
const ART_PACK_PATH = "res://assets/art_pack/"

var character_models := {
        "idle_human": {
                "path": "res://assets/art_pack2/Characters/Idle.glb",
                "type": "character",
                "scale": Vector3(1.0, 1.0, 1.0),
                "offset": Vector3(0, 0, 0)
        },
        "idle_character": {
                "path": "res://attached_assets/characters3d.com - Idle_1764447738501.glb",
                "type": "character",
                "scale": Vector3(1.0, 1.0, 1.0),
                "offset": Vector3(0, 0, 0)
        },
        "superhero_female": {
                "path": CHARACTERS_PATH + "Base Characters/Godot/Superhero_Female.gltf",
                "type": "character",
                "scale": Vector3(1.0, 1.0, 1.0),
                "offset": Vector3(0, 0, 0)
        },
        "superhero_male": {
                "path": CHARACTERS_PATH + "Base Characters/Godot/Superhero_Male.gltf",
                "type": "character",
                "scale": Vector3(1.0, 1.0, 1.0),
                "offset": Vector3(0, 0, 0)
        }
}

var hairstyle_models := {
        "hair_beard": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Hair_Beard.gltf", "type": "hairstyle"},
        "hair_buns": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Hair_Buns.gltf", "type": "hairstyle"},
        "hair_buzzed": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Hair_Buzzed.gltf", "type": "hairstyle"},
        "hair_buzzed_female": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Hair_BuzzedFemale.gltf", "type": "hairstyle"},
        "hair_long": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Hair_Long.gltf", "type": "hairstyle"},
        "hair_simple_parted": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Hair_SimpleParted.gltf", "type": "hairstyle"},
        "eyebrows_female": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Eyebrows_Female.gltf", "type": "hairstyle"},
        "eyebrows_regular": {"path": CHARACTERS_PATH + "Hairstyles/Origin at 0/glTF (Godot)/Eyebrows_Regular.gltf", "type": "hairstyle"}
}

var prop_models := {
        "anvil": {"path": FANTASY_PROPS_PATH + "Anvil.gltf", "type": "prop", "category": "crafting"},
        "anvil_log": {"path": FANTASY_PROPS_PATH + "Anvil_Log.gltf", "type": "prop", "category": "crafting"},
        "axe_bronze": {"path": FANTASY_PROPS_PATH + "Axe_Bronze.gltf", "type": "prop", "category": "weapon"},
        "pickaxe_bronze": {"path": FANTASY_PROPS_PATH + "Pickaxe_Bronze.gltf", "type": "prop", "category": "tool"},
        "bag": {"path": FANTASY_PROPS_PATH + "Bag.gltf", "type": "prop", "category": "container"},
        "barrel": {"path": FANTASY_PROPS_PATH + "Barrel.gltf", "type": "prop", "category": "container"},
        "barrel_apples": {"path": FANTASY_PROPS_PATH + "Barrel_Apples.gltf", "type": "prop", "category": "food"},
        "barrel_holder": {"path": FANTASY_PROPS_PATH + "Barrel_Holder.gltf", "type": "prop", "category": "furniture"},
        "bed_twin1": {"path": FANTASY_PROPS_PATH + "Bed_Twin1.gltf", "type": "prop", "category": "furniture"},
        "bed_twin2": {"path": FANTASY_PROPS_PATH + "Bed_Twin2.gltf", "type": "prop", "category": "furniture"},
        "bench": {"path": FANTASY_PROPS_PATH + "Bench.gltf", "type": "prop", "category": "furniture"},
        "book_5": {"path": FANTASY_PROPS_PATH + "Book_5.gltf", "type": "prop", "category": "decoration"},
        "book_7": {"path": FANTASY_PROPS_PATH + "Book_7.gltf", "type": "prop", "category": "decoration"},
        "book_single": {"path": FANTASY_PROPS_PATH + "Book_Simplified_Single.gltf", "type": "prop", "category": "decoration"},
        "book_stack_1": {"path": FANTASY_PROPS_PATH + "Book_Stack_1.gltf", "type": "prop", "category": "decoration"},
        "book_stack_2": {"path": FANTASY_PROPS_PATH + "Book_Stack_2.gltf", "type": "prop", "category": "decoration"},
        "bookcase": {"path": FANTASY_PROPS_PATH + "Bookcase_2.gltf", "type": "prop", "category": "furniture"},
        "bookstand": {"path": FANTASY_PROPS_PATH + "BookStand.gltf", "type": "prop", "category": "furniture"},
        "bottle": {"path": FANTASY_PROPS_PATH + "Bottle_1.gltf", "type": "prop", "category": "item"},
        "bucket_metal": {"path": FANTASY_PROPS_PATH + "Bucket_Metal.gltf", "type": "prop", "category": "container"},
        "bucket_wooden": {"path": FANTASY_PROPS_PATH + "Bucket_Wooden_1.gltf", "type": "prop", "category": "container"},
        "cabinet": {"path": FANTASY_PROPS_PATH + "Cabinet.gltf", "type": "prop", "category": "furniture"},
        "cage_small": {"path": FANTASY_PROPS_PATH + "Cage_Small.gltf", "type": "prop", "category": "container"},
        "candle_1": {"path": FANTASY_PROPS_PATH + "Candle_1.gltf", "type": "prop", "category": "light"},
        "candle_2": {"path": FANTASY_PROPS_PATH + "Candle_2.gltf", "type": "prop", "category": "light"},
        "candlestick": {"path": FANTASY_PROPS_PATH + "CandleStick.gltf", "type": "prop", "category": "light"},
        "candlestick_stand": {"path": FANTASY_PROPS_PATH + "CandleStick_Stand.gltf", "type": "prop", "category": "light"},
        "candlestick_triple": {"path": FANTASY_PROPS_PATH + "CandleStick_Triple.gltf", "type": "prop", "category": "light"},
        "carrot": {"path": FANTASY_PROPS_PATH + "Carrot.gltf", "type": "prop", "category": "food"},
        "cauldron": {"path": FANTASY_PROPS_PATH + "Cauldron.gltf", "type": "prop", "category": "crafting"},
        "chain_coil": {"path": FANTASY_PROPS_PATH + "Chain_Coil.gltf", "type": "prop", "category": "item"},
        "chair": {"path": FANTASY_PROPS_PATH + "Chair_1.gltf", "type": "prop", "category": "furniture"},
        "chalice": {"path": FANTASY_PROPS_PATH + "Chalice.gltf", "type": "prop", "category": "treasure"},
        "chandelier": {"path": FANTASY_PROPS_PATH + "Chandelier.gltf", "type": "prop", "category": "light"},
        "chest_wood": {"path": FANTASY_PROPS_PATH + "Chest_Wood.gltf", "type": "prop", "category": "container"},
        "coin": {"path": FANTASY_PROPS_PATH + "Coin.gltf", "type": "prop", "category": "treasure"},
        "coin_pile": {"path": FANTASY_PROPS_PATH + "Coin_Pile.gltf", "type": "prop", "category": "treasure"},
        "coin_pile_2": {"path": FANTASY_PROPS_PATH + "Coin_Pile_2.gltf", "type": "prop", "category": "treasure"},
        "crate_metal": {"path": FANTASY_PROPS_PATH + "Crate_Metal.gltf", "type": "prop", "category": "container"},
        "crate_wooden": {"path": FANTASY_PROPS_PATH + "Crate_Wooden.gltf", "type": "prop", "category": "container"},
        "dummy": {"path": FANTASY_PROPS_PATH + "Dummy.gltf", "type": "prop", "category": "training"},
        "farm_crate_apple": {"path": FANTASY_PROPS_PATH + "FarmCrate_Apple.gltf", "type": "prop", "category": "food"},
        "farm_crate_carrot": {"path": FANTASY_PROPS_PATH + "FarmCrate_Carrot.gltf", "type": "prop", "category": "food"},
        "farm_crate_empty": {"path": FANTASY_PROPS_PATH + "FarmCrate_Empty.gltf", "type": "prop", "category": "container"},
        "key_gold": {"path": FANTASY_PROPS_PATH + "Key_Gold.gltf", "type": "prop", "category": "treasure"},
        "key_metal": {"path": FANTASY_PROPS_PATH + "Key_Metal.gltf", "type": "prop", "category": "item"},
        "lantern_wall": {"path": FANTASY_PROPS_PATH + "Lantern_Wall.gltf", "type": "prop", "category": "light"},
        "mug": {"path": FANTASY_PROPS_PATH + "Mug.gltf", "type": "prop", "category": "item"},
        "nightstand": {"path": FANTASY_PROPS_PATH + "Nightstand_Shelf.gltf", "type": "prop", "category": "furniture"},
        "peg_rack": {"path": FANTASY_PROPS_PATH + "Peg_Rack.gltf", "type": "prop", "category": "furniture"},
        "pot": {"path": FANTASY_PROPS_PATH + "Pot_1.gltf", "type": "prop", "category": "crafting"},
        "pot_lid": {"path": FANTASY_PROPS_PATH + "Pot_1_Lid.gltf", "type": "prop", "category": "crafting"},
        "banner_1": {"path": FANTASY_PROPS_PATH + "Banner_1.gltf", "type": "prop", "category": "decoration"},
        "banner_2": {"path": FANTASY_PROPS_PATH + "Banner_2.gltf", "type": "prop", "category": "decoration"}
}

var building_models := {
        "balcony_cross_corner": {"path": MEDIEVAL_VILLAGE_PATH + "Balcony_Cross_Corner.gltf", "type": "building", "category": "balcony"},
        "balcony_cross_straight": {"path": MEDIEVAL_VILLAGE_PATH + "Balcony_Cross_Straight.gltf", "type": "building", "category": "balcony"},
        "balcony_simple_corner": {"path": MEDIEVAL_VILLAGE_PATH + "Balcony_Simple_Corner.gltf", "type": "building", "category": "balcony"},
        "balcony_simple_straight": {"path": MEDIEVAL_VILLAGE_PATH + "Balcony_Simple_Straight.gltf", "type": "building", "category": "balcony"},
        "corner_exterior_brick": {"path": MEDIEVAL_VILLAGE_PATH + "Corner_Exterior_Brick.gltf", "type": "building", "category": "wall"},
        "corner_exterior_wood": {"path": MEDIEVAL_VILLAGE_PATH + "Corner_Exterior_Wood.gltf", "type": "building", "category": "wall"},
        "door_1_flat": {"path": MEDIEVAL_VILLAGE_PATH + "Door_1_Flat.gltf", "type": "building", "category": "door"},
        "door_1_round": {"path": MEDIEVAL_VILLAGE_PATH + "Door_1_Round.gltf", "type": "building", "category": "door"},
        "door_2_flat": {"path": MEDIEVAL_VILLAGE_PATH + "Door_2_Flat.gltf", "type": "building", "category": "door"},
        "door_2_round": {"path": MEDIEVAL_VILLAGE_PATH + "Door_2_Round.gltf", "type": "building", "category": "door"},
        "door_4_flat": {"path": MEDIEVAL_VILLAGE_PATH + "Door_4_Flat.gltf", "type": "building", "category": "door"},
        "door_4_round": {"path": MEDIEVAL_VILLAGE_PATH + "Door_4_Round.gltf", "type": "building", "category": "door"},
        "door_8_flat": {"path": MEDIEVAL_VILLAGE_PATH + "Door_8_Flat.gltf", "type": "building", "category": "door"},
        "door_8_round": {"path": MEDIEVAL_VILLAGE_PATH + "Door_8_Round.gltf", "type": "building", "category": "door"},
        "doorframe_flat_brick": {"path": MEDIEVAL_VILLAGE_PATH + "DoorFrame_Flat_Brick.gltf", "type": "building", "category": "door"},
        "doorframe_round_brick": {"path": MEDIEVAL_VILLAGE_PATH + "DoorFrame_Round_Brick.gltf", "type": "building", "category": "door"},
        "floor_brick": {"path": MEDIEVAL_VILLAGE_PATH + "Floor_Brick.gltf", "type": "building", "category": "floor"},
        "floor_redbrick": {"path": MEDIEVAL_VILLAGE_PATH + "Floor_RedBrick.gltf", "type": "building", "category": "floor"},
        "floor_wood_dark": {"path": MEDIEVAL_VILLAGE_PATH + "Floor_WoodDark.gltf", "type": "building", "category": "floor"},
        "floor_wood_light": {"path": MEDIEVAL_VILLAGE_PATH + "Floor_WoodLight.gltf", "type": "building", "category": "floor"},
        "chimney": {"path": MEDIEVAL_VILLAGE_PATH + "Prop_Chimney.gltf", "type": "building", "category": "roof"},
        "chimney_2": {"path": MEDIEVAL_VILLAGE_PATH + "Prop_Chimney2.gltf", "type": "building", "category": "roof"},
        "crate": {"path": MEDIEVAL_VILLAGE_PATH + "Prop_Crate.gltf", "type": "building", "category": "prop"},
        "metal_fence": {"path": MEDIEVAL_VILLAGE_PATH + "Prop_MetalFence_Simple.gltf", "type": "building", "category": "fence"},
        "overhang_plaster": {"path": MEDIEVAL_VILLAGE_PATH + "Overhang_Plaster_Long.gltf", "type": "building", "category": "roof"},
        "overhang_roof": {"path": MEDIEVAL_VILLAGE_PATH + "Overhang_Roof_Plaster.gltf", "type": "building", "category": "roof"}
}

var nature_models := {
        "bush_common": {"path": NATURE_PATH + "Bush_Common.gltf", "type": "nature", "category": "bush"},
        "bush_flowers": {"path": NATURE_PATH + "Bush_Common_Flowers.gltf", "type": "nature", "category": "bush"},
        "clover_1": {"path": NATURE_PATH + "Clover_1.gltf", "type": "nature", "category": "plant"},
        "clover_2": {"path": NATURE_PATH + "Clover_2.gltf", "type": "nature", "category": "plant"},
        "common_tree_1": {"path": NATURE_PATH + "CommonTree_1.gltf", "type": "nature", "category": "tree"},
        "common_tree_2": {"path": NATURE_PATH + "CommonTree_2.gltf", "type": "nature", "category": "tree"},
        "common_tree_3": {"path": NATURE_PATH + "CommonTree_3.gltf", "type": "nature", "category": "tree"},
        "common_tree_4": {"path": NATURE_PATH + "CommonTree_4.gltf", "type": "nature", "category": "tree"},
        "common_tree_5": {"path": NATURE_PATH + "CommonTree_5.gltf", "type": "nature", "category": "tree"},
        "dead_tree_1": {"path": NATURE_PATH + "DeadTree_1.gltf", "type": "nature", "category": "tree"},
        "dead_tree_2": {"path": NATURE_PATH + "DeadTree_2.gltf", "type": "nature", "category": "tree"},
        "dead_tree_3": {"path": NATURE_PATH + "DeadTree_3.gltf", "type": "nature", "category": "tree"},
        "dead_tree_4": {"path": NATURE_PATH + "DeadTree_4.gltf", "type": "nature", "category": "tree"},
        "dead_tree_5": {"path": NATURE_PATH + "DeadTree_5.gltf", "type": "nature", "category": "tree"},
        "fern": {"path": NATURE_PATH + "Fern_1.gltf", "type": "nature", "category": "plant"},
        "flower_3_group": {"path": NATURE_PATH + "Flower_3_Group.gltf", "type": "nature", "category": "flower"},
        "flower_3_single": {"path": NATURE_PATH + "Flower_3_Single.gltf", "type": "nature", "category": "flower"},
        "flower_4_group": {"path": NATURE_PATH + "Flower_4_Group.gltf", "type": "nature", "category": "flower"},
        "flower_4_single": {"path": NATURE_PATH + "Flower_4_Single.gltf", "type": "nature", "category": "flower"},
        "grass_short": {"path": NATURE_PATH + "Grass_Common_Short.gltf", "type": "nature", "category": "grass"},
        "grass_tall": {"path": NATURE_PATH + "Grass_Common_Tall.gltf", "type": "nature", "category": "grass"},
        "grass_wispy_short": {"path": NATURE_PATH + "Grass_Wispy_Short.gltf", "type": "nature", "category": "grass"},
        "grass_wispy_tall": {"path": NATURE_PATH + "Grass_Wispy_Tall.gltf", "type": "nature", "category": "grass"},
        "mushroom_common": {"path": NATURE_PATH + "Mushroom_Common.gltf", "type": "nature", "category": "mushroom"},
        "mushroom_laetiporus": {"path": NATURE_PATH + "Mushroom_Laetiporus.gltf", "type": "nature", "category": "mushroom"},
        "pebble_round_1": {"path": NATURE_PATH + "Pebble_Round_1.gltf", "type": "nature", "category": "rock"},
        "pebble_round_2": {"path": NATURE_PATH + "Pebble_Round_2.gltf", "type": "nature", "category": "rock"},
        "pebble_round_3": {"path": NATURE_PATH + "Pebble_Round_3.gltf", "type": "nature", "category": "rock"},
        "rock_medium_1": {"path": NATURE_PATH + "Rock_Medium_1.gltf", "type": "nature", "category": "rock"},
        "rock_medium_2": {"path": NATURE_PATH + "Rock_Medium_2.gltf", "type": "nature", "category": "rock"},
        "rock_medium_3": {"path": NATURE_PATH + "Rock_Medium_3.gltf", "type": "nature", "category": "rock"},
        "pine_1": {"path": NATURE_PATH + "Pine_1.gltf", "type": "nature", "category": "tree"},
        "pine_2": {"path": NATURE_PATH + "Pine_2.gltf", "type": "nature", "category": "tree"},
        "pine_3": {"path": NATURE_PATH + "Pine_3.gltf", "type": "nature", "category": "tree"},
        "pine_4": {"path": NATURE_PATH + "Pine_4.gltf", "type": "nature", "category": "tree"},
        "pine_5": {"path": NATURE_PATH + "Pine_5.gltf", "type": "nature", "category": "tree"},
        "plant_1": {"path": NATURE_PATH + "Plant_1.gltf", "type": "nature", "category": "plant"},
        "plant_1_big": {"path": NATURE_PATH + "Plant_1_Big.gltf", "type": "nature", "category": "plant"},
        "plant_7": {"path": NATURE_PATH + "Plant_7.gltf", "type": "nature", "category": "plant"},
        "plant_7_big": {"path": NATURE_PATH + "Plant_7_Big.gltf", "type": "nature", "category": "plant"},
        "twisted_tree_1": {"path": NATURE_PATH + "TwistedTree_1.gltf", "type": "nature", "category": "tree"},
        "twisted_tree_2": {"path": NATURE_PATH + "TwistedTree_2.gltf", "type": "nature", "category": "tree"},
        "twisted_tree_3": {"path": NATURE_PATH + "TwistedTree_3.gltf", "type": "nature", "category": "tree"},
        "twisted_tree_4": {"path": NATURE_PATH + "TwistedTree_4.gltf", "type": "nature", "category": "tree"},
        "twisted_tree_5": {"path": NATURE_PATH + "TwistedTree_5.gltf", "type": "nature", "category": "tree"},
        "rockpath_round_wide": {"path": NATURE_PATH + "RockPath_Round_Wide.gltf", "type": "nature", "category": "path"},
        "rockpath_square_wide": {"path": NATURE_PATH + "RockPath_Square_Wide.gltf", "type": "nature", "category": "path"}
}

var creature_models := {
        "bear": {"path": ART_PACK_PATH + "models/animals/bear.obj", "type": "creature", "category": "predator", "scale": Vector3(1.0, 1.0, 1.0)},
        "boar": {"path": ART_PACK_PATH + "models/animals/boar.obj", "type": "creature", "category": "prey", "scale": Vector3(1.0, 1.0, 1.0)},
        "wolf": {"path": ART_PACK_PATH + "models/animals/wolf.obj", "type": "creature", "category": "predator", "scale": Vector3(1.0, 1.0, 1.0)}
}

var weapon_models := {
        "axe": {"path": ART_PACK_PATH + "weapons/axe.obj", "type": "weapon", "category": "melee"},
        "sword": {"path": ART_PACK_PATH + "weapons/sword.obj", "type": "weapon", "category": "melee"},
        "bow": {"path": ART_PACK_PATH + "weapons/bow.obj", "type": "weapon", "category": "ranged"},
        "knife": {"path": ART_PACK_PATH + "weapons/knife.obj", "type": "weapon", "category": "melee"},
        "pickaxe": {"path": ART_PACK_PATH + "weapons/pickaxe.obj", "type": "weapon", "category": "tool"}
}

var structure_models := {
        "column": {"path": ART_PACK_PATH + "structures/column.obj", "type": "structure", "category": "support"},
        "door": {"path": ART_PACK_PATH + "structures/door.obj", "type": "structure", "category": "door"},
        "foundation": {"path": ART_PACK_PATH + "structures/foundation.obj", "type": "structure", "category": "base"},
        "wall_segment": {"path": ART_PACK_PATH + "structures/wall_segment.obj", "type": "structure", "category": "wall"},
        "window": {"path": ART_PACK_PATH + "structures/window.obj", "type": "structure", "category": "wall"}
}

func _ready():
        print("[ModelLoader] Initialized with ", get_total_model_count(), " models")

func get_total_model_count() -> int:
        return character_models.size() + hairstyle_models.size() + prop_models.size() + building_models.size() + nature_models.size() + creature_models.size() + weapon_models.size() + structure_models.size()

func load_model(model_id: String, model_type: String = "character") -> Node3D:
        var model_dict := _get_model_dict(model_type)
        
        if not model_dict.has(model_id):
                emit_signal("model_load_failed", model_id, "Model not found: " + model_id)
                return null
        
        var model_data = model_dict[model_id]
        var path = model_data.path
        
        if model_cache.has(path):
                var cached = model_cache[path]
                if cached:
                        var instance = _create_instance_from_resource(cached)
                        if instance:
                                _apply_model_settings(instance, model_data)
                                emit_signal("model_loaded", model_id, instance)
                                return instance
        
        var resource = load(path)
        if not resource:
                emit_signal("model_load_failed", model_id, "Failed to load: " + path)
                return null
        
        model_cache[path] = resource
        
        var instance = _create_instance_from_resource(resource)
        
        if not instance:
                emit_signal("model_load_failed", model_id, "Failed to instantiate: " + path)
                return null
        
        _apply_model_settings(instance, model_data)
        emit_signal("model_loaded", model_id, instance)
        return instance

func _create_instance_from_resource(resource) -> Node3D:
        if resource is PackedScene:
                return resource.instantiate()
        elif resource is Mesh:
                var mesh_instance = MeshInstance3D.new()
                mesh_instance.mesh = resource
                return mesh_instance
        elif resource is ArrayMesh:
                var mesh_instance = MeshInstance3D.new()
                mesh_instance.mesh = resource
                return mesh_instance
        elif resource is Node3D:
                return resource.duplicate()
        return null

func _get_model_dict(model_type: String) -> Dictionary:
        match model_type:
                "character": return character_models
                "hairstyle": return hairstyle_models
                "prop": return prop_models
                "building": return building_models
                "nature": return nature_models
                "creature": return creature_models
                "weapon": return weapon_models
                "structure": return structure_models
                _: return character_models

func _apply_model_settings(node: Node3D, settings: Dictionary):
        if settings.has("scale"):
                node.scale = settings.scale
        if settings.has("offset"):
                node.position = settings.offset
        if settings.has("rotation"):
                node.rotation_degrees = settings.rotation

func get_available_characters() -> Array:
        return character_models.keys()

func get_available_props() -> Array:
        return prop_models.keys()

func get_available_buildings() -> Array:
        return building_models.keys()

func get_available_creatures() -> Array:
        return creature_models.keys()

func get_available_hairstyles() -> Array:
        return hairstyle_models.keys()

func get_available_nature() -> Array:
        return nature_models.keys()

func get_available_weapons() -> Array:
        return weapon_models.keys()

func get_available_structures() -> Array:
        return structure_models.keys()

func get_props_by_category(category: String) -> Array:
        var result := []
        for key in prop_models:
                if prop_models[key].get("category", "") == category:
                        result.append(key)
        return result

func get_nature_by_category(category: String) -> Array:
        var result := []
        for key in nature_models:
                if nature_models[key].get("category", "") == category:
                        result.append(key)
        return result

func get_buildings_by_category(category: String) -> Array:
        var result := []
        for key in building_models:
                if building_models[key].get("category", "") == category:
                        result.append(key)
        return result

func load_hairstyle(hairstyle_id: String) -> Node3D:
        return load_model(hairstyle_id, "hairstyle")

func create_full_character(base_id: String, hairstyle_id: String = "", gender: String = "male") -> Node3D:
        var character = load_model(base_id, "character")
        if not character:
                return null
        
        if not hairstyle_id.is_empty():
                var hairstyle = load_hairstyle(hairstyle_id)
                if hairstyle:
                        var head_bone = _find_head_bone(character)
                        if head_bone:
                                head_bone.add_child(hairstyle)
                        else:
                                character.add_child(hairstyle)
        
        return character

func _find_head_bone(node: Node) -> Node3D:
        if node is Skeleton3D:
                var skeleton = node as Skeleton3D
                var head_idx = skeleton.find_bone("Head")
                if head_idx >= 0:
                        var bone_attach = BoneAttachment3D.new()
                        bone_attach.bone_name = "Head"
                        skeleton.add_child(bone_attach)
                        return bone_attach
        
        for child in node.get_children():
                var result = _find_head_bone(child)
                if result:
                        return result
        
        return null

func get_random_npc_appearance() -> Dictionary:
        var genders = ["male", "female"]
        var gender = genders[randi() % genders.size()]
        
        var base_model = "superhero_male" if gender == "male" else "superhero_female"
        
        var male_hairstyles = ["hair_beard", "hair_buzzed", "hair_simple_parted"]
        var female_hairstyles = ["hair_buns", "hair_buzzed_female", "hair_long"]
        
        var hairstyles = male_hairstyles if gender == "male" else female_hairstyles
        var hairstyle = hairstyles[randi() % hairstyles.size()]
        
        return {
                "gender": gender,
                "base_model": base_model,
                "hairstyle": hairstyle
        }

func get_random_tree() -> String:
        var trees = get_nature_by_category("tree")
        if trees.is_empty():
                return ""
        return trees[randi() % trees.size()]

func get_random_rock() -> String:
        var rocks = get_nature_by_category("rock")
        if rocks.is_empty():
                return ""
        return rocks[randi() % rocks.size()]

func get_random_plant() -> String:
        var plants = get_nature_by_category("plant")
        if plants.is_empty():
                return ""
        return plants[randi() % plants.size()]

func get_random_bush() -> String:
        var bushes = get_nature_by_category("bush")
        if bushes.is_empty():
                return ""
        return bushes[randi() % bushes.size()]

func get_random_furniture() -> String:
        var furniture = get_props_by_category("furniture")
        if furniture.is_empty():
                return ""
        return furniture[randi() % furniture.size()]

func get_random_container() -> String:
        var containers = get_props_by_category("container")
        if containers.is_empty():
                return ""
        return containers[randi() % containers.size()]

func get_model_info(model_id: String, model_type: String = "character") -> Dictionary:
        var model_dict := _get_model_dict(model_type)
        return model_dict.get(model_id, {})

func register_model(model_id: String, path: String, model_type: String, settings: Dictionary = {}):
        var model_data = {
                "path": path,
                "type": model_type,
                "scale": settings.get("scale", Vector3(1.0, 1.0, 1.0)),
                "offset": settings.get("offset", Vector3(0, 0, 0)),
                "rotation": settings.get("rotation", Vector3(0, 0, 0)),
                "category": settings.get("category", "")
        }
        
        var model_dict := _get_model_dict(model_type)
        model_dict[model_id] = model_data

func preload_models(model_ids: Array, model_type: String = "character"):
        for model_id in model_ids:
                load_model(model_id, model_type)

func clear_cache():
        model_cache.clear()

func get_all_categories(model_type: String) -> Array:
        var categories := {}
        var model_dict := _get_model_dict(model_type)
        
        for key in model_dict:
                var cat = model_dict[key].get("category", "")
                if not cat.is_empty():
                        categories[cat] = true
        
        return categories.keys()
