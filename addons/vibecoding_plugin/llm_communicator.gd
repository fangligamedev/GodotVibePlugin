@tool
extends Node

signal llm_suggestion_received(suggestion_text)
signal llm_action_requested(action_data)

var http_request: HTTPRequest
var _pending_request = false
var chat_history = [] # Array of {role, content}

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)
	
func reset_history():
	chat_history = []

func _on_state_snapshot_ready(state_data):
	# Don't spam the LLM, primitive throttle
	if _pending_request:
		return
	
	# For prototype: don't auto-send on every state change unless configured
	pass

# Public method to manually trigger analysis, e.g. from UI
func send_state_to_llm(state_data, user_query="", is_test=false):
	if _pending_request:
		print("VibeCoding: LLM Request already pending.")
		return

	# 1. Try Config File first
	var config_path = "res://addons/vibecoding_plugin/vibecoding_config.json"
	var api_key = ""
	var model = "gemini-pro"
	
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.get_data()
			if data.has("gemini_api_key"):
				api_key = data["gemini_api_key"]
			if data.has("model"):
				model = data["model"]
		else:
			print("VibeCoding: Failed to parse config file.")

	# 2. Fallback to Project Settings
	if api_key.is_empty() or api_key == "YOUR_API_KEY_HERE":
		api_key = ProjectSettings.get_setting("vibecoding/gemini_api_key")

	if api_key.is_empty() or api_key == "YOUR_API_KEY_HERE":
		emit_signal("llm_suggestion_received", "Error: API Key missing.\nPlease set configuration.")
		return
		
	var url = ""
	var headers = []
	var body = ""
	var is_openrouter = api_key.begins_with("sk-or-")

	if is_openrouter:
		url = "https://openrouter.ai/api/v1/chat/completions"
		headers = [
			"Content-Type: application/json",
			"Authorization: Bearer " + api_key
		]
		
		# Construct prompt with System Instructions for Tools
		var system_instruction = """
You are a Godot Engine Expert Assistant (Agent).
You have a specific goal: Help the user design and implement a game in Godot 4.x.

CAPABILITIES:
1. DESIGN: You can plan the project structure.
2. IMPLEMENT: You can write scripts and create directories using tools.
3. INSPECT: You can read files and list directories to understanding the current state.
4. CHAIN-TASK: You can chain tasks to run autonomously.

Supported Actions (Return ONE JSON at the END of response):
1. save_script
   { "action": "save_script", "arguments": { "path": "res://script.gd", "content": "..." } }
2. make_dir
   { "action": "make_dir", "arguments": { "path": "res://dir" } }
3. read_file (Use this to check your work!)
   { "action": "read_file", "arguments": { "path": "res://script.gd" } }
4. list_dir
   { "action": "list_dir", "arguments": { "path": "res://" } }
5. chain_task (Use this to continue to the next step AUTOMATICALLY)
   { "action": "chain_task", "arguments": { "reason": "Moving to next step: implementing player" } }

WORKFLOW:
- If user asks for a complex feature (e.g. "Space Invaders"), Start by creating a `design_doc.md`.
- Then, break it down into steps.
- Execute ONE step at a time.
- After executing, use "chain_task" to trigger the next step immediately.
"""
		var messages = []
		messages.append({"role": "system", "content": system_instruction})
		
		# Add History
		for msg in chat_history:
			messages.append(msg)
			
		# Prepare current user msg
		var user_content = "Godot State: " + JSON.stringify(state_data) + "\n\nUser Request: " + user_query
		var user_msg = {"role": "user", "content": user_content}
		messages.append(user_msg)
		
		# Save to history for next time
		chat_history.append(user_msg)
		
		var request_body = {
			"model": model,
			"messages": messages
		}
			
		body = JSON.stringify(request_body)
	else:
		# Google Generative AI (Simplified history support for now)
		# ... (Keep existing simple logic or upgrade if needed, focusing on OpenRouter for Agent first)
		url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + api_key
		headers = ["Content-Type: application/json"]
		
		# Construct prompt with history manually for Google (as it uses 'contents' array differently)
		var full_prompt = "System: You are a Godot Agent.\n"
		for msg in chat_history:
			full_prompt += msg.role + ": " + msg.content + "\n"
		full_prompt += "User: " + user_query + "\nState: " + JSON.stringify(state_data)
		
		body = JSON.stringify({
			"contents": [{
				"parts": [{"text": full_prompt}]
			}]
		})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("VibeCoding: Error sending HTTP request")
	else:
		_pending_request = true
		print("VibeCoding: Sending state to LLM (Provider: ", "OpenRouter" if is_openrouter else "Google", ")...")

func _http_request_completed(result, response_code, headers, body):
	_pending_request = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("llm_suggestion_received", "Error: HTTP Request failed.")
		return
		
	if response_code != 200:
		emit_signal("llm_suggestion_received", "Error: LLM returned " + str(response_code) + "\n" + body.get_string_from_utf8())
		return
		
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var text = ""
	
	# Parse response based on likely format
	if response.has("choices") and response.choices.size() > 0:
		# OpenAI/OpenRouter format
		text = response.choices[0].message.content
	elif response.has("candidates") and response.candidates.size() > 0:
		# Google format
		text = response.candidates[0].content.parts[0].text
	
	if not text.is_empty():
		emit_signal("llm_suggestion_received", text)
		
		# Update History
		# We need to reconstruct the user message that started this, but for now we'll just append what we got.
		# Ideally we append the user msg *before* sending, assuming success.
		# For this prototype, we'll append the assistant response here.
		chat_history.append({"role": "assistant", "content": text})
		
		# Try to extract JSON Action using a smarter brace counter
		var action_data = _extract_json_action(text)
		if action_data:
			emit_signal("llm_action_requested", action_data)

func _extract_json_action(text: String):
	# Look for the pattern "action": to identify a likely JSON block
	var action_marker = "\"action\":"
	var marker_pos = text.find(action_marker)
	
	if marker_pos == -1:
		return null
		
	# Find the opening brace '{' *before* the action marker
	# We search backwards from the marker position
	var start_brace = text.rfind("{", marker_pos)
	if start_brace == -1:
		return null
		
	# Now count braces to find the matching closing brace
	var brace_count = 0
	var in_string = false
	var escape = false
	var end_brace = -1
	
	for i in range(start_brace, text.length()):
		var char = text[i]
		
		if char == "\\":
			escape = not escape
			continue
			
		if char == "\"":
			if not escape:
				in_string = not in_string
		
		if not in_string:
			if char == "{":
				brace_count += 1
			elif char == "}":
				brace_count -= 1
				if brace_count == 0:
					end_brace = i
					break
		
		if char != "\\":
			escape = false # Reset escape unless we just set it
			
	if end_brace != -1:
		var json_str = text.substr(start_brace, end_brace - start_brace + 1)
		# Clean up any potential markdown code block markers surrounding it if any (just in case)
		# But the brace extractor should handle it well enough if the JSON is valid.
		
		var json = JSON.new()
		var err = json.parse(json_str)
		if err == OK:
			return json.get_data()
		else:
			print("VibeCoding: JSON Parse Error on extracted block: ", json_str)
			
	return null

func execute_godot_action(action_data):
	# TODO: Implement action execution logic
	print("VibeCoding: Executing action ", action_data)
