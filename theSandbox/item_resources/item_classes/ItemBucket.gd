extends Item
class_name ItemBucket

## 0 = Empty bucket, 1 = Water Bucket, 2 = Infinite Bucket
@export var type = 0

func onUse(tileX:int,tileY:int,planetDir:int,planet,lastTile:Vector2):
	
	if lastTile == Vector2(tileX,tileY) and type < 2:
		return
	
	match type:
		0:
			emptyBucket(tileX,tileY,planetDir,planet,lastTile)
		1:
			fullBucket(tileX,tileY,planetDir,planet,lastTile)
		2:
			magicBucket(tileX,tileY,planetDir,planet,lastTile)
	
func emptyBucket(tileX:int,tileY:int,planetDir:int,planet,lastTile:Vector2):
	
	var waterLevel = abs( planet.DATAC.getWaterData(tileX,tileY) )
	
	if waterLevel > 0.6:
		planet.DATAC.setWaterData(tileX,tileY,0.0)
		if Network.isMultiplayerGame:
			Network.send_p2p_packet(0,{"packetType":"waterAdd","amount":0.0,"posX":tileX,"posY":tileY})
		PlayerData.replaceSelectedSlot(3026,1)
		sound(tileX,tileY,planet)

func fullBucket(tileX:int,tileY:int,planetDir:int,planet,lastTile:Vector2):
	
	
	var waterLevel = abs( planet.DATAC.getWaterData(tileX,tileY) )
	
	if waterLevel < 0.8:
		planet.DATAC.setWaterData(tileX,tileY,0.8)
		if Network.isMultiplayerGame:
			Network.send_p2p_packet(0,{"packetType":"waterAdd","amount":0.8,"posX":tileX,"posY":tileY})
		PlayerData.replaceSelectedSlot(3025,1)
		sound(tileX,tileY,planet)

func magicBucket(tileX:int,tileY:int,planetDir:int,planet,lastTile:Vector2):
	
	planet.DATAC.setWaterData(tileX,tileY,1.0)
	if Network.isMultiplayerGame:
		Network.send_p2p_packet(0,{"packetType":"waterAdd","amount":1.0,"posX":tileX,"posY":tileY})
	sound(tileX,tileY,planet,true)

func sound(tileX:int,tileY:int,planet,quiet:bool=false):
	var pos = planet.to_global(planet.tileToPos(Vector2(tileX,tileY)))
	var vol = 1.0
	if quiet:
		vol = 0.2
	SoundManager.playSound("enemy/swim0",pos,vol,0.1)
