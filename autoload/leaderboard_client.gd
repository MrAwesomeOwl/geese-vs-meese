extends Node
#const LB_SERVER_URL = "ws://localhost:57732/"
const LB_SERVER_URL = "wss://www.narda.net:5732/"
var client: WebSocketPeer

signal on_successfully_connected
signal on_disconnected
signal on_authenticated
signal _on_score_response(message: Dictionary)
signal _on_register_response(message: Dictionary)
signal _on_auth_response(message: Dictionary)
signal _on_connection_attempt_result(connection_successful: bool)
var is_connected_to_server := false
var authenticated_as_id: String = ""
var trying_to_connect := false

func get_scores(level_id: String) -> Array:
	send_packet({"type":"getScores","levelId":level_id})
	while true:
		var response = await _on_score_response
		if "failed" in response || response.type == "error":
			if "message" in response:
				return ["failed", response.message]
			else:
				return ["failed", "Server blew up"]
		elif response.levelId == level_id:
			return response.scores
			
	return []
	
## Returns {"failed":true} if registration was unsuccessful.
func register() -> Dictionary:
	if authenticated_as_id: return {"failed":true}
	send_packet({"type":"register"})
	while true:
		var response = await _on_register_response
		if response.type == "register": 
			authenticated_as_id = response.id
			on_authenticated.emit()
		return response
	return {}
	
func authenticate(id: String, token: String) -> Dictionary:
	if authenticated_as_id: return {"failed":true}
	send_packet({"type":"auth","id":id,"token":token})
	while true:
		var response = await _on_auth_response
		if response.type == "auth": 
			authenticated_as_id = response.id
			on_authenticated.emit()
		if response.type == "error": response.failed = true
		return response
	return {}
	
func send_packet(message: Dictionary):
	print("SENT PACKET:",message)
	client.put_packet(JSON.stringify(message).to_utf8_buffer())

func _handle_packet(message: Dictionary):
	print("GOT PACKET:",message)
	match message.type:
		"auth": _on_auth_response.emit(message)
		"getScores": _on_score_response.emit(message)
		"register": _on_register_response.emit(message)
		"error":
			if message.code == "invalidLevel":
				_on_score_response.emit(message)
			elif message.code == "invalidUser" || message.code == "invalidCredentials":
				_on_auth_response.emit(message)

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
		if !is_connected_to_server: 
			print("connected to server")
			is_connected_to_server = true
			on_successfully_connected.emit()
			trying_to_connect = false
			_on_connection_attempt_result.emit(true)
		while client.get_available_packet_count():
			_handle_packet(JSON.parse_string(client.get_packet().get_string_from_utf8()))
	else:
		if is_connected_to_server:
			print("connection to server lost")
			is_connected_to_server = false
			authenticated_as_id = ""
			_on_auth_response.emit({"failed":true})
			_on_register_response.emit({"failed":true})
			_on_score_response.emit({"failed":true})
			on_disconnected.emit()
			connect_to_server()
