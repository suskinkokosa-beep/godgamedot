extends Node

var temp_noise: FastNoiseLite
var moist_noise: FastNoiseLite

func setup(temp_noise_res: FastNoiseLite, moist_noise_res: FastNoiseLite):
    temp_noise = temp_noise_res
    moist_noise = moist_noise_res

func get_biome_at(pos: Vector3) -> String:
    if not temp_noise or not moist_noise:
        return "plains"
    var tx = pos.x * 0.01
    var tz = pos.z * 0.01
    var t = temp_noise.get_noise_2d(tx, tz)
    var m = moist_noise.get_noise_2d(tx, tz)
    t = (t + 1.0) * 0.5
    m = (m + 1.0) * 0.5
    if t < 0.25:
        if m < 0.3: return "tundra"
        return "taiga"
    elif t < 0.45:
        if m < 0.3: return "grassland"
        return "forest"
    elif t < 0.7:
        if m < 0.2: return "savanna"
        if m < 0.5: return "plains"
        return "forest"
    else:
        if m < 0.2: return "desert"
        return "seasonal_forest"
