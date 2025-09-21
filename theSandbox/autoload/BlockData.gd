extends Node

@onready var groundItemScene = preload("res://object_scenes/ground_item/ground_item.tscn")
@onready var blockBreakParticle = preload("res://object_scenes/particles/blockBreak/block_break_particles.tscn")

@onready var trapfireball = preload("res://items/weapons/staffs/firebolt/firebolt.tscn")

var theChunker = null
var theGenerator = null
var lookup = null

var replaceableBlocks :Array[int] = [0,1,17,77,82,90,131]

var aestheticCommands :Array[String] = ["leaf","drip","leafrustle","sparkle","furnacesound","spark","windchime","shopCheck"]

#blockentitycontainers
var pinwheels :Dictionary = {}
var itemFrames :Dictionary = {}
var armorStands :Dictionary = {}

func _ready():
	var ins = CHUNKDRAW.new()
	theChunker = ins
	add_child(ins)
	
	var g = PLANETGEN.new()
	theGenerator = g
	add_child(g)
	
	lookup = theChunker.returnLookup()
	
	#theChunker.attemptSpawnEnemy.connect(attemptSpawnEnemy)

func checkForCollision(id):
	var d = theChunker.getBlockDictionary(id)
	return d["hasCollision"]

func checkIfNatural(id):
	var d = theChunker.getBlockDictionary(id)
	return d["natural"]

func breakBlock(x,y,planet,blockID,infoID,doneByPlayer:bool=false):
	
	var data = theChunker.getBlockDictionary(blockID)
	
	spawnBreakParticle(x,y,blockID,data["breakParticleID"],planet,infoID,doneByPlayer)
	spawnGroundItem(x,y,data["itemToDrop"],planet,blockID)
	
	planet.editTiles( theChunker.runBreak(planet.DATAC,Vector2i.ZERO,x,y,blockID) )

func breakWall(x,y,planet,blockID):
	if blockID <= 1:
		return
	
	var data = theChunker.getBlockDictionary(blockID)
	spawnBreakParticle(x,y,blockID,data["breakParticleID"],planet,0,true)
	if ItemData.itemExists(-blockID):
		spawnGroundItem(x,y,-blockID,planet)


func spawnGroundItem(tilex:int,tiley:int,id:int,planet,oldBlock:int=0):
	
	## special cases ##
	match id:
		-1:
			return
		18:
			AchievementData.unlockMedal("obtainOre")
		24:
			AchievementData.unlockMedal("obtainOre")
		27:
			AchievementData.unlockMedal("obtainOre")
		7: # is tree sapling
			
			if randi() % 30 == 0:
				spawnItemRaw(tilex,tiley,3037,planet)
			
			if oldBlock == 9:
				if randi() % 3 != 0:
					return # returns if dropped from big tree
		
		17: # is wheat seed
			if randi() % 6 != 0:
				if randi() % 6 == 0:
					spawnItemRaw(tilex,tiley,148,planet)
				return
			
		19: # is chair
			id = 6000 + ( planet.DATAC.getInfoData(tilex,tiley) / 4)
		22: # is closed door
			id = 6050 + ( planet.DATAC.getInfoData(tilex,tiley) / 2)
		23: # is open door
			id = 6050 + ( planet.DATAC.getInfoData(tilex,tiley) / 8)
		37: # is potato
			if planet.DATAC.getInfoData(tilex,tiley) >= 4:
				spawnItemRaw(tilex,tiley,37,planet)
				spawnItemRaw(tilex,tiley,37,planet)
				if oldBlock == 37: # only unlock if crop potato and not natural
					AchievementData.unlockMedal("harvestCrop")
		53: # is wool
			id = 3041 + planet.DATAC.getInfoData(tilex,tiley)
			print( planet.DATAC.getInfoData(tilex,tiley) )
		55: # is bed
			id = 6150 # for now
		76: # is glowing orb
			if planet.DATAC.getInfoData(tilex,tiley) == 0:
				if randi() % 10 != 0: # 10 % chance 
					return # returns if not fully grown and roll failed
		83: # wheat
			if planet.DATAC.getInfoData(tilex,tiley) < 2:
				spawnItemRaw(tilex,tiley,17,planet)
				return # deletes if wheat isnt fullygrown
			spawnItemRaw(tilex,tiley,17,planet)
			spawnItemRaw(tilex,tiley,17,planet)
			
			AchievementData.unlockMedal("harvestCrop")
			
		93: # hidden wire
			id = 6200 + planet.DATAC.getInfoData(tilex,tiley)
		110:
			if oldBlock == 111:
				if randi() % 3 != 0:
					return # returns if dropped from big tree
		130: # is trophy
			id = 3177 + planet.DATAC.getInfoData(tilex,tiley)
		142: # is shingle
			id = 6230 + planet.DATAC.getInfoData(tilex,tiley)
		148: # lettuce
			if planet.DATAC.getInfoData(tilex,tiley) >= 3:
				spawnItemRaw(tilex,tiley,3189,planet)
				spawnItemRaw(tilex,tiley,148,planet)
				spawnItemRaw(tilex,tiley,148,planet)
				AchievementData.unlockMedal("harvestCrop")
	
	var ins = groundItemScene.instantiate()
	ins.itemID = id
	ins.position = planet.tileToPos(Vector2(tilex,tiley))
	planet.entityContainer.call_deferred("add_child",ins)

