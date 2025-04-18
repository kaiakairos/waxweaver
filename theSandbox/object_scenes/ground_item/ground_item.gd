extends CharacterBody2D
class_name GroundItem

@onready var texture = $textureRoot/texture
@onready var back = $textureRoot/back

@onready var tint = $textureRoot/texture/tint

@onready var floorDetector = $FloorDetector

var rotSide = 0

var gravity = 600

var itemID = 0
var amount = 1
var maxAmount = 99

var ticks = 0

var tweening = false

var parent

var droppedByPlayer :float= 0
var dropvel :Vector2 = Vector2.ZERO

var frozen = false

var coolVelcoity :bool = false
var pickedByHopper :bool = false

func _ready():
	var itemData = ItemData.getItem(itemID)
	
	var img = itemData.texture.get_image()
	img.resize(int(img.get_width()*0.75),int(img.get_height()*0.75),0)
	
	texture.texture = ImageTexture.create_from_image(img)
	back.texture = texture.texture
	maxAmount = itemData.maxStackSize
	
	if !itemData is ItemBlock:
		texture.material = null
	
	parent = get_parent().get_parent()
	
	if droppedByPlayer <= 0 and !coolVelcoity:
		var randVelocity = Vector2(randi_range(-70,70),-60)
		rotSide = getPlanetPosition()
		velocity = randVelocity.rotated(rotSide*(PI/2))
	else:
		rotSide = getPlanetPosition()
		velocity = dropvel.rotated(GlobalRef.player.rotated*(PI/2))
	

	
	determineAmount()
	
func _process(delta):
	
	droppedByPlayer -= 60.0 * delta
	
	if tweening:
		return
	
	ticks += 1 * delta * 80.0
	rotSide = getPlanetPosition()
	
	var newVelocity = velocity.rotated(-rotSide*(PI/2))
	
	if !coolVelcoity:
		if !frozen:
			newVelocity.x = lerp(newVelocity.x,0.0,8.0*delta)
			newVelocity.y += gravity * delta
			newVelocity.y = min(newVelocity.y,150)
		else:
			newVelocity = lerp(newVelocity,Vector2.ZERO,0.2)
	else:
		#newVelocity.x = lerp(newVelocity.x,0.0,8.0*delta)
		newVelocity.y += gravity * delta
		newVelocity.y = min(newVelocity.y,150)
	
	match floorDetector.getFloorTile():
		105:
			newVelocity.x = GlobalRef.conveyorspeed
		106:
			newVelocity.x = -GlobalRef.conveyorspeed
	
	velocity = newVelocity.rotated(rotSide*(PI/2))
	
	move_and_slide()
	
	if parent is Ship:
		$textureRoot.rotation = 0
	else:
		$textureRoot.rotation = rotSide*(PI/2)
	
	texture.offset.y = (sin(ticks*0.12) * 2.0) - 2
	back.offset.y = texture.offset.y
	
	if parent is Ship:
		var t = parent.posToTile(position)
		if t == null:
			return # gay
		if parent.DATAC.getBGData(t.x,t.y) <= 1:
			if parent.get_parent().is_in_group("planet"):
				# on planet
				reparent(parent.get_parent().get_parent().entityContainer)
			else:
				frozen = true
	
func getPlanetPosition():
	if !is_instance_valid(parent):
		return 0
	if parent is Ship:
		if parent.get_parent().is_in_group("planet"):
				# on planet
				return parent.targetRot
		return 0
		
	var p = parent.posToTile(position)
	if p == null:
		var angle1 = Vector2(1,1)
		var angle2 = Vector2(-1,1)
		
		var dot1 = int(position.dot(angle1) >= 0)
		var dot2 = int(position.dot(angle2) > 0) * 2
		
		return [0,1,3,2][dot1 + dot2]
	return parent.DATAC.getPositionLookup(p.x,p.y)

func _on_area_2d_body_entered(body):
	
	if tweening:
		return
	tweenAndDestroy(body.global_position,true)


func _on_stack_body_entered(body):
	
	## Stack with items of same type ##
	
	if tweening or body == self:
		return

	if body is GroundItem:
		if body.itemID != itemID or body.tweening:
			return
		if body.ticks >= ticks:
			if amount + body.amount > maxAmount: return
			amount += body.amount
			determineAmount()
			body.tweenAndDestroy(global_position,false)
			return

func determineAmount():
	if amount > 1:
		tint.color.a = (amount - 1) * 0.05

func tweenAndDestroy(pos,shouldAddItem):
	if tweening:
		return
	
	if droppedByPlayer > 0:
		return
		
	tweening = true
	var tween = get_tree().create_tween()
	tween.tween_property(self,"global_position",pos,0.1)
	await tween.finished
	
	if shouldAddItem:
		var amountLeft = PlayerData.addItem(itemID,amount)
		if amountLeft == 0:
			var itemData = ItemData.getItem(itemID)
			Indicators.itemPopup(itemData.itemName,amount,global_position)
			SoundManager.playSound("inventory/pickupItem",global_position,1.0,0.12,"INVENTORY")
			queue_free()
		else:
			tweening = false
			amount = amountLeft
	else:
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
