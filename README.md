# Copy Material Overrides
 This is an addon for the Godot game engine / editor (written for version 4.3)

 This addon is for setting Surface Material Overrides on mesh instances from materials on other mesh instances.
 On 3D meshes you can (normally) define upto 16 material slots and assign different surfaces to different slots.
 This tool is therefore primarily for setting using these slots for setting generic materials onto meshes (e.g. tiled brick, wood, concrete etc materials)

 Copy the copy_material_overrides folder into your projects res://addons folder (create it if needed).
 Enable the addon by going into the Project menu's Project Settings option, selecting the Plugins tab and ticking this addons enabled box.

 Once the addon is running it adds a "Start Copy Materials" button to the top of the editor.
 Once this button is pressed it will open the Copy Surface Material Overrides window and change to 3 buttons:
 - The CMO button reopens / refocuses the Copy Material Overrides window.
 - The Grab button loads the materials associated with the currently selected mesh instance into the CMO tool.
 - The Apply button sets the currently selected mesh instances material overrides from the values in the CMO tool.

 Within the Copy Material Overrides window you can
 - See a preview of the current set of meshes.
 - Select scenes to load and select from them mesh instances to load materials from.
 - Create a select "sample" files of collections of materials.
 - Manipulate the order of materials via swapping / drag and drop swapping (copying if ctrl held down).
 - Drop in scenes and materials from other godot editor dialogs (e.g. file viewer, scene dialog)
 - Grab / Apply materials to currently selected mesh instances.
 - Display 16 materials or the number of material slots in the loaded mesh.
