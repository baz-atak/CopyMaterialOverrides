@tool
class_name CMOMaterialLine extends HBoxContainer

const self_scene = preload("res://addons/copy_material_overrides/cmo_material_line.tscn")

@export var lines_material : Material
@export var slot_number : int
@export var move_up_func : Callable
@export var move_down_func : Callable
@export var select_func : Callable
@export var unset_func : Callable
@export var move_swap_func : Callable
@export var drag_change_func : Callable
@export var get_drag_image_func : Callable

static func constructor(p_slot,
		p_up_func : Callable, p_down_func : Callable,
		p_select_func : Callable, p_unset_func : Callable,
		p_swap_func : Callable, p_change_func : Callable,
		p_get_drag_image : Callable) -> CMOMaterialLine:
	var result = self_scene.instantiate()
	result.slot_number = p_slot
	result.move_up_func = p_up_func
	result.move_down_func = p_down_func
	result.move_swap_func = p_swap_func
	result.select_func = p_select_func
	result.unset_func = p_unset_func
	result.drag_change_func = p_change_func
	result.get_drag_image_func = p_get_drag_image
	result.populate()
	return result

func _ready() -> void:
	var gui := EditorInterface.get_base_control()
	$UpButton.icon = gui.get_theme_icon("ArrowUp", "EditorIcons")
	$DownButton.icon = gui.get_theme_icon("ArrowDown", "EditorIcons")
	$SelectButton.icon = gui.get_theme_icon("FolderBrowse", "EditorIcons")
	$UnsetButton.icon = gui.get_theme_icon("Close", "EditorIcons")

func populate() -> void:
	$SlotLabel.text = str(slot_number)
	$UpButton.pressed.connect(move_up_func.bind(slot_number))
	$DownButton.pressed.connect(move_down_func.bind(slot_number))
	$SelectButton.pressed.connect(select_func.bind(slot_number))
	$UnsetButton.pressed.connect(unset_func.bind(slot_number))

func set_lines_material(value : Material):
	lines_material = value
	display_material()

func display_material():
	if lines_material:
		var material_path_info = CopyMaterialDialog.split_path(lines_material.resource_path)
		$PathLabel.text = material_path_info[0]
		$MaterialButton.text = material_path_info[1]
	else:
		$PathLabel.text = ""
		$MaterialButton.text = ""

func _get_drag_data(position):
	if lines_material:
		var drag_data = {"type": "material", "material": lines_material, "slot": slot_number, "source": self }
		var preview_image : Texture2D = get_drag_image_func.bind(slot_number).call()
		if preview_image:
			var preview_rect : TextureRect = TextureRect.new()
			preview_rect.texture = preview_image
			set_drag_preview(preview_rect)
		else:
			print("no preview image")
		return drag_data
	return null

func _can_drop_data(position, data) -> bool:
	if data is Dictionary:
		if data["type"] == "material":
			return (data["slot"] != slot_number)
		elif data["type"] == "resource":
			var resource = data["resource"]
			return resource is Material
		elif data["type"] == "files":
			if data["files"][0].ends_with(".material"):
				return true
			elif data["files"][0].ends_with(".tres") or data["files"][0].ends_with(".res"):
				var tst = load(data["files"][0])
				if tst and tst is Material:
					return true
	return false

func _drop_data(position, data):
	if _can_drop_data(position, data):
		if data["type"] == "material":
			if Input.is_key_pressed(KEY_CTRL):
				var replacement = data["material"]
				if replacement and replacement is Material:
					drag_change_func.bind(slot_number, replacement).call()
			else:
				move_swap_func.bind(data["slot"]).bind(slot_number).call()
		elif data["type"] == "resource":
			var replacement = data["resource"]
			if replacement and replacement is Material:
				drag_change_func.bind(slot_number, replacement).call()
		elif data["type"] == "files":
			var replacement = load(data["files"][0])
			if replacement and replacement is Material:
				drag_change_func.bind(slot_number, replacement).call()

func _on_material_button_pressed() -> void:
	if lines_material:
		EditorInterface.get_inspector().resource_selected.emit(lines_material, lines_material.resource_path)
