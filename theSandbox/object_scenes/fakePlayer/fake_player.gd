extends CharacterBody2D
class_name FakePlayer

var planet :Planet
var movingDir :int = 0

var speed :float = 98.0

var steam_ID :int = 0

var blinkTick : float = 240.0

var quad :int = 0

func _process(delta:float) -> void:
	quad = getQuad()
	move(delta)
	if movingDir != 0:
		$PlayerLayers.scale.x = movingDir
	blink(delta)
	updateAnimation()
	rotation = quad * (PI/2)
	up_direction = Vector2(0,-1).rotated(quad * (PI/2))

func move(delta:float) -> void:
	var newVel :Vector2= velocity.rotated( quad * (PI/2) * -1 )
	
	var gorp :float = 1.0
	if $ceilingCast.is_colliding():
		gorp = 0.25
		squish(0.68)
	else:
		squish(1.0)
	
	newVel.x = lerp(newVel.x,speed * movingDir * gorp, 1.0-pow(2.0,(-delta/0.04)) )
	newVel.y += 1000.0 * delta
	newVel.y = min(300,newVel.y) # cap vertical speed
		
	velocity = newVel.rotated( getQuad() * (PI/2))
	move_and_slide()

func jump(height:int):
	var newVel :Vector2= velocity.rotated( getQuad() * (PI/2) * -1 )
	newVel.y = -height
	velocity = newVel.rotated( getQuad() * (PI/2))

func getMovementPacket(packet:Dictionary):
	position = packet["position"]
	movingDir = packet["newDir"]
	speed = packet["speed"]
	$PlayerLayers/eye/Pupil.offset = packet["pupil"]
	if packet["jump"] > 0:
		jump(packet["jump"])
	
	

func getQuad() -> int:
	
	var pos = getPos()
	if pos == null:
		var angle1 = Vector2(1,1)
		var angle2 = Vector2(-1,1)
			
		var dot1 = int(position.dot(angle1) >= 0)
		var dot2 = int(position.dot(angle2) > 0) * 2
		
		return [0,1,3,2][dot1 + dot2]
	
	return planet.DATAC.getPositionLookup(pos.x,pos.y)

func getPos():
	return planet.posToTile(position)

func setAllPlayerFrames(frame:int):
	for sprite in $PlayerLayers.get_children():
		sprite.frame = frame

func updateAnimation():
	var trueVel :Vector2= velocity.rotated( getQuad() * (PI/2) * -1 )
	if !is_on_floor():
		if trueVel.y < 0:
			setAnim("jump")
		else:
			setAnim("fall")
		return
	
	if movingDir == 0:
		setAnim("idle")
	else:
		$AnimationPlayer.play("walk")

func setAnim(newAnim:String):
	if newAnim == $AnimationPlayer.current_animation:
		return
	$AnimationPlayer.play(newAnim)

func blink(delta:float):
	
	blinkTick += delta * 60.0
	if blinkTick > 120.0:
		if randi() % 60 == 0:
			$PlayerLayers/eye.visible = false
			blinkTick = -5.0
			if randi() % 6 == 0:
				blinkTick = -15.0
			
	if roundi(blinkTick) == 0 or roundi(blinkTick) == -10:
		$PlayerLayers/eye.visible = true
	elif roundi(blinkTick) == -5:
		$PlayerLayers/eye.visible = false

func squish(target:float):
	for obj in $PlayerLayers.get_children():
		obj.scale.y = lerp(obj.scale.y,target,0.2)
		if obj == $PlayerLayers/eye:
			obj.scale.y = 1.0
			obj.position.y = lerp(obj.position.y,3.0+(3.0*int(target!=1.0)),0.2 )

func setArmor(helmetid:int,chestid:int,legsid:int):
	
	var helmet = ItemData.getItem(helmetid)
	var chest = ItemData.getItem(chestid)
	var legs = ItemData.getItem(legsid)
	
	
	
	# check for main armor
	if helmet is ItemArmorHelmet:
		$PlayerLayers/helmet.texture =  helmet.armorTexture
	else:
		$PlayerLayers/helmet.texture = null
	
	if chest is ItemArmorChest:
		$PlayerLayers/chestplate.texture =  chest.armorTexture
	else:
		$PlayerLayers/chestplate.texture = null
	
	if legs is ItemArmorLegs:
		$PlayerLayers/leggings.texture =  legs.armorTexture
	else:
		$PlayerLayers/leggings.texture = null
