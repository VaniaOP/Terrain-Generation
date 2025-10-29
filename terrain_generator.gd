extends Node
# import plugin
const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")
const HTerrainTextureSet = preload("res://addons/zylann.hterrain/hterrain_texture_set.gd")

#The guide I follow recommended this way, but didnt work for me
#check below for solution
#https://habr.com/ru/articles/571626/
#const texture_set = preload("res://terrain_texture_set.tres")

#needed to implement texture set
#Docs I followed suggested this, but it gives an error
#var TSet = preload("res://TSet.tres")

var grass_texture = load("res://textures/GRASS/Grass005_1K-JPG_Color.jpg")
var sand_texture = load("res://textures/SAND/Ground080_1K-PNG_Color.png")

# get viewport
#@export_node_path() var viewport_path :NodePath
#@onready var viewport :SubViewport = get_node(viewport_path)

@export var viewport :SubViewport

#get colorrect
#@export_node_path() var shader_node_path :NodePath
#@onready var shader_node :ColorRect = get_node(shader_node_path)

@export var shader_node :ColorRect

func _ready():
	randomize()
	
	# offset randomly
	shader_node.material.set_shader_parameter("offset", Vector2(randf_range(-100.0, 100.0), randf_range(-100, 100)))
	
	# Create terrain data
	var terrain_data = HTerrainData.new()
	#must be 513 1025 2049 4097. The bigger it is, the longer it will load
	#make sure to set ColorRect, Subviewport and centering to correct values
	#ColorRect and Subviewport get the same value
	#Dont forget to move camera, and give correct value to water
	terrain_data.resize(1025)
	
	# get images, change them later
	var heightmap :Image = terrain_data.get_image(HTerrainData.CHANNEL_HEIGHT)
	
	var normalmap :Image = terrain_data.get_image(HTerrainData.CHANNEL_NORMAL)
	
	var splatmap :Image = terrain_data.get_image(HTerrainData.CHANNEL_SPLAT)
	
	# Cycle for texture type 0 - image
	shader_node.material.set_shader_parameter("texture_type", 0)
	
	# update viewport
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# await render
	await get_tree().process_frame
	await get_tree().process_frame
	
	# get viewport image
	var computed_heightmap :Image = viewport.get_texture().get_image()
	
	# convert to correct type
	computed_heightmap.convert(Image.FORMAT_RF)
	
	# Cycle for texture type 1 - normal
	shader_node.material.set_shader_parameter("texture_type", 1)
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var computed_normalmap :Image = viewport.get_texture().get_image()
	
	computed_normalmap.convert(Image.FORMAT_RF)
	
	# Cycle for texture type 2 - splat
	shader_node.material.set_shader_parameter("texture_type", 2)
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var computed_splatmap :Image = viewport.get_texture().get_image()
	
	computed_splatmap.convert(Image.FORMAT_RF)
	
	# Cycle for texture type 3 - splat_a
	shader_node.material.set_shader_parameter("texture_type", 3)
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var computed_splatmap_a :Image = viewport.get_texture().get_image()
	
	computed_splatmap_a.convert(Image.FORMAT_RF)
	
	#unite splatmap and splatmap_a
	for x in range(computed_splatmap.get_width()):
		for y in range(computed_splatmap.get_height()):
			var p :Color = computed_splatmap.get_pixel(x, y)
			p.a = computed_splatmap_a.get_pixel(x, y).r
			computed_splatmap.set_pixel(x, y, p)
	
	# Swap images
	heightmap.copy_from(computed_heightmap)
	normalmap.copy_from(computed_normalmap)
	splatmap.copy_from(computed_splatmap)
	
	#may be useful, present in official docs
	#commit changes so they get uploaded to the GPU
	#fixes land disappering
	var modified_region = Rect2(Vector2(), heightmap.get_size())
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_NORMAL)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_SPLAT)
	
	
	#terrain texture set following official docs
	#https://hterrain-plugin.readthedocs.io/en/latest/#procedural-generation
	#this part can be done from editor. Docs quote:
	# NOTE: usually this is not made from script, it can be built with editor tools
	var texture_set = HTerrainTextureSet.new()
	texture_set.set_mode(HTerrainTextureSet.MODE_TEXTURES)
	texture_set.insert_slot(-1)
	texture_set.set_texture(0, HTerrainTextureSet.TYPE_ALBEDO_BUMP, grass_texture)
	texture_set.insert_slot(-1)
	texture_set.set_texture(1, HTerrainTextureSet.TYPE_ALBEDO_BUMP, sand_texture)
	
	# Create the terrain
	var terrain = HTerrain.new()
	terrain.set_shader_type(HTerrain.SHADER_CLASSIC4_LITE)
	#the initial doc wanted this, but the offical ones dont use it
	terrain.set_shader_param("u_triplanar", true)
	terrain.set_shader_param("u_tile_reduction", Quaternion(1.0, 1.0, 1.0, 1.0))
	terrain.set_shader_param("u_depth_blending", true)
	terrain.set_data(terrain_data)
	terrain.set_texture_set(texture_set)
	#terrain.set_texture_set(TSet)
	#center the island
	#negative half of map size
	terrain.position = Vector3(-512.5, -25, -512.5)
	
	# Add terrain to tree
	add_child(terrain)
	
	# Use if need to update collider while running
	#terrain.update_collider()

#	__     __          _        ___  ____  
#	\ \   / /_ _ _ __ (_) __ _ / _ \|  _ \ 
#	 \ \ / / _` | '_ \| |/ _` | | | | |_) |
#	  \ V / (_| | | | | | (_| | |_| |  __/ 
#	   \_/ \__,_|_| |_|_|\__,_|\___/|_|    

#TODO: see why the textures look dim
