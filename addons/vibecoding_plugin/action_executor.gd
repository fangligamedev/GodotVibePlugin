@tool
extends Node

# helper class to execute actions requested by LLM

func execute_action(action_name: String, args: Dictionary) -> Dictionary:
	print("VibeCoding: Executing action '", action_name, "' with args: ", args)
	
	match action_name:
		"save_script":
			return _save_script(args.get("path"), args.get("content"))
		"make_dir":
			return _make_dir(args.get("path"))
		"set_setting":
			return _set_setting(args.get("name"), args.get("value"))
		"rescan_filesystem":
			return _rescan_filesystem()
		"read_file":
			return _read_file(args.get("path"))
		"list_dir":
			return _list_dir(args.get("path"))
		_:
			return {"success": false, "message": "Unknown action: " + action_name}

func _save_script(path: String, content: String) -> Dictionary:
	if not path.begins_with("res://"):
		return {"success": false, "message": "Path must start with res://"}
	
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		var err = DirAccess.make_dir_recursive_absolute(dir)
		if err != OK:
			return {"success": false, "message": "Failed to create directory: " + dir}

	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return {"success": false, "message": "Failed to open file for writing: " + path}
	
	file.store_string(content)
	file.close()
	
	# Trigger filesystem scan to make Godot notice the new file
	_rescan_filesystem()
	
	return {"success": true, "message": "Script saved to " + path}

func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"success": false, "message": "File not found: " + path}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"success": false, "message": "Failed to open file for reading: " + path}
		
	var content = file.get_as_text()
	file.close()
	return {"success": true, "content": content}

func _list_dir(path: String) -> Dictionary:
	if not DirAccess.dir_exists_absolute(path):
		return {"success": false, "message": "Directory not found: " + path}
		
	var dir = DirAccess.open(path)
	if not dir:
		return {"success": false, "message": "Failed to open directory: " + path}
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var files = []
	var dirs = []
	
	while file_name != "":
		if not file_name.begins_with("."): # skip hidden
			if dir.current_is_dir():
				dirs.append(file_name)
			else:
				files.append(file_name)
		file_name = dir.get_next()
		
	return {"success": true, "dirs": dirs, "files": files}

func _make_dir(path: String) -> Dictionary:
	if not path.begins_with("res://"):
		return {"success": false, "message": "Path must start with res://"}
		
	var err = DirAccess.make_dir_recursive_absolute(path)
	if err != OK:
		return {"success": false, "message": "Failed to create directory."}
		
	_rescan_filesystem()
	return {"success": true, "message": "Directory created: " + path}

func _set_setting(name: String, value) -> Dictionary:
	ProjectSettings.set_setting(name, value)
	ProjectSettings.save()
	return {"success": true, "message": "Project setting updated: " + name}

func _rescan_filesystem() -> Dictionary:
	var editor_interface = EditorInterface
	if editor_interface:
		editor_interface.get_resource_filesystem().scan()
		return {"success": true, "message": "Filesystem scanned."}
	return {"success": false, "message": "EditorInterface not available."}
