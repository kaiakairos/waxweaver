extends Node2D
class_name System

@onready var objectContainer = $Objects
@onready var cosmicBodyContainer = $CosmicBodies

@onready var planetScene = preload("res://world_scenes/planet/planet.tscn")
@onready var fakePlayerScene = preload("res://object_scenes/fakePlayer/fake_player.tscn")
@onready var playerListItemScene = preload("res://ui_scenes/multiplayer/playerListItem/player_list_item.tscn")

@export var rootPlanet := Node2D

var planets = []

var planetsShouldGenerate = true

var autosaveTicks :float= 0
var lastSave :float= Time.get_unix_time_from_system()

var ticks :int= -600

var mainPlanet :Planet
var tickSync :float = 0.0

func _ready():
	planetsShouldGenerate = !Saving.has_save(Saving.loadedFile)
	
	if Saving.loadedFile == "multiplayer":
		planetsShouldGenerate = false 
	
	generateNewSystem()
	GlobalRef.system = self
	
	if Saving.worldType == 2:
		GlobalRef.cheatsEnabled = true
	
	$lightRenderViewport.world_2d = get_tree().root.get_viewport().world_2d
	$dropShadowViewport.world_2d = get_tree().root.get_viewport().world_2d
	GlobalRef.lightRenderVP = $lightRenderViewport
	GlobalRef.dropShadowRenderVP = $dropShadowViewport
	
	Network.connect("updatePlayerList",createPlayers)
	if Network.isMultiplayerGame:
		createPlayers()
		
	
	await get_tree().create_timer(5.0).timeout
	
	AchievementData.unlockMedal("openGame")

func generateNewSystem():
	
	GlobalRef.savedHealth = 100
	PlayerData.money = 0
	GlobalRef.cheatsEnabled = false
	
	for planet in cosmicBodyContainer.get_children():
		planet.queue_free()
	
	#Create sun
	var sun = planetScene.instantiate()
	sun.planetType = "sun"
	sun.SIZEINCHUNKS = 8
	sun.system = self
	cosmicBodyContainer.add_child(sun)
	rootPlanet = sun
	
	#  create Forest
	var forestPlanet = planetScene.instantiate()
	forestPlanet.planetType = "forest"
	forestPlanet.orbiting = sun
	forestPlanet.system = self
	forestPlanet.SIZEINCHUNKS = 96
	forestPlanet.orbitDistance = 36000.0
	forestPlanet.orbitSpeed = 3.0
	forestPlanet.orbitPeriod = randf_range(0.0,PI * 2) # where along the rotation is it
	
	mainPlanet = forestPlanet
	
	cosmicBodyContainer.add_child(forestPlanet)
	
	#  create moon
	var forestMoon = planetScene.instantiate()
	forestMoon.planetType = "lunar"
	forestMoon.orbiting = forestPlanet
	forestMoon.system = self
	forestMoon.SIZEINCHUNKS = 32
	forestMoon.orbitDistance = 8000.0
	forestMoon.orbitSpeed = 50.0
	forestMoon.orbitPeriod = randf_range(0.0,PI * 2) # where along the rotation is it
	
	cosmicBodyContainer.add_child(forestMoon)
	
	#  create arid planet
	#var aridPlanet = planetScene.instantiate()
	#aridPlanet.planetType = "arid"
	#aridPlanet.orbiting = sun
	#aridPlanet.system = self
	#aridPlanet.SIZEINCHUNKS = 64
	#aridPlanet.orbitDistance = 15000.0
	#aridPlanet.orbitSpeed = 4.0
	#aridPlanet.orbitPeriod = randf_range(0.0,PI * 2) # where along the rotation is it
	
	#cosmicBodyContainer.add_child(aridPlanet)
	
	# used for saving order
	planets.append(sun)
	planets.append(forestPlanet)
	planets.append(forestMoon)
	
	# halt
	if !planetsShouldGenerate:
		loadSaveFromFile()
	
	await get_tree().create_timer(0.1).timeout
	
	#Spawns player position
	if is_instance_valid(GlobalRef.player):
		GlobalRef.camera.map.map(self,cosmicBodyContainer.get_children())
	else:
		
		var player = load("res://object_scenes/player/player.tscn").instantiate()
		player.system = self
		objectContainer.add_child(player)
		
		var pee = forestPlanet.DATAC.findSpawnPosition(BlockData.theChunker.returnLookup())
		player.position = Vector2(pee) + forestPlanet.position
		player.attachToPlanet(forestPlanet)
		player.respawn()
	
		var children = cosmicBodyContainer.get_children()
		children.append(player)
		GlobalRef.camera.map.map(self,children)
		
		await get_tree().create_timer(0.1).timeout
		player.respawn()
		saveGameToFile()

