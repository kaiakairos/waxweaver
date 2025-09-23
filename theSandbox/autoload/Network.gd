extends Node

const PACKET_READ_LIMIT: int = 32
var is_host: bool = false

var lobby_id: int = 0

var lobby_members: Array = []
var lobby_members_max: int = 8
var lobby_host :int = 0

signal updatePlayerList
signal successfullyCreatedLobby
signal successfullyJoinedLobby
signal lobbyJoinFailure

signal leftLobby
signal playerLeft(member_id:int)

var createdLobbyData :Dictionary = {}

var recievedWorldPackets :Dictionary = {}

var isMultiplayerGame :bool = false

var multiplayerOpenedChests :Array= []

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created) # connects lobby created signal to function
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)

func _process(delta: float) -> void:
	if lobby_id > 0:
		read_all_p2p_packets()
	

func create_lobby(lobbyType,maxMembers):
	if lobby_id == 0: # dont create lobby if lobby already exists
		is_host = true
		Steam.createLobby(lobbyType,maxMembers)
		
		multiplayerOpenedChests = []

func _on_lobby_created(connect:int, this_lobby_id:int):
	if connect == 1: # connected 1 means OKAY!! https://godotsteam.com/classes/main/#result for more result options
		lobby_id = this_lobby_id
		
		Steam.setLobbyJoinable(lobby_id,true)
		
		for key in createdLobbyData.keys():
			Steam.setLobbyData(lobby_id,key,createdLobbyData[key])
		
		Steam.setLobbyData(lobby_id,"gamemode",Saving.getWorldTypeName())
		Steam.setLobbyData(lobby_id,"name",Saving.worldName)
		Steam.setLobbyData(lobby_id,"host",Steamworks.steam_username)
		
		print("Created Lobby with ID: " + str(lobby_id))
		emit_signal("successfullyCreatedLobby")
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		
		
		
		isMultiplayerGame = true
		
	else:
		print("Lobby creation failed: error code " + str(connect))

func join_lobby(this_lobby_id: int):
	leave_lobby() # attempt to leave any current lobby if joining a new one
	is_host = false
	Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		get_lobby_members()
		make_p2p_handshake()
		emit_signal("successfullyJoinedLobby")
		isMultiplayerGame = true
	else:
		emit_signal("lobbyJoinFailure")

func get_lobby_members():
	lobby_members.clear()
	
	var numOfMembers: int = Steam.getNumLobbyMembers(lobby_id)
	for member in range(0,numOfMembers):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id,member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id) # might not always work
		
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
	
	print("lobbymembers: " + str(lobby_members))
	emit_signal("updatePlayerList") 
	
	var newLobbyOwner = Steam.getLobbyOwner(lobby_id)
	if lobby_host == 0: # only run this when there's no host set
		is_host = newLobbyOwner == Steamworks.steam_id # check if we're now the host
		lobby_host = newLobbyOwner
	else:
		var hostInGame :bool= false
		for member in lobby_members:
			if member["steam_id"] == lobby_host:
				hostInGame = true
		if !hostInGame:
			get_tree().change_scene_to_file("res://ui_scenes/mainMenu/main_menu.tscn")
			leave_lobby()
			

func leave_lobby() -> void:
	
	isMultiplayerGame = false
	lobby_host = 0
	multiplayerOpenedChests = []
	
	if lobby_id == 0:
		return # do nothing if not in lobby 
	
	Steam.leaveLobby(lobby_id)
	lobby_id = 0
	for this_member in lobby_members:
		if this_member["steam_id"] == Steamworks.steam_id:
			continue # skip over ourselves
		Steam.closeP2PSessionWithUser(this_member["steam_id"])
	
	lobby_members.clear()
	emit_signal("leftLobby")

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	
	# This function will change whenever a player joins or leaves the lobby
	
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	var playerHasLeft := true
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
		playerHasLeft = false
		GlobalRef.sendChat("%s has joined the lobby." % changer_name)
		
		if is_host:
			hostSendWorld(change_id)
		
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
		GlobalRef.sendChat("%s has left the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
		GlobalRef.sendChat("%s has been kicked from the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)
		GlobalRef.sendChat("%s has been banned from the lobby." % changer_name)
	else:
		print("%s did... something." % changer_name)
		GlobalRef.sendChat("%s did... something." % changer_name)
	
	var newLobbyOwner = Steam.getLobbyOwner(lobby_id)
	if lobby_host == 0:
		is_host = newLobbyOwner == Steamworks.steam_id # check if we're now the host
		lobby_host = newLobbyOwner
	
	# Update the lobby now that a change has occurred
	get_lobby_members()
	if playerHasLeft:
		playerLeft.emit(change_id)
		
	
	

func send_p2p_packet(send_target: int,packet_data: Dictionary, send_type: int = 0):
	var channel :int = 0
	var data:PackedByteArray
	data.append_array( var_to_bytes(packet_data) ) # convert dictionary to bytes
	
	print("SENDING PACKET: " + str(packet_data))
	
	if send_target == 0: # 0 means send to every lobby member
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member["steam_id"] != Steamworks.steam_id: # don't send packets to ourselves!!
					Steam.sendP2PPacket(member["steam_id"],data, send_type, channel)
					
	else: # send to specific member instead, using that member's steam id
		Steam.sendP2PPacket(send_target,data, send_type, channel)

func _on_p2p_session_request(remote_id:int): # idk what this does
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	
	Steam.acceptP2PSessionWithUser(remote_id)

func make_p2p_handshake():
	send_p2p_packet(0, {"packetType": "handshake", "steam_id": Steamworks.steam_id, "username": Steamworks.steam_username})

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		print("Attempted to read " + str(read_count) + " packets, that's too many!!")
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1) # recursive function,, idk ??

func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size,0)
		
		var packet_sender: int = this_packet["remote_steam_id"] # gets remote steam ID
		
		var packet_code: PackedByteArray = this_packet["data"]
		var readable_data = bytes_to_var(packet_code)
		if readable_data == null:
			return # packet is invalid?
		
		interpretPacket(packet_sender,readable_data)

