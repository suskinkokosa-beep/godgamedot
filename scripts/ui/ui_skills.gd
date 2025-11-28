\
extends WindowDialog

onready var grid = $VBox/SkillsGrid

func _ready():
    visible = false
    if has_node("/root/PlayerProgression"):
        get_node("/root/PlayerProgression").connect("player_updated", Callable(self, "_on_player_updated"))

func _on_player_updated(net_id, _=null):
    # display first player's skills for alpha
    var pp = get_node_or_null("/root/PlayerProgression")
    if not pp:
        return
    var p = pp.get_player(net_id)
    if not p: return
    grid.clear()
    for k in p.skills.keys():
        var h = HBoxContainer.new()
        var lbl = Label.new()
        lbl.text = str(k).capitalize()
        var val = Label.new()
        val.text = str(p.skills[k])
        h.add_child(lbl)
        h.add_child(val)
        grid.add_child(h)

func open_for(net_id:int):
    _on_player_updated(net_id)
    popup_centered()
