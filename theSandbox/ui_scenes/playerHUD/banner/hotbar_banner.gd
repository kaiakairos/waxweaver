extends Node2D

@onready var holdSlot = $holdingSlot

@onready var crafting = $Menu/Crafting

var invOpen = false

var deathTimer :SceneTreeTimer = null

# chat nodes
@onready var cheatOrigin = $Cheat
@onready var textBox = $Cheat/TextEdit
@onready var chat = $Chat
var previousMessage = ""

@onready var chatMessageScene = preload("res://ui_scenes/chat/chat_message.tscn")

var longassstring :PackedStringArray


@onready var hb = $BossHealthbar/hb

var shopPosition :Vector2= Vector2.ZERO
var screenshotTick :int = 0 # just to make sure screenshot gets delayed

func _ready():
	
	GlobalRef.hotbar = self
	
	#assign self to slots
	for slot in $Hotbar.get_children():
		slot.parent = self
	for slot in $Menu/InventoryBody.get_children():
		slot.parent = self
	for slot in $Menu/ArmorSlots.get_children():
		slot.parent = self
	for slot in $Menu/AccessorySlots.get_children():
		slot.parent = self
	for slot in $Menu/VanitySlots.get_children():
		slot.parent = self
	for slot in $ChestInventory/slots.get_children():
		slot.parent = self
	
	$Menu.visible = false
	
	# connect health bar
	PlayerData.connect("updateHealth",updateHealth)
	PlayerData.connect("forceOpenInventory",forceOpenInventory)
	PlayerData.connect("updateMoney",updateMoney)
	CreatureData.connect("spawnedBoss",connectBossHealthbar)
	
	await get_tree().create_timer(0.25).timeout
	updateMoney()
	
	if Saving.worldType == 1:
		$"Death Screen/respawn".hide()
	
	if Saving.worldType == 2:
		$Menu/CreativeMenu.show()
		$Menu/creativetoggle.show()
	
func _process(delta):
	var pos = to_local(get_global_mouse_position()) - Vector2(6,6)
	holdSlot.position = Vector2i( pos )
	if Input.is_action_just_pressed("inventory") and !GlobalRef.chatIsOpen:
		invOpen = !invOpen
		$Menu.visible = invOpen
		
		if !invOpen:
			PlayerData.closeChest()
			$shop.hide()
			PlayerData.updateCraftingDisplay(-1)
			$Menu/changerecipedisplay/craftdisplay.frame = 0
		$ItemPreview.position.x = (194 * int(invOpen)) + (3 * (1-int(invOpen) ))
	
	$ChestInventory.visible = PlayerData.chestOBJ != null
	$Menu/Crafting.visible = PlayerData.chestOBJ == null
	
	if $ChestInventory.visible:
		$shop.hide()
	
	if $shop.visible:
		$Menu/Crafting.visible = false
		if shopPosition.distance_to(GlobalRef.player.global_position) > 64:
			$shop.hide()
	
	# mana
	
	$HealthBar/manabar.max_value = PlayerData.manaMax
	$HealthBar/manabar.value = PlayerData.mana
	$HealthBar/manabar.visible = PlayerData.mana != PlayerData.manaMax
	
	# cheat commands
	if Input.is_action_just_pressed("openCommand"):
		
		
		if !GlobalRef.commandLineAvailable and !Network.isMultiplayerGame:
			return
		
		if cheatOrigin.visible:
			interpretCommand(textBox.text)
		
		cheatOrigin.visible = !cheatOrigin.visible
		textBox.text = ""
		
		GlobalRef.chatIsOpen = cheatOrigin.visible
		
		if cheatOrigin.visible:
			textBox.grab_focus()
	
	if cheatOrigin.visible:
		if Input.is_action_just_pressed("ui_up"):
			textBox.text = previousMessage
			textBox.set_caret_column(previousMessage.length())
			#interpretCommand(previousMessage + " ")
	
	# death message
	if is_instance_valid(deathTimer):
		$"Death Screen/respawn".text = "respawn in " + str( int(deathTimer.time_left) )
	
	# fps counter
	$fps.text = "fps: " + str(1.0/delta ).left(4)
	
	if Input.is_action_pressed("screenshot"):
		screenshotTick += 1
		if screenshotTick > 100:
			BlockData.takeBigSreenShot(GlobalRef.currentPlanet)
			screenshotTick = -99999
	if Input.is_action_just_released("screenshot"):
		screenshotTick = 0
	
