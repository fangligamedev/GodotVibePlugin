@tool
extends EditorPlugin

var dap_client = null
var state_manager = null
var llm_communicator = null
var action_executor = null
var vibecoding_dock = null
var plugin_button = null

func _enter_tree():
	print("VibeCoding AI Assistant plugin enabled.")

	# 1. Initialize core modules
	dap_client = preload("res://addons/vibecoding_plugin/dap_client.gd").new()
	state_manager = preload("res://addons/vibecoding_plugin/state_manager.gd").new()
	llm_communicator = preload("res://addons/vibecoding_plugin/llm_communicator.gd").new()
	action_executor = preload("res://addons/vibecoding_plugin/action_executor.gd").new()

	add_child(dap_client)
	add_child(state_manager)
	add_child(llm_communicator)
	add_child(action_executor)

	# [NEW] Register Project Setting for API Key
	if not ProjectSettings.has_setting("vibecoding/gemini_api_key"):
		ProjectSettings.set_setting("vibecoding/gemini_api_key", "")
		ProjectSettings.set_initial_value("vibecoding/gemini_api_key", "")
	
	# Add property info to make it visible in Project Settings
	ProjectSettings.add_property_info({
		"name": "vibecoding/gemini_api_key",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PASSWORD, # Hide actual characters
		"usage": PROPERTY_USAGE_DEFAULT
	})
	# Save to ensure it persists immediately if needed, though usually auto-saved on change
	ProjectSettings.save()

	# Connect signals for module communication
	if dap_client.has_signal("scene_tree_updated"):
		dap_client.connect("scene_tree_updated", Callable(state_manager, "_on_scene_tree_updated"))
	if dap_client.has_signal("object_properties_updated"):
		dap_client.connect("object_properties_updated", Callable(state_manager, "_on_object_properties_updated"))
	if dap_client.has_signal("debug_paused"):
		dap_client.connect("debug_paused", Callable(state_manager, "_on_debug_paused"))
	if dap_client.has_signal("log_message"):
		dap_client.connect("log_message", Callable(state_manager, "_on_log_message"))

	if state_manager.has_signal("state_snapshot_ready"):
		state_manager.connect("state_snapshot_ready", Callable(llm_communicator, "_on_state_snapshot_ready"))
	
	if llm_communicator.has_signal("llm_suggestion_received"):
		llm_communicator.connect("llm_suggestion_received", Callable(self, "_on_llm_suggestion_received"))
	if llm_communicator.has_signal("llm_action_requested"):
		llm_communicator.connect("llm_action_requested", Callable(self, "_on_llm_action_requested"))

	# 2. Register UI
	# Add custom Dock
	vibecoding_dock = preload("res://addons/vibecoding_plugin/ui/vibecoding_dock.gd").new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, vibecoding_dock)
	vibecoding_dock.set_name("VibeCoding")
	vibecoding_dock.set_visible(false) # Hidden by default
    
	# Connect UI signal [NEW]
	if vibecoding_dock.has_signal("request_analysis"):
		vibecoding_dock.connect("request_analysis", Callable(self, "_on_ui_request_analysis"))

	# Add toolbar button to toggle Dock visibility
	plugin_button = Button.new()
	plugin_button.text = "Vibe AI"
	# plugin_button.icon = load("res://addons/vibecoding_plugin/icons/plugin_icon.svg") # Icon might not exist yet
	plugin_button.connect("pressed", Callable(self, "_on_plugin_button_pressed"))
	add_control_to_container(CONTAINER_TOOLBAR, plugin_button)

	# 3. Initialize DAP Client connection
	# Defer connection to ensure everything is ready
	dap_client.call_deferred("connect_to_godot_dap_server")

func _exit_tree():
	print("VibeCoding AI Assistant plugin disabled.")

	# 1. Clean up UI and resources
	if vibecoding_dock:
		remove_control_from_docks(vibecoding_dock)
		vibecoding_dock.queue_free()
	
	if plugin_button:
		remove_control_from_container(CONTAINER_TOOLBAR, plugin_button)
		plugin_button.queue_free()

	# 2. Clean up modules
	if dap_client:
		dap_client.disconnect_from_godot_dap_server()
		dap_client.queue_free()
	if state_manager:
		state_manager.queue_free()
	if llm_communicator:
		llm_communicator.queue_free()
	if action_executor:
		action_executor.queue_free()

func _on_plugin_button_pressed():
	if vibecoding_dock:
		vibecoding_dock.set_visible(!vibecoding_dock.is_visible())

# State to track auto-pilot mode
var is_auto_pilot = false

func _on_llm_suggestion_received(suggestion_text):
	# Display LLM suggestion in Dock
	if vibecoding_dock:
		vibecoding_dock.display_suggestion(suggestion_text)
	
	# If we are in auto-pilot mode but NO action was received (this signal comes first or standalone),
	# we generally wait to see if an action follows. 
	# However, llm_communicator emits suggestion first, then action.
	# So we should check if action follows. A simple way is to let the action handler drive the loop.
	# If NO action is requested, we need to know that to STOP auto-pilot.
	# For now, we'll let the user manually stop or the LLM explicitly conclude.
	# A better heuristic: If response does NOT contain "action": ..., stop.
	pass

func _on_llm_action_requested(action_data):
	print("LLM requested action:", action_data)
	
	var result = {}
	if action_executor:
		# Special handling for chain_task (still supported, but now implicit via Auto-Pilot)
		if action_data.get("action") == "chain_task":
			is_auto_pilot = true # Explicitly enable if AI requests it
			var reason = action_data.get("arguments", {}).get("reason", "Continuing...")
			if vibecoding_dock:
				vibecoding_dock.display_suggestion("[AUTO-PILOT] " + reason)
		
		# Execute the real action
		if action_data.get("action") != "chain_task":
			result = action_executor.execute_action(action_data.get("action"), action_data.get("arguments", {}))
		
		if vibecoding_dock:
			vibecoding_dock.display_suggestion("Action Executed: " + str(result))
			
		# AUTO-PILOT LOGIC
		if is_auto_pilot:
			if vibecoding_dock:
				vibecoding_dock.display_suggestion("[AUTO-PILOT] Feedback sent. Waiting for next step...")
			
			# Wait a bit to let the editor catch up / avoid spamming
			await get_tree().create_timer(1.5).timeout
			
			# Feed the result back to the LLM and ask to continue
			var feedback = "Action executed. Result: " + str(result) + ". \nIMPORTANT: If the plan is not finished, execute the next step IMMEDIATELY. If finished, output the Final Summary."
			_on_ui_request_analysis(feedback, true) # Pass true to indicate this is an internal auto-loop request

func _on_ui_request_analysis(query, is_internal_loop=false):
	# User manually requested analysis via UI
	if state_manager and llm_communicator:
		# Detect Auto-Pilot intent from user
		if not is_internal_loop:
			var q_lower = query.to_lower()
			if "auto" in q_lower or "自动" in q_lower or "plan" in q_lower or "计划" in q_lower:
				is_auto_pilot = true
				if vibecoding_dock:
					vibecoding_dock.display_suggestion("[AUTO-PILOT] Mode Enabled. I will execute until finished.")
			else:
				is_auto_pilot = false # Reset if user asks a normal question

		if query == "TEST_PING":
			llm_communicator.send_state_to_llm({}, "Hello! This is a connectivity test.", true)
		else:
			var snapshot = state_manager.get_current_state_snapshot()
			llm_communicator.send_state_to_llm(snapshot, query, false)
