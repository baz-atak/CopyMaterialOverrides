@tool
class_name CopyMaterialDialog extends Container

var other_scene_dialog : EditorFileDialog
var save_sample_dialog : EditorFileDialog
var material_dialog : EditorFileDialog

var max_list_size := 100

var mesh_list : Dictionary = {}
var material_list : Dictionary = {}

var grab_button : Button
var apply_button : Button
var scene_instance

var check_age := 0.0
var check_interval := 2.0
var editor_inspector : EditorInspector
var mesh_line_number := 0
var mesh_material_count := 0
var use_material_count := 0
var find_material_path := "res://"
var find_material_slot := 0

var sample_image : Image
const sis : int = 128

var drag_data : Dictionary

var undo_redo #: EditorUndoRedoManager

func _ready():
	var gui := EditorInterface.get_base_control()
	anchor_left = 0
	anchor_bottom = 0
	anchor_right = 0
	anchor_top = 0
	%OtherSceneBrowseButton.icon = gui.get_theme_icon("FolderBrowse", "EditorIcons")
	%ClearButton.icon = gui.get_theme_icon("Remove", "EditorIcons")
	%CopyMaterialsButton.disabled = true
	%CopyMaterialsButton2.disabled = true
	%LoadMaterialsFromMeshButton.disabled = true
	%SaveMaterialsButton.disabled = true
	editor_inspector = EditorInterface.get_inspector()
	undo_redo = get_undo_redo(get_parent())
	if !undo_redo:
		undo_redo = EditorPlugin.new().get_undo_redo()
	for i in range(0, 16):
		material_list[i] = null
	grab_button = Button.new()
	grab_button.text = "Grab"
	#grab_button.icon = gui.get_theme_icon("StatusWarning", "EditorIcons")
	grab_button.icon = gui.get_theme_icon("ToolPan", "EditorIcons")
	grab_button.pressed.connect(_on_load_materials_from_mesh_button_pressed)
	grab_button.disabled = true
	apply_button = Button.new()
	apply_button.text = "Apply"
	apply_button.icon = gui.get_theme_icon("StatusSuccess", "EditorIcons")
	#apply_button.icon = gui.get_theme_icon("ActionCopy", "EditorIcons")
	apply_button.pressed.connect(_on_copy_materials_button_pressed)
	apply_button.disabled = true

# this should be a get on the var grab_button, but that doen't appear to work across scripts
func get_grab_button():
	return grab_button

func get_apply_button():
	return apply_button

func get_undo_redo(parent_node):
	if parent_node:
		if parent_node.has_method("get_undo_redo"):
			return parent_node.get_undo_redo()
		else:
			return get_undo_redo(parent_node.get_parent())

func _on_exit_tree():
	if scene_instance:
		scene_instance.queue_free()

func _process(delta):
	check_age = check_age - delta
	if check_age <= 0.0:
		var current_node = editor_inspector.get_edited_object()
		if current_node and current_node.has_method("set_surface_override_material"):
			var reqd_material_count : int = current_node.get_surface_override_material_count()
			%CopyMaterialsButton.disabled = (reqd_material_count <= 0) or !check_has_materials()
			%CopyMaterialsButton2.disabled = %CopyMaterialsButton.disabled
			apply_button.disabled = %CopyMaterialsButton.disabled
			%LoadMaterialsFromMeshButton.disabled = (reqd_material_count <= 0)
			grab_button.disabled = %LoadMaterialsFromMeshButton.disabled
		else:
			%CopyMaterialsButton.disabled = true
			%CopyMaterialsButton2.disabled = true
			apply_button.disabled = true
			%LoadMaterialsFromMeshButton.disabled = true
			grab_button.disabled = true
		check_age = check_interval

func _get_drag_data(position):
	if drag_data and !drag_data.is_empty() and drag_data["material"] != null:
		var item_number = drag_data["slot"]
		var preview_image : Texture2D = _get_sample_image(item_number)
		if preview_image:
			var preview_rect : TextureRect = TextureRect.new()
			preview_rect.texture = preview_image
			set_drag_preview(preview_rect)
		return drag_data
	return null

