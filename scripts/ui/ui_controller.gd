
extends CanvasLayer
class_name UIController

var inventory_ui
var stats_ui
var map_ui
var journal_ui

func _ready():
    inventory_ui = $InventoryUI
    stats_ui = $StatsUI
    map_ui = $MapUI
    journal_ui = $JournalUI

func update_player_stats(hp, st, hu, th, temp):
    stats_ui.set_stats(hp, st, hu, th, temp)

func update_inventory(items):
    inventory_ui.set_items(items)

func add_journal_entry(t):
    journal_ui.add_entry(t)
