extends Node2D

var searchingForLobbyList :bool = false
@onready var lobbyListItemScene = preload("res://ui_scenes/multiplayer/lobbyListItem/lobby_list_item.tscn")

func _ready():
	Steam.connect("lobby_match_list",interpretLobbies)
	Network.connect("lobbyJoinFailure",lobbyFailure)

func getLobbyList():
	if searchingForLobbyList:
		print("I'm still searching! be patient !!")
		return
	
	for i in $NinePatchRect/ScrollContainer/VBoxContainer.get_children():
		i.queue_free()
	
	$previewText.text = "Loading lobbies..."
	
	searchingForLobbyList = true
	
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE) # makes lobby search worldwide
	Steam.requestLobbyList()


func interpretLobbies(lobbies) -> void:
	searchingForLobbyList = false
	
	$previewText.visible = lobbies.size() == 0
	
	if lobbies.size() == 0:
		$previewText.text = "no public lobbies :("
		return
	
	for lobbyID in lobbies:
		var ins = lobbyListItemScene.instantiate()
		var lobbyName :String = Steam.getLobbyData(lobbyID,"name")
		var lobbyPlayerCurrent :int = Steam.getNumLobbyMembers(lobbyID)
		var lobbyPlayerMax :int = Steam.getLobbyMemberLimit(lobbyID)
		
		var gamemode :String = Steam.getLobbyData(lobbyID,"gamemode")
		var host :String = Steam.getLobbyData(lobbyID,"host")
		
		ins.updateData(lobbyID,lobbyName,lobbyPlayerCurrent,lobbyPlayerMax,gamemode,host)
		ins.connect("sendLobbyID",placeIDInBox)
		$NinePatchRect/ScrollContainer/VBoxContainer.add_child(ins)


func placeIDInBox(id:int):
	$textEdit.text = str(id)

func _on_join_from_id_pressed():
	
	Network.join_lobby( $textEdit.text.to_int() )
	hide()
	$"../joiningLobby".show()


func _on_text_edit_text_changed():
	var newString :String = $textEdit.text
	var r :Array[String] = ["0","1","2","3","4","5","6","7","8","9"]
	var newestString :String = ""
	for i in range(newString.length()):
		var char =  newString.substr(i,1)
		if r.has(char):
			newestString = newestString + char
	$textEdit.text = newestString
	$textEdit.set_caret_column(newestString.length())

func lobbyFailure():
	var h = $textEdit.text
	$textEdit.text = "Failed to join lobby..."
	await get_tree().create_timer(3.0).timeout
	if $textEdit.text == "Failed to join lobby...":
		$textEdit.text = h


func _on_reload_button_pressed():
	getLobbyList()
