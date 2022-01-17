extends Spatial

const TMP_DIR: String = "res://tmp"
const RES_PATH: String = "res://samples/Haru/"

const CUBISM_LOADER_FACTORY_PATH: String = "res://cubism_model_factory.gdns"

onready var root: Spatial = $Root

var model
var drawables: Array
var meshes: Array = []
var textures: Array = []
var moc

# debug
var masks = []
var opacities = []

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var factory = load(CUBISM_LOADER_FACTORY_PATH).new()
	model = factory.cubism_model(ProjectSettings.globalize_path(RES_PATH), "Haru.model3.json")
	
	model.apply_expression("F03")
#	model.update(1.0)
	
	# debug
#	for e in model.expressions():
#		print(JSON.print(e, "\t"))
#	print(JSON.print(model.expressions(), "\t"))
#	var parts = model.parts()
#	var draw_orders = []
#	var render_orders = []
	
	var canvas_info := CubismFactory.canvas_info(model.canvas_info())
	
	var json = model.json()
	
	moc = model.moc()
	
	textures = _load_textures(json["file_references"]["textures"], RES_PATH)
	
	drawables = model.drawables()
	
#	meshes.resize(drawables.size())
	
	for drawable in drawables:
		var d := CubismFactory.drawable(drawable)
		
		# debug
#		if d.draw_order in draw_orders:
#			print("draw order already exists %d" % d.draw_order)
#		else:
#			draw_orders.append(d.draw_order)
#		if d.render_order in render_orders:
#			print("render order already exists %d" % d.render_order)
#		else:
#			render_orders.append(d.render_order)
		
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
		mat.vertex_color_is_srgb = true
		mat.albedo_color.a = d.opacity
		if mat.albedo_color.a < 0.1:
			mesh.name = "%s_%d" % [mesh.name, d.opacity]
			pass
#		print(d.opacity)

		mesh.set_surface_material(0, mat)
		
		# debug
		for mask in d.masks:
			if masks.has(mask):
				print("%s mask exists" % mask)
			else:
				masks.append(mask)
		
		var v_material := ShaderMaterial.new()
		var f_material := ShaderMaterial.new()
		
#		mesh.texture = textures[d.texture_index]
		meshes.append(mesh)
#		meshes[d.render_order] = mesh
		root.add_child(mesh)
	
#	print(meshes)
#	print(masks)

func _process(delta: float) -> void:
	model.update(delta)
	drawables = model.drawables()
	_draw_mesh()
	model.apply_expression("F01")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	elif event.is_action_pressed("ui_accept"):
		root.rotate_y(PI/4)

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
	var visited_idx: Array = []
	for drawable_idx in drawables.size():
		if drawable_idx in visited_idx:
			continue
		
		var d := CubismFactory.drawable(drawables[drawable_idx])
		var m: MeshInstance = meshes[drawable_idx]
		
		var dynamic_flags: String = d.dynamic_flags_string
		var target: int = d.render_order
		
		for mask_idx in d.masks:
#		if d.masks.size() > 0:
			# TODO this seems weird
#			for mask_drawable_index in moc.drawable_masks[d.render_order]:
			if mask_idx == -1:
				continue
			
			visited_idx.append(mask_idx)
			
			# TODO print
#			print("mask: %s" % dynamic_flags)
			if not CubismFactory.DynamicFlags.VERTEX_POSITIONS_CHANGED in dynamic_flags:
				continue
			
			var masking_drawable = drawables[mask_idx]
			var mask_d := CubismFactory.drawable(masking_drawable)
			
#			var array_mesh := ArrayMesh.new()
			var array_mesh: ArrayMesh = meshes[mask_idx].mesh
			var array: Array = meshes[mask_idx].mesh.surface_get_arrays(0)
			var mat: SpatialMaterial = array_mesh.surface_get_material(0)
			array_mesh.clear_surfaces()
			
			var vertices = array[Mesh.ARRAY_VERTEX]
			var uvs = array[Mesh.ARRAY_TEX_UV]
			var indices = array[Mesh.ARRAY_INDEX]
			
			for pos_idx in mask_d.vertex_positions.size():
				vertices[pos_idx] = mask_d.vertex_positions[pos_idx]
				vertices[pos_idx].y *= -1
			for uv_idx in mask_d.vertex_uvs.size():
				uvs[uv_idx] = mask_d.vertex_uvs[uv_idx]
				uvs[uv_idx].y *= -1
			
			array[Mesh.ARRAY_VERTEX] = vertices
			array[Mesh.ARRAY_TEX_UV] = uvs
			
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
			meshes[mask_idx].mesh = array_mesh
			
#			var mat := SpatialMaterial.new()
			mat.albedo_texture = textures[d.texture_index]
			mat.flags_transparent = true
			mat.render_priority = mask_d.render_order
			if mask_d.masks.empty():
				mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MIX
			else:
				if "IS_INVERTED_MASK" in mask_d.constant_flags_string:
					# Looks like this requires a stencil buffer that doesn't exist in Godot
					print("inverted")
					pass
				else:
					# Looks like this requires a stencil buffer that doesn't exist in Godot
					pass

			if "BLEND_ADDITIVE" in mask_d.constant_flags_string:
				mat.params_blend_mode = SpatialMaterial.BLEND_MODE_ADD
			elif "BLEND_MULTIPLICATIVE" in mask_d.constant_flags_string:
				mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MUL
			else:
				mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MIX
			mat.vertex_color_is_srgb = true
			mat.albedo_color.a = 1.0

			meshes[mask_idx].set_surface_material(0, mat)
			
#			print(meshes[mask_idx])
		
		if d.opacity <= 0.0 and not "IS_VISIBLE" in dynamic_flags:
			continue
#		print("reg: %s" % dynamic_flags)
		
#		var array_mesh := ArrayMesh.new()
		var array_mesh: ArrayMesh = m.mesh
		var array: Array = m.mesh.surface_get_arrays(0)
		var mat: SpatialMaterial = array_mesh.surface_get_material(0)
		array_mesh.clear_surfaces()
		
		var vertices = array[Mesh.ARRAY_VERTEX]
		var uvs = array[Mesh.ARRAY_TEX_UV]
		var indices = array[Mesh.ARRAY_INDEX]
		
		for pos_idx in d.vertex_positions.size():
#			vertices[pos_idx] = Vector2(d.vertex_positions[pos_idx].x, -d.vertex_positions[pos_idx].y)
			vertices[pos_idx] = d.vertex_positions[pos_idx]
			vertices[pos_idx].y *= -1
#			vertices.append(Vector2(pos.x, -pos.y))
		for uv_idx in d.vertex_uvs.size():
#			uvs[uv_idx] = Vector2(d.vertex_uvs[uv_idx].x, -d.vertex_uvs[uv_idx].y)
			uvs[uv_idx] = d.vertex_uvs[uv_idx]
			uvs[uv_idx].y *= -1
#			uvs.append(Vector2(uv.x, -uv.y))
#		for index in d.indices:
#			indices.append(index)
		
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_TEX_UV] = uvs
#		array[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		m.mesh = array_mesh
		
#		m.mesh = array_mesh
		
#		var mat := SpatialMaterial.new()
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
		mat.vertex_color_is_srgb = true
		mat.albedo_color.a = d.opacity
#		print(d.opacity)

		m.set_surface_material(0, mat)
		
		visited_idx.append(drawable_idx)
		
#		print(d.dynamic_flags_string)
		

###############################################################################
# Public functions                                                            #
###############################################################################
