extends Item
class_name ItemGift

@export var loottable :Loot
@export var unlockAchievement :bool = false

func onUse(tileX:int,tileY:int,planetDir:int,planet,lastTile:Vector2):
	var items :Array[LootItem] = loottable.getLoot()
	PlayerData.consumeSelected()
	for item in items:
		var itemCountLeft = PlayerData.addItem(item.id,item.amount)
		if itemCountLeft > 0:
			BlockData.spawnItemVelocity(GlobalRef.player.position,item.id,planet,Vector2(0,0),itemCountLeft)
		else:
			Indicators.itemPopup(ItemData.getItemName(item.id),item.amount,GlobalRef.player.global_position)
		
		print( "Loot found: " + str(item.amount) + " " + ItemData.getItemName(item.id) )
		
		
	GlobalRef.player.spawnGiftParticle()
	
	if unlockAchievement:
		AchievementData.unlockMedal("findVanity")
