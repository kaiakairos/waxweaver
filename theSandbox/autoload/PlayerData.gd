extends Node

## HEALTH ##
var maxHealth :int= 100  ## just for health bar shit u feel
var currentHealth :int= 100
signal updateHealth

## INVENTORY ##
# [ITEMID,COUNT]
var inventory = [] # 0-39 inventory, 40-42 armor, 
				   # 43-48 trinket, 49 held, 50 - 52 vanity
				   # 53 - 77 chest inventory (25 slots)
signal updateInventory
signal onlyUpdateCraft
signal selectedSlotChanged
signal armorUpdated
signal forceOpenInventory
var selectedSlot = 0
var selectedSlotRemember = 0

var currentSelectedChest = null
var chestOBJ = null

## MONEY ##
var money :int = 0
signal updateMoney

## mana ##
var manaMax :int= 250
var mana :int = 250
var manaIdleTicks :int = 0

var displayedCrafting :int = -1
signal changedDisplayedCrafting

func _ready():
	initializeInventory()

func _process(delta):
	# check distance from chest
	if chestOBJ != null:
		if chestDisCheck(chestOBJ,currentSelectedChest):
			closeChest()
	
	if inventory[49][0] != -1:
		if selectedSlot != 49:
			selectedSlotRemember = selectedSlot
			selectedSlot = 49
			emit_signal("selectedSlotChanged")
	else:
		if selectedSlot == 49:
			selectedSlot = selectedSlotRemember
			emit_signal("selectedSlotChanged")
	
	if !is_instance_valid(GlobalRef.player):
		return
	
	if manaIdleTicks > 0:
		manaIdleTicks -= 1
	else:
		if mana == manaMax - 1:
			SoundManager.playSound("items/manaFull",GlobalRef.player.global_position,1.2)
			GlobalRef.player.manaFilled()
		
		mana += 1
		if GlobalRef.playerHC.checkIfHasEffect("focused"):
			mana += 1
		mana = min(mana,manaMax)
	
func useMana(amount) -> bool:
	if amount > mana:
		return false
	
	mana -= amount
	manaIdleTicks = 90
	return true

func initializeInventory():
	inventory = []
	for i in range(78):
		inventory.append([-1,-1])

func addItem(itemID,amount,rangeMin:int=0,rangeMax:int=40):
	
	var itemCountLeft = amount
	
	var itemData = ItemData.data[itemID]
	
	if itemData == null:
		printerr("ERROR: Failed to grab item data.")
		return # return null
	
	var itemMax = itemData.maxStackSize
	for slot in inventoryHasItem(itemID,rangeMin,rangeMax):
		var add = inventory[slot][1] + itemCountLeft
		if add > itemMax:
			itemCountLeft -= (itemMax - inventory[slot][1])
			inventory[slot][1] = itemMax
		else:
			inventory[slot][1] += itemCountLeft
			itemCountLeft = 0
			emit_signal("updateInventory")
			emit_signal("onlyUpdateCraft")
			return 0
	
	var emptySlot = findEmptySlot(rangeMin,rangeMax)
	if emptySlot == null:
		BlockData.spawnItemRaw(self.x, self.y, itemID, self.planet)
		return itemCountLeft
	
	if itemCountLeft > itemMax:
		while itemCountLeft > itemMax:
			inventory[emptySlot] = [itemID,itemMax]
			itemCountLeft -= itemMax
			emptySlot = findEmptySlot(rangeMin,rangeMax)
			if emptySlot == null:
				emit_signal("updateInventory")
				return itemCountLeft
	
	inventory[emptySlot] = [itemID,itemCountLeft]
	
	emit_signal("updateInventory")
	emit_signal("onlyUpdateCraft")
	return 0
	

func findEmptySlot(rangeMin:int=0,rangeMax:int=40):
	for i in range(rangeMax):
		var slot = i + rangeMin
		if inventory[slot][0] == -1:
			return slot
	return null

func inventoryHasItem(itemID,rangeMin:int=0,rangeMax:int=40):
	var slots = []
	for i in range(rangeMax):
		var slot = i + rangeMin
		if inventory[slot][0] == itemID:
			slots.append(slot)
	return slots

