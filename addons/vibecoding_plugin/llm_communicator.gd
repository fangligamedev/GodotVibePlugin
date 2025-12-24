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
func send_state_to_llm(state_data, user_query="", mode="Chat", images=[]):
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

	# Prepare System Instruction (Chinese)
	var system_instruction = """
你是一个Godot引擎专家助手 (VibeCoding Agent)。
你的目标是帮助用户设计和实现Godot 4.x游戏。

当前模式: %s

能力:
1. 设计: 规划项目结构。
2. 实现: 编写脚本，创建目录。
3. 检查: 读取文件，列出目录以理解当前状态。

支持的动作 (仅在 Agent 模式下使用，请在回复末尾返回一个 JSON):
1. save_script
   { "action": "save_script", "arguments": { "path": "res://script.gd", "content": "..." } }
2. make_dir
   { "action": "make_dir", "arguments": { "path": "res://dir" } }
3. read_file (想要检查代码时使用!)
   { "action": "read_file", "arguments": { "path": "res://script.gd" } }
4. list_dir
   { "action": "list_dir", "arguments": { "path": "res://" } }

工作流 (Agent 模式):
1. 规划: 先创建或更新 `design_doc.md`。
2. 执行: 逐步执行。使用 `save_script` 或 `make_dir`。
3. 自动驾驶: 用户希望你完成整个任务。每次操作后，我会把结果反馈给你。请立即输出下一个动作，直到完成。
4. 完成: 当完成所有步骤后，必须输出一份最终报告，包含：
   - 1. 设计文档 (摘要)
   - 2. 项目介绍 (构建了什么)
   - 3. 游戏说明 (操作与玩法)

注意事项:
- 如果是 Chat 模式，请直接回答用户问题，不要输出 Action JSON，除非用户明确要求生成代码片段供复制。
- 请使用中文回复。
""" % [mode]

	if is_openrouter:
		url = "https://openrouter.ai/api/v1/chat/completions"
		headers = [
			"Content-Type: application/json",
			"Authorization: Bearer " + api_key
		]
		
		var messages = []
		messages.append({"role": "system", "content": system_instruction})
		
		# Add History
		for msg in chat_history:
			messages.append(msg)
			
		# Prepare current user msg (Multimodal Support)
		var user_content_list = []
		
		# Text context
		var text_context = "Godot State: " + JSON.stringify(state_data) + "\n\nUser Request: " + user_query
		user_content_list.append({"type": "text", "text": text_context})
		
		# Images
		for img in images:
			if img and not img.is_empty():
				var png_buffer = img.save_png_to_buffer()
				var base64_str = Marshalls.raw_to_base64(png_buffer)
				user_content_list.append({
					"type": "image_url",
					"image_url": {
						"url": "data:image/png;base64," + base64_str
					}
				})

		var user_msg = {"role": "user", "content": user_content_list}
		messages.append(user_msg)
		
		# Save to history for next time (Simplified: just saving text part for now to save tokens/complexity, or full msg?)
		# For history efficiency, maybe just save text or summary? For now, full object.
		# CAUTION: Large images in history consume context properties.
		# Decision: Do NOT save base64 images to history for this v0.2 to avoid context explosion.
		var history_msg = {"role": "user", "content": text_context} 
		chat_history.append(history_msg)
		
		var request_body = {
			"model": model,
			"messages": messages
		}
			
		body = JSON.stringify(request_body)
	else:
		# Google Generative AI
		url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + api_key
		headers = ["Content-Type: application/json"]
		
		var contents = []
		
		# History (Simplified for Google - it expects 'contents' array with parts)
		var history_text = "System: " + system_instruction + "\n"
		for msg in chat_history:
			# msg.content might be string or array now
			var content_str = ""
			if typeof(msg.content) == TYPE_STRING:
				content_str = msg.content
			elif typeof(msg.content) == TYPE_ARRAY:
				for part in msg.content:
					if part.get("type") == "text":
						content_str += part.text + "\n"
			history_text += msg.role + ": " + content_str + "\n"
			
		# Current Message
		var parts = []
		parts.append({"text": history_text + "\nUser: " + user_query + "\nState: " + JSON.stringify(state_data)})
		
		# Images
		for img in images:
			if img and not img.is_empty():
				var png_buffer = img.save_png_to_buffer()
				var base64_str = Marshalls.raw_to_base64(png_buffer)
				parts.append({
					"inline_data": {
						"mime_type": "image/png",
						"data": base64_str
					}
				})
		
		contents.append({"parts": parts})
		
		body = JSON.stringify({
			"contents": contents
		})
		
		# Update history (Text only)
		chat_history.append({"role": "user", "content": user_query})

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
