"""
this script is to draw a triangle onto CommentButton.$color_button../color_rect
"""

@tool
extends ColorRect

var _triangle_points:PackedVector2Array
var _color:Color
var _sr:float # triangle's size reduction
var timer:Timer

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)

func custom_draw(color:Color = _color):
	_sr = size.x / 6
	_triangle_points = PackedVector2Array(
		[Vector2(_sr,_sr),Vector2(_sr, size.y-_sr), Vector2(size.x-_sr, _sr)]
	)
	_color = color
	
	queue_redraw()


# WARNING: _draw() can happen automatically after ready.
# That means it happens before custom_draw() calls it, in which case
# its size, color, and triangle points are empty.
func _draw():
	if visible:
		if _triangle_points.size() == 0 or _triangle_points[0] == Vector2.ZERO:
			timer.start(0.1)
			if !timer.timeout.is_connected(custom_draw):
				timer.timeout.connect(custom_draw)
		else:
			draw_polygon(_triangle_points, [_color])
