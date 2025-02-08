# Copyright (c) 2025 bsagames
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorPlugin

var start_button : Button
var grab_button : Button
var apply_button : Button
var dialog_window : Window

func _enter_tree():
	assert(Engine.get_version_info().major >= 4)
	# Create the dialog
	dialog_window = preload("copy_material_window.tscn").instantiate()
	dialog_window.hide()
	dialog_window.set_mode(Window.MODE_WINDOWED)
	add_child(dialog_window)
	# Create the buttons
	start_button = Button.new()
	start_button.text = "Start Copy Materials"
	start_button.icon = EditorInterface.get_base_control().get_theme_icon("ActionCopy", "EditorIcons")
	start_button.pressed.connect(_on_button_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, start_button)

func _exit_tree():
	# Remove the buttons when the plugin is disabled
	if grab_button:
		remove_control_from_container(CONTAINER_TOOLBAR, grab_button)
		grab_button.queue_free()
	if apply_button:
		remove_control_from_container(CONTAINER_TOOLBAR, apply_button)
		apply_button.queue_free()
	if start_button:
		remove_control_from_container(CONTAINER_TOOLBAR, start_button)
		start_button.queue_free()
	if dialog_window:
		remove_child(dialog_window)
		dialog_window.queue_free()
	
func _get_plugin_name() -> String:
	return "CopyMaterialOverrides"

func _on_button_pressed():
	if dialog_window.get_mode() == Window.MODE_MINIMIZED:
		dialog_window.set_mode(Window.MODE_WINDOWED)
	if !grab_button:
		grab_button = dialog_window.get_grab_button()
		if grab_button:
			add_control_to_container(CONTAINER_TOOLBAR, grab_button)
		start_button.text = "CMO"
		start_button.icon = EditorInterface.get_base_control().get_theme_icon("VBoxContainer", "EditorIcons")
	if !apply_button:
		apply_button = dialog_window.get_apply_button()
		if apply_button:
			add_control_to_container(CONTAINER_TOOLBAR, apply_button)
	dialog_window.show()
	dialog_window.grab_focus()

# should implement _get_state to store the state (rather than doing it in copy_material_window)
# but I don't like when it gets called
#func _get_state() -> Dictionary:
	#print("saving state ", dialog_window.get_save_settings())
	#return dialog_window.get_save_settings()
	
# should implement _set_state to restore the state (rather than doing it in copy_material_window)
# but I don't like when it gets called
#func _set_state(state: Dictionary) -> void:
	#print("loading state ", state)
	#dialog_window.set_settings(state)