func clickedSlot(slot):
	if !invOpen:
		return
	if PlayerData.inventory[49][0] == -1: # if hand is empty
		PlayerData.swapItem(slot,49) 
		displayItemName("",null)
		return
	elif PlayerData.inventory[slot][0] == -1: # if slot is empty
		PlayerData.swapItem(slot,49)
		var data = ItemData.getItem(PlayerData.inventory[slot][0])
		displayItemName( ItemData.getItemName( PlayerData.inventory[slot][0] ),data )
		return
	elif PlayerData.inventory[slot][0] != PlayerData.inventory[49][0]:
		PlayerData.swapItem(slot,49)
		var data = ItemData.getItem(PlayerData.inventory[slot][0])
		displayItemName( ItemData.getItemName( PlayerData.inventory[slot][0] ),data )
		return
	else:
		var maxStack = ItemData.data[PlayerData.inventory[slot][0]].maxStackSize
		var total = PlayerData.inventory[slot][1] + PlayerData.inventory[49][1]
		if total <= maxStack:
			PlayerData.inventory[slot][1] = total
			PlayerData.inventory[49] = [-1,-1]
		else:
			PlayerData.inventory[slot][1] = maxStack
			PlayerData.inventory[49][1] = total - maxStack 
		PlayerData.emit_signal("updateInventory")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")

func splitSlot(slot):
	if !invOpen:
		return

	
	#If Hand slot is empty
	if PlayerData.inventory[49][0] == -1:
		var amount = PlayerData.inventory[slot][1]
		var half = PlayerData.inventory[slot][1] / 2
		if amount <= 1:
			return
		
		PlayerData.inventory[slot][1] = half
		PlayerData.inventory[49] = [PlayerData.inventory[slot][0],amount-half]
		PlayerData.emit_signal("updateInventory")
		PlayerData.emit_signal("selectedSlotChanged")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")
		if slot >= 53:
			PlayerData.saveChestString()
		return
	#If placement slot is empty
	elif PlayerData.inventory[slot][0] == -1:
		PlayerData.inventory[slot] = [PlayerData.inventory[49][0],1]
		PlayerData.inventory[49][1] -= 1
		if PlayerData.inventory[49][1] <= 0:
			PlayerData.inventory[49] = [-1,-1]
		PlayerData.emit_signal("updateInventory")
		PlayerData.emit_signal("selectedSlotChanged")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")
		if slot >= 53:
			PlayerData.saveChestString()
		return
	#If neither are empty but they aren't the same item type
	elif PlayerData.inventory[slot][0] != PlayerData.inventory[49][0]:
		return
	#If neither are empty but they ARE the same item type
	else:
		var maxStack = ItemData.data[PlayerData.inventory[slot][0]].maxStackSize
		
		if PlayerData.inventory[slot][1] >= maxStack:
			return
		
		PlayerData.inventory[slot][1] += 1
		
		PlayerData.inventory[49][1] -= 1
		if PlayerData.inventory[49][1] <= 0:
			PlayerData.inventory[49] = [-1,-1]
		PlayerData.emit_signal("updateInventory")
		PlayerData.emit_signal("selectedSlotChanged")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")
		if slot >= 53:
			PlayerData.saveChestString()
		return

func transferSlot(slot):
	
	if !invOpen:
		return # dont do anything if inventory isnt open
	
	if PlayerData.inventory[slot][0] == -1:
		return # dont do anything on empty slots
	
	if slot >= 53: # is inside chest
		var yo = PlayerData.inventory[slot]
		var amountLeft = PlayerData.addItem(yo[0],yo[1])
		if amountLeft == null:
			return
		if amountLeft > 0:
			PlayerData.inventory[slot][1] = amountLeft
		else:
			PlayerData.inventory[slot] = [-1,-1]
		PlayerData.saveChestString()
		PlayerData.emit_signal("updateInventory")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")
		return
		
	if $ChestInventory.visible: # and inside main inventory
		var yo = PlayerData.inventory[slot]
		var amountLeft = PlayerData.addItem(yo[0],yo[1],53,25)
		if amountLeft == null:
			return
		if amountLeft > 0:
			PlayerData.inventory[slot][1] = amountLeft
		else:
			PlayerData.inventory[slot] = [-1,-1]
		PlayerData.saveChestString()
		PlayerData.emit_signal("updateInventory")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")
		
		if slot >= 40 and slot <= 52:
			# slot was an armor/trinket slot
			PlayerData.emit_signal("armorUpdated")
		return
	
	# not interacting with chest anymore
	if slot < 10: # is hotbar
		var yo = PlayerData.inventory[slot]
		var amountLeft = PlayerData.addItem(yo[0],yo[1],10,30)
		if amountLeft == null:
			return
		if amountLeft > 0:
			PlayerData.inventory[slot][1] = amountLeft
		else:
			PlayerData.inventory[slot] = [-1,-1]
		PlayerData.emit_signal("updateInventory")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")
		return
	else:
		var yo = PlayerData.inventory[slot]
		var amountLeft = PlayerData.addItem(yo[0],yo[1],0,10)
		if amountLeft == null:
			return
		if amountLeft > 0:
			PlayerData.inventory[slot][1] = amountLeft
		else:
			PlayerData.inventory[slot] = [-1,-1]
		PlayerData.emit_signal("updateInventory")
		SoundManager.playSound("inventory/pickupItem",GlobalRef.player.global_position,1.0,0.12,"INVENTORY")
		PlayerData.emit_signal("selectedSlotChanged")
		
		if slot >= 40 and slot <= 52:
			# slot was an armor/trinket slot
			PlayerData.emit_signal("armorUpdated")
		
		return

