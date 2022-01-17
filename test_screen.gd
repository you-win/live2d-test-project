extends Node2D

const TMP_DIR: String = "res://tmp"

export var model_name: String = "Haru"

var res_path: String = "res://samples/%s/"
var file_name: String = "%s.model3.json"

const CUBISM_LOADER_FACTORY_PATH: String = "res://cubism_model_factory.gdns"

onready var root = $Root

var model
var drawables: Array
var meshes: Array = [] # MeshInstances
var mask_indices: Array = [] # int
var mesh_materials: Array = [] # Materials for MeshInstances
var textures: Array = []
var moc
var canvas_info

# Camera control
var is_dragging := false

# debug
var masks = []
var opacities = []

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	res_path = res_path % model_name
	file_name = file_name % model_name
	
	var factory = load(CUBISM_LOADER_FACTORY_PATH).new()
	model = factory.cubism_model(ProjectSettings.globalize_path(res_path), file_name)
	
	canvas_info = CubismFactory.canvas_info(model.canvas_info())
	
	var json = model.json()
	
	moc = model.moc()
	
	textures = _load_textures(json["file_references"]["textures"], res_path)
	
	# TODO debug
	$Gui/TextureRect.texture = textures[0]
	if textures.size() > 1:
		$Gui/TextureRect2.texture = textures[1]
	
	drawables = model.drawables()
	
#	model.apply_expression("F03")
#	model.update(0.1)

	# Mask index prepass
	for drawable in drawables:
		var d := CubismFactory.drawable(drawable)
		if not d.masks.empty():
			for i in d.masks:
				if not i in mask_indices:
					mask_indices.append(i)
	
	meshes.resize(drawables.size())
	mesh_materials.resize(drawables.size())
	
	for d_idx in drawables.size():
		if d_idx in mask_indices:
			continue
		
		var d := CubismFactory.drawable(drawables[d_idx])
		
		print(d.constant_flags_string)
		
		var mesh := _create_mesh(d)
		mesh.texture = textures[d.texture_index]
		mesh.z_as_relative = false
		mesh.z_index = d.render_order
		mesh.modulate.a = d.opacity
		
		var mat := ShaderMaterial.new()
		if CubismFactory.ConstantFlags.BLEND_ADDITIVE in d.constant_flags_string:
			mat.shader = load("res://shaders/additive.shader")
		elif CubismFactory.ConstantFlags.BLEND_MULTIPLICATIVE in d.constant_flags_string:
			mat.shader = load("res://shaders/multiplicative.shader")
		else:
			mat.shader = load("res://shaders/normal.shader")
		
		mesh.mesh.surface_set_material(0, mat)
		
		meshes[d_idx] = mesh
		mesh_materials[d_idx] = mat
		
		root.add_child(mesh)
		
		for mask_idx in d.masks:
			if mask_idx == -1:
				continue
			if meshes[mask_idx] != null:
				print("mask already processed %d" % mask_idx)
				continue
			
			var mask := CubismFactory.drawable(drawables[mask_idx])
			print(mask.constant_flags_string)
			var mask_mesh := _create_mesh(mask)
			mask_mesh.z_as_relative = false
			mask_mesh.z_index = d.render_order
			
			var mask_mat := ShaderMaterial.new()
			if not "IS_INVERTED_MASK" in mask.constant_flags_string:
				mask_mat.shader = load("res://shaders/inverted_mask.shader")
			else:
				mask_mat.shader = load("res://shaders/mask.shader")
			
			mask_mesh.texture = textures[d.texture_index]
			mask_mat.set_shader_param("u_tex_0", textures[mask.texture_index])
			
			mask_mesh.mesh.surface_set_material(0, mask_mat)
			
			meshes[mask_idx] = mask_mesh
			mesh_materials[mask_idx] = mask_mat
			
			root.add_child(mask_mesh)
			mask_mesh.name = "Mesh_%d" % mask_idx

func _process(delta: float) -> void:
	model.update(delta)
	drawables = model.drawables()
	_draw_mesh()
#	model.apply_expression("F03")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			$Camera.zoom += Vector2(0.4, 0.4)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			$Camera.zoom -= Vector2(0.4, 0.4)
		elif event.button_index == BUTTON_LEFT:
			is_dragging = event.pressed
	elif event is InputEventMouseMotion:
		if is_dragging:
			root.global_position.x += event.relative.x * 2
			root.global_position.y += event.relative.y * 2

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