func saveGameToFile():
	var gameData :Dictionary= {} # will hold all data
	var planetDictionary :Array = [] # will hold the data for planets
	var chestDictionary :Array = [] # will hold planet chest data
	
	for planet in planets: # parse over all planets
		var saveString :PackedStringArray= planet.DATAC.getSaveString()
		var hex :String= var_to_bytes(saveString).hex_encode() # compact string
		planetDictionary.append( hex )
		
		var chest = planet.chestDictionary
		var chestHex :String= var_to_bytes(chest).hex_encode() # compact string
		chestDictionary.append( chestHex )
	
	gameData["version"] = GlobalRef.version
	gameData["versionEra"] = 1 # 0:alpha, 1:release
	gameData["planets"] = planetDictionary
	gameData["chests"] = chestDictionary
	gameData["playerInventory"] = var_to_bytes(PlayerData.inventory).hex_encode()
	gameData["playerHealth"] = GlobalRef.player.healthComponent.health
	gameData["playtime"] = GlobalRef.globalTick
	gameData["worldname"] = Saving.worldName
	gameData["worldType"] = Saving.worldType
	gameData["cheats"] = GlobalRef.cheatsEnabled
	gameData["mimicsSpawnable"] = GlobalRef.playerHasInteractedWithChest
	if GlobalRef.playerSpawnPlanet != null:
		gameData["spawnPlanet"] = planets.find(GlobalRef.playerSpawnPlanet) # gets planet id
		gameData["spawnpoint"] = var_to_str(GlobalRef.playerSpawn)
	
	gameData["claimedPraffinBossPrize"] = GlobalRef.claimedPraffinBossPrize
	gameData["claimedWormBossPrize"] = GlobalRef.claimedWormBossPrize
	gameData["claimedFinalBossPrize"] = GlobalRef.claimedFinalBossPrize
	
	gameData["money"] = PlayerData.money
	gameData["shopItems"] = Saving.shopItems
	
	gameData["mutliplayerInventories"] = var_to_bytes(Saving.mutliplayerInventories).hex_encode()
	
	Saving.write_save(Saving.loadedFile,gameData)
	
	lastSave = Time.get_unix_time_from_system() # keep track of time elapsed
	
	PlayerData.emit_signal("updateInventory")
	PlayerData.emit_signal("armorUpdated")
	
func loadSaveFromFile():
	
	if Saving.loadedFile == "multiplayer":
		multiplayerWorldLoad()
		return
	
	var gameData = Saving.read_save( Saving.loadedFile )
	if gameData == null:
		printerr( "Failed to load save, save file doesn't exist." )
		return
	
	var planetDic :Array = gameData["planets"]
	var chestDic :Array = gameData["chests"]
	var id :int= 0
	for planet in planets: # parse over all planets
		
		# planet data
		var decoded :PackedByteArray = planetDic[id].hex_decode()
		var pldt :PackedStringArray = bytes_to_var(decoded)
		planet.DATAC.loadFromString(pldt[0],pldt[1],pldt[2],pldt[3],pldt[4])
		if planet == GlobalRef.currentPlanet:
			planet.forceChunkDrawUpdate()
			
		# chest data
		var chestDecoded :PackedByteArray = chestDic[id].hex_decode()
		var chstdt :Dictionary = bytes_to_var(chestDecoded)
		planet.chestDictionary = chstdt.duplicate()
		
		id += 1
	
	# inventory
	PlayerData.inventory = bytes_to_var(gameData["playerInventory"].hex_decode())
	
	# spawnpoint
	if gameData.has("spawnpoint"):
		GlobalRef.playerSpawnPlanet = planets[ gameData["spawnPlanet"] ] # gets planet id
		GlobalRef.playerSpawn = str_to_var(gameData["spawnpoint"])
	
	#time
	GlobalRef.globalTick = gameData["playtime"]
	if gameData.has("worldname"):
		Saving.worldName = gameData["worldname"]
	
	if gameData.has("worldType"):
		Saving.worldType = gameData["worldType"]
	else:
		Saving.worldType = 0
	
	# player health
	GlobalRef.savedHealth = gameData["playerHealth"]
	if GlobalRef.savedHealth <= 0:
		GlobalRef.savedHealth = 60
		if Saving.worldType == 1:
			GlobalRef.savedHealth = 0
	
	if gameData.has("claimedPraffinBossPrize"):
		GlobalRef.claimedPraffinBossPrize = gameData["claimedPraffinBossPrize"]
		GlobalRef.claimedWormBossPrize = gameData["claimedWormBossPrize"]
		GlobalRef.claimedFinalBossPrize = gameData["claimedFinalBossPrize"]
	else:
		GlobalRef.claimedPraffinBossPrize = false
		GlobalRef.claimedWormBossPrize = false
		GlobalRef.claimedFinalBossPrize = false
	
	if gameData.has("shopItems"):
		Saving.shopItems = gameData["shopItems"]
	else:
		Saving.shopItems = []
	
	# cheats
	GlobalRef.cheatsEnabled = gameData["cheats"]
	if Saving.worldType == 2: # is creative
		GlobalRef.commandLineAvailable = true
		GlobalRef.cheatsEnabled = true
	
	# game data
	GlobalRef.playerHasInteractedWithChest = gameData["mimicsSpawnable"]
	
	if gameData.has("money"):
		PlayerData.money = gameData["money"]
	else:
		PlayerData.money = 0
	
	if gameData.has("mutliplayerInventories"):
		Saving.mutliplayerInventories = bytes_to_var( gameData["mutliplayerInventories"].hex_decode() )
	
	PlayerData.emit_signal("updateInventory")
	PlayerData.emit_signal("armorUpdated")
	
