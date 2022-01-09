extends Node

func _iter_set(from: Dictionary, to):
	for key in from.keys():
		to.set(key, from[key])

func pretty_print(data: Reference) -> String:
	var dict := {}
	
	for i in data.get_property_list():
		if i.name in ["Reference", "script", "Script Variables"]:
			continue
		dict[i.name] = data.get(i.name)
	
	return JSON.print(dict, "\t")

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
	
	func _to_string():
		return CubismFactory.pretty_print(self)

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
	
	func _to_string():
		return CubismFactory.pretty_print(self)

func parameter(d: Dictionary) -> Parameter:
	var r := Parameter.new()
	
	_iter_set(d, r)
	
	return r

class Part:
	var id: int
	var opacity: float
	
	func _to_string():
		return CubismFactory.pretty_print(self)

func part(d: Dictionary) -> Part:
	var r := Part.new()
	
	_iter_set(d, r)
	
	return r

class Motion:
	var file: String
	var fade_in_time: float
	var fade_out_time: float
	
	func _to_string():
		return CubismFactory.pretty_print(self)

func motion(d: Dictionary) -> Motion:
	var r := Motion.new()
	
	_iter_set(d, r)
	
	return r

class CanvasInfo:
	var size: Vector2
	var origin: Vector2
	var ppu: float
	
	func _to_string():
		return CubismFactory.pretty_print(self)

func canvas_info(d: Dictionary) -> CanvasInfo:
	var r := CanvasInfo.new()
	
	_iter_set(d, r)
	
	return r
