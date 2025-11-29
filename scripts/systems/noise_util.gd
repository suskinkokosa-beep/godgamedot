extends Node

func create_noise(seed_value: int, lacunarity: float = 2.0, persistence: float = 0.5, octaves: int = 4, period: float = 64.0) -> FastNoiseLite:
    var n = FastNoiseLite.new()
    n.seed = seed_value
    n.fractal_octaves = octaves
    n.frequency = 1.0 / period
    n.fractal_gain = persistence
    n.fractal_lacunarity = lacunarity
    n.noise_type = FastNoiseLite.TYPE_SIMPLEX
    return n
