extends Node3D

var xr_interface: XRInterface
var socket = WebSocketPeer.new()

# Vervang dit IP-adres door het daadwerkelijke IP-adres van jouw ESP32 op je netwerk
var robot_url = "ws://192.168.1.100:81"

func _ready():
	# 1. Start OpenXR voor de Quest 3
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR succesvol gestart!")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR kon niet worden geïnitialiseerd (normaal als je op je PC test zonder headset).")

	# 2. Start de WebSocket verbinding met de robot
	var err = socket.connect_to_url(robot_url)
	if err != OK:
		print("Fout bij opzetten WebSocket verbinding.")
	else:
		print("Verbinden met robot op: ", robot_url)

func _process(delta):
	# Houd de verbinding live en luister naar data van de robot
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var message = packet.get_string_from_utf8()
			print("Bericht van robot: ", message)
			
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("Verbinding gesloten. Code: %d, Reden: %s" % [code, reason])

# Functie die je straks kunt aanroepen als je een knop indrukt in VR om de robot te bewegen
func send_command_to_robot(command: String):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(command)
		print("Verzonden naar robot: ", command)
	else:
		print("Kan niet verzenden: Geen actieve verbinding met de robot.")
