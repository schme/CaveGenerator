tool
extends EditorPlugin

const generator := preload("Generator.tscn")
var generator_instance = null

func _enter_tree():
	generator_instance = generator.instance()
	generator_instance.connect("export_current", self, "_on_export_current")
	get_editor_interface().get_editor_viewport().add_child(generator_instance)
	make_visible(false)

func _exit_tree():
	if generator_instance:
		generator_instance.free()

func has_main_screen():
	return true

func make_visible(visible):
	if generator_instance:
		generator_instance.visible = visible


func get_plugin_name():
	return "CaveGen"


func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("TileMap", "EditorIcons")

func find_first_tilemap(root: Node):
	# Lets do breadth first to get the closest to root
	for child in root.get_children():
		if child is TileMap:
			return child
	for child in root.get_children():
		if find_first_tilemap(child):
			return child
	return null

func _on_export_current():
	var edited_root: Node = get_editor_interface().get_edited_scene_root()
	var tilemap = find_first_tilemap(edited_root)
	if tilemap != null:
		generator_instance.export_current_to_tilemap(tilemap)
		print("Tilemap exported!")
	else:
		print("Create a tilemap in the current scene to export!")