signal multiplayerWorldDataRecieved

func interpretPacket(sender:int,packet) -> void:
	var packetType :String = packet["packetType"]
	
	if packetType != "worldSend":
		print("RECIEVED PACKET: " + str(packet))
	else:
		print("RECIEVED WORLD PACKET: " + str(packet["step"]))
	
	if !is_instance_valid(GlobalRef.currentPlanet) and packetType != "worldSend":
		return
	
	match packetType:
		"worldSend":
			if sender != lobby_host:
				return # don't let random clients send this
			loadWorld(packet)
		"editTiles":
			GlobalRef.currentPlanet.recieveMultiplayerBlockUpdate(packet,sender)
		"playerMovement":
			if is_instance_valid(GlobalRef.system):
				if GlobalRef.system.checkIfPlayerExists(sender):
					if packet["type"] == "normal":
						GlobalRef.system.getFakePlayer(sender).getMovementPacket(packet)
					elif packet["type"] == "ladder":
						GlobalRef.system.getFakePlayer(sender).getLadderPacket(packet)
					elif packet["type"] == "chair":
						GlobalRef.system.getFakePlayer(sender).getChairPacket(packet)
		"updateArmor":
			if is_instance_valid(GlobalRef.system):
				if GlobalRef.system.checkIfPlayerExists(sender):
					GlobalRef.system.getFakePlayer(sender).setArmor(packet["helmet"],packet["chest"],packet["legs"])
		"syncTime":
			if !is_host:
				GlobalRef.globalTick = packet["tick"]
		"chestUpdate":
			GlobalRef.currentPlanet.chestDictionary[packet["chestPosition"]] = packet["chestStringData"]
		"chestState":
			var tile = packet["position"]
			if packet["newState"] == "closed":
				multiplayerOpenedChests.erase(tile)
			else: # opened
				if !multiplayerOpenedChests.has(tile):
					multiplayerOpenedChests.append(tile)
					# animation
					var ins = load("res://object_scenes/chest/chest_open.tscn").instantiate()
					ins.position = GlobalRef.currentPlanet.tileToPos(tile)
					ins.rot = GlobalRef.currentPlanet.DATAC.getPositionLookup(tile.x,tile.y)
					ins.body = GlobalRef.currentPlanet
					ins.pos = tile
					ins.multiplayerInstance = true
					GlobalRef.currentPlanet.entityContainer.add_child(ins)
		"chatMessage":
			if packet["type"] == "normal":
				GlobalRef.sendChat(packet["text"])
			else:
				GlobalRef.sendError(packet["text"])
		"playerDie":
			if GlobalRef.system.checkIfPlayerExists(sender):
				GlobalRef.system.getFakePlayer(sender).die()
		"dropItem":
			BlockData.spawnItemRaw(packet["tileX"],packet["tileY"],packet["item"],GlobalRef.currentPlanet,packet["amount"],true,packet["direction"])
		"inventory":
			if !is_host:
				return
			
			Saving.mutliplayerInventories[sender] = packet["data"]
		"armorStandUpdate":
			var pos :Vector2i = Vector2i(packet["posX"],packet["posY"])
			if !BlockData.armorStands.has(pos):
				return
			var armorStand = BlockData.armorStands[pos]
			if !is_instance_valid(armorStand):
				return
			
			armorStand.recievePacket(packet)
		"itemFrameUpdate":
			var pos :Vector2i = Vector2i(packet["posX"],packet["posY"])
			if !BlockData.itemFrames.has(pos):
				return
			var itemFrame = BlockData.itemFrames[pos]
			if !is_instance_valid(itemFrame):
				return
			
			itemFrame.recievePacket(packet)
		"waterAdd":
			GlobalRef.currentPlanet.DATAC.setWaterData(packet["posX"],packet["posY"],packet["amount"] * -1.0)
		"knockbackPlayer":
			if GlobalRef.system.checkIfPlayerExists(sender):
				GlobalRef.system.getFakePlayer(sender).getKnockedBack(packet)
		"healthUpgrade":
			if !is_host:
				return
			
			Saving.multiplayerHealths[sender] = packet["health"]
		