func _can_drop_data(position : Vector2, data) -> bool:
	if data is Dictionary:
		if data["type"] == "material":
			var material_slot : int = get_viewport_slot(position)
			if material_slot >= 0 and material_slot != data["slot"]:
				return true
		elif data["type"] == "resource":
			var resource = data["resource"]
			return resource is Material
		elif data["type"] == "nodes":
			var node_paths = data["nodes"]
			if node_paths:
				var node_path = node_paths[0]
				if node_path and node_path is NodePath:
					var mesh_instance = get_node(node_path)
					if mesh_instance:
						return mesh_instance is MeshInstance3D
			return false
		elif data["type"] == "files":
			var f = data["files"][0]
			if f.ends_with(".tscn") or f.ends_with(".scn"):
				return true
			elif f.ends_with(".material"):
				return get_viewport_slot(position) >= 0
			elif f.ends_with("tres") or f.ends_with("res"):
				if get_viewport_slot(position) >= 0:
					var tst = load(f)
					if tst and tst is Material:
						return true
	return false

func _drop_data(position, data):
	if _can_drop_data(position, data):
		var material_drop_slot : int = get_viewport_slot(position)
		if data["type"] == "material":
			if material_drop_slot >= 0:
				if Input.is_key_pressed(KEY_CTRL):
					var replacement = data["material"]
					if replacement and replacement is Material:
						set_lines_material(material_drop_slot, replacement, true)
				else:
					_swap_material_slots(data["slot"], material_drop_slot)
		elif data["type"] == "resource":
			var replacement = data["resource"]
			if replacement and replacement is Material:
				if material_drop_slot >= 0:
					set_lines_material(material_drop_slot, replacement, true)
		elif data["type"] == "nodes":
			var mesh_instance = get_node(data["nodes"][0])
			display_mesh_materials(mesh_instance, true)
		else:
			var f = data["files"][0]
			if f.ends_with(".tscn") or f.ends_with(".scn"):
				_on_other_scene_selected(f)
			else:
				if material_drop_slot >= 0:
					var replacement = load(f)
					if replacement and replacement is Material:
						set_lines_material(material_drop_slot, replacement, true)

func get_viewport_slot(position : Vector2) -> int:
	var viewport_position = position - %SubViewportContainer.position
	var material_slot : int = int(viewport_position.x / sis) + (int(viewport_position.y / sis) * 8)
	if material_slot >= 0 and material_slot < use_material_count:
		return material_slot
	else:
		return -1

func get_other_scene_path() -> String:
	return %OtherScenePath.text

func set_other_scene_path(path : String) -> void:
	%OtherScenePath.text = path

func get_split_offset() -> int:
	return %VSplitContainer.split_offset
	
func set_split_offset(offset : int) -> void:
	%VSplitContainer.split_offset = offset

func _on_other_scene_browse_button_pressed() -> void:
	browse_scenes(%OtherScenePath.text)
	
func _on_sample_dir_button_pressed() -> void:
	browse_scenes("res://addons/copy_material_overrides/samples/")

func browse_scenes(default_path: String):
	if other_scene_dialog:
		if other_scene_dialog.mode != EditorFileDialog.MODE_WINDOWED:
			other_scene_dialog.set_mode(EditorFileDialog.MODE_WINDOWED)
		if other_scene_dialog.visible:
			other_scene_dialog.popup_centered()
			other_scene_dialog.grab_focus()
		else:
			other_scene_dialog.popup_centered()
			other_scene_dialog.show()
			other_scene_dialog.grab_focus()
	else:
		other_scene_dialog = EditorFileDialog.new()
		other_scene_dialog.set_mode(EditorFileDialog.MODE_WINDOWED)
		other_scene_dialog.set_file_mode(EditorFileDialog.FILE_MODE_OPEN_FILE)
		other_scene_dialog.file_selected.connect(_on_other_scene_selected)
		other_scene_dialog.add_filter("*.tscn, *.scn", "Select scene")
		other_scene_dialog.exclusive = false
		add_child(other_scene_dialog)
		other_scene_dialog.popup_centered(Vector2i(1000, 600))
	if default_path.begins_with("res://"):
		other_scene_dialog.set_current_path(default_path)
	else:
		other_scene_dialog.set_current_path("res://")

