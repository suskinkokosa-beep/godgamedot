extends Node
class_name BiomeMap

var temp_noise:OpenSimplexNoise
var moist_noise:OpenSimplexNoise

func setup(temp_noise_res:OpenSimplexNoise, moist_noise_res:OpenSimplexNoise):
    temp_noise = temp_noise_res
    moist_noise = moist_noise_res

# returns biome name for world position (Vector3)
func get_biome_at(pos:Vector3) -> String:
    if not temp_noise or not moist_noise:
        return "plains"
    var tx = pos.x * 0.01
    var tz = pos.z * 0.01
    var t = temp_noise.get_noise_2d(tx, tz)
    var m = moist_noise.get_noise_2d(tx, tz)
    # normalize to 0..1
    t = (t + 1.0) * 0.5
    m = (m + 1.0) * 0.5
    # simple biome rules
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
