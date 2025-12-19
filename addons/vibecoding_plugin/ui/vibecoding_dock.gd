@tool
extends Control

signal request_analysis(query)

var output_log: RichTextLabel
var input_field: TextEdit
var send_button: Button

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
	
	# Output area for LLM suggestions
	output_log = RichTextLabel.new()
	output_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_log.text = "[b]VibeCoding AI Ready.[/b]\n\nWaiting for input..."
	output_log.bbcode_enabled = true
	output_log.fit_content = false 
	output_log.scroll_active = true
	output_log.selection_enabled = true # Allow copying text
	vbox.add_child(output_log)
	
	vbox.add_child(HSeparator.new())
	
	# Input area
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)
	
	input_field = TextEdit.new()
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.custom_minimum_size = Vector2(0, 80) # Increased height
	input_field.placeholder_text = "Ask AI... (Shift+Enter for new line)"
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
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if not event.shift_pressed:
			get_viewport().set_input_as_handled()
			_on_send_pressed()

func display_suggestion(text: String):
	output_log.add_text("\n\nAI: " + text)

func _on_send_pressed():
	var query = input_field.text
	if query.strip_edges().is_empty():
		return
	
	output_log.add_text("\n\nUser: " + query)
	output_log.add_text("\n(Sending to AI...)") # Feedback
	input_field.text = ""
	
	print("VibeCodingUI: Emitting request_analysis: ", query)
	emit_signal("request_analysis", query)

func _on_test_connection_pressed():
	output_log.add_text("\n\nUser: [TEST CONNECTION]")
	output_log.add_text("\n(Testing connectivity...)")
	emit_signal("request_analysis", "TEST_PING")