func remove_children(from_parent):
	var children = from_parent.get_children()
	for child in children:
		from_parent.remove_child(child)
		child.queue_free()

func _on_other_scene_selected(path):
	if path:
		clear_sample_image()
		if path.begins_with("res://addons/copy_material_overrides/"):
			var scene_resource = load(path)
			if scene_resource:
				scene_instance = scene_resource.instantiate()
				if scene_instance is MeshInstance3D:
					display_mesh_materials(scene_instance, false)
		else:
			var path_info := split_path(path)
			%OtherScenePath.text = path_info[0] + "/"
			%OtherSceneName.text = path_info[1]
			mesh_list = {}
			remove_children(%SceneMeshList)
			mesh_line_number = 0
			var scene_resource = load(path)
			if scene_resource:
				scene_instance = scene_resource.instantiate()
				get_meshes_from_scene(scene_instance, "")
			if mesh_line_number > 0:
				display_mesh_materials(mesh_list[0], true)
			check_age = 0.0

func get_meshes_from_scene(scene, path_info : String):
	if scene is MeshInstance3D:
		add_mesh_to_list(scene, path_info)
	else:
		if scene.has_method("get_children"):
			for node in scene.get_children():
				get_meshes_from_scene(node, path_info + "/" + node.name)
				if mesh_line_number >= max_list_size:
					return

func add_mesh_to_list(mi3d : MeshInstance3D, path_info : String):
	mesh_list[mesh_line_number] = mi3d
	#
	var path_label := Label.new()
	path_label.custom_minimum_size = Vector2(700, 0)
	path_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	path_label.text = path_info
	#
	var mesh_button := Button.new()
	mesh_button.custom_minimum_size = Vector2(300, 0)
	mesh_button.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	mesh_button.text = mi3d.name
	mesh_button.pressed.connect(_on_mesh_button_pressed.bind(mesh_line_number))
	#
	var h_container := HBoxContainer.new()
	h_container.add_child(path_label)
	h_container.add_child(mesh_button)
	%SceneMeshList.add_child(h_container)
	mesh_line_number = mesh_line_number + 1
	
func _on_mesh_button_pressed(line_number: int):
	display_mesh_materials(mesh_list[line_number], true)

func clear_sample_image():
	mesh_material_count = 0
	if !%SixteenCheckButton.button_pressed:
		%SaveMaterialsButton.disabled = true
		remove_children(%MaterialList)
		for i in range(0, 16):
			if i < use_material_count:
				material_list[i] = null
			%SamplesGrid001.set_surface_override_material(i, null)

func display_mesh_materials(source_mesh: MeshInstance3D, fallback := false):
	clear_sample_image()
	if source_mesh and source_mesh.mesh:
		mesh_material_count = min(source_mesh.get_surface_override_material_count(), source_mesh.mesh.get_surface_count())
		if mesh_material_count > 0:
			var last_slot = mesh_material_count - 1
			for material_slot in range(0, mesh_material_count):
				if !%SixteenCheckButton.button_pressed:
					add_material_line(material_slot)
				var material : Material = source_mesh.get_surface_override_material(material_slot)
				if !material and fallback:
					material = source_mesh.mesh.surface_get_material(material_slot)
				if material:
					var take_image = material_slot == last_slot
					set_lines_material(material_slot, material, take_image)
					%SamplesGrid001.set_surface_override_material(material_slot, material)
				else:
					print("missing material ", material_slot)
	set_save_materials_button()

func set_save_materials_button():
	%SaveMaterialsButton.disabled = !check_has_materials()

func check_has_materials() -> bool:
	for i in range(0, use_material_count):
		if material_list[i]:
			return true
	return false

func add_material_line(material_slot : int):
	var material_line := CMOMaterialLine.constructor(material_slot,
			_on_move_material_up, _on_move_material_down,
			_browse_materials, unset_lines_material,
			_swap_material_slots, _on_material_changed,
			_get_sample_image)
	%MaterialList.add_child(material_line)

func _on_move_material_up(material_slot : int):
	if material_slot > 0:
		_swap_material_slots(material_slot - 1, material_slot)

