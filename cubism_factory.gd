extends Node

func _iter_set(from: Dictionary, to):
	for key in from.keys():
		to.set(key, from[key])

class Drawable:
	var index: int
	var render_order: int
	var draw_order: int
	var texture_index: int
	var indices: PoolIntArray
	var vertex_positions: PoolVector2Array
	var vertex_uvs: PoolVector2Array
	var opacity: float
	var masks: PoolIntArray
	
	var constant_flags: int
	var constant_flags_string: String
	var constant_flags_binary: int
	var constant_flags_hex: int
	
	var dynamic_flags: int
	var dynamic_flags_string: String
	var dynamic_flags_binary: int
	var dynamic_flags_hex: int

func drawable(d: Dictionary) -> Drawable:
	var r := Drawable.new()
	
	_iter_set(d, r)
	
	return r

class Parameter:
	var id: int
	var value: float
	var min_value: float
	var max_value: float
	var default_value: float

func parameter(d: Dictionary) -> Parameter:
	var r := Parameter.new()
	
	_iter_set(d, r)
	
	return r

class Part:
	var id: int
	var opacity: float

func part(d: Dictionary) -> Part:
	var r := Part.new()
	
	_iter_set(d, r)
	
	return r

class Motion:
	var file: String
	var fade_in_time: float
	var fade_out_time: float

func motion(d: Dictionary) -> Motion:
	var r := Motion.new()
	
	_iter_set(d, r)
	
	return r