func loadWorld(data:Dictionary):
	
	#recievedWorldPackets
	var step :String = data["step"]
	match step:
		"tile": recievedWorldPackets["tile"] = data["data"]
		"bg": recievedWorldPackets["bg"] = data["data"]
		"info": recievedWorldPackets["info"] = data["data"]
		"time": recievedWorldPackets["time"] = data["data"]
		"water": recievedWorldPackets["water"] = data["data"]
		"chest": recievedWorldPackets["chest"] = data["data"]
		"globaltick": recievedWorldPackets["globaltick"] = data["data"]
		"inventory": 
			recievedWorldPackets["inventory"] = data["data"]
			recievedWorldPackets["health"] = data["health"]
	
	print(str(recievedWorldPackets.size()) + " world packets revieved")
	
	if recievedWorldPackets.size() < 8:
		return # world is yet to be loaded
	
	Saving.loadedFile = "multiplayer"
	
	# be sure to reset all data
	GlobalRef.playerSpawnPlanet = null
	GlobalRef.playerSpawn = null
	GlobalRef.clearEverything()
	PlayerData.initializeInventory()
	
	
	get_tree().change_scene_to_file("res://world_scenes/system/system.tscn")

func hostSendWorld(playerID:int = 0):
	
	if !is_instance_valid(GlobalRef.currentPlanet):
		printerr("Tried to send world data, but world data doesn't exist!")
		return
	
	
	await get_tree().create_timer(5.0).timeout

	print("sending world packets")

	var saveString :PackedStringArray= GlobalRef.currentPlanet.DATAC.getSaveString()
	# returns a set of strings that holds tile, bg, info, time, water
	var tileHex :String= var_to_bytes(saveString[0]).hex_encode()
	var bgHex :String= var_to_bytes(saveString[1]).hex_encode()
	var infoHex :String= var_to_bytes(saveString[2]).hex_encode()
	var timeHex :String= var_to_bytes(saveString[3]).hex_encode()
	var waterHex :String= var_to_bytes(saveString[4]).hex_encode()
	
	var chestHex :String= var_to_bytes(GlobalRef.currentPlanet.chestDictionary).hex_encode()
	
	
	send_p2p_packet(playerID,{"packetType":"worldSend","step":"tile","data":tileHex},2)
	
	await get_tree().create_timer(0.25).timeout
	
	send_p2p_packet(playerID,{"packetType":"worldSend","step":"bg","data":bgHex},2)
	
	await get_tree().create_timer(0.25).timeout
	
	send_p2p_packet(playerID,{"packetType":"worldSend","step":"info","data":infoHex},2)
	
	await get_tree().create_timer(0.25).timeout
	
	send_p2p_packet(playerID,{"packetType":"worldSend","step":"time","data":timeHex},2)
	
	await get_tree().create_timer(0.25).timeout
	
	send_p2p_packet(playerID,{"packetType":"worldSend","step":"water","data":waterHex},2)
	
	await get_tree().create_timer(0.25).timeout
	
	send_p2p_packet(playerID,{"packetType":"worldSend","step":"chest","data":chestHex},2)
	send_p2p_packet(playerID,{"packetType":"worldSend","step":"globaltick","data":GlobalRef.globalTick},2)
	
	if Saving.mutliplayerInventories.has(playerID):
		var h = 0
		if Saving.multiplayerHealths.has(playerID):
			h = Saving.multiplayerHealths[playerID]
		send_p2p_packet(playerID,{"packetType":"worldSend","step":"inventory","data":var_to_bytes(Saving.mutliplayerInventories[playerID]).hex_encode(),"health":h},2)
	else:
		send_p2p_packet(playerID,{"packetType":"worldSend","step":"inventory","data":"noData","health":0},2)

func checkIfPlayerInLobby(id:int):
	for member in lobby_members:
		if member["steam_id"] == id:
			return true
	return false


