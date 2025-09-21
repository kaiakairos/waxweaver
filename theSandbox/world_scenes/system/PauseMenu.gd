extends CanvasLayer

@onready var parent = get_parent()

func _ready():
	Steam.lobby_created.connect(_on_lobby_created) 
	
	if Network.isMultiplayerGame:
		# this means we've joined the lobby, rather than creating it. still wanna do the thing
		$lobbyID/Label2.text = "lobby id: " + str(Network.lobby_id)
		$lobbyID.show()

func _process(delta):
	var secsSinceSave = int( Time.get_unix_time_from_system() ) - int(parent.lastSave)
	$lastsave.text = "last saved: " + str(secsSinceSave) + "s ago"
	$MouseIcon.position = get_viewport().get_mouse_position()


func _on_savegame_pressed():
	parent.saveGameToFile()


func _on_unpause_pressed():
	get_tree().paused = false
	hide()
	$optionsMenu.hide()
	$PlayerList.show()
	$achievementsMenu.hide()


func _on_saveandquit_pressed():
	parent.saveGameToFile()
	get_tree().paused = false
	SoundManager.deleteAllSounds()
	
	if Network.isMultiplayerGame:
		
		Network.send_p2p_packet(Network.lobby_host,{"packetType":"inventory","data":PlayerData.inventory},2)
		await get_tree().create_timer(2.0).timeout
		Network.leave_lobby()
	
	get_tree().change_scene_to_file("res://ui_scenes/mainMenu/main_menu.tscn")



func _on_options_pressed():
	$optionsMenu.visible = !$optionsMenu.visible
	$PlayerList.visible = !$optionsMenu.visible


func _on_medals_pressed():
	$achievementsMenu.clear()
	$achievementsMenu.initializeAchievements()
	$achievementsMenu.show()


func _on_options_menu_menu_closed():
	$PlayerList.visible = true


func _on_create_lobby_menu_pressed():
	if Network.isMultiplayerGame:
		return
	
	$lobbyCreation.visible = !$lobbyCreation.visible

var lobbyType = Steam.LOBBY_TYPE_PUBLIC
var playersMax :int = 10
func _on_create_lobby_pressed():
	if Network.isMultiplayerGame:
		return
	Network.create_lobby(lobbyType,playersMax)
	$lobbyCreation.hide()
	_on_unpause_pressed()
	GlobalRef.sendChat("Lobby opened!")

func _on_visibility_pressed():
	if lobbyType == Steam.LOBBY_TYPE_FRIENDS_ONLY:
		lobbyType = Steam.LOBBY_TYPE_PUBLIC
		$lobbyCreation/visibility.forceChangeText("visibility: PUBLIC")
	else:
		lobbyType = Steam.LOBBY_TYPE_FRIENDS_ONLY
		$lobbyCreation/visibility.forceChangeText("visibility: FRIENDS ONLY")


func _on_player_slider_value_changed(value):
	playersMax = roundi(value)
	$"lobbyCreation/player count".text = str(playersMax)


func _on_copy_lobby_id_pressed():
	DisplayServer.clipboard_set(str(Network.lobby_id))
	GlobalRef.sendChat("Copied Lobby ID to clipboard!")

func _on_lobby_created(connect:int, this_lobby_id:int):
	if connect != 1:
		return
	
	$lobbyID/Label2.text = "lobby id: " + str(this_lobby_id)
	$lobbyID.show()
