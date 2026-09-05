extends SceneTree

func _initialize() -> void:
	var house := Image.load_from_file("res://assets/studio/house_source.png")
	if house == null or house.is_empty():
		quit(1)
		return
	house.resize(48, 56, Image.INTERPOLATE_NEAREST)
	house.save_png("res://assets/props/house.png")
	_make_orb().save_png("res://assets/ui/capture_orb.png")
	_make_potion().save_png("res://assets/ui/potion.png")
	quit()

func _make_orb() -> Image:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in 16:
		for x in 16:
			var d := pow(x - 7.5, 2) + pow(y - 7.5, 2)
			if d <= 47.0:
				var color := Color("102044")
				if d <= 34.0: color = Color("e86850") if y < 8 else Color("f8e8a4")
				if y in [7, 8]: color = Color("102044")
				image.set_pixel(x, y, color)
	image.fill_rect(Rect2i(6, 6, 4, 4), Color("102044"))
	image.fill_rect(Rect2i(7, 7, 2, 2), Color.WHITE)
	return image

func _make_potion() -> Image:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(6, 1, 5, 3), Color("102044"))
	image.fill_rect(Rect2i(7, 2, 3, 3), Color("78a8ad"))
	image.fill_rect(Rect2i(4, 4, 9, 11), Color("102044"))
	image.fill_rect(Rect2i(5, 5, 7, 9), Color("f8e8a4"))
	image.fill_rect(Rect2i(5, 9, 7, 5), Color("78b568"))
	image.fill_rect(Rect2i(7, 7, 3, 5), Color.WHITE)
	return image