func swapItem(slot1,slot2):
	
	if slot1 >= 53 and currentSelectedChest == null:
		return # return if trying to interact with chest slots with no chest
	
	var points = 0
	var updateArmor = false
	var updateHeld = false
	
	var givemedal = false
	
	match slot1:
		40: #helmet
			points += int(ItemData.getItem(inventory[slot1][0]) is ItemArmorHelmet)
			points += int(ItemData.getItem(inventory[slot2][0]) is ItemArmorHelmet)
			updateArmor = true
		41: #chest
			points += int(ItemData.getItem(inventory[slot1][0]) is ItemArmorChest)
			points += int(ItemData.getItem(inventory[slot2][0]) is ItemArmorChest)
			updateArmor = true
		42: #legs
			points += int(ItemData.getItem(inventory[slot1][0]) is ItemArmorLegs)
			points += int(ItemData.getItem(inventory[slot2][0]) is ItemArmorLegs)
			updateArmor = true
		50: #vanity helmet
			points += int(ItemData.getItem(inventory[slot1][0]) is ItemArmorHelmet)
			points += int(ItemData.getItem(inventory[slot2][0]) is ItemArmorHelmet)
			updateArmor = true
		51: #vanity chest
			points += int(ItemData.getItem(inventory[slot1][0]) is ItemArmorChest)
			points += int(ItemData.getItem(inventory[slot2][0]) is ItemArmorChest)
			updateArmor = true
		52: #vanity legs
			points += int(ItemData.getItem(inventory[slot1][0]) is ItemArmorLegs)
			points += int(ItemData.getItem(inventory[slot2][0]) is ItemArmorLegs)
			updateArmor = true
		43,44,45,46,47,48:
			points += int(ItemData.getItem(inventory[slot1][0]) is ItemTrinket)
			points += int(ItemData.getItem(inventory[slot2][0]) is ItemTrinket)
			if points > 0:
				givemedal = true
			updateArmor = true
		
		
		PlayerData.selectedSlot:
			updateHeld = true
			points += 3
		
		_: # every other slot
			points += 3
	
	if inventory[slot1][0] == -1:
		points += 1
	if inventory[slot2][0] == -1:
		points += 1
	
	if points < 2:
		return
	
	if givemedal:
		AchievementData.unlockMedal("equipTrinket")
	
	var carry = inventory[slot1].duplicate()
	inventory[slot1] = inventory[slot2]
	inventory[slot2] = carry
	
	GlobalRef.playerCanUseItem = false
	
	if slot1 >= 53 and currentSelectedChest != null:
		saveChestString()
	
	emit_signal("updateInventory")
	emit_signal("onlyUpdateCraft")
	var g = GlobalRef.player.get_global_mouse_position()
	SoundManager.playSound("inventory/pickupItem",g,1.0,0.12,"INVENTORY")
	if updateArmor:
		emit_signal("armorUpdated")
	if updateHeld:
		PlayerData.selectSlot(PlayerData.selectedSlot)
	

func getSelectedItemData():
	return ItemData.data[inventory[selectedSlot][0]]

func getSelectedItemID():
	return inventory[selectedSlot][0]

func consumeSelected():
	inventory[selectedSlot][1] -= 1
	if inventory[selectedSlot][1] <= 0:
		inventory[selectedSlot] = [-1,-1]
	emit_signal("updateInventory")
	emit_signal("onlyUpdateCraft")

func getItemTotals():
	var items = []
	var amounts = []
	for item in inventory:
		if item[0] == -1: continue
		if items.has(item[0]):
			amounts[items.find(item[0])] += item[1]
		else:
			items.append(item[0])
			amounts.append(item[1])
	return [items,amounts]

func consumeItems(items:Array,amounts:Array):
	for i in range(items.size()):
		consumeFromSlots(checkForEnoughItems(items[i],amounts[i]),amounts[i])

func checkForEnoughItems(itemID,amount):
	var foundAmount = 0
	var slots = []
	for i in range(40):
		if inventory[i][0] == itemID:
			foundAmount += inventory[i][1]
			slots.append(i)
		if foundAmount >= amount:
			return slots
	return slots

func checkForItemAmount(itemID):
	var foundAmount = 0
	for i in range(40):
		if inventory[i][0] == itemID:
			foundAmount += inventory[i][1]
	return foundAmount

func consumeFromSlots(slots:Array,amount:int):
	var amountLeft = amount
	for i in slots:
		if inventory[i][1] > amountLeft:
			inventory[i][1] -= amountLeft
			return
		amountLeft -= inventory[i][1]
		inventory[i] = [-1,-1]