func spawnItemRaw(tilex:int,tiley:int,id:int,planet,amount:int=1,droppedByPlayer:bool=false,dropDir:int=1):
	# spawns an item without considering special cases
	var ins = groundItemScene.instantiate()
	ins.itemID = id
	if droppedByPlayer:
		ins.droppedByPlayer = 4
		ins.dropvel = Vector2(200*dropDir,-100)
	ins.amount = amount
	ins.position = planet.tileToPos(Vector2(tilex,tiley))
	planet.entityContainer.add_child(ins)

func spawnItemVelocity(pos:Vector2,id:int,planet,velocity:Vector2,amount:int=1):
	# spawns an item without considering special cases and with velocity
	var ins = groundItemScene.instantiate()
	ins.itemID = id
	ins.dropvel = velocity
	ins.amount = amount
	ins.position = pos
	ins.coolVelcoity = true
	planet.entityContainer.add_child(ins)

func spawnBreakParticle(tilex:int,tiley:int,id:int,otherId:int,planet,infoID:int,doneByPlayer:bool=false):
	
	var newId = id
	if otherId != -1:
		newId = otherId
	
	var ins = blockBreakParticle.instantiate()
	ins.textureID = newId
	ins.infoID = infoID
	ins.blockID = id
	ins.position = planet.tileToPos(Vector2(tilex,tiley))
	ins.doneByPlayer = doneByPlayer
	planet.entityContainer.add_child(ins)

## multiTile stuff
func checkIfPlaceable(tileX:int,tileY:int,planet,size:Vector2i,grounded:bool,startInfo:int,blockIgnore:int):
	
	var mltY = startInfo / size.x
	var mltX = (size.x * mltY * -1) + startInfo
	var dir = planet.DATAC.getPositionLookup(tileX,tileY)
	
	for xi in range(size.x):
		for yi in range(size.y + int(grounded)):
			var rot = Vector2( xi - mltX, yi - mltY ).rotated((PI/2)*dir);
			var worldX :int = tileX + round(rot.x)
			var worldY :int = tileY + round(rot.y)
			
			var tile = planet.DATAC.getTileData(worldX,worldY)
			
			if grounded && yi == size.y: # return false if not grounded
				if !BlockData.theChunker.getBlockDictionary(tile)["hasCollision"]:
					return false
			elif !replaceableBlocks.has(tile) and tile != blockIgnore: # return false if block in the way
				return false
			
			if worldX < 0 or worldX >= planet.SIZEINCHUNKS * 8:
				return false # return false if outside world boundaries
			if worldY < 0 or worldY >= planet.SIZEINCHUNKS * 8:
				return false
			
			
			var newDir = planet.DATAC.getPositionLookup(worldX,worldY)
			if newDir != dir: # return false if on world corner
				return false
		
	return true

func placeTiles(tileX:int,tileY:int,planet,size:Vector2i,blockID:int,startInfo:int,infoOffset:int):
	
	
	var DICK = {}
	
	
	var mltY = startInfo / size.x
	var mltX = (size.x * mltY * -1) + startInfo
	var dir = planet.DATAC.getPositionLookup(tileX,tileY)
	
	var i = 0
	
	for xi in range(size.x):
		for yi in range(size.y):
			var rot = Vector2( xi - mltX, yi - mltY ).rotated((PI/2)*dir);
			var worldX :int = tileX + round(rot.x)
			var worldY :int = tileY + round(rot.y)
			
			var replacePos := Vector2i( worldX,worldY )
			DICK[replacePos] = blockID;
			
			var info = (yi * size.x) + i
			
			planet.DATAC.setInfoData(worldX,worldY,info + infoOffset)
			
		i += 1
		
	return DICK

