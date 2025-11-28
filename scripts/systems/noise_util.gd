extends Node
class_name NoiseUtil

# returns a configured OpenSimplexNoise resource for the provided seed and scale
func create_noise(seed:int, lacunarity:float=2.0, persistence:float=0.5, octaves:int=4, period:float=64.0) -> OpenSimplexNoise:
    var n = OpenSimplexNoise.new()
    n.seed = seed
    n.octaves = octaves
    n.period = period
    n.persistence = persistence
    n.lacunarity = lacunarity
    return n