func craftItem(recipe:CraftingRecipe):
	if inventory[49][0] != -1 and inventory[49][0] != recipe.itemToCraft:
		return
	
	var maxStack = ItemData.getItem(recipe.itemToCraft).maxStackSize
	if inventory[49][1] + recipe.amountToCraft > maxStack:
		return
	
	var ingredients = []
	var ingAmounts = []
	for ing in recipe.ingredients:
		ingredients.append( ing.ingredient )
		ingAmounts.append( ing.amount )
	
	consumeItems(ingredients,ingAmounts)
	if inventory[49][0] == -1:
		inventory[49] = [ recipe.itemToCraft,recipe.amountToCraft ]
	else:
		if inventory[49][1] + recipe.amountToCraft <= maxStack:
			inventory[49][1] += recipe.amountToCraft
	emit_signal("updateInventory")
	
	for i in ingredients.size():
		if checkForItemAmount(ingredients[i]) < ingAmounts[i]:
			return false # can not craft again
	
	return true # can craft again

func sendHealthUpdate(newHealth,newMax):
	maxHealth = newMax
	currentHealth = newHealth
	emit_signal("updateHealth")

func selectSlot(newSlot):
	selectedSlot = newSlot
	emit_signal("selectedSlotChanged")

func checkForIngredient(itemID,amount):
	var foundAmount = 0
	var slots = []
	for i in range(40):
		if inventory[i][0] == itemID:
			foundAmount += inventory[i][1]
			slots.append(i)
		if foundAmount >= amount:
			return true
	return false

func getSlotItemData(slot:int):
	return ItemData.data[inventory[slot][0]]

func openChestInventory(chestarray:Array):
	inventory.resize(53)
	inventory += chestarray

func clearChestInventory():
	inventory.resize(53)
	#var newAppendArray = []
	for i in range(25):
		inventory.append([-1,-1])

func saveChestString():
	if currentSelectedChest == null:
		return
	
	var chestString = ""
	for i in range(25):
		var slot :int= 53 + i
		var id :int= inventory[slot][0] 
		if id == -1:
			continue
		var amount :int= inventory[slot][1]
		var string :String= str(id) + "x" + str(amount) + "x" + str(i)
		# 3010x1x0,13x99x16,
		chestString = chestString + string + ","
	
	chestOBJ.chestDictionary[currentSelectedChest] = chestString

func saveChestFromArray(data):
	var chestString = ""
	for i in range(25):
		var slot :int= i
		var id :int= data[slot][0] 
		if id == -1:
			continue
		var amount :int= data[slot][1]
		var string :String= str(id) + "x" + str(amount) + "x" + str(i)
		# 3010x1x0,13x99x16,
		chestString = chestString + string + ","
	
	return chestString

func loadChestString(chestString:String):
	# parse string
	var a :PackedStringArray = chestString.split(",",false)
	var chestInv :Array[Array]= []
	var previousSlot :int= -1
	for itemString in a:
		var id :int = int(itemString.get_slice("x",0))
		var amount :int = int(itemString.get_slice("x",1))
		var slot :int = int(itemString.get_slice("x",2))
		
		for i in range( slot-previousSlot-1 ):
			chestInv.append( [-1,-1] ) # append a certain amount of empty slots
		
		chestInv.append( [id,amount] ) # append the real item
		
		previousSlot = slot
	
	for i in range(24 -previousSlot):
		chestInv.append( [-1,-1] )
	
	return chestInv

func generateEmptyChest():
	var array = []
	for i in range(25):
		array.append([-1,-1])
	return array
	
func loadChest(body,pos):
	
	if chestDisCheck(body,pos):
		return false
	
	currentSelectedChest = pos
	
	var chestArray :Array
	var chestString = ""
	if body.chestDictionary.has(currentSelectedChest):
		chestString = body.chestDictionary[currentSelectedChest]
	
	if chestString != "":
		chestArray = loadChestString(chestString)
	else:
		chestArray = generateEmptyChest()
	
	chestOBJ = body
	openChestInventory(chestArray)
	emit_signal("updateInventory")
	emit_signal("forceOpenInventory")
	
	return true
	
