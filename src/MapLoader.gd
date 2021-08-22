extends Node

var map_image


func load_map(map_filepath: String) -> Array:
	
	var map_data = []
	map_image = load(map_filepath)
	map_image.lock()
	for x in map_image.get_width():
		map_data.append([])
		for y in map_image.get_height():
			map_data[x].append(_get_block_for_colour(x, y))
	return map_data


func _get_block_for_colour(x: int, y: int) -> int:
	var colour = map_image.get_pixel(x, y)
	match colour:
		Color8(105,105,105):
			return 0 # placed stone block
		Color.blue:
			get_parent().spawnpoints[get_parent().Teams.BLUE] = Vector2(x*8, y*8)
			return 10 # blue tent
		Color.red:
			get_parent().spawnpoints[get_parent().Teams.RED] = Vector2(x*8, y*8)
			return 11 # red tent
		_:
			return -1 # air tile
