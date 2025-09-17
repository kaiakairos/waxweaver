extends Node2D
class_name Planet

var system = null

@export var planetType : String = "forest"
@export var SIZEINCHUNKS :int = 16 # (size * 8)^2 = number of tiles

@onready var DATAC = $PLANETDATA

@onready var chunkContainer = $ChunkContainer
@onready var entityContainer = $EntityContainer

@export var mass := 10000.0
@export var orbiting : Node2D
@export var orbitSpeed :float = 0.0001
@export var orbitDistance :int = 0
var orbitPeriod = 0
var orbitReverse = false
var orbitVelocity = Vector2.ZERO

var chunkScene = preload("res://world_scenes/chunk/chunk.tscn")

var centerPoint = Vector2.ZERO

#Noise
var noise = FastNoiseLite.new()

var tick = 0

var chunkDictionary = {}

var tickAlive = 0

signal doneEditingTiles

# Chest Data
var chestDictionary :Dictionary= {}

var planetTypeOverride :String = ""

func _ready():
	
	if orbiting != null:
		position = orbiting.position + Vector2(orbitDistance,0).rotated(orbitPeriod)
		position.x = int(position.x)
		position.y = int(position.y)
	
	
	set_physics_process(false)
	generateEmptyArray()
	noise.seed = randi()
	if system.planetsShouldGenerate:
		generateTerrain()
		
		for i in range(20): # pregenerate structures
			var structures :Dictionary= DATAC.pregenerateStrucutres( BlockData.getLookup() )
			if structures.is_empty():
				return
			
			editTiles(structures)
			#print("\nROLL " + str(i + 1))
			#print(structures)
		
	
########################################################################
############################## ORBITING ################################
########################################################################

func _process(delta):
	##Orbit##
	
	if orbiting != null and tickAlive > 240:
		
		var posHold = position
		
		if !orbitReverse:
			orbitPeriod += orbitSpeed * 0.0001 * (delta*60)

			position = orbiting.position + Vector2(orbitDistance,0).rotated(orbitPeriod)
			position.x = int(position.x)
			position.y = int(position.y)
			
			orbitVelocity = position - posHold
		else:
			
			posHold = orbiting.position
			
			orbitPeriod += orbitSpeed * 0.0001 * (delta*60)
		
			orbiting.position = position + Vector2(-orbitDistance,0).rotated(orbitPeriod)
			orbiting.position.x = int(orbiting.position.x)
			orbiting.position.y = int(orbiting.position.y)
		
			orbitVelocity = orbiting.position - posHold
		
		if orbitPeriod > PI * 2:
			orbitPeriod -= (PI * 2)
	
	tickAlive += 1
		
func reverseOrbitingParents():
	if orbiting == null:
		return
	orbitReverse = true
	orbiting.reverseOrbitingParents()

func clearOrbitingParents():
	orbitReverse = false
	if orbiting != null:
		orbiting.clearOrbitingParents()

########################################################################
########################## CHUNK SIMULATION ############################
########################################################################

func _physics_process(delta):
	tick += 1
	DATAC.setGlobalTick(GlobalRef.globalTick)
	#var shouldUpdateLight = 0
	for key in chunkDictionary:
		var chunk = chunkDictionary[key]
		if tick % 4 != chunk.id4:
			continue
		
		var changesArray = chunk.tickUpdate()
		var committedChanges = changesArray[1]
		
		if changesArray[0]:
			chunk.drawLiquid()
		
		#Updates light
		#shouldUpdateLight += int(chunk.MUSTUPDATELIGHT)
		chunk.MUSTUPDATELIGHT = false
		
		if committedChanges.size() > 0:
			editTiles(committedChanges)
	
	#if shouldUpdateLight > 0 and is_instance_valid(GlobalRef.player):
	GlobalRef.player.updateLightStatic()

