extends Control

func _ready():
	var rect = TextureRect.new()
	rect.texture = load("res://Cross.png")
	rect.anchor_left = 0.5
	rect.anchor_right = 0.5
	rect.anchor_top = 0.5
	rect.anchor_bottom = 0.5
	var texture_size = rect.texture.get_size()
	rect.margin_left = -texture_size.x / 2
	rect.margin_right = -texture_size.x / 2
	rect.margin_top = -texture_size.y / 2
	rect.margin_bottom = -texture_size.y / 2
	add_child(rect)