func updateHealth():
	var h :HealthComponent = GlobalRef.player.healthComponent
	$HealthBar/healthText.text = str(h.health) + " / " + str(h.maxHealth)
	$HealthBar/bar.scale.x = h.health
	$HealthBar/barShadow.scale.x = h.maxHealth


func interpretCommand(text):
	
	#removes enters
	text = text.replace("\n","")
	
	if text == "":
		return
	previousMessage = text
	
	if text.left(1) != "/":
		# is chat message
		var chatName :String= ""
		if Network.isMultiplayerGame:
			chatName = Steamworks.steam_username
		var chatmsg :String = "< " + chatName + " > " + text + " "
		GlobalRef.sendChat(chatmsg)
		if Network.isMultiplayerGame:
			Network.send_p2p_packet(0,{"packetType":"chatMessage","text":chatmsg,"type":"normal"})
		return
	
	text = text.trim_prefix("/") # remove slash from front of command
	
	var command = text.get_slice(" ",0)
	
	if Network.isMultiplayerGame:
		if !Network.is_host:
			GlobalRef.sendChat("You don't have permission to use commands!")
			return
	
	if command == "cheats":
		GlobalRef.cheatsEnabled = true
		Saving.autosave()
		GlobalRef.sendChat("Cheats enabled!")
		GlobalRef.sendChat("This save can no longer earn achievements.")
		return
	
	if !GlobalRef.cheatsEnabled:
		if true:#OS.has_feature("template"): # only stop commands if release version
			GlobalRef.sendChat("Cheats are currently disabled.")
			GlobalRef.sendChat("Type '/cheats' to enable them.")
			GlobalRef.sendChat("Enabling cheats will lock this save")
			GlobalRef.sendChat("from earning achievements permanently.")
			return
	
	match command:
		"fullbright":
			GlobalRef.lightmap.visible = !GlobalRef.lightmap.visible
			if GlobalRef.lightmap.visible:
				GlobalRef.sendChat("Fullbright: DISABLED")
			else:
				GlobalRef.sendChat("Fullbright: ENABLED")
		"give":
			var item = text.get_slice(" ",1)
			var amount = text.get_slice(" ",2)
			
			if item == "":
				GlobalRef.sendError("ERROR: missing item input")
				return # return if item not inputted 
			if !ItemData.itemExists(int(item)):
				GlobalRef.sendError("ERROR: item of id " + item + " does not exist.")
				return # return if item does not exist

			if amount == "":
				amount = "1" # make amount 1 if no amount in entered
			
			PlayerData.addItem(int(item),int(amount))
			GlobalRef.sendChat("Gave player " + amount + " " + ItemData.getItemName(int(item)))
		
		"ship":
			GlobalRef.player.spawnShip()
		
		"tick":
			var amount = text.get_slice(" ",1)
			if amount == "":
				GlobalRef.sendError("ERROR: missing time input")
				return # return if time not inputted 
			GlobalRef.globalTick += int(amount)
			GlobalRef.sendChat("Advanced time by " + str(int(amount)/15.0) + " seconds.")
		
		"time":
			GlobalRef.sendChat("Time is " + str(GlobalRef.globalTick) + ".")
		
		"zoom":
			var z = text.get_slice(" ",1)
			if z == "" or z == "zoom":
				GlobalRef.sendError("ERROR: missing zoom amount")
				return
			GlobalRef.camera.zoom = Vector2(float(z),float(z))
			GlobalRef.camera.changeZoom()
			GlobalRef.sendChat("Zoom set to " + z + ".")
		
		"summon":
			var n = text.get_slice(" ",1)
			if n == "" or n == "summon":
				GlobalRef.sendError("ERROR: missing enemy name")
				return
			
			var times = text.get_slice(" ",2)
			if times == "":
				times = "1"
			
			var b = 0
			for i in range(int(times)):
				CreatureData.summonCommand(GlobalRef.currentPlanet,GlobalRef.player.position,n)
				b += 1
			if b == 0:
				GlobalRef.sendError("ERROR: amount invalid")
		
		"noclip":
			GlobalRef.player.toggleNoClip()
			GlobalRef.sendChat("Toggled noclip")
		"inflict":
			var effect = text.get_slice(" ",1)
			if effect == "" or effect == "inflict":
				GlobalRef.sendError("ERROR: missing effect name")
				return
			var time = text.get_slice(" ",2)
			if time == "" or time == effect:
				time = "10"
			GlobalRef.player.healthComponent.inflictStatus(effect,float(time))
			GlobalRef.sendChat("Inflicted player with " + effect + " for " + time + " seconds.")
		"heal":
			GlobalRef.player.healthComponent.heal(99999)
			GlobalRef.sendChat("Healed player.")
		"kill":
			GlobalRef.player.healthComponent.damagePassive(99999,"cheats")
		"save":
			GlobalRef.system.saveGameToFile()
		"load":
			GlobalRef.system.loadSaveFromFile()
			GlobalRef.player.respawn()
		"respawn":
			GlobalRef.player.respawn()
		"kit":
			PlayerData.addItem(3153,1)
			PlayerData.addItem(3154,1)
			PlayerData.addItem(3158,1)
			PlayerData.addItem(3032,4)
			PlayerData.addItem(3035,198)
			PlayerData.addItem(3155,1)
			PlayerData.addItem(3156,1)
			PlayerData.addItem(3157,1)
			PlayerData.addItem(3092,1)
			PlayerData.addItem(3145,1)
		"shadow":
			GlobalRef.lightmap.toggleShadow()
			GlobalRef.sendChat("Toggled drop shadow")
		"fps":
			$fps.visible = !$fps.visible
			GlobalRef.sendChat("Toggled FPS display")
		"clear":
			PlayerData.initializeInventory() # erases inventory
			PlayerData.addItem(3000,1) # readds starting tools
			PlayerData.addItem(3001,1)
			PlayerData.emit_signal("armorUpdated")
		"god":
			GlobalRef.player.healthComponent.god = !GlobalRef.player.healthComponent.god
			GlobalRef.sendChat("Toggled god mode: " + str(GlobalRef.player.healthComponent.god))
		"music":
			SoundManager.randomMusicTick = 9999
			GlobalRef.sendChat("Playing music")
		"conveyor":
			GlobalRef.conveyorspeed = float(text.get_slice(" ",1))
		"rich":
			PlayerData.addMoney(1000)
			GlobalRef.sendChat("Added 1000 money")
		_:
			GlobalRef.sendError("Error: command doesn't exist")
			return

