extends WindowDialog

onready var lbl_level = $VBox/LblLevel
onready var grid = $VBox/StatsGrid

func _ready():
    visible = false
    if has_node("/root/StatsSystem"):
        get_node("/root/StatsSystem").connect("stats_changed", Callable(self, "_on_stats_changed"))

func _on_stats_changed(player_id, stats):
    # for alpha, display first player's stats
    grid.clear()
    for k in stats.keys():
        var h = HBoxContainer.new()
        var l = Label.new()
        l.text = str(k).capitalize()
        var v = Label.new()
        v.text = str(stats[k])
        h.add_child(l)
        h.add_child(v)
        grid.add_child(h)

func open_for(player_id:int):
    # update and show
    var ss = get_node_or_null("/root/StatsSystem")
    if ss:
        var p = ss.get_stats(player_id)
        if p:
            lbl_level.text = "Level: %d" % p.level
            _on_stats_changed(player_id, p.stats)
    popup_centered()
