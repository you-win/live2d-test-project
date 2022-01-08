extends Node2D

const TMP_DIR: String = "res://tmp"
const RES_PATH: String = "res://samples/Haru/"

const CUBISM_LOADER_FACTORY_PATH: String = "res://cubism_loader_factory.gdns"

onready var root: Node2D = $Root

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var dir := Directory.new()
	if not dir.dir_exists(TMP_DIR):
		dir.make_dir(TMP_DIR)
	
	var factory = load(CUBISM_LOADER_FACTORY_PATH).new()
	var loader = factory.cubism_loader(ProjectSettings.globalize_path("%sHaru.model3.json" % RES_PATH))
	
	var json = loader.json()
	
	var textures: Array = _load_textures(json["file_references"]["textures"], RES_PATH)
	
	var drawables = loader.drawables()
	for drawable in drawables:
		var d := CubismFactory.drawable(drawable)
		
		var mesh := MeshInstance2D.new()
		var array_mesh := ArrayMesh.new()
		
		var array: Array = []
		array.resize(Mesh.ARRAY_MAX)
		
		var vertices := PoolVector2Array()
		var uvs := PoolVector2Array()
		var indices := PoolIntArray()
		
#		for pos in drawable["vertex_positions"]:
#			vertices.append(pos)
#		for uv in drawable["vertex_uvs"]:
#			uvs.append(uv)
#		for index in drawable["indices"]:
#			indices.append(index)
		for pos in d.vertex_positions:
			vertices.append(pos)
		for uv in d.vertex_uvs:
			uvs.append(uv)
		for index in d.indices:
			indices.append(index)
		
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_TEX_UV] = uvs
		array[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		mesh.mesh = array_mesh
		
		var mat := CanvasItemMaterial.new()
		
		
		mesh.mesh.surface_set_material(array_mesh.get_surface_count() - 1, mat)
		
		mesh.texture = textures[d.texture_index]
		root.add_child(mesh)
		
		mesh.z_index = d.draw_order
		
		ResourceSaver.save("%s/%d.tres" % [TMP_DIR, drawable["index"]], array_mesh)
#		print("name: %s - tex: %d" % [drawable["index"], drawable["texture_index"]])

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
		image.load("%s%s" % [res_path, path])
		image_texture.create_from_image(image)
		textures.append(image_texture)
	
	return textures

###############################################################################
# Public functions                                                            #
###############################################################################