func printIntoChat(text:String,color:Color = Color.WHITE):
	var newMessage = chatMessageScene.instantiate()
	newMessage.text = text
	newMessage.color = color
	
	for oldMessage in chat.get_children():
		oldMessage.position.y -= 24
	
	chat.add_child(newMessage)

func displayItemName(text:String,itemData:Item):
	
	$ItemPreview/itemSlotName.text = text
	
	if text == "":
		$ItemPreview/subtext.text = ""
		$ItemPreview/information.text = ""
		$ItemPreview/infoBox.visible = false
		$ItemPreview/namebox.visible = false
		return
	
	$ItemPreview/namebox.visible = true
	$ItemPreview/subtext.text = itemData.subtext
	
	## information data
	var infoText = ""
	var size = 0
	if itemData is ItemDamage:
		infoText += "damage: " + str(itemData.damage) + "\n"
		size += 18
		infoText += "swing speed: " + str(itemData.animSpeed) + "\n"
		size += 18
		if itemData is ItemMining:
			infoText += "mine speed: " + str(itemData.miningMultiplier) + "\n"
			size += 18
			infoText += "mining power: " + str(itemData.miningLevel) + "\n"
			size += 18
	elif itemData is ItemArmor:
		infoText += "defense: " + str(itemData.defense) + "\n"
		size += 18
	elif itemData is ItemFood:
		infoText += "heals: " + str(itemData.healingAmount) + "\n"
		size += 18
		infoText += "eat time: " + str(itemData.eatTime) + " seconds \n"
		size += 18
	elif itemData is ItemPlant:
		infoText += "can be planted on top of: \n[ "+ str(itemData.descCanPlaceOn) + " ]\n"
		size += 18
		size += 18
	elif itemData is ItemTrinket:
		infoText += "trinket \n"
		size += 18
	elif itemData is ItemGift:
		infoText += "left click to open! \n"
		size += 18
	elif itemData is ItemArrow:
		infoText += "damage: " + str(itemData.damage) + "\n"
		size += 18
		infoText += "speed: " + str(itemData.velocityMultiplier) + "\n"
		size += 18
	elif itemData is ItemBow:
		infoText += "damage: " + str(itemData.damage) + "\n"
		size += 18
		infoText += "velocity: " + str(itemData.velocity) + "\n"
		size += 18
		infoText += "delay: " + str(itemData.fireRate) + "\n"
		size += 18
	
	if itemData.desc != "":
		infoText += itemData.desc
		size += (itemData.desc.count("\n")+1) * 18
		infoText += "\n"
	
	
	if itemData.materialIn.size() > 0:
		infoText += "material \n"
		size += 18
	
	$ItemPreview/information.text = infoText
	$ItemPreview/infoBox.size.y = size
	$ItemPreview/infoBox.visible = (infoText != "")

