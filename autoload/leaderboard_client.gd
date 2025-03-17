extends Node
const LB_SERVER_URL = "ws://localhost:57732/"
var client: WebSocketPeer

signal on_successfully_connected
signal on_disconnected
signal _on_score_response(message: Dictionary)
signal _on_register_response(message: Dictionary)
signal _on_auth_response(message: Dictionary)
signal _on_connection_attempt_result(connection_successful: bool)
var connection_open := false
var authenticated_as_id: String = ""
var trying_to_connect := false

func get_scores(level_id: String) -> Array[Array]:
	send_packet({"type":"getScores","levelId":level_id})
	while true:
		var response = await _on_score_response
		if response.type == "error":
			return []
		elif response.levelId == level_id:
			return response.scores
			
	return []
	
## Returns {"failed":true} if registration was unsuccessful.
func register() -> Dictionary:
	if authenticated_as_id: return {"failed":true}
	send_packet({"type":"register"})
	while true:
		var response = await _on_register_response
		if response.type == "register": authenticated_as_id = response.id
		return response
	return {}
	
func authenticate(id: String, token: String) -> Dictionary:
	if authenticated_as_id: return {"failed":true}
	send_packet({"type":"auth","id":id,"token":token})
	while true:
		var response = await _on_auth_response
		if response.type == "auth": authenticated_as_id = response.id
		if response.type == "error": response.failed = true
		return response
	return {}
	
func send_packet(message: Dictionary):
	print("SEND PACKET:",message)
	client.put_packet(JSON.stringify(message).to_utf8_buffer())

func _handle_packet(message: Dictionary):
	match message.type:
		"auth": _on_auth_response.emit(message)
		"getScores": _on_score_response.emit(message)
		"register": _on_register_response.emit(message)
		"error":
			if message.code == "invalidLevel":
				_on_score_response.emit(message)
			elif message.code == "invalidUser" || message.code == "invalidCredentials":
				_on_auth_response.emit(message)
	print("GOT PACKET:",message)

# Called when the node enters the scene tree for the first time.
func connect_to_server() -> void:
	client = WebSocketPeer.new()
	var this_client = client
	while true:
		if client != this_client: break
		trying_to_connect = true
		client.connect_to_url(LB_SERVER_URL)
		if (await  _on_connection_attempt_result == true):
			break
		await Util.wait(5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	client.poll()
	
	if trying_to_connect && client.get_ready_state() == client.STATE_CLOSED:
		trying_to_connect = false
		_on_connection_attempt_result.emit(false)
	
	var state = client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if !connection_open: 
			print("connected to server")
			connection_open = true
			on_successfully_connected.emit()
			trying_to_connect = false
			_on_connection_attempt_result.emit(true)
		while client.get_available_packet_count():
			_handle_packet(JSON.parse_string(client.get_packet().get_string_from_utf8()))
	else:
		if connection_open:
			print("connection to server lost")
			connection_open = false
			authenticated_as_id = ""
			_on_auth_response.emit({"failed":true})
			_on_register_response.emit({"failed":true})
			_on_score_response.emit({"failed":true})
			on_disconnected.emit()
			connect_to_server()
