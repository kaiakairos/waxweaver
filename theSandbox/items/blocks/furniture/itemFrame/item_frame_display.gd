extends Enemy

var itemId :int = -1

var tick :int = 0

func _ready():
	if itemId == -1:
		queue_free()
		return
	
	rotation = getWorldRot(self)
	
	$sprite.texture = ItemData.getItemTexture(itemId)
	$sprite2.texture = $sprite.texture
	tick = randi() % 6

func _process(delta):
	tick += 1
	
	var tiledd = getPos()
	var chunk = Vector2(int(tiledd.x)/8,int(tiledd.y)/8)
	if !planet.chunkDictionary.has(chunk):
		queue_free()
		set_process(false)
	
	if tick % 6 == 0:
		
		var tile = getTile()
		if tile != 162: # destroy item frame if item frame is gone
			destroy(true)
			return
		
		var time = getTime() # tile time
		if time * -1 != itemId: # time inverted should equal item id
			destroy(false)
			return
		

func destroy(dropItem:bool):
	if dropItem:
		var p = getPos()
		BlockData.spawnItemRaw(p.x,p.y,itemId,planet)
	
	queue_free()

func sendUpdatePacket():
	if !Network.isMultiplayerGame:
		return

func recievePacket(packet:Dictionary):
	pass