func placeDoor(tileX:int,tileY:int,planet,startInfo:int,infoOffset:int,side:int):
	
	
	var DICK = {}
	var size :Vector2i = Vector2i(2,2)
	
	var mltY = startInfo / size.x
	var mltX = (size.x * mltY * -1) + startInfo
	var dir = planet.DATAC.getPositionLookup(tileX,tileY)
	
	#var i = 0
	
	for xi in range(size.x):
		for yi in range(size.y):
			var rot = Vector2( xi - mltX, yi - mltY ).rotated((PI/2)*dir);
			var worldX :int = tileX + round(rot.x)
			var worldY :int = tileY + round(rot.y)
			
			var replacePos := Vector2i( worldX,worldY )
			if side == xi:
				DICK[replacePos] = 22;
				
				#var info = (yi * size.x) + i
				
				planet.DATAC.setInfoData(worldX,worldY,yi + infoOffset)
			else:
				DICK[replacePos] = 0;
			
		#i += 1
		
	return DICK

func spawnLooseItem(position,body,id,amount):
	
	if id == -1:
		return null
	
	var ins = groundItemScene.instantiate()
	ins.itemID = id
	ins.amount = amount
	ins.position = position
	body.entityContainer.add_child(ins)
	
	return ins

func getSoundMaterialID(blockID) -> int:
	var d = theChunker.getBlockDictionary(blockID)
	return d["soundMaterial"]