func editTiles(changeCommit,doneByPlayer:bool=false,multiplayer_from:int=0):
	var chunksToUpdate = []
	
	for change in changeCommit.keys():
		var c = changeCommit[change]
		if c is String:
			BlockData.doBlockAction(c,change.x,change.y,self)
			if BlockData.aestheticCommands.has(c):
				changeCommit.erase(change) # remove strings for multiplayer
			continue
		match c:
			-1:
				var save:int = DATAC.getTileData(change.x,change.y)
				DATAC.setTileData(change.x,change.y,airOrCaveAir(change.x,change.y))
				BlockData.breakBlock(change.x,change.y,self,save,DATAC.getInfoData(change.x,change.y),doneByPlayer)
				DATAC.setInfoData(change.x,change.y,0)
				DATAC.setTimeData(change.x,change.y,GlobalRef.globalTick)
				
				if chestDictionary.has(Vector2(change.x,change.y)):
					var p = Vector2(change.x,change.y)
					PlayerData.dropChestContainer(self,p,chestDictionary[p])
					chestDictionary.erase(p)
				
			0:
				DATAC.setTileData(change.x,change.y,airOrCaveAir(change.x,change.y))
				DATAC.setTimeData(change.x,change.y,GlobalRef.globalTick)
				DATAC.setInfoData(change.x,change.y,0)
			-99999:
				var save:int = DATAC.getBGData(change.x,change.y)
				DATAC.setBGData(change.x,change.y,0)
				BlockData.breakWall(change.x,change.y,self,save)
			_: #Default
				if c < -1:
					DATAC.setBGData(change.x,change.y,abs(c))
				else:
					DATAC.setTileData(change.x,change.y,c)
					if doneByPlayer:
						DATAC.setTimeData(change.x,change.y,GlobalRef.globalTick)
		
		var chunkVector = Vector2( change.x/8 , change.y/8 )
		if !chunksToUpdate.has(chunkVector):
			chunksToUpdate.append(chunkVector)
		
		#Theres gotta be a way to clean this up
		var morganfreemansayingtrue := false
		if int(change.x) % 8 == 0:
			if !chunksToUpdate.has(chunkVector + Vector2( -1 , 0 )):
				chunksToUpdate.append(chunkVector + Vector2( -1 , 0 ))
			morganfreemansayingtrue = true
		elif int(change.x) % 8 == 7:
			if !chunksToUpdate.has(chunkVector + Vector2( 1 , 0 )):
				chunksToUpdate.append(chunkVector + Vector2( 1 , 0 ))
			morganfreemansayingtrue = true
		if int(change.y) % 8 == 0:
			if !chunksToUpdate.has(chunkVector + Vector2( 0 , -1 )):
				chunksToUpdate.append(chunkVector + Vector2( 0 , -1 ))
			morganfreemansayingtrue = true
		elif int(change.y) % 8 == 7:
			if !chunksToUpdate.has(chunkVector + Vector2( 0 , 1 )):
				chunksToUpdate.append(chunkVector + Vector2( 0 , 1 ))
			morganfreemansayingtrue = true
		
		if c < -1:
			if morganfreemansayingtrue:
				if !chunksToUpdate.has(chunkVector + Vector2( 1 , 1 )):
					chunksToUpdate.append(chunkVector + Vector2( 1 , 1 ))
				if !chunksToUpdate.has(chunkVector + Vector2( -1 , 1 )):
					chunksToUpdate.append(chunkVector + Vector2( -1 , 1 ))
				if !chunksToUpdate.has(chunkVector + Vector2( 1 , -1 )):
					chunksToUpdate.append(chunkVector + Vector2( 1 , -1 ))
				if !chunksToUpdate.has(chunkVector + Vector2( -1 , -1 )):
					chunksToUpdate.append(chunkVector + Vector2( -1 , -1 ))
	
	for vec in chunksToUpdate:
		if chunkDictionary.has(vec):
			chunkDictionary[vec].drawData()
	
	if Network.isMultiplayerGame and multiplayer_from == 0:
		if changeCommit.size() == 0:
			return
		sendMultiplayerBlockUpdate(changeCommit,doneByPlayer)
		

func sendMultiplayerBlockUpdate(changeCommit,doneByPlayer):
	
	var infoDictionary = {}
	var timeDictionary = {}
	
	for changeKey in changeCommit.keys():
		infoDictionary[changeKey] = DATAC.getInfoData(changeKey.x,changeKey.y) 
		timeDictionary[changeKey] = DATAC.getTimeData(changeKey.x,changeKey.y) 
	
	Network.send_p2p_packet(0,{"packetType":"editTiles",
	"changes":changeCommit,
	"infoChange":infoDictionary,"timeChange":timeDictionary,
	"doneByPlayer":doneByPlayer})

func recieveMultiplayerBlockUpdate(packetData,sender:int):
	
	var infoDictionary :Dictionary = packetData["infoChange"]
	var timeDictionary :Dictionary = packetData["timeChange"]
	
	for changeKey in packetData["changes"].keys():
		DATAC.setInfoData(changeKey.x,changeKey.y,infoDictionary[changeKey]) 
		DATAC.setTimeData(changeKey.x,changeKey.y,timeDictionary[changeKey]) 
	
	editTiles(packetData["changes"],packetData["doneByPlayer"],sender)
	
func setLight(x,y,level): ## Useful for settings dynamic moving lights
	var currentLight = DATAC.getLightData(x,y)
	if level >= abs(currentLight):
		DATAC.setLightData(x,y,level * -1.0)


########################################################################
############################ GENERATION ################################
########################################################################

func generateEmptyArray():
	centerPoint = Vector2(SIZEINCHUNKS*4,SIZEINCHUNKS*4) - Vector2(0.5,0.5)
	
	var s := SIZEINCHUNKS*8
	
	DATAC.createEmptyArrays(s,centerPoint)