func _create_mesh(d: CubismFactory.Drawable) -> MeshInstance2D:
	var mesh := MeshInstance2D.new()
	var array_mesh := ArrayMesh.new()
	
	var array: Array = []
	array.resize(Mesh.ARRAY_MAX)
	
	var vertices: PoolVector2Array = []
	var uvs: PoolVector2Array = []
	var indices: PoolIntArray = []
	
	for pos in d.vertex_positions:
		vertices.append(Vector2(pos.x, -pos.y))
	for uv in d.vertex_uvs:
		uvs.append(Vector2(uv.x, -uv.y))
	for index in d.indices:
		indices.append(index)
	
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_TEX_UV] = uvs
	array[Mesh.ARRAY_INDEX] = indices
	
	if indices.size() == 0:
		printerr("indices are empty for drawable %d" % d.index)
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	mesh.mesh = array_mesh
	
	mesh.scale *= canvas_info.ppu
	
	return mesh

func _draw_mesh() -> void:
	var visited_masks: Array = []
	for drawable_idx in drawables.size():
		if drawable_idx in mask_indices:
			continue
		
		var d := CubismFactory.drawable(drawables[drawable_idx])
		var mesh: MeshInstance2D = meshes[drawable_idx]
		
		if d.opacity <= 0.0 or not "IS_VISIBLE" in d.dynamic_flags_string:
			mesh.visible = false
			continue
		else:
			mesh.visible = true
			mesh.modulate.a = d.opacity
		
		var array: Array
		if mesh.mesh.get_surface_count() > 0:
			array = mesh.mesh.surface_get_arrays(0)
		else:
			array = []
			array.resize(Mesh.ARRAY_MAX)
		var mat: ShaderMaterial = mesh_materials[drawable_idx]
		mesh.mesh.clear_surfaces()
		
		var vertices = array[Mesh.ARRAY_VERTEX]
		var uvs = array[Mesh.ARRAY_TEX_UV]
		
		for pos_idx in d.vertex_positions.size():
			vertices[pos_idx] = d.vertex_positions[pos_idx]
			vertices[pos_idx].y *= -1
		for uv_idx in d.vertex_uvs.size():
			uvs[uv_idx] = d.vertex_uvs[uv_idx]
			uvs[uv_idx].y *= -1
		
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_TEX_UV] = uvs
		
		mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		
		mesh.mesh.surface_set_material(0, mat)
		mesh.modulate.a = d.opacity
		
		for mask_idx in d.masks:
			if mask_idx in visited_masks:
				continue
			visited_masks.append(mask_idx)
			
			if mask_idx == -1:
				continue
			
			var mask := CubismFactory.drawable(drawables[mask_idx])
			var mask_mesh: MeshInstance2D = meshes[mask_idx]
			
			if mask.opacity <= 0.0 or not "IS_VISIBLE" in mask.dynamic_flags_string:
				mask_mesh.visible = false
				continue
			else:
				mask_mesh.visible = true
				mask_mesh.modulate.a = mask.opacity
			
			var mask_array: Array
			if mask_mesh.mesh.get_surface_count() > 0:
				mask_array = mask_mesh.mesh.surface_get_arrays(0)
			else:
				mask_array = []
				mask_array.resize(Mesh.ARRAY_MAX)
			var mask_mat: ShaderMaterial = mesh_materials[mask_idx]
			mask_mesh.mesh.clear_surfaces()
			
			if not CubismFactory.DynamicFlags.VERTEX_POSITIONS_CHANGED in mask.dynamic_flags_string:
				continue
			
			var mask_vertices = mask_array[Mesh.ARRAY_VERTEX]
			var mask_uvs = mask_array[Mesh.ARRAY_TEX_UV]
			
			for pos_idx in mask.vertex_positions.size():
				mask_vertices[pos_idx] = mask.vertex_positions[pos_idx]
				mask_vertices[pos_idx].y *= -1
			for uv_idx in mask.vertex_uvs.size():
				mask_uvs[uv_idx] = mask.vertex_uvs[uv_idx]
				mask_uvs[uv_idx].y *= -1
			
			mask_array[Mesh.ARRAY_VERTEX] = mask_vertices
			mask_array[Mesh.ARRAY_TEX_UV] = mask_uvs
			
			mask_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mask_array)

			mask_mesh.mesh.surface_set_material(0, mask_mat)

###############################################################################
# Public functions                                                            #
###############################################################################