func _on_move_material_down(material_slot : int):
	if material_slot < (use_material_count - 1):
		_swap_material_slots(material_slot, material_slot + 1)

func _swap_material_slots(material_slot1 : int, material_slot2 : int):
	var replacement_material1 = material_list[material_slot2]
	var replacement_material2 = material_list[material_slot1]
	set_lines_material(material_slot1, replacement_material1, false)
	set_lines_material(material_slot2, replacement_material2)

func _on_material_changed(material_slot : int, replacement : Material):
	set_lines_material(material_slot, replacement)

func unset_lines_material(material_slot : int):
	if material_list[material_slot]:
		set_lines_material(material_slot, null, true)
	
func set_lines_material(material_slot : int, replacement : Material, update_sample_image = true):
	material_list[material_slot] = replacement
	%SamplesGrid001.set_surface_override_material(material_slot, replacement)
	var material_line : CMOMaterialLine = %MaterialList.get_child(material_slot)
	material_line.set_lines_material(replacement)
	if update_sample_image:
		await RenderingServer.frame_post_draw
		sample_image = %SubViewport.get_texture().get_image()
	set_save_materials_button()

func set_sixteen_mode(show_sixteen : bool):
	%SixteenCheckButton.set_pressed_no_signal(show_sixteen)
	add_and_remove_material_lines()

func is_sixteen_mode():
	return %SixteenCheckButton.button_pressed

func _on_sixteen_check_button_toggled(toggled_on: bool) -> void:
	add_and_remove_material_lines()

func add_and_remove_material_lines():
	if %SixteenCheckButton.button_pressed:
		if mesh_material_count < 16:
			for material_slot in range(mesh_material_count,  16):
				add_material_line(material_slot)
				if material_list[material_slot]:
					set_lines_material(material_slot, material_list[material_slot], true)
		use_material_count = 16
	else:
		if mesh_material_count < 16:
			for material_slot in range(mesh_material_count,  16):
				var old_line = %MaterialList.get_child(mesh_material_count)
				if old_line:
					%MaterialList.remove_child(old_line)
					old_line.queue_free()
				%SamplesGrid001.set_surface_override_material(material_slot, null)
		use_material_count = mesh_material_count

func _on_copy_materials_button_pressed() -> void:
	var current_node = editor_inspector.get_edited_object()
	if current_node and current_node.has_method("set_surface_override_material"):
		var reqd_material_count : int = current_node.get_surface_override_material_count()
		if reqd_material_count > 0:
			undo_redo.create_action("copy material overrides")
			for i in range(0, reqd_material_count):
				var material = %SamplesGrid001.get_surface_override_material(i)
				if material:
					var old_material = current_node.get_surface_override_material(i)
					undo_redo.add_do_method(current_node, "set_surface_override_material", i, material)
					undo_redo.add_undo_method(current_node, "set_surface_override_material", i, old_material)
			undo_redo.commit_action()
	else:
		print("Unexpected lack of surface material override slots")


func _on_load_materials_from_mesh_button_pressed() -> void:
	var current_node = editor_inspector.get_edited_object()
	if current_node and current_node.has_method("get_surface_override_material"):
		var available_material_count : int = current_node.get_surface_override_material_count()
		if available_material_count > 0:
			var last_slot = available_material_count - 1
			for material_slot in range(0, available_material_count):
				var material : Material = current_node.get_surface_override_material(material_slot)
				set_lines_material(material_slot, material, material_slot == last_slot)
		check_age = 0.0
	else:
		print("Unexpected lack of surface material override slots")

func _on_save_materials_button_pressed() -> void:
	if save_sample_dialog:
		if save_sample_dialog.mode != EditorFileDialog.MODE_WINDOWED:
			save_sample_dialog.set_mode(EditorFileDialog.MODE_WINDOWED)
		if save_sample_dialog.visible:
			save_sample_dialog.popup_centered()
			save_sample_dialog.grab_focus()
		else:
			save_sample_dialog.popup_centered()
			save_sample_dialog.show()
			save_sample_dialog.grab_focus()
	else:
		save_sample_dialog = EditorFileDialog.new()
		save_sample_dialog.set_mode(EditorFileDialog.MODE_WINDOWED)
		save_sample_dialog.set_file_mode(EditorFileDialog.FILE_MODE_SAVE_FILE)
		save_sample_dialog.set_current_path("res://addons/copy_material_overrides/samples/")
		save_sample_dialog.set_current_file("sample_.tscn")
		save_sample_dialog.add_filter("*.tscn")
		save_sample_dialog.file_selected.connect(_on_save_sample_selected)
		save_sample_dialog.exclusive = false
		add_child(save_sample_dialog)
		save_sample_dialog.popup_centered(Vector2i(1000, 600))