func updateDefense(amount:int):
	$Menu/defense/defenseAmount.text = str(amount)

func showDeathScreen(time):
	$"Death Screen".visible = true
	deathTimer = get_tree().create_timer(time)
	await deathTimer.timeout
	$"Death Screen".visible = false

func forceOpenInventory():
	invOpen = true
	$Menu.visible = invOpen
	
	#crafting.createCraftingIcons()
	$ItemPreview.position.x = (197 * int(invOpen)) + (3 * (1-int(invOpen) ))


func _on_crafting_vi_s_toggle_pressed():
	crafting.showUncraftables = !crafting.showUncraftables
	crafting.forceReload()
	$Menu/craftingViSToggle/VisibleEyes.frame = int(crafting.showUncraftables)

func _unhandled_input(event):
	
	# mouse scroll
	if event is InputEventMouseButton:
		if event["pressed"] == false:
			return
		var curSlot = PlayerData.selectedSlot
		if event["button_index"] == 4:
			curSlot -= 1
			if curSlot < 0:
				curSlot = 9
			selectSlot(curSlot)
		elif event["button_index"] == 5:
			curSlot += 1
			if curSlot > 9:
				curSlot = 0
			selectSlot(curSlot)
		
		return
	
	# inventory keys
	if not event is InputEventKey:
		return
	
	if event["keycode"] < 49 or event["keycode"] > 57:
		if event["keycode"] == 48: # special case for 0 key
			selectSlot(9)
		return
	selectSlot(event["keycode"]-49)

func selectSlot(slot):
	if PlayerData.selectedSlot == slot:
		return
	PlayerData.selectSlot(slot)
	for i in $Hotbar.get_children():
		i.updateSelected()

func updateStatus():
	for c in $StatusDisplay.get_children():
		c.queue_free()
	var i = 0
	for effect in GlobalRef.player.healthComponent.statusEffects:
		var ins = load("res://object_scenes/specialResource/statusEffects/status_display.tscn").instantiate()
		ins.status = effect
		ins.position.y = i * 10
		$StatusDisplay.add_child(ins)
		i += 1

func connectBossHealthbar():
	if !is_instance_valid(CreatureData.boss):
		hb.hide()
		return
	
	var hc :HealthComponent = CreatureData.boss.healthComp
	hb.max_value = hc.maxHealth
	hb.value = hc.health
	hb.textSet(hc.health,hc.maxHealth)
	hb.show()
	hb.set_process(true)

func updateMoney():
	$Menu/money.text = "$" + str(PlayerData.money)

func showShop():
	shopPosition = GlobalRef.player.global_position
	$shop.show()

func isShopVisible():
	return $shop.visible


func _on_changerecipedisplay_pressed():
	var current = PlayerData.displayedCrafting
	current += 1
	if current == 7:
		current = -1
	
	match current:
		-1:
			GlobalRef.sendChat("displaying recipes for: everything")
		0:
			GlobalRef.sendChat("displaying recipes for: blocks")
		1:
			GlobalRef.sendChat("displaying recipes for: walls")
		2:
			GlobalRef.sendChat("displaying recipes for: tools/weapons")
		3:
			GlobalRef.sendChat("displaying recipes for: equipables")
		4:
			GlobalRef.sendChat("displaying recipes for: food")
		5:
			GlobalRef.sendChat("displaying recipes for: furniture")
		6:
			GlobalRef.sendChat("displaying recipes for: electrical")
	
	$Menu/changerecipedisplay/craftdisplay.frame = current + 1
	PlayerData.updateCraftingDisplay(current)


func _on_toggle_creative_pressed():
	$Menu/CreativeMenu.visible = !$Menu/CreativeMenu.visible
