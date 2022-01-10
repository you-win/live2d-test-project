extends Spatial

const TMP_DIR: String = "res://tmp"
const RES_PATH: String = "res://samples/Haru/"

const CUBISM_LOADER_FACTORY_PATH: String = "res://cubism_model_factory.gdns"

onready var root: Spatial = $Root

var loader
var drawables: Array
var meshes: Array = []

# debug
var masks

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
#	var dir := Directory.new()
#	if not dir.dir_exists(TMP_DIR):
#		if dir.make_dir(TMP_DIR) != OK:
#			printerr("unable to create tmp dir, we are probably crashing")
	
	var factory = load(CUBISM_LOADER_FACTORY_PATH).new()
	loader = factory.cubism_loader(ProjectSettings.globalize_path("%sHaru.model3.json" % RES_PATH))
	
	# debug
	
	
	var canvas_info := CubismFactory.canvas_info(loader.canvas_info())
	
	var json = loader.json()
	
	var textures: Array = _load_textures(json["file_references"]["textures"], RES_PATH)
	
	drawables = loader.drawables()
#	var drawable_array: Array = []
#	drawable_array.resize(drawables.size())
	
	for drawable in drawables:
		var d := CubismFactory.drawable(drawable)
		
		var mesh := MeshInstance.new()
		var array_mesh := ArrayMesh.new()
		
		var array: Array = []
		array.resize(Mesh.ARRAY_MAX)
		
		var vertices := PoolVector2Array()
		var uvs := PoolVector2Array()
		var indices := PoolIntArray()
		
		for pos in d.vertex_positions:
			vertices.append(Vector2(pos.x, -pos.y))
		for uv in d.vertex_uvs:
			uvs.append(Vector2(uv.x, -uv.y))
		for index in d.indices:
			indices.append(index)
		
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_TEX_UV] = uvs
		array[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		mesh.mesh = array_mesh
		
#		var mat := CanvasItemMaterial.new()
#
#		if d.masks.empty():
#			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
#		else:
#			for mask in d.masks:
#				pass
		var mat := SpatialMaterial.new()
		mat.albedo_texture = textures[d.texture_index]
		mat.flags_transparent = true
		mat.render_priority = d.render_order
		if d.masks.empty():
			mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MIX
		else:
			if "IS_INVERTED_MASK" in d.constant_flags_string:
				# Looks like this requires a stencil buffer that doesn't exist in Godot
				pass
			else:
				# Looks like this requires a stencil buffer that doesn't exist in Godot
				pass
		
		if "BLEND_ADDITIVE" in d.constant_flags_string:
			mat.params_blend_mode = SpatialMaterial.BLEND_MODE_ADD
		elif "BLEND_MULTIPLICATIVE" in d.constant_flags_string:
			mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MUL
		else:
			mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MIX
		mat.albedo_color.a = d.opacity

#		var mat := ShaderMaterial.new()
#		match d.constant_flags_string:
#			"BLEND_ADDITIVE":
#				pass
#			"BLEND_MULTIPLICATIVE":
#				pass
#			_:
#				print("Unhandled %s" % d.constant_flags_string)
#				pass
		
#		mesh.mesh.surface_set_material(array_mesh.get_surface_count() - 1, mat)
		mesh.material_override = mat
		
		for mask in d.masks:
			
			pass
		
#		mesh.texture = textures[d.texture_index]
		meshes.append(mesh)
		root.add_child(mesh)
		
#		mesh.scale *= canvas_info.ppu
		
#		mesh.z_index = d.draw_order
#		mesh.z_index = d.render_order # Seems more correct than draw order
		
#		drawable_array[d.render_order] = mesh
		
#		if ResourceSaver.save("%s/%d.tres" % [TMP_DIR, drawable["index"]], array_mesh) != OK:
#			printerr("Unable to save array mesh in %s" % TMP_DIR)
#		print("name: %s - tex: %d" % [drawable["index"], drawable["texture_index"]])
#	for drawable_idx in drawable_array.size():
#		var d: Spatial = drawable_array[drawable_idx]
#		root.add_child(d)
#		d.translate(Vector3(0, 0, -drawable_idx/drawable_array.size()))
#	root.rotate_z(PI)
#	root.rotate_y(PI)

func _process(delta: float) -> void:
	loader.update(delta)
	drawables = loader.drawables()
	_draw_mesh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _load_textures(paths: Array, res_path: String) -> Array:
	var textures: Array = []
	
	for path in paths:
		var image_texture := ImageTexture.new()
		var image := Image.new()
		if image.load("%s%s" % [res_path, path]) != OK:
			printerr("Unable to load image %s" % path)
			continue
		image_texture.create_from_image(image)
		textures.append(image_texture)
	
	return textures

func _draw_mesh() -> void:
	for drawable_idx in drawables.size():
		var d := CubismFactory.drawable(drawables[drawable_idx])
		var m: MeshInstance = meshes[drawable_idx]
		
		var dynamic_flags: String = d.dynamic_flags_string
		if d.opacity <= 0.0 and not "IS_VISIBLE" in dynamic_flags:
			continue
		
		var mat = m.mesh.surface_get_material(0)
		

###############################################################################
# Public functions                                                            #
###############################################################################