func doBlockAction(action:String,tileX:int,tileY:int,planet):
	match action:
		"drip":
			var ins = load("res://object_scenes/entity/enemy_scenes/ambientEntities/caveDrip/caveDrip.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.planet = planet
			planet.entityContainer.add_child(ins)
		"leaf":
			var ins = load("res://object_scenes/entity/enemy_scenes/ambientEntities/leafFall/leafFall.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.planet = planet
			planet.entityContainer.add_child(ins)
		"leafrustle":
			var p = planet.tileToPos(Vector2(tileX,tileY))
			var g = planet.to_global(p)
			SoundManager.playSound("ambient/treerustle",g,1.0,0.02)
		"sparkle":
			var ins = load("res://items/blocks/foliage/rockFoliage/sparkle_part.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.z_index = 5
			ins.z_as_relative = false
			planet.entityContainer.add_child(ins)
		"furnacesound":
			var p = planet.tileToPos(Vector2(tileX,tileY))
			var g = planet.to_global(p)
			SoundManager.playSound("ambient/furnaceCrackle",g,1.0,0.02)
		"spark":
			var ins = load("res://items/electrical/electric_spark.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.rotation = (PI/2) * planet.DATAC.getPositionLookup(tileX,tileY)
			ins.z_index = 5
			ins.z_as_relative = false
			planet.entityContainer.add_child(ins)
			SoundManager.playSound("blocks/zap",planet.to_global(ins.position),1.0)
		"teleport":
			var pos = planet.tileToPos(Vector2(tileX,tileY))
			var dir = planet.DATAC.getPositionLookup(tileX,tileY)
			var info = planet.DATAC.getInfoData(tileX,tileY)
			var offset = Vector2( 4,-8 )
			if info == 1:
				offset = Vector2( -4,-8 )
			
			GlobalRef.player.position = pos + offset.rotated( dir * (PI/2) )
		"forceOpen":
			GlobalRef.player.openDoor(Vector2i(tileX,tileY),planet,1)
			SoundManager.playSound("interacts/door",planet.to_global(planet.tileToPos(Vector2(tileX,tileY))),1.2,0.1)
		"forceClose":
			var info = planet.DATAC.getInfoData(tileX,tileY) % 8
			if [0,2,5,7].has(info):
				return
			GlobalRef.player.closeDoor(Vector2i(tileX,tileY),planet)
			SoundManager.playSound("interacts/door",planet.to_global(planet.tileToPos(Vector2(tileX,tileY))),1.2,0.1)
		"spitter":
			
			var dir :Vector2i= Vector2i(Vector2(1,0).rotated( planet.DATAC.getInfoData(tileX,tileY) * (PI/2) ))
			var blockid = planet.DATAC.getTileData( tileX+dir.x,tileY+dir.y )
			if GlobalRef.immortalTiles.has( blockid ):
				return # cancel if block shouldnt be moved
			
			var ins = load("res://items/electrical/spitter/spitter_block_spit.tscn").instantiate()
			ins.position = planet.tileToPos( Vector2(tileX+dir.x,tileY+dir.y) )
			ins.direction = Vector2( dir.x, dir.y )
			ins.planet = planet
			ins.ogTile = Vector2( tileX+dir.x,tileY+dir.y )
			ins.blockID = blockid
			ins.info = planet.DATAC.getInfoData( tileX+dir.x,tileY+dir.y )
			planet.entityContainer.add_child( ins )
			planet.editTiles( { Vector2i(tileX+dir.x,tileY+dir.y) : 0 } )
		"sucker":
			var dir :Vector2i= Vector2i(Vector2(1,0).rotated( planet.DATAC.getInfoData(tileX,tileY) * (PI/2) ))
			
			#get block
			var scanned :int = 0
			for i in range(16):
				if i < 2:
					continue
				var s :Vector2i = dir * i
				var tile = planet.DATAC.getTileData( tileX+s.x,tileY+s.y )
				if tile >= 2:
					scanned = i
					break
			if scanned < 2:
				return
			
			var vec :Vector2i = dir * scanned
			
			var blockid = planet.DATAC.getTileData( tileX+vec.x,tileY+vec.y )
			if GlobalRef.immortalTiles.has( blockid ):
				return # cancel if block shouldnt be moved
			
			var ins = load("res://items/electrical/spitter/spitter_block_spit.tscn").instantiate()
			ins.position = planet.tileToPos( Vector2(tileX+vec.x,tileY+vec.y) )
			ins.direction = Vector2( dir.x * -1, dir.y * -1 )
			ins.planet = planet
			ins.ogTile = Vector2( tileX+vec.x,tileY+vec.y )
			ins.blockID = blockid
			ins.info = planet.DATAC.getInfoData( tileX+vec.x,tileY+vec.y )
			planet.entityContainer.add_child( ins )
			planet.editTiles( { Vector2i(tileX+vec.x,tileY+vec.y) : 0 } )
		"placer":
			# if this is being ran, chest and empty space are already confirmed
			var chestPos :Vector2i= Vector2i(tileX,tileY)+Vector2i(Vector2(-1,0).rotated( planet.DATAC.getInfoData(tileX,tileY) * (PI/2) ))
			if planet.chestDictionary.has(Vector2(chestPos)):
				var chestString = planet.chestDictionary[Vector2(chestPos)]
				var chestData = PlayerData.loadChestString(chestString)
				
				if PlayerData.currentSelectedChest == Vector2(chestPos):
					PlayerData.closeChest()
				
				var slot = -1
				var type = 0
				for i in range(25):
					var id = chestData[i][0]
					var data = ItemData.getItem(id)
					if data is ItemBlock:
						slot = i
						break
					if data is ItemPlant:
						slot = i
						type = 1
						break
					if data is ItemTypeBlock:
						slot = i
						type = 2
						break
				if slot == -1:
					var p = planet.to_global( planet.tileToPos( Vector2(chestPos.x,chestPos.y) ) )
					SoundManager.playSound("blocks/placer",p,1.0,0.1)
					return
				
				var itemID = chestData[slot][0]
				var amount = chestData[slot][1]
				
				if amount > 1:
					chestData[slot] = [itemID,amount-1]
				else:
					chestData[slot] = [-1,-1] # delete item if only 1 left
				
				var newString = PlayerData.saveChestFromArray(chestData)
				planet.chestDictionary[Vector2(chestPos)] = newString
				
				var placePos :Vector2i= Vector2i(tileX,tileY)+Vector2i(Vector2(1,0).rotated( planet.DATAC.getInfoData(tileX,tileY) * (PI/2) ))
				
				var blockID = 2
				var data = ItemData.getItem(itemID)
				match type:
					0:
						blockID = data.blockID
					1:
						blockID = data.blockToPlace
					2:
						blockID = data.blockID
						planet.DATAC.setInfoData(placePos.x,placePos.y,data.multiTileId)
				
				planet.editTiles( {placePos: blockID},true )
				
				var s = SoundManager.getMineSound(blockID)
				var p = planet.to_global( planet.tileToPos( Vector2(placePos.x,placePos.y) ) )
				SoundManager.playSoundStream( s,p, SoundManager.blockPlaceVol, 0.1,"BLOCKS")

				
			else:
				var p = planet.to_global( planet.tileToPos( Vector2(chestPos.x,chestPos.y) ) )
				SoundManager.playSound("blocks/placer",p,1.0,0.1)
		
		"hopper":
			
			var dir :int= planet.DATAC.getPositionLookup(tileX,tileY)
			var chestPos = Vector2(0,1).rotated( (PI/2) * dir ) + Vector2(tileX,tileY)
			
			var ins = load("res://items/electrical/hopper/hoppe_item_detector.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.planet = planet
			ins.chestPos = chestPos
			ins.rotation = (PI/2) * dir
			planet.entityContainer.add_child(ins)
		"trapdoorOpen":
			var dick = GlobalRef.player.setAllTrapdoors(Vector2(tileX,tileY),48,planet)
			planet.editTiles( dick )
			var p = planet.to_global( planet.tileToPos(Vector2(tileX,tileY) ) )
			SoundManager.playSound("interacts/door",p,1.2,0.1)
		"trapdoorClose":
			var dick = GlobalRef.player.setAllTrapdoors(Vector2(tileX,tileY),47,planet)
			planet.editTiles( dick )
			var p = planet.to_global( planet.tileToPos(Vector2(tileX,tileY) ) )
			SoundManager.playSound("interacts/door",p,1.2,0.1)
		"windchime":
			var p = planet.tileToPos(Vector2(tileX,tileY))
			var g = planet.to_global(p)
			SoundManager.playSound("ambient/windchime",g,0.8,0.1)
		"shopCheck":
			if !GlobalRef.hotbar.isShopVisible():
				planet.editTiles( {Vector2i(tileX,tileY):139} )
		"trapfireball":
			var ins = trapfireball.instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.planet = planet
			var r = randf_range(-0.1,0.1)
			ins.velocity = Vector2(240,0).rotated( planet.DATAC.getInfoData(tileX,tileY) * (PI/2) + r)
			
			planet.entityContainer.add_child(ins)
		"itemFramePlace":
			
			if itemFrames.has(Vector2i(tileX,tileY)):
				if is_instance_valid(itemFrames[Vector2i(tileX,tileY)]):
					return
				else:
					itemFrames.erase(Vector2i(tileX,tileY))
			
			var time = planet.DATAC.getTimeData(tileX,tileY)
			if time > 0:
				return
			var itemID = time * -1
			
			var ins = load("res://items/blocks/furniture/itemFrame/item_frame_display.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.itemId = itemID
			ins.planet = planet
			
			itemFrames[Vector2i(tileX,tileY)] = ins
			
			planet.entityContainer.add_child(ins)
		"summonArmorStand":
			if armorStands.has(Vector2i(tileX,tileY)):
				if is_instance_valid(armorStands[Vector2i(tileX,tileY)]):
					return
				else:
					armorStands.erase(Vector2i(tileX,tileY))
			var ins = load("res://items/blocks/furniture/armorstand/armor_stand.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.planet = planet
			ins.rotation = (PI/2) * planet.DATAC.getPositionLookup(tileX,tileY)
			
			ins.basetilex = tileX
			ins.basetiley = tileY
			
			armorStands[Vector2i(tileX,tileY)] = ins
			
			var FUCK = Vector2i( Vector2(0,-1).rotated(ins.rotation) )
			ins.toptilex = tileX + FUCK.x
			ins.toptiley = tileY + FUCK.y
			
			planet.entityContainer.add_child(ins)
		"summonPinwheel":
			
			if pinwheels.has(Vector2i(tileX,tileY)):
				if is_instance_valid(pinwheels[Vector2i(tileX,tileY)]):
					return
				else:
					pinwheels.erase(Vector2i(tileX,tileY))
			
			var ins = load("res://items/blocks/furniture/pinwheel/pinwheel.tscn").instantiate()
			ins.position = planet.tileToPos(Vector2(tileX,tileY))
			ins.planet = planet
			ins.rotation = (PI/2) * planet.DATAC.getPositionLookup(tileX,tileY)
			
			ins.basetilex = tileX
			ins.basetiley = tileY
			pinwheels[Vector2i(tileX,tileY)] = ins
			
			planet.entityContainer.add_child(ins)
		
func checkForEmmission(id):
	var d = theChunker.getBlockDictionary(id)
	return d["lightEmmission"]

func getLookup():
	return theChunker.returnLookup()

func getBlockTexture(blockID) -> Texture2D:
	var d = theChunker.getBlockDictionary(blockID)
	return d["texture"]

func takeBigSreenShot(planet:Planet):
	
	var range :int= 96 # in chunks
	var lightSimAmount :int = 64
	var bigimageTile = Image.create(range * 64,range * 64,false,Image.FORMAT_RGBA8)
	var bigimage = Image.create(range * 64,range * 64,false,Image.FORMAT_RGBA8)
	
	
	var shape = RectangleShape2D.new() # this is so thing doesn't argue
	shape.size = Vector2(8,8)
	var body :Node2D = Node2D.new()
	
	GlobalRef.sendChat("Rendering planet...")
	await get_tree().process_frame
	
	for x in range(range):
		for y in range(range):
			var pos = Vector2( x,y )
			var images :Array= theChunker.generateTexturesFromData(planet.DATAC,pos,body,shape,false)
			var waterImage :Array= theChunker.drawLiquid(planet.DATAC,pos,false)
			
			bigimage.blend_rect( images[1],Rect2(0,0,64,64),Vector2i(x*64,y*64) )
			
			var shadow :Image = Image.create(64,64,false,Image.FORMAT_RGBA8)
			for xx in range(64):
				for yy in range(64):
					
					if xx + x == 62 + range:
						continue
					if yy + y == 62 + range:
						continue
					
					if images[0].get_pixel(xx,yy).a > 0.5:
						shadow.set_pixel(xx,yy, Color(0,0,0,0.4 ) )
					if images[2].get_pixel(xx,yy).a > 0.5:
						shadow.set_pixel(xx,yy, Color(0,0,0,0.4 ) )
			bigimageTile.blend_rect( shadow,Rect2(0,0,64,64),Vector2i(x*64,y*64)+Vector2i(1,1) )
			bigimageTile.blend_rect( images[0],Rect2(0,0,64,64),Vector2i(x*64,y*64) )
			bigimageTile.blend_rect( images[2],Rect2(0,0,64,64),Vector2i(x*64,y*64) )
			bigimageTile.blend_rect( waterImage[0],Rect2(0,0,64,64),Vector2i(x*64,y*64) )
	
	bigimage.blend_rect(bigimageTile,Rect2i(0,0,range*64,range*64),Vector2i.ZERO  )
	
	GlobalRef.sendChat("Simulating light...")
	await get_tree().process_frame
	
	for l in range(lightSimAmount):
		for x in range(range):
			for y in range(range):
				var pos = Vector2( x,y )
				theChunker.simulateLightOnly( planet.DATAC,pos,GlobalRef.daylightMult )
	
	GlobalRef.sendChat("Generating light image...")
	await get_tree().process_frame
	
	var lightimage :Image= Image.create(range * 8,range * 8,false,Image.FORMAT_RGBA8)
	
	for x in range(range*8):
		for y in range(range*8):
			var c = abs(planet.DATAC.getLightData(x,y))
			lightimage.set_pixel(x,y, Color(c,c,c,1.0) )
	lightimage.resize(range*64,range*64,1)
	
	GlobalRef.sendChat("Shading planet... This could take a while...")
	await get_tree().process_frame
	await get_tree().process_frame
	
	for x in range(range * 64):
		for y in range(range * 64):
			var baseColor :Color= bigimage.get_pixel(x,y)
			var lightColor :Color= lightimage.get_pixel(x,y)
			
			# basically doing the shader code
			lightColor.r *= 1.125
			lightColor.g *= 1.05
			lightColor.b *= 1.115
			
			lightColor.r = clamp(lightColor.r,0.0,1.0)
			lightColor.g = clamp(lightColor.g,0.0,1.0)
			lightColor.b = clamp(lightColor.b,0.0,1.0)
			
			lightColor.r = floor(lightColor.r*16.0)/16.0
			lightColor.g = floor(lightColor.g*16.0)/16.0
			lightColor.b = floor(lightColor.b*16.0)/16.0
			
			if lightColor.r > 0.9:
				lightColor.r = 1.0
			if lightColor.g > 0.9:
				lightColor.g = 1.0
			if lightColor.b > 0.9:
				lightColor.b = 1.0
			
			bigimage.set_pixel(x,y, baseColor * lightColor)
	
	var filename = str( int(Time.get_unix_time_from_system()) )
	DirAccess.make_dir_recursive_absolute("user://screenshots/")
	bigimage.save_png("user://screenshots/" + filename + ".png")
	body.queue_free()
	
	GlobalRef.sendChat("Complete! Image saved at user://screenshots/"+ filename + ".png")
	Saving.open_site(ProjectSettings.globalize_path("user://screenshots"))
