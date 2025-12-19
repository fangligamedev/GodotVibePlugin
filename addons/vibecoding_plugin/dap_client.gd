@tool
extends Node

signal scene_tree_updated(tree_data)
signal object_properties_updated(object_id, properties)
signal debug_paused(reason, thread_id, frame_id)
signal log_message(type, message)

var _tcp_client: StreamPeerTCP
var _status: int = StreamPeerTCP.STATUS_NONE
var _stream: StreamPeerTCP
var _connected: bool = false
const DAP_PORT = 6006 # Default Godot DAP port

func _ready():
	_tcp_client = StreamPeerTCP.new()

func connect_to_godot_dap_server():
	var err = _tcp_client.connect_to_host("127.0.0.1", DAP_PORT)
	if err != OK:
		printerr("VibeCoding: Failed to connect to DAP server on port ", DAP_PORT)
		return
	
	_status = _tcp_client.get_status()
	print("VibeCoding: Connecting to DAP server...")
	set_process(true)

func disconnect_from_godot_dap_server():
	if _tcp_client:
		_tcp_client.disconnect_from_host()
	_connected = false
	print("VibeCoding: Disconnected from DAP server.")

func _process(delta):
	_tcp_client.poll()
	var new_status = _tcp_client.get_status()
	
	if new_status != _status:
		_status = new_status
		match _status:
			StreamPeerTCP.STATUS_CONNECTED:
				print("VibeCoding: Connected to DAP server!")
				_connected = true
				_on_connected()
			StreamPeerTCP.STATUS_ERROR:
				printerr("VibeCoding: DAP connection error.")
			StreamPeerTCP.STATUS_NONE:
				print("VibeCoding: DAP disconnected.")
				_connected = false

	if _connected and _tcp_client.get_available_bytes() > 0:
		_read_data()

func _on_connected():
	# Send initialization request (simplified)
	var init_req = {
		"seq": 1,
		"type": "request",
		"command": "initialize",
		"arguments": {
			"adapterID": "godot",
			"clientID": "vibecoding_plugin",
			"clientName": "VibeCoding Plugin"
		}
	}
	_send_dap_message(init_req)

func _read_data():
	# Simplified reading logic - assumes full messages for now
	# In production, this needs proper Content-Length parsing
	var data = _tcp_client.get_utf8_string(_tcp_client.get_available_bytes())
	if data.is_empty(): 
		return

	# Iterate over lines for simpler parsing if multiple messages come
	# This is vastly simplified. Debug Adapter Protocol uses Content-Length headers.
	# For prototype, we assume we might get raw JSON or lines.
	# Proper implementation requires a state machine for parsing headers + body.
	print("VibeCoding: Received DAP data: ", data)
	
	# Mock parsing logic to trigger signals
	# In real implementation: Parse 'Content-Length: ... \r\n\r\n{json}'
	pass

func _send_dap_message(data: Dictionary):
	var json_str = JSON.stringify(data)
	var content_length = json_str.length()
	var header = "Content-Length: %d\r\n\r\n" % content_length
	_tcp_client.put_data(header.to_ascii_buffer())
	_tcp_client.put_data(json_str.to_ascii_buffer())

# Public API for Plugin to request data
func request_scene_tree():
	# Generic request structure
	pass

func request_object_properties(object_id):
	pass