func posToTile(pos):
	# just ensures anything emitted into the main system doesnt crash
	return null

func _exit_tree():
	
	$lightRenderViewport.world_2d = null
	$dropShadowViewport.world_2d = null
	
	saveGameToFile()

func _process(delta):
	if Options.options["autosaving"]:
		autosaveTicks += delta
	if autosaveTicks > 180.0: # every 3 minutes
		if GlobalRef.player.velocity.length() < 2.0: # make sure player is standing still
			Saving.autosave()
			autosaveTicks = 0.0
			print("Game autosaved!")
	
	if Input.is_action_just_pressed("pause"):
		if GlobalRef.hotbar.cheatOrigin.visible:
			return
		get_tree().paused = !get_tree().paused
		$PauseMenu.visible = get_tree().paused
		
		$PauseMenu/optionsMenu.hide()
		$PauseMenu/achievementsMenu.hide()

	ticks += 1
	if ticks % 300 == 0:
		if GlobalRef.player.position.length() < 64:
			AchievementData.unlockMedal("findCore")
	
	if Input.is_action_just_pressed("fullscreen"):
		fullscreentoggle()
	
	# multiplayer
	if Network.isMultiplayerGame and Network.is_host:
		tickSync += delta
		if tickSync > 200.0:
			Network.send_p2p_packet(0,{"packetType":"syncTime","tick":GlobalRef.globalTick})
			tickSync = 0.0
	
func fullscreentoggle():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	

func multiplayerWorldLoad():
	var worldData :Dictionary= Network.recievedWorldPackets
	
	var tile :String =  bytes_to_var(worldData["tile"].hex_decode())
	var bg :String =  bytes_to_var(worldData["bg"].hex_decode())
	var info :String =  bytes_to_var(worldData["info"].hex_decode())
	var time :String =  bytes_to_var(worldData["time"].hex_decode())
	var water :String =  bytes_to_var(worldData["water"].hex_decode())
	var chest :Dictionary =  bytes_to_var(worldData["chest"].hex_decode())
	mainPlanet.DATAC.loadFromString(tile,bg,info,time,water)
	mainPlanet.chestDictionary = chest.duplicate()
	
	GlobalRef.globalTick = worldData["globaltick"]
	
	if worldData["inventory"] == "noData":
		PlayerData.addItem(3000,1)
		PlayerData.addItem(3001,1)
	else:
		PlayerData.inventory = bytes_to_var(worldData["inventory"].hex_decode())
	
	PlayerData.emit_signal("updateInventory")
	PlayerData.emit_signal("armorUpdated")
	
	Network.recievedWorldPackets = {} # clear it
	
	Saving.setWorldType(Steam.getLobbyData(Network.lobby_id,"gamemode"))

var fakePlayerDictionary :Dictionary

func createPlayers():
	var playerIDs = []
	for player in Network.lobby_members:
		playerIDs.append(player["steam_id"])
		if player["steam_id"] == Steamworks.steam_id:
			continue # don't make a player for ourselves
		if checkIfPlayerExists(player["steam_id"]):
			continue # don't recreate existing players
		
		var fakePlayer = fakePlayerScene.instantiate()
		fakePlayer.steam_ID = player["steam_id"]
		fakePlayer.planet = mainPlanet
		fakePlayer.steam_name = player["steam_name"]
		mainPlanet.entityContainer.add_child(fakePlayer)
		
		fakePlayerDictionary[ player["steam_id"] ] = fakePlayer
	
	# clear non-existant players
	for fakePlayerID in fakePlayerDictionary.keys():
		if playerIDs.has(fakePlayerID):
			continue
		getFakePlayer(fakePlayerID).queue_free()
		fakePlayerDictionary.erase(fakePlayerID)
	
	# list
	for child in $PauseMenu/PlayerList/vbox.get_children():
		child.queue_free() # just clear the player list 
	
	for player in Network.lobby_members:
		var ins = playerListItemScene.instantiate()
		ins.playerID = player["steam_id"]
		ins.username = player["steam_name"]
		$PauseMenu/PlayerList/vbox.add_child(ins)
	

func checkIfPlayerExists(id:int):
	return fakePlayerDictionary.has(id)

func getFakePlayer(id:int):
	return fakePlayerDictionary[ id ]

