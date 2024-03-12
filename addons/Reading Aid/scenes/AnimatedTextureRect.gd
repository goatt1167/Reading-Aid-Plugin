@tool
extends TextureRect
class_name AnimatedTextureRect

#1#
@export var sprites:SpriteFrames

var playing = false

var _current_animation:StringName
var _current_frame := 0
var _frame_per_sec := 1.0
var _remaining_time:= 0.0

func names():
	print(sprites.get_animation_names())

#1#
func play(anim:StringName):
	if !sprites.has_animation(anim): push_error("no such animation"); return
	# setup for playing
	_current_frame = -1
	_current_animation = anim
	_prepare_next_frame()
	
	playing = true
	
func stop():
	playing = false
	texture = null


func _process(delta):
	if !playing: return
	if !sprites.has_animation(_current_animation): return
	
	if _current_frame_completed():
		_prepare_next_frame()
	_play_current_frame_for(delta)
 

#1#
func _prepare_next_frame():
	_current_frame += 1
	if _current_frame >= sprites.get_frame_count(_current_animation): _current_frame = 0
	texture = sprites.get_frame_texture(_current_animation, _current_frame)
	_frame_per_sec = sprites.get_animation_speed(_current_animation)
	_remaining_time = 1 / _frame_per_sec * sprites.get_frame_duration(_current_animation, _current_frame)

func _play_current_frame_for(time):
	_remaining_time -= time


func _current_frame_completed() -> bool:
	return _remaining_time <= 0
