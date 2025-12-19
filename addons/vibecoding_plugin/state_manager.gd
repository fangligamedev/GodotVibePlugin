@tool
extends Node

signal state_snapshot_ready(state_data)

var current_scene_tree = {}
var current_properties = {}
var debug_context = {}
var recent_logs = []

func _on_scene_tree_updated(tree_data):
	current_scene_tree = tree_data
	_notify_update()

func _on_object_properties_updated(object_id, properties):
	current_properties[object_id] = properties
	_notify_update()

func _on_debug_paused(reason, thread_id, frame_id):
	debug_context = {
		"reason": reason,
		"thread_id": thread_id,
		"frame_id": frame_id
	}
	_notify_update()

func _on_log_message(type, message):
	recent_logs.append({"type": type, "message": message, "timestamp": Time.get_unix_time_from_system()})
	if recent_logs.size() > 50:
		recent_logs.pop_front()

func get_current_state_snapshot():
	return {
		"scene_tree": current_scene_tree,
		"selected_properties": current_properties,
		"debug_context": debug_context,
		"logs": recent_logs
	}

func _notify_update():
	# Debounce or immediate notify
	emit_signal("state_snapshot_ready", get_current_state_snapshot())
