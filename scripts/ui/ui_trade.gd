extends WindowDialog

var trader = null
var player = null

func open_trade(t, p):
    trader = t
    player = p
    $Items.clear()
    for it in trader.inventory:
        var h = HBoxContainer.new()
        var lbl = Label.new()
        lbl.text = str(it.id) + " - " + str(it.price)
        var btn = Button.new()
        btn.text = "Buy"
        btn.pressed.connect(callable(self, "_on_buy_pressed"), [it])
        h.add_child(lbl)
        h.add_child(btn)
        $Items.add_child(h)
    popup_centered()

func _on_buy_pressed(item):
    var inv = get_node_or_null("/root/Inventory")
    if not inv: return
    # simple buy: remove coins from player (not implemented) and add item
    inv.add_item(item.id, 1, 1.0)
