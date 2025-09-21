extends Node2D

var planet :Planet = null

var toptilex :int = 0
var toptiley :int = 0

var basetilex :int = 0
var basetiley :int = 0

var tick :float = 0.0

var hat :int = 0
var chest :int = 0
var legs :int = 0

func _ready():
	tick = randf_range(0.0,0.1)
	
	updateArmorVisual()
	

func _process(delta):
	tick += delta
	if tick > 0.1:
		var baseTile = planet.DATAC.getTileData(basetilex,basetiley)
		if baseTile != 167:
			breakArmorStand()
		tick = 0.0
	
	var chunk = Vector2(int(basetilex)/8,int(basetiley)/8)
	if !planet.chunkDictionary.has(chunk):
		queue_free()

func breakArmorStand():
	
	if ItemData.getItem(hat) is ItemArmorHelmet:
		dropItem(hat,true)
	if ItemData.getItem(chest) is ItemArmorChest:
		dropItem(chest,true)
	if ItemData.getItem(legs) is ItemArmorLegs:
		dropItem(legs,true)

	queue_free()

func updateArmorVisual():
	var flip :int= planet.DATAC.getInfoData(toptilex,toptiley)
	hat = planet.DATAC.getInfoData(basetilex,basetiley)
	chest = planet.DATAC.getTimeData(toptilex,toptiley)
	legs = planet.DATAC.getTimeData(basetilex,basetiley)
	
	for sprite in get_children():
		if sprite is Sprite2D:
			sprite.flip_h = flip == -1
	
	var hatItem = ItemData.getItem(hat)
	var chestItem = ItemData.getItem(chest)
	var legsItem = ItemData.getItem(legs)
	
	if hatItem is ItemArmorHelmet:
		$hat.texture = hatItem.armorTexture
	else:
		$hat.texture = null
	
	if chestItem is ItemArmorChest:
		$chest.texture = chestItem.armorTexture
	else:
		$chest.texture = null
	
	if legsItem is ItemArmorLegs:
		$legs.texture = legsItem.armorTexture
	else:
		$legs.texture = null


func _on_color_rect_gui_input(event):
	if event is InputEventMouseMotion:
		return
		
	if event is InputEventMouseButton:
		if event["button_mask"] != 2:
			return
		if !event["pressed"]:
			return
	else:
		return
	
	if GlobalRef.player.get_local_mouse_position().length() > 48:
		return # too far
	
	
	var itemID = PlayerData.getSelectedItemID()
	var itemData = ItemData.getItem(itemID)
	
	var clearHeldItem :bool = false
	
	if itemData is ItemArmorHelmet:
		var currentID = planet.DATAC.getInfoData(basetilex,basetiley)
		if ItemData.getItem(currentID) is ItemArmorHelmet:
			dropItem(currentID)
		planet.DATAC.setInfoData(basetilex,basetiley,itemID)
		clearHeldItem = true
	
	if itemData is ItemArmorChest:
		var currentID = planet.DATAC.getTimeData(toptilex,toptiley)
		if ItemData.getItem(currentID) is ItemArmorChest:
			dropItem(currentID)
		planet.DATAC.setTimeData(toptilex,toptiley,itemID)
		clearHeldItem = true
		
	if itemData is ItemArmorLegs:
		var currentID = planet.DATAC.getTimeData(basetilex,basetiley)
		if ItemData.getItem(currentID) is ItemArmorLegs:
			dropItem(currentID)
		planet.DATAC.setTimeData(basetilex,basetiley,itemID)
		clearHeldItem = true
		
	
	if clearHeldItem:
		PlayerData.inventory[PlayerData.selectedSlot] = [-1,-1]
		PlayerData.emit_signal("updateInventory")
	else:
		stripArmorStand()
	
	updateArmorVisual()
	
	sendUpdatePacket()

func stripArmorStand():
	var chat = planet.DATAC.getInfoData(basetilex,basetiley)
	var cchest = planet.DATAC.getTimeData(toptilex,toptiley)
	var clegs = planet.DATAC.getTimeData(basetilex,basetiley)
	
	if ItemData.getItem(chat) is ItemArmorHelmet:
		dropItem(chat)
		planet.DATAC.setInfoData(basetilex,basetiley,1)
		return
	if ItemData.getItem(cchest) is ItemArmorChest:
		dropItem(cchest)
		planet.DATAC.setTimeData(toptilex,toptiley,0)
		return
	if ItemData.getItem(clegs) is ItemArmorLegs:
		dropItem(clegs)
		planet.DATAC.setTimeData(basetilex,basetiley,0)
		return

func dropItem(id:int,fakePlayerCanPick:bool = false):
	var item = BlockData.spawnLooseItem(planet.tileToPos(Vector2(toptilex,toptiley)),planet,id,1)
	if !fakePlayerCanPick:
		item.droppedByEnemy = true

func sendUpdatePacket():
	if !Network.isMultiplayerGame:
		return
	
	var chat = planet.DATAC.getInfoData(basetilex,basetiley)
	var cchest = planet.DATAC.getTimeData(toptilex,toptiley)
	var clegs = planet.DATAC.getTimeData(basetilex,basetiley)
	
	Network.send_p2p_packet(0,{"packetType":"armorStandUpdate",
	"hat":chat,"chest":cchest,"legs":clegs,
	"posX":basetilex,"posY":basetiley})

func recievePacket(packet:Dictionary):
	planet.DATAC.setInfoData(basetilex,basetiley,packet["hat"])
	planet.DATAC.setTimeData(toptilex,toptiley,packet["chest"])
	planet.DATAC.setTimeData(basetilex,basetiley,packet["legs"])
	updateArmorVisual()