func _on_save_sample_selected(path):
	var packed_scene = PackedScene.new()
	packed_scene.pack(%SamplesGrid001)
	var error = ResourceSaver.save(packed_scene, path)
	if error != OK:
		print("Error saving scene: ", error)


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var material_slot : int = int(event.position.x / sis) + (int(event.position.y / sis) * 8)
		if material_slot >= 0 and material_slot < use_material_count:
			drag_data = {"type": "material", "material": material_list[material_slot], "slot": material_slot, "source": self }
			#show_in_inspector(material_slot)
		else:
			drag_data = {}

func _get_sample_image(material_slot : int) -> ImageTexture:
	var image_format = sample_image.get_format()
	var small_image := Image.create_empty(sis, sis, false, image_format)
	var row : int = int(material_slot / 8)
	var col : int = material_slot - (row * 8)
	small_image.blit_rect(sample_image, Rect2i(col * sis, row * sis, sis, sis), Vector2i(0, 0))
	var image_texture := ImageTexture.create_from_image(small_image)
	return image_texture

func show_in_inspector(material_slot : int) -> void:
	if material_slot >= 0 and material_slot < use_material_count:
		var material : Material = material_list[material_slot]
		EditorInterface.get_inspector().resource_selected.emit(material, material.resource_path)

func _browse_materials(material_slot : int):
	find_material_slot = material_slot
	if material_dialog:
		if material_dialog.mode != EditorFileDialog.MODE_WINDOWED:
			material_dialog.set_mode(EditorFileDialog.MODE_WINDOWED)
		if material_dialog.visible:
			material_dialog.popup_centered()
			material_dialog.grab_focus()
		else:
			material_dialog.popup_centered()
			material_dialog.show()
			material_dialog.grab_focus()
	else:
		material_dialog = EditorFileDialog.new()
		material_dialog.set_mode(EditorFileDialog.MODE_WINDOWED)
		material_dialog.set_file_mode(EditorFileDialog.FILE_MODE_OPEN_FILE)
		material_dialog.file_selected.connect(_on_browse_materials_selected)
		material_dialog.add_filter("*.material, *.tres", "Select material")
		material_dialog.exclusive = false
		add_child(material_dialog)
		material_dialog.popup_centered(Vector2i(1000, 600))
	if find_material_path.begins_with("res://"):
		material_dialog.set_current_path(find_material_path)
	else:
		material_dialog.set_current_path("res://")

func _on_browse_materials_selected(path):
	if path and find_material_slot < use_material_count:
		var replacement = load(path)
		if replacement and replacement is Material:
			set_lines_material(find_material_slot, replacement, true)
			var path_info = split_path(path)
			find_material_path = path_info[0] + "/"

func set_find_material_path(value):
	find_material_path = value

func get_find_material_path():
	return find_material_path
	
func change_center_mass(center_size):
	%VSplitContainer.custom_minimum_size.y = center_size

func get_center_mass():
	return %VSplitContainer.custom_minimum_size.y

static func split_path(path : String) -> Array:
	var sep_pos = path.rfind("/")
	var result : Array = ["", ""]
	result[0] = path.substr(0, sep_pos)
	result[1] = path.substr(sep_pos + 1)
	return result


func _on_clear_button_pressed() -> void:
	mesh_list = {}
	remove_children(%SceneMeshList)
	mesh_material_count = 0
	if %SixteenCheckButton.button_pressed:
		for i in range(0, 16):
			set_lines_material(i, null, false)
	else:
		%SaveMaterialsButton.disabled = true
		remove_children(%MaterialList)
		for i in range(0, 16):
			material_list[i] = null
			%SamplesGrid001.set_surface_override_material(i, null)
