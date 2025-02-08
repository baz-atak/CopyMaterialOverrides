@tool
extends Window

var close_position

var old_window_size
var window_resized := false
var resize_refresh_delay := 0.0
const resize_refresh_wait := 2.0
var requires_refresh := false

var settings_file_path := "res://addons/copy_material_overrides/settings.inf"

const non_center_mass = 350

func _ready() -> void:
	load_settings()
	old_window_size = size

func _process(delta: float) -> void:
	if visible:
		if window_resized:
			resize_refresh_delay = resize_refresh_delay + delta
			if resize_refresh_delay > resize_refresh_wait:
				close_position = position
				requires_refresh = true
				window_resized = false
				visible = false

func _on_close_requested() -> void:
	close_position = position
	hide()

func _exit_tree() -> void:
	save_settings()

func _on_visibility_changed() -> void:
	if !visible:
		if requires_refresh:
			visible = true
			requires_refresh = false
	else:
		old_window_size = size
		if close_position:
			position = close_position
	#var apply_button : Button = %CopyMaterialDialog.get_apply_button()
	#if apply_button:
		#apply_button.visible = visible


func load_settings() -> void:
	if (not FileAccess.file_exists(settings_file_path)):
		return
	var save_settings_file = FileAccess.open(settings_file_path, FileAccess.READ)
	if save_settings_file.get_length() > 0:
		var aline = save_settings_file.get_line()
		if aline:
			var parse_results = JSON.parse_string(aline)
			if parse_results:
				set_settings(parse_results)

func set_settings(state : Dictionary):
	if !state.is_empty():
		close_position = Vector2(state.get("x", 20), state.get("y", 20))
		position = close_position
		%CopyMaterialDialog.set_other_scene_path(state.get("path", "res://"))
		%CopyMaterialDialog.set_split_offset(state.get("split_offset", 144))
		%CopyMaterialDialog.set_sixteen_mode(state.get("sixteen", false))
		%CopyMaterialDialog.set_find_material_path(state.get("materials", "res://"))
		size.y = state.get("size_y", 800)
		old_window_size = size
		%CopyMaterialDialog.change_center_mass(size.y - non_center_mass)


func save_settings() -> void:
	var save_settings_file := FileAccess.open(settings_file_path, FileAccess.WRITE)
	var json_string=JSON.stringify(get_save_settings())
	save_settings_file.store_line(json_string)
	save_settings_file.flush()
	save_settings_file.close()

func get_save_settings() -> Dictionary:
	return { "x" : position.x, "y" : position.y,
		"path" : %CopyMaterialDialog.get_other_scene_path(),
		"split_offset" : %CopyMaterialDialog.get_split_offset(),
		"sixteen" : %CopyMaterialDialog.is_sixteen_mode(),
		"materials" : %CopyMaterialDialog.get_find_material_path(),
		"size_y" : size.y,
		}


func _on_size_changed() -> void:
	if size and old_window_size and size.y != old_window_size.y:
		%CopyMaterialDialog.change_center_mass(size.y - non_center_mass)
		old_window_size = size
		requires_refresh = false
		resize_refresh_delay = 0.0
		window_resized = true

func get_grab_button():
	return %CopyMaterialDialog.get_grab_button()
	
func get_apply_button():
	return %CopyMaterialDialog.get_apply_button()
