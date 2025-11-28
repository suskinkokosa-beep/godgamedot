
extends Control
class_name JournalUI

var entries := []

func add_entry(text:String):
    entries.append(text)
    _refresh()

func _refresh():
    $Scroll/Label.text = ""
    for e in entries:
        $Scroll/Label.text += "- " + e + "\n"
