
extends Control
class_name StatsUI

func set_stats(health, stamina, hunger, thirst, temp):
    $HealthBar.value = health
    $StaminaBar.value = stamina
    $HungerBar.value = hunger
    $ThirstBar.value = thirst
    $TempLabel.text = str(temp) + "°C"