func generateTerrain():
	
	match Saving.worldName:
		"skyblock":
			BlockData.theGenerator.generateLunarPlanet(DATAC,noise)
			return
		"lattice":
			BlockData.theGenerator.generateLatticePlanet(DATAC,noise)
			return
		"skyblockhardcore":
			BlockData.theGenerator.generateLunarPlanet(DATAC,noise)
			return
		"latticehardcore":
			BlockData.theGenerator.generateLatticePlanet(DATAC,noise)
			return
	
	match planetType:
		"forest":BlockData.theGenerator.generateForestPlanet(DATAC,noise)
	
	return

func loadChunkArea(pos):
	var radius :int = 11
	var cool = []
	for x in range(radius):
		for y in range(radius):
			var trueCoords :Vector2 = pos + Vector2( x - (radius/2) , y - (radius/2) )
			
			if trueCoords.x != clamp(trueCoords.x,0,SIZEINCHUNKS-1):
				continue
			if trueCoords.y != clamp(trueCoords.y,0,SIZEINCHUNKS-1):
				continue
			
			if !chunkDictionary.has(trueCoords):
				var ins = chunkScene.instantiate()
				ins.position = trueCoords
				chunkDictionary[trueCoords] = ins
				chunkContainer.add_child(ins)
			
			cool.append(trueCoords)
	
	for chunk in chunkDictionary.keys():
		if !cool.has(chunk):
			chunkDictionary[chunk].queue_free()
			chunkDictionary.erase(chunk)
			#await get_tree().create_timer(0.1).timeout
	
	
func clearChunks():
	set_physics_process(false)

	chunkContainer.queue_free()
	var new = Node2D.new()
	add_child(new)
	chunkContainer = new
	move_child(chunkContainer,1)
	
	chunkDictionary = {}
	
########################################################################
################################ MATH ##################################
########################################################################

func getBlockPosition(x,y):
	var angle1 = Vector2(1,1)
	var angle2 = Vector2(-1,1)
	var newPos = Vector2(x,y) - centerPoint
	
	var dot1 = int(newPos.dot(angle1) >= 0)
	var dot2 = int(newPos.dot(angle2) > 0) * 2
	
	return [0,1,3,2][dot1 + dot2]

func getBlockDistance(x,y):
	var quadtrant = DATAC.getPositionLookup(x,y)
	var newPos = Vector2(x,y) - centerPoint
	newPos = newPos.rotated((PI/2)*-quadtrant)
	return -newPos.y

func getBlockRoundedDistance(x,y):
	return (Vector2(x,y) - centerPoint).length()

func airOrCaveAir(x,y):
	var surface = max(SIZEINCHUNKS*2, (SIZEINCHUNKS*4) - 128 )
	#Returns 1 for cave air or 0 for surface air
	return int(getBlockDistance(x,y) <= surface - 2)

func posToTile(pos):
	var planetRadius = SIZEINCHUNKS * 32 #32 is (chunk size * tile size)/2
	var relativePos = pos + Vector2(planetRadius,planetRadius)
	var sizeInTiles = SIZEINCHUNKS * 8
	
	var tilePos = Vector2(int(relativePos.x)/8,int(relativePos.y)/8)
	if tilePos.x < 0 or tilePos.y < 0 or tilePos.x >= sizeInTiles or tilePos.y >= sizeInTiles:
		return null
	
	return tilePos

func tileToPos(pos):
	var planetRadius = SIZEINCHUNKS * 32
	return (pos * 8) - Vector2(planetRadius,planetRadius) + Vector2(4,4)

func pickRandomValidSpot():
	for attempt in range(20):
		var randKey = chunkDictionary.keys()[randi() % chunkDictionary.size()]
		var chunk = chunkDictionary[randKey]
		#if chunk.onScreen:
		#	
		continue
		var pos = chunk.pos * 8
		pos.x += randi() % 8
		pos.y += randi() % 8
		return pos
	return Vector2(-100,-100)

func getSurfaceDistance(x,y):
	var quadtrant = DATAC.getPositionLookup(x,y)
	var newPos = Vector2(x,y) - centerPoint
	newPos = newPos.rotated((PI/2)*-quadtrant)
	var surface = max( (SIZEINCHUNKS*8) / 4, ((SIZEINCHUNKS*8)/2) - 128 )
	return surface + newPos.y

########################################################################
############################ VISIBILITY ################################
########################################################################

func loadPlanet():
	#createChunks()
	set_physics_process(true)
	reverseOrbitingParents()
	Background.setBG(planetType)
	GlobalRef.currentPlanet = self

func unloadPlanet():
	clearChunks()
	clearOrbitingParents()
	Background.clearBG()
	if GlobalRef.currentPlanet == self:
		GlobalRef.currentPlanet = null

func forceChunkDrawUpdate():
	for chunk in chunkContainer.get_children():
		chunk.drawData()
