extends CanvasGroup

var startFrame :int = 0

func _ready():
	changeArmor()
	setFrame(startFrame)
		

func setFrame(frame:int):
	for child in get_children():
		child.frame = frame
		if GlobalRef.playerSide == 0:
			child.flip_h = true

func _process(delta):
	modulate.a -= 0.02 * 60.0 * delta
	if modulate.a < 0.0:
		queue_free()

func changeArmor():
	
	var helmet = PlayerData.getSlotItemData(40)
	var chest = PlayerData.getSlotItemData(41)
	var legs = PlayerData.getSlotItemData(42)
	
	var vanityHelmet = PlayerData.getSlotItemData(50)
	var vanityChest = PlayerData.getSlotItemData(51)
	var vanityLegs = PlayerData.getSlotItemData(52)
	
	# check for main armor
	if helmet is ItemArmorHelmet:
		$helmet.texture = helmet.armorTexture

	if chest is ItemArmorChest:
		$chestplate.texture =  chest.armorTexture

	if legs is ItemArmorLegs:
		$leggings.texture =  legs.armorTexture
	
	# check for vanity
	if vanityHelmet is ItemArmorHelmet:
		$helmet.texture =  vanityHelmet.armorTexture

	if vanityChest is ItemArmorChest:
		$chestplate.texture =  vanityChest.armorTexture

	if vanityLegs is ItemArmorLegs:
		$leggings.texture =  vanityLegs.armorTexture
