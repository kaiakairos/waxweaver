extends Control

var lobbyID :int = 0

signal sendLobbyID(id:int)

func updateData(lobbyNewID:int,lobbyName:String,playerCount:int,playersMax:int,gamemode:String="normal",lobbyUsername:String="somebody's lobby"):
	
	$lobbyName.text = lobbyName
	$playerCount.text = str(playerCount) + " / " + str(playersMax) + "\n" + gamemode
	$lobbyUserName.text = lobbyUsername + "'s lobby"
	lobbyID = lobbyNewID


func _on_get_id_pressed():
	emit_signal("sendLobbyID",lobbyID)
