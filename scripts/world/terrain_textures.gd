extends Node
class_name TerrainTextures

static func create_grass_albedo() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for y in range(256):
		for x in range(256):
			var n = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var n2 = noise.get_noise_2d(x * 2.0, y * 2.0) * 0.5 + 0.5
			var detail = n * 0.7 + n2 * 0.3
			
			var r = lerp(0.2, 0.35, detail)
			var g = lerp(0.45, 0.65, detail)
			var b = lerp(0.15, 0.25, detail)
			img.set_pixel(x, y, Color(r, g, b, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_grass_normal() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 12346
	noise.frequency = 0.08
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for y in range(256):
		for x in range(256):
			var dx = noise.get_noise_2d(x + 1, y) - noise.get_noise_2d(x - 1, y)
			var dy = noise.get_noise_2d(x, y + 1) - noise.get_noise_2d(x, y - 1)
			
			var nx = -dx * 0.5
			var ny = -dy * 0.5
			var nz = 1.0
			var len = sqrt(nx*nx + ny*ny + nz*nz)
			nx /= len
			ny /= len
			nz /= len
			
			img.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_dirt_albedo() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 23456
	noise.frequency = 0.06
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	for y in range(256):
		for x in range(256):
			var n = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var n2 = noise.get_noise_2d(x * 3.0, y * 3.0) * 0.5 + 0.5
			var detail = n * 0.6 + n2 * 0.4
			
			var r = lerp(0.35, 0.55, detail)
			var g = lerp(0.25, 0.4, detail)
			var b = lerp(0.15, 0.25, detail)
			img.set_pixel(x, y, Color(r, g, b, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_dirt_normal() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 23457
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	for y in range(256):
		for x in range(256):
			var dx = noise.get_noise_2d(x + 1, y) - noise.get_noise_2d(x - 1, y)
			var dy = noise.get_noise_2d(x, y + 1) - noise.get_noise_2d(x, y - 1)
			
			var nx = -dx * 0.8
			var ny = -dy * 0.8
			var nz = 1.0
			var len = sqrt(nx*nx + ny*ny + nz*nz)
			nx /= len
			ny /= len
			nz /= len
			
			img.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_rock_albedo() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 34567
	noise.frequency = 0.04
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	var noise2 = FastNoiseLite.new()
	noise2.seed = 34568
	noise2.frequency = 0.15
	noise2.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	for y in range(256):
		for x in range(256):
			var n = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var n2 = noise2.get_noise_2d(x, y) * 0.5 + 0.5
			var detail = n * 0.5 + n2 * 0.5
			
			var base_gray = lerp(0.35, 0.6, detail)
			var r = base_gray + randf_range(-0.03, 0.03)
			var g = base_gray + randf_range(-0.02, 0.02)
			var b = base_gray + randf_range(-0.02, 0.04)
			img.set_pixel(x, y, Color(clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1), 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_rock_normal() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 34569
	noise.frequency = 0.12
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	for y in range(256):
		for x in range(256):
			var dx = noise.get_noise_2d(x + 1, y) - noise.get_noise_2d(x - 1, y)
			var dy = noise.get_noise_2d(x, y + 1) - noise.get_noise_2d(x, y - 1)
			
			var nx = -dx * 1.2
			var ny = -dy * 1.2
			var nz = 1.0
			var len = sqrt(nx*nx + ny*ny + nz*nz)
			nx /= len
			ny /= len
			nz /= len
			
			img.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_sand_albedo() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 45678
	noise.frequency = 0.08
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for y in range(256):
		for x in range(256):
			var n = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var n2 = noise.get_noise_2d(x * 4.0, y * 4.0) * 0.5 + 0.5
			var detail = n * 0.6 + n2 * 0.4
			
			var r = lerp(0.85, 0.95, detail)
			var g = lerp(0.75, 0.85, detail)
			var b = lerp(0.55, 0.65, detail)
			img.set_pixel(x, y, Color(r, g, b, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_sand_normal() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 45679
	noise.frequency = 0.15
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for y in range(256):
		for x in range(256):
			var dx = noise.get_noise_2d(x + 1, y) - noise.get_noise_2d(x - 1, y)
			var dy = noise.get_noise_2d(x, y + 1) - noise.get_noise_2d(x, y - 1)
			
			var nx = -dx * 0.3
			var ny = -dy * 0.3
			var nz = 1.0
			var len = sqrt(nx*nx + ny*ny + nz*nz)
			nx /= len
			ny /= len
			nz /= len
			
			img.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_snow_albedo() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 56789
	noise.frequency = 0.06
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for y in range(256):
		for x in range(256):
			var n = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var sparkle = noise.get_noise_2d(x * 8.0, y * 8.0) * 0.5 + 0.5
			var detail = n * 0.8 + sparkle * 0.2
			
			var base = lerp(0.9, 1.0, detail)
			var r = base
			var g = base
			var b = lerp(0.95, 1.0, detail)
			img.set_pixel(x, y, Color(r, g, b, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

static func create_snow_normal() -> ImageTexture:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 56790
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for y in range(256):
		for x in range(256):
			var dx = noise.get_noise_2d(x + 1, y) - noise.get_noise_2d(x - 1, y)
			var dy = noise.get_noise_2d(x, y + 1) - noise.get_noise_2d(x, y - 1)
			
			var nx = -dx * 0.2
			var ny = -dy * 0.2
			var nz = 1.0
			var len = sqrt(nx*nx + ny*ny + nz*nz)
			nx /= len
			ny /= len
			nz /= len
			
			img.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0))
	
	var tex = ImageTexture.create_from_image(img)
	return tex
