@tool
extends Control

signal request_analysis(query, mode, images)

var output_log: RichTextLabel
var input_field: TextEdit
var send_button: Button
var mode_selector: OptionButton
var image_preview_container: HBoxContainer
var pending_images: Array[Image] = []

func _ready():
	# Root sizing
	custom_minimum_size = Vector2(200, 200)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Main container with background
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(panel)

	# VBox layout inside panel
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# Top Bar: Mode Selector
	var top_bar = HBoxContainer.new()
	vbox.add_child(top_bar)
	
	var mode_label = Label.new()
	mode_label.text = "Mode:"
	top_bar.add_child(mode_label)
	
	mode_selector = OptionButton.new()
	mode_selector.add_item("Chat (问答)", 0)
	mode_selector.add_item("Agent (代理)", 1)
	mode_selector.select(1) # Default to Agent
	top_bar.add_child(mode_selector)
	
	# Output area for LLM suggestions
	output_log = RichTextLabel.new()
	output_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_log.text = "[b]VibeCoding AI Ready.[/b]\n\nwaiting for input..."
	output_log.bbcode_enabled = true
	output_log.fit_content = false 
	output_log.scroll_active = true
	output_log.selection_enabled = true # Allow copying text
	vbox.add_child(output_log)
	
	vbox.add_child(HSeparator.new())
	
	# Image Preview Area
	image_preview_container = HBoxContainer.new()
	image_preview_container.custom_minimum_size = Vector2(0, 0) # Collapses when empty
	vbox.add_child(image_preview_container)
	
	# Input area
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)
	
	input_field = TextEdit.new()
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.custom_minimum_size = Vector2(0, 80) # Increased height
	input_field.placeholder_text = "Ask AI... (Shift+Enter for newline, Cmd+V to paste image)"
	input_field.connect("gui_input", Callable(self, "_on_input_gui_input"))
	hbox.add_child(input_field)
	
	send_button = Button.new()
	send_button.text = "Send"
	send_button.connect("pressed", Callable(self, "_on_send_pressed"))
	hbox.add_child(send_button)
	
	# Test Connection Button
	var test_btn = Button.new()
	test_btn.text = "Test Connection"
	test_btn.connect("pressed", Callable(self, "_on_test_connection_pressed"))
	vbox.add_child(test_btn) # Add below input area

func _on_input_gui_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			if not event.shift_pressed:
				get_viewport().set_input_as_handled()
				_on_send_pressed()
		# Paste handling
		if event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
			# Defer to allow default paste first (for text), but we check for image
			call_deferred("_check_clipboard_for_image")

func _check_clipboard_for_image():
	var image = DisplayServer.clipboard_get_image()
	if image:
		_add_image_preview(image)

func _add_image_preview(image: Image):
	if image.is_empty():
		return
		
	# Check if generic icon or proper image? 
	# Godot clipboard_get_image works for copied bitmaps.
	
	pending_images.append(image)
	
	var texture = ImageTexture.create_from_image(image)
	var texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(64, 64)
	
	image_preview_container.add_child(texture_rect)
	# input_field.placeholder_text = "Image added! Type message..."

func _clear_images():
	pending_images.clear()
	for child in image_preview_container.get_children():
		child.queue_free()

func display_suggestion(text: String):
	output_log.add_text("\n\nAI: " + text)

func _on_send_pressed():
	var query = input_field.text
	if query.strip_edges().is_empty() and pending_images.is_empty():
		return
	
	var mode_idx = mode_selector.selected
	var mode_name = "Agent" if mode_idx == 1 else "Chat"
	
	output_log.add_text("\n\nUser (" + mode_name + "): " + query)
	if not pending_images.is_empty():
		output_log.add_text("\n[Attached " + str(pending_images.size()) + " image(s)]")
		
	output_log.add_text("\n(Sending to AI...)") # Feedback
	input_field.text = ""
	
	print("VibeCodingUI: Emitting request_analysis: ", query, " Mode: ", mode_name, " Images: ", pending_images.size())
	
	# Emit signal with all data
	emit_signal("request_analysis", query, mode_name, pending_images.duplicate())
	
	_clear_images()

func _on_test_connection_pressed():
	output_log.add_text("\n\nUser: [TEST CONNECTION]")
	output_log.add_text("\n(Testing connectivity...)")
	emit_signal("request_analysis", "TEST_PING", "Chat", [])
