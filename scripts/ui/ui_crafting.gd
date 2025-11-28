extends Control

onready var recipe_list = $RecipeList
onready var req_panel = $ReqPanel
onready var craft_btn = $CraftBtn

var recipes := {
    "axe": {"wood":3, "stone":1, "produces":"axe"},
    "pickaxe": {"wood":2, "stone":2, "produces":"pickaxe"},
    "campfire": {"wood":5, "stone":3, "produces":"campfire", "spawn_scene":"res://scenes/buildings/foundation.tscn"}
}

func _ready():
    for r in recipes.keys():
        recipe_list.add_item(r)
    recipe_list.connect("item_selected", Callable(self, "_on_recipe_selected"))
    craft_btn.connect("pressed", Callable(self, "_on_craft_pressed"))

func _on_recipe_selected(index):
    var name = recipe_list.get_item_text(index)
    var reqs = recipes[name]
    req_panel.clear()
    for k in reqs.keys():
        if k == "produces" or k == "spawn_scene": continue
        var l = Label.new()
        l.text = str(k) + ": " + str(reqs[k])
        req_panel.add_child(l)

func _on_craft_pressed():
    var selected = recipe_list.get_selected_items()
    if selected.size() == 0: return
    var name = recipe_list.get_item_text(selected[0])
    var reqs = recipes[name]
    var net = get_node_or_null("/root/Network")
    var inv = get_node_or_null("/root/Inventory")
    if not inv:
        print("No inventory available")
        return
    # check materials locally first
    for k in reqs.keys():
        if k == "produces" or k == "spawn_scene": continue
        var needed = reqs[k]
        var found = false
        for it in inv.get_items():
            if it.id == k and it.count >= needed:
                found = true
                break
        if not found:
            print("Missing: ", k)
            return
    # Request server to perform craft / item creation
    if net:
        # remove materials on server
        for k in reqs.keys():
            if k == "produces" or k == "spawn_scene": continue
            rpc_id(1, "rpc_request_inventory_update", "remove", k, reqs[k])
        # If crafting creates an item
        if reqs.has("produces"):
            var prod = reqs["produces"]
            rpc_id(1, "rpc_request_inventory_update", "add", prod, 1)
        # If crafting spawns a building, request spawn (place near player)
        if reqs.has("spawn_scene"):
            var scene_path = reqs["spawn_scene"]
            var player = get_tree().get_nodes_in_group("players")[0] if get_tree().get_nodes_in_group("players").size() > 0 else null
            if player and player.has_node("Camera3D"):
                var from = player.get_node("Camera3D").global_transform.origin
                var to = from + -player.get_node("Camera3D").global_transform.basis.z * 3.0
                var tf = Transform3D(player.global_transform.basis, to)
                rpc_id(1, "rpc_request_spawn", scene_path, tf)
    else:
        # Local craft fallback
        for k in reqs.keys():
            if k == "produces" or k == "spawn_scene": continue
            inv.remove_item(k, reqs[k])
        if reqs.has("produces"):
            inv.add_item(reqs["produces"], 1, 2.0)
        if reqs.has("spawn_scene"):
            var s = ResourceLoader.load(reqs["spawn_scene"])
            if s:
                var inst = s.instantiate()
                get_tree().get_root().get_node("/root/World").add_child(inst)
                inst.global_transform.origin = player.global_transform.origin + Vector3(0,0,3)