func closeChest():
	if currentSelectedChest == null:
		return
	
	saveChestString()
	clearChestInventory()
	
	chestOBJ = null
	currentSelectedChest = null

func chestDisCheck(body,tile):
	var glob = GlobalRef.player.global_position
	var secGlob = body.to_global(body.tileToPos(tile))
	var dis = abs((glob - secGlob).length())
		
	if dis > 40:
		return true
	return false

func dropChestContainer(body,pos,string):
	# parse string
	var a :PackedStringArray = string.split(",",false)

	for itemString in a:
		var id :int = int(itemString.get_slice("x",0))
		var amount :int = int(itemString.get_slice("x",1))
		BlockData.spawnLooseItem(body.tileToPos(pos),body,id,amount)
	closeChest()
	
	
func scanForArrow():
	for i in range(40):
		var id = inventory[i][0]
		var data = ItemData.getItem(id)
		if data is ItemArrow:
			return [data,i] # sends item data and slots
	return null

func scanForBullet():
	for i in range(40):
		var id = inventory[i][0]
		var data = ItemData.getItem(id)
		if data is ItemBullet:
			return [data,i] # sends item data and slots
	return null

func scanForBlock():
	for i in range(40):
		var id = inventory[i][0]
		var data = ItemData.getItem(id)
		if data is ItemBlock:
			return [data,i] # sends item data and slots
		if data is ItemTypeBlock:
			return [data,i] # sends item data and slots
	return null

func replaceSelectedSlot(id:int,amount:int):
	inventory[selectedSlot] = [id,amount]
	emit_signal("updateInventory")

func getHandSlot():
	return inventory[49]

func clearHandSlot():
	inventory[49] = [-1,-1]

func _unhandled_input(event):
	if event.is_action_pressed("mouse_right"):
		
		if GlobalRef.player.dead:
			return # can't drop items, player is dead
		
		var slot = getHandSlot()
		if slot[0] == -1:
			return
		
		var playerState = GlobalRef.player.state
		var mouseX = int(GlobalRef.player.get_local_mouse_position().rotated(GlobalRef.player.rotated*-(PI/2)).x > 0) * 2
		match playerState:
			3:
				return
			0:
				var planet = GlobalRef.player.planetOn
				var tile = planet.posToTile(GlobalRef.player.position)
				BlockData.spawnItemRaw(tile.x,tile.y,slot[0],planet,slot[1],true, mouseX - 1 )
			2:
				var planet = GlobalRef.player.shipOn
				var tile = planet.posToTile(GlobalRef.player.shipOn.to_local(GlobalRef.player.global_position))
				BlockData.spawnItemRaw(tile.x,tile.y,slot[0],planet,slot[1],true, mouseX - 1 )
			1:
				var planet = GlobalRef.player.shipOn
				var tile = planet.posToTile(GlobalRef.player.shipOn.to_local(GlobalRef.player.global_position))
				BlockData.spawnItemRaw(tile.x,tile.y,slot[0],planet,slot[1],true, mouseX - 1 )
			
				
		clearHandSlot()
		emit_signal("updateInventory")

####################################################################
####################################################################
######################### CRAFTING REDONE ##########################
####################################################################
####################################################################

func parseRecipies() -> Array:
	
	var recipies :Array[int]= []
	
	for slot in range(40): # scans all items in inventory
		
		if inventory[slot][0] == -1:
			continue # ignore if slot empty
		
		var item = ItemData.getItem(inventory[slot][0])
		for recipe in item.materialIn: # scans each recipe on item
			if !recipies.has( recipe ):
				recipies.append( recipe ) # appends every unique recipe
	
	# return all discovered recipies
	
	return recipies

func checkIfCraftable(recipe:CraftingRecipe):
	for ing in recipe.ingredients:
		if !checkForIngredient(ing.ingredient,ing.amount):
			return false
	return true

func addMoney(amount:int):
	money += amount
	emit_signal("updateMoney")
	if money > 5000:
		AchievementData.unlockMedal("haveMoney")

func loseMoney(amount:int):
	money -= amount
	if money < 0:
		money = 0
	emit_signal("updateMoney")

func spendMoney(amount:int) -> bool: # returns false if not enough cash
	if money - amount < 0:
		return false
	money -= amount
	emit_signal("updateMoney")
	return true

func updateCraftingDisplay(n):
	displayedCrafting = n
	emit_signal("changedDisplayedCrafting")
