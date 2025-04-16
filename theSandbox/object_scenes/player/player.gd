extends CharacterBody2D
class_name Player

@export var system : Node2D

@onready var sprite = $PlayerLayers
@onready var animationPlayer = $AnimationPlayer
@onready var cameraOrigin = $CameraOrigin

@onready var shipDEBUG = preload("res://world_scenes/ship/ship.tscn")

@onready var healthComponent :HealthComponent= $HealthComponent
@onready var shipFinder = $ShipFinder
@onready var floorDetector = $FloorDetector

@onready var gift = preload("res://object_scenes/particles/giftopenparticle/giftopenparticle.tscn")
@onready var aura = preload("res://object_scenes/particles/playerAura/player_aura.tscn")

var rotated = 0
var rotationDelayTicks = 0

var gravity = 1000

var previousChunk = Vector2.ZERO

var planetOn :Node2D = null
var shipOn :Node2D = null
var lastPlanetOn :Node2D = null
##States: 0 = ON PLANET, 1 = ON SHIP IN SPACE, 
##      2 = ON SHIP ON PLANET, 3 = IN SPACE
var state = 0 

## States: 0 = REGULAR, 1 = SITTING, 2 = LADDER, 3 = BED
var movementState = 0

var animSecs :float= 0
var ladderSecs :float= 0
var lastOnLadder :float= 0 # for determining if the player can attach to ladder again
var maxCameraDistance := 0

var lastTileItemUsedOn := Vector2(-10,-10)

var noClip = false
var noClipSpeed = 200

var tick = 0
var blinkSecs :float= 0

var beingKnockedback = false

var dead = false

var wasInWater = false
var wasJustOnFloorEarlierActually = false

var airTime :float = 0.0

@onready var itemRoot = $itemWorldRotation/heldItemRoot
var heldItemAnim :itemHeldClass = null

var usingItem = false

## armors
@onready var helmetSpr = $PlayerLayers/helmet
@onready var chestSpr = $PlayerLayers/chestplate
@onready var legsSpr = $PlayerLayers/leggings

var myTile := Vector2.ZERO # players tile in the world
var lastFloorTile := 0

# footstep
var stream :AudioStreamOggVorbis = null #SoundManager.getMineSound(blockID)

@export var manaFilledPart :CPUParticles2D

var holdingtick :int = 0
var justswapped :bool = false

var jumpsRemaining :int = 0
var hoverSecs :int= 0
var dashIdle :int = 0
var canDash :bool = true
var dashDelay :int = 0

var holdingDirection :int = 0


######################################################################
########################### BASIC FUNTIONS ###########################
######################################################################


func _ready():
	GlobalRef.player = self
	GlobalRef.playerHC = healthComponent
	PlayerData.connect("selectedSlotChanged",swapSlot)
	PlayerData.connect("armorUpdated",changeArmor)
	
	if system.planetsShouldGenerate: # new game
		PlayerData.addItem(3000,1)
		PlayerData.addItem(3001,1)
	
	PlayerData.selectSlot(0)
	
	PlayerData.emit_signal("armorUpdated")
	healthComponent.health = GlobalRef.savedHealth
	PlayerData.emit_signal("updateHealth")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	
	

func _process(delta):
	
	tick+=1
	
	$rightClicker.global_position = get_global_mouse_position()
	
	if Stats.specialProperties.has("iv") and healthComponent.health < healthComponent.maxHealth:
		healthComponent.inflictStatus("normalRegen",0.1)
	
	
	if Input.is_action_pressed("mouse_left"): # this is stupid just for item bug
		holdingtick += 1
	else:
		holdingtick = 0
	
	match state:
		0: #On planet
			z_index = 0
			determineMovementState(delta)
			findShipToAttachTo()
			detachFromPlanetToSpace()
		1: #On ship in space
			z_index = 1
			if detachFromShip(): return
			determineMovementState(delta)
			findPlanetToAttachInShip()
		2: # On ship on planet
			z_index = 1
			determineMovementState(delta)
			detachFromShip()
			shipDetachFromPlanet()
		3: # In space
			z_index = 0
			if findShipToAttachTo(): return
			inSpaceMovement(delta)
			findPlanetToAttachInSpace()

	scrollBackgrounds(velocity,delta)
	
	## do mouse stuff ##
	
	## Ignore below for now ##
	shipFinder.global_position = get_global_mouse_position()
	if dead:
		return
	
	runItemProcess(delta)
	if usingItem:
		useItem()
	else:
		lastTileItemUsedOn = Vector2(-10,-10)
	
	if !GlobalRef.playerCanUseItem:
		GlobalRef.playerCanUseItem = true
	
	if GlobalRef.chatIsOpen:
		return
	
	#map toggle
	#if Input.is_action_just_pressed("map"):
	#	GlobalRef.camera.mapbg.visible = !GlobalRef.camera.mapbg.visible
	#	GlobalRef.camera.map.visible = GlobalRef.camera.mapbg.visible
	
	# suffocates player if they are in a block
	if $suffocatingCast/suffocate.is_colliding() and !noClip:
		healthComponent.inflictStatus("suffocating",0.1)
	
	$rotateRand.rotation = sprite.rotation
	
######################################################################
############################## MOVEMENT ##############################
######################################################################

func determineMovementState(delta):
	
	if noClip:
		noClipMovement(delta)
		return
	
	match movementState:
		0:
			normalMovement(delta)
		1:
			chairMovement(delta)
		2:
			ladderMovement(delta)
		3:
			bedMovement(delta)

func noClipMovement(delta):
	var dir = Vector2.ZERO
	dir.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	dir.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	
	if GlobalRef.chatIsOpen:
		dir = Vector2.ZERO
	
	if !dead:
		if Input.is_action_just_pressed("scroll_up"):
			noClipSpeed += 100
		elif Input.is_action_just_pressed("scroll_down"):
			noClipSpeed -= 100
			noClipSpeed = max(0,noClipSpeed)
		
	velocity = dir.normalized() * noClipSpeed
	move_and_slide()
	
	if !dead:
		GlobalRef.camera.rotation = 0
	ensureCamPosition()
	updateLight()

func setPlanetRotation():
	var newRotation = getPlanetPosition()
	if newRotation != rotated:
		rotationDelayTicks -= 1
		if rotationDelayTicks <= 0:
			rotated = newRotation
			rotationDelayTicks = 8
		airTime = 0.0 # cancel fall damage if screen rotates
	else:
		rotationDelayTicks = 8

func getProperRotationSource():
	if GlobalRef.playerGravityOverride != -1:
		return GlobalRef.playerGravityOverride * (PI/2)
	if state == 0:
		return rotated*(PI/2)
	return shipOn.rotation

func normalMovement(delta):
	
	setPlanetRotation()
	var rotSource = getProperRotationSource() # should rotate to planet or ship
	
	sprite.rotation = lerp_angle(sprite.rotation,rotSource,0.4)
	$itemWorldRotation.rotation = sprite.rotation
	up_direction = Vector2(0,-1).rotated(rotSource)
	
	var onFloor = isOnFloor(rotSource)
	var speed = Stats.getSpeed()
	
	if onFloor and !wasJustOnFloorEarlierActually:
		playFootstepSound() # landing on floor sound effect
	wasJustOnFloorEarlierActually = onFloor
	
	if squishHeadUnderCeiling(): # reduce speed if squashed
		speed *= 0.25
	
	var doubleTapped = false
	
	var dir = 0
	dir = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	
	if healthComponent.checkIfHasEffect("confused"):
		dir *= -1
	
	if dir != 0:
		
		
		if GlobalRef.playerSide == int(dir == 1):
			if dashIdle < 10 and dashIdle > 0 and holdingDirection < 10:
				doubleTapped = true
		dashIdle = -1
		
		GlobalRef.playerSide = int(dir == 1)
		
		holdingDirection += 1
		
		if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
			holdingDirection = 0
		
	else:
		dashIdle += 1
	
	if GlobalRef.chatIsOpen:
		dir = 0
	
	var speedAdd :float= 0.0
	match floorDetector.getFloorTile():
		105:
			speedAdd = GlobalRef.conveyorspeed
		106:
			speedAdd = -GlobalRef.conveyorspeed
	
	
	var newVel = velocity.rotated(-rotSource)
	if beingKnockedback:
		newVel.x = lerp(newVel.x, (dir * speed) + speedAdd, 0.025) # make framerate independent
	else:
		newVel.x = lerp(newVel.x, (dir * speed) + speedAdd, 1.0-pow(2.0,(-delta/0.04)))
	
	if doubleTapped and canDash and dashDelay <= 0 and Stats.hasProperty("dash"):
		newVel.x = 1800.0 * dir * Stats.speedMult
		canDash = false
		dashDelay = 30
		beingKnockedback = false
	if dashDelay > 0:
		dashDelay -= 1
		dashingParticle()
	
	newVel.y += Stats.getGravity() * delta
	newVel.y = min(newVel.y,Stats.getTerminalVelocity())
	
	var body = planetOn
	if shipOn != null:
		body = shipOn
	$swimmingDetector.body = body
	newVel = WATERJUMPCAMERALETSGO(body,newVel,rotSource,onFloor,delta)
	
	if movementState == 2:
		updateLight()
		ensureCamPosition()
		return
	
	if healthComponent.checkIfHasEffect("frozen"):
		var newerVel = velocity.rotated(-rotSource)
		newerVel.x = lerp(newerVel.x,0.0,0.1)
		newerVel.y += 1000 * delta
		newVel = newerVel
	
	velocity = newVel.rotated(rotSource)
	
	
	move_and_slide()
	
	playerAnimation(dir,newVel,delta)
	updateLight()
	
	ensureCamPosition()
	
	if onFloor and beingKnockedback and newVel.y > 0:
		beingKnockedback = false
	
	if !onFloor:
		airTime += delta
		if newVel.y < 0:
			airTime = 0.0
	else:
		# fall damage stuff
		var fallDamage = int(airTime * 60.0 ) - 35
		
		if Stats.hasProperty("fallImmune"):
			fallDamage = 0
		
		if fallDamage > 10:
			healthComponent.damage(fallDamage,null,false,"fall damage")
			if fallDamage >= 90 and healthComponent.health > 0 and healthComponent.health < 10:
				AchievementData.unlockMedal("takeFall")
		airTime = 0.0

func WATERJUMPCAMERALETSGO(body,vel,rot,onFloor,delta):
	# uses world to alter velocity
	if !is_instance_valid(body):
		return vel
	var tile = body.posToTile(body.to_local(global_position))
	
	if tile == null:
		return vel
	
	#load audio stream for footstep
	if tile != myTile: # if tile changes
		var floorr = tile + Vector2(0,1).rotated((PI/2)*rotated) # gets floor tile
		var blockID :int = body.DATAC.getTileData(floorr.x,floorr.y)
		if blockID != null and lastFloorTile != blockID and blockID > 1:
			stream = SoundManager.getMineSound(blockID)
			lastFloorTile = blockID
	
	myTile = tile
	
	# attach to ladder if holding up
	if lastOnLadder > 0:
		lastOnLadder -= delta # subtract ladder msecs
	if body.DATAC.getTileData(tile.x,tile.y) == 25:
		if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
			
			if lastOnLadder > 0:
				return vel
			
			velocity = Vector2.ZERO
			vel = Vector2.ZERO
			if movementState == 2:
				return vel
			animationPlayer.stop()
			movementState = 2 # enter ladder state
			if body is Planet:
				rotated = body.DATAC.getPositionLookup(tile.x,tile.y)
			attachToLadder(tile,body)
	
	
	# emit light if have trinket
	if Stats.hasProperty("emitLight"):
		var amount :float = 0.6
		var l = body.DATAC.getLightData(tile.x,tile.y)
		if l <= amount:
			body.DATAC.setLightData(tile.x,tile.y,-amount)
	
	# there must be a better way
	var inWater = abs(body.DATAC.getWaterData(tile.x,tile.y)) > 0.3
	if inWater: # code if currently in water
		wasInWater = true
		canDash = true
		$Bubble.scale = Vector2.ZERO
		hoverSecs = 0
		jumpsRemaining = Stats.extraJumps
		healthComponent.inflictStatus("wet",8)
		vel.y = min(vel.y,30 + (Stats.swimMult * 2.5))
		if Input.is_action_pressed("jump") and !GlobalRef.chatIsOpen:
			vel.y = -25 - Stats.getSwim()
		lerpCameraRotation(rot,delta)
		vel.x = clamp(vel.x, -Stats.getSwim(),Stats.getSwim() )
		airTime = 0.0 # cancel fall damage
		return vel
	
	if wasInWater and Input.is_action_pressed("jump"):
		vel.y += -150.0
		wasInWater = false
		# code for leaving water
			
	if onFloor: # this is where the regular jump is done
		jumpsRemaining = Stats.extraJumps
		canDash = true
		if hoverSecs > 0 and $Bubble.scale.x > 0.1:
			$Bubble.scale = Vector2.ZERO
			var fart = load("res://object_scenes/particles/bubblewand/bubblepop.tscn").instantiate()
			fart.position = position
			get_parent().add_child(fart)
		hoverSecs = 0
		if Input.is_action_just_pressed("jump") and !GlobalRef.chatIsOpen:
			vel.y = Stats.getJump()
			
		lerpCameraRotation(rot,delta)
	elif jumpsRemaining > 0:
		if Input.is_action_just_pressed("jump") and !GlobalRef.chatIsOpen:
			vel.y = Stats.getJump()
			jumpsRemaining -= 1
			airTime = 0.0 # cancel fall damage
			var fart = load("res://object_scenes/particles/doubleJump/doublejumpparticle.tscn").instantiate()
			fart.position = position
			fart.rotation = sprite.rotation
			get_parent().add_child(fart)
	elif Stats.specialProperties.has("bubblehover"):
		if hoverSecs == 0:
			if Input.is_action_just_pressed("jump"):
				hoverSecs = 120
		elif hoverSecs > 0 and Input.is_action_pressed("jump"):
			hoverSecs -= delta
			vel.y = lerp(vel.y,0.0,0.5)
			airTime = 0
			$Bubble.scale = lerp($Bubble.scale,Vector2(1,1),0.2)
			$Bubble.rotation = sprite.rotation
			if hoverSecs <= 0:
				hoverSecs = -1
				$Bubble.scale = Vector2.ZERO
				var fart = load("res://object_scenes/particles/bubblewand/bubblepop.tscn").instantiate()
				fart.position = position
				get_parent().add_child(fart)
		elif Input.is_action_just_released("jump") and hoverSecs > 0:
			$Bubble.scale = Vector2.ZERO
			var fart = load("res://object_scenes/particles/bubblewand/bubblepop.tscn").instantiate()
			fart.position = position
			get_parent().add_child(fart)
	
	if GlobalRef.playerGravityOverride != -1:
		lerpCameraRotation(rot,delta)
	return vel

func chairMovement(delta):
	
	velocity = Vector2.ZERO
	
	
	if shipOn != null:
		sprite.rotation = shipOn.rotation
		lerpCameraRotation(shipOn.rotation,delta)
	if Input.is_action_pressed("jump"):
		movementState = 0
	
	squishSprites(1.0)
	eyeBallAnim(delta)
	updateLight()
	ensureCamPosition()

func ladderMovement(delta):
	
	lastOnLadder = 0.4
	
	if beingKnockedback: # cancel ladder state if hit
		movementState = 0
		return
	
	var vdir = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	
	var hdir = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if hdir != 0:
		flipPlayer(hdir)
	
	sprite.rotation = lerp_angle(sprite.rotation,rotated*(PI/2),0.4)
	$itemWorldRotation.rotation = sprite.rotation
	up_direction = Vector2(0,-1).rotated(rotated*(PI/2))
	
	airTime = 0.0
	
	## animtation
	if vdir != 0:
		ladderSecs += delta
		if ladderSecs > 0.14:
			if getPlayerFrame() == 8:
				setAllPlayerFrames(9)
			else:
				setAllPlayerFrames(8)
			SoundManager.playSound("items/ladderClimb",global_position,1.2,0.1)
			ladderSecs = 0
	else:
		ladderSecs = 0.139
	
	var obj = planetOn
	
	var newVel = Vector2.ZERO
	var ladderSpeed = 80
	
	if is_instance_valid(shipOn):
		obj = shipOn
		newVel = velocity.rotated(-shipOn.rotation)
		newVel = Vector2(0,vdir * ladderSpeed)
	else:
		newVel = velocity.rotated(-rotated*(PI/2))
		newVel = Vector2(0,vdir * ladderSpeed)
	
	
	if Input.is_action_pressed("jump"):
		movementState = 0
		newVel.y = -250 
		
	
	
	var tile = obj.posToTile(obj.to_local(global_position))
	
	if tile == null: # return early if player walks ladder to sky limit
		movementState = 0
		newVel.y = -250 * int(Input.is_action_pressed("move_up"))
		velocity = newVel.rotated(rotated*(PI/2))
		move_and_slide()
		return
	
	var blockType = obj.DATAC.getTileData(tile.x,tile.y)
	if blockType != 25:
		movementState = 0
		newVel.y = -250 * int(Input.is_action_pressed("move_up"))
	
	if is_instance_valid(shipOn):
		velocity = newVel.rotated(shipOn.rotation)
	else:
		velocity = newVel.rotated(rotated*(PI/2))
	
	move_and_slide()
	
	squishSprites(1.0)
	eyeBallAnim(delta)
	updateLight()
	ensureCamPosition()
	
	lerpCameraRotation(rotated*(PI/2),delta)
func bedMovement(delta):
	
	velocity = Vector2.ZERO
	
	
	if shipOn != null:
		#sprite.rotation = shipOn.rotation
		GlobalRef.camera.rotation = lerp_angle(GlobalRef.camera.rotation,shipOn.rotation,1.0-pow(2.0,(-delta/0.2)))
	
	if Input.is_action_pressed("jump"):
		movementState = 0
	
	squishSprites(1.0)
	$PlayerLayers/eye.hide()
	updateLight()
	ensureCamPosition()
	
func inSpaceMovement(delta):
	
	if noClip:
		noClipMovement(delta)
		return
	
	var dir = Vector2.ZERO
	dir.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	dir.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	
	velocity += dir.normalized() * 2
	
	sprite.rotate(1.0 * delta)
	
	lerpCameraRotation(0,delta)
	move_and_slide()
	ensureCamPosition()

#region planet attaching/detaching stuff. scary
func detachFromShip():
	if state == 1 or state == 2:
		#Code for dismounting ship
		var pos = shipOn.posToTile(shipOn.to_local(global_position))
		if pos == null:
			#reparent(shipOn.get_parent())
			velocity += shipOn.velocity
			move_and_slide()
			ensureCamPosition()
			shipOn = null
			if planetOn == null:
				state = 3
			else:
				state = 0
			return true
		if shipOn.DATAC.getBGData(pos.x,pos.y) < 2: #If background is air
			#reparent(shipOn.get_parent())
			velocity += shipOn.velocity
			move_and_slide()
			ensureCamPosition()
			shipOn = null
			if planetOn == null:
				state = 3
			else:
				state = 0
			return true
	return false

func findShipToAttachTo():
	var areas = $ShipCollider.get_overlapping_areas()
	if areas.size() <= 0:
		return false
	
	var ship = areas[0].get_parent()
	var pos = ship.posToTile(ship.to_local(global_position))
	if pos == null:
		return false
	if ship.DATAC.getBGData(pos.x,pos.y) > 1: #If background is solid
		shipOn = ship
		velocity -= shipOn.velocity
		move_and_slide()
		if planetOn == null:
			state = 1
		else:
			state = 2
		return true
	
	return false

## IF PLAYER IS OUTSIDE SHIP
func findPlanetToAttachInSpace():
	if planetOn != null:
		return
	for planet in system.cosmicBodyContainer.get_children():
		var distance = planet.global_position - global_position
		var minimumDis = sqrt(pow(planet.SIZEINCHUNKS*32,2) * 2) + 570
		if distance.length() <= minimumDis:
			attachToPlanet(planet)
			state = 0
			return

func detachFromPlanetToSpace():
	if planetOn == null:
		return
	var maxDis = sqrt(pow(planetOn.SIZEINCHUNKS*32,2) * 2) + 620
	var distance = planetOn.global_position - global_position
	if distance.length() > maxDis:
		detachFromPlanet()
		state = 3

## IF PLAYER IS INSIDE SHIP
func findPlanetToAttachInShip():
	if planetOn != null:
		return
	for planet in system.cosmicBodyContainer.get_children():
		var distance = planet.global_position - global_position
		var minimumDis = sqrt(pow(planet.SIZEINCHUNKS*32,2) * 2) + 570
		if distance.length() <= minimumDis:
			attachToPlanet(planet)
			shipOn.reparent(planet.entityContainer)
			state = 2
			return

func shipDetachFromPlanet():
	if planetOn == null:
		return
	var maxDis = sqrt(pow(planetOn.SIZEINCHUNKS*32,2) * 2) + 620
	var distance = planetOn.global_position - global_position
	if distance.length() > maxDis:
		var s = planetOn
		planetOn = null
		s.unloadPlanet()
		var relativePosition = shipOn.to_local(global_position)
		reparent(system.objectContainer)
		shipOn.reparent(system.objectContainer)
		
		global_position = shipOn.global_position + relativePosition.rotated(shipOn.rotation)
		
		state = 1

func attachToPlanet(planet:Planet):
	planet.loadPlanet()
	planetOn = planet
	lastPlanetOn = planet
	reparent(planetOn.entityContainer)

func detachFromPlanet():
	var s = planetOn
	planetOn = null
	s.unloadPlanet()
	reparent(system.objectContainer)
#endregion


func ensureCamPosition():

	cameraOrigin.position = Vector2(0,-40).rotated(GlobalRef.camera.rotation)
	cameraOrigin.position.x = int(cameraOrigin.position.x)
	cameraOrigin.position.y = int(cameraOrigin.position.y)
	GlobalRef.camera.global_position = to_global(cameraOrigin.position)
	
	if shipOn:
		GlobalRef.camera.cpass(shipOn.velocity)
	else:
		GlobalRef.camera.cpass(velocity)

######################################################################
############################## ITEMS #################################
######################################################################

func useItem():
	
	if !GlobalRef.playerCanUseItem:
		return
	
	#if PlayerData.selectedSlot == 49 and GlobalRef.hotbar.isShopVisible():
	#	return
	
	var itemData = PlayerData.getSelectedItemData()
	if itemData == null:
		$PlayerLayers/handFront.visible = true
		return
	
	var editBody = getEditingBody()
	if !is_instance_valid(editBody):
		return
	
	var mousePos = editBody.get_local_mouse_position()
	var tile = editBody.posToTile(mousePos)
	
	if itemData != null and tile != null:
		
		if !itemData.infiniteReach:
			if get_local_mouse_position().length() > 64:
				return
		
		if dead:
			return
		
		if itemData.clickToUse:
			if Input.is_action_just_pressed("mouse_left"):
				itemData.onUse(tile.x,tile.y,getPlanetPosition(),editBody,lastTileItemUsedOn)
		else:
			itemData.onUse(tile.x,tile.y,getPlanetPosition(),editBody,lastTileItemUsedOn)
		
		lastTileItemUsedOn = Vector2(tile.x,tile.y)

func swapSlot():
	# clear previousAnimation
	for i in itemRoot.get_children():
		i.queue_free()
	
	var itemID = PlayerData.getSelectedItemID()
	var s = ItemData.matchItemAnimation(itemID)
	
	justswapped = true
	
	if s == null:
		heldItemAnim = null
		$PlayerLayers/handFront.visible = true
		return
	
	var ins = ItemData.heldItemAnims[s].instantiate()
	ins.itemID = itemID
	ins.handColor = $PlayerLayers/body.modulate
	
	heldItemAnim = ins
	itemRoot.add_child(ins)
	if holdingtick < 2:
		return
	
	if Input.is_action_pressed("mouse_left") and !heldItemAnim.usedUp:
		heldItemAnim.onFirstUse()
	

func runItemProcess(delta):
	
	if !GlobalRef.playerCanUseItem:
		return
		
	#if PlayerData.selectedSlot == 49 and GlobalRef.hotbar.isShopVisible():
	#	return
	
	if !is_instance_valid(heldItemAnim):
		return
	
	if heldItemAnim.override:
		$PlayerLayers/handFront.visible = !heldItemAnim.isVisible
	else:
		$PlayerLayers/handFront.visible = !heldItemAnim.visible
	
	if Input.is_action_just_pressed("mouse_left") and !heldItemAnim.usedUp and !justswapped:
		heldItemAnim.onFirstUse()
	
	if usingItem and !heldItemAnim.usedUp:
		heldItemAnim.onUsing(delta)
	else:
		heldItemAnim.onNotUsing(delta)
	
	justswapped = false


func setAllTrapdoors(tile:Vector2,replaceID:int,body):
	var dick = {}
	var quad = body.DATAC.getPositionLookup(tile.x,tile.y)
	# scans right
	for i in range(32):
		var newPos = Vector2i( Vector2(i,0).rotated( quad * (PI/2) ) ) + Vector2i(tile.x,tile.y)
		var existingTile = body.DATAC.getTileData(newPos.x,newPos.y)
		if existingTile != 47 and existingTile != 48:
			break
		dick[newPos] = replaceID
	
	for i in range(31):
		var newPos = Vector2i( Vector2(-i-1,0).rotated( quad * (PI/2) ) ) + Vector2i(tile.x,tile.y)
		var existingTile = body.DATAC.getTileData(newPos.x,newPos.y)
		if existingTile != 47 and existingTile != 48:
			break
		dick[newPos] = replaceID
	
	return dick

func openDoor(tile,body,playerDir):
	var info = body.DATAC.getInfoData(tile.x,tile.y) % 2 # top or bottom of door
	var doorType = body.DATAC.getInfoData(tile.x,tile.y) / 2
	
	var swing = playerDir * 4
	var startInfo = info * 2
	if playerDir == 0:
		startInfo = 1 + (info * 2)
		
	if BlockData.checkIfPlaceable(tile.x,tile.y,body,Vector2i(2,2),false,startInfo,22):
		var d = BlockData.placeTiles(tile.x,tile.y,body,Vector2i(2,2),23,startInfo,(doorType * 8) + swing)
		body.editTiles(d)
	else: # if open fails, try opening in other direction
		playerDir = 1 - playerDir
		swing = playerDir * 4
		startInfo = info * 2
		if playerDir == 0:
			startInfo = 1 + (info * 2)
		
		if BlockData.checkIfPlaceable(tile.x,tile.y,body,Vector2i(2,2),false,startInfo,22):
			var d = BlockData.placeTiles(tile.x,tile.y,body,Vector2i(2,2),23,startInfo,(doorType * 8) + swing)
			body.editTiles(d)

func closeDoor(tile,body):
	var info = body.DATAC.getInfoData(tile.x,tile.y)
	var doorSwing = 0
	
	if info % 8 < 4:
		doorSwing = 1
	
	var d = BlockData.placeDoor(tile.x,tile.y,body,info % 4,(info/8)*2,doorSwing)
	body.editTiles(d)
	

func chairSit(tile,editBody):
	animationPlayer.play("sit")
	setAllPlayerFrames(7)
	snapToPositionChair(tile,editBody)
	wasInWater = false

func attachToLadder(tile,editBody):
	animationPlayer.play("climbLadder")
	setAllPlayerFrames(9)
	snapToPosition(tile,editBody)
	wasInWater = false
	beingKnockedback = false

func snapToPositionChair(tile,editBody):
	var info = editBody.DATAC.getInfoData(tile.x,tile.y)
	
	var pos = editBody.tileToPos(tile)
	if editBody is Ship:
		pos = editBody.tileToPosRotated(tile)
	
	var dif = -2
	if info % 2 == 0:
		dif = 6
	var offset = Vector2(0,dif).rotated((PI/2)*getPlanetPosition())
			
	if state == 1:
		offset = offset.rotated(editBody.rotation)
			
	position = pos + offset
			
	if editBody is Ship:
		position += editBody.position
	
	if info % 4 <= 1:
		flipPlayer(1)
	else:
		flipPlayer(-1)
	
	if state == 3:
		await get_tree().process_frame
		position = pos + offset
		if editBody is Ship:
			position += editBody.position

func snapToPosition(tile,editBody):
	var pos = editBody.tileToPos(tile)
	if editBody is Ship:
		pos = editBody.tileToPosRotated(tile)
			
	position = pos
			
	if editBody is Ship:
		position += editBody.position
		if state % 2 == 1:
			rotated = 0
	
	if state == 3:
		await get_tree().process_frame
		position = pos
		if editBody is Ship:
			position += editBody.position

func scanForStations():
	var scanBody = planetOn
	if is_instance_valid(shipOn):
		scanBody = shipOn
	
	if !is_instance_valid(scanBody):
		return []
		
	var scan :Array[int]= []
	for x in range(12):
		for y in range(12):
			var peegas = scanBody.posToTile(scanBody.to_local(global_position))
			if peegas == null:
				continue
			var pos = Vector2(x,y) + peegas - Vector2(6,6)
			
			var tile = scanBody.DATAC.getTileData(pos.x,pos.y)
			if !scan.has(tile):
				scan.append(tile)
	
	return scan

######################################################################
############################ ANIMATION ###############################
######################################################################

func squishHeadUnderCeiling() -> bool:
	
	if Input.is_action_pressed("crouch"):
		squishSprites(0.68)
		return true
	
	var underCeiling = isUnderCeiling(rotated*(PI/2))
	if underCeiling:
		squishSprites(0.68)
		return true
	squishSprites(1.0)
	return false

func flipPlayer(dir):
	sprite.scale.x = dir
	$itemWorldRotation.scale.x = dir

func playerAnimation(dir,newVel,delta):
	#improve this later
	if healthComponent.checkIfHasEffect("frozen"):
		return
	
	if dir != 0:
		flipPlayer(dir)
	
	eyeBallAnim(delta)
	
	var flor = isOnFloor(rotated*(PI/2))
	if shipOn != null:
		flor = isOnFloor(shipOn.rotation)
	
	if !flor:
		if newVel.y <= 0:
			animationPlayer.play("jump")
			return
		else:
			animationPlayer.play("fall")
			return
	if dir == 0:
		animationPlayer.play("idle")
	elif animationPlayer.current_animation != "walk":
			animationPlayer.play("walk")

func eyeBallAnim(delta):
	var glob = global_position - get_global_mouse_position()
	var gay = glob.rotated(-GlobalRef.camera.rotation)
	$PlayerLayers/eye/Pupil.offset = gay.normalized() * Vector2(-sprite.scale.x,-1)
	
	# silly blink
	blinkSecs += delta
	if blinkSecs > 2:
		if randi() % 60 == 0:
			$PlayerLayers/eye.visible = false
			blinkSecs = -0.1
			if randi() % 6 == 0:
				blinkSecs = -0.3
	
	# this could probably be refactored, leftover jank from move to deltat
	if blinkSecs > 0 or (blinkSecs > -0.2 && blinkSecs < -0.1):
		$PlayerLayers/eye.visible = true
	elif blinkSecs > -0.1:
		$PlayerLayers/eye.visible = false

func setAllPlayerFrames(frame:int):
	for obj in sprite.get_children():
		obj.frame = frame
		
func getPlayerFrame():
	return sprite.get_children()[0].frame


func squishSprites(target):
	for obj in sprite.get_children():
		obj.scale.y = lerp(obj.scale.y,target,0.2)
		if obj == $PlayerLayers/eye:
			obj.scale.y = 1.0
			obj.position.y = lerp(obj.position.y,3.0+(3.0*int(target!=1.0)),0.2 )


func scrollBackgrounds(vel,delta):
	Background.scroll(vel.rotated(-GlobalRef.camera.rotation)*-delta)


func changeArmor():
	
	var helmet = PlayerData.getSlotItemData(40)
	var chest = PlayerData.getSlotItemData(41)
	var legs = PlayerData.getSlotItemData(42)
	
	var vanityHelmet = PlayerData.getSlotItemData(50)
	var vanityChest = PlayerData.getSlotItemData(51)
	var vanityLegs = PlayerData.getSlotItemData(52)
	
	var newDefense = 0
	
	
	# check for main armor
	if helmet is ItemArmorHelmet:
		helmetSpr.texture =  helmet.armorTexture
		newDefense += helmet.defense
		AchievementData.unlockMedal("equipArmor")
	else:
		helmetSpr.texture = null
	if chest is ItemArmorChest:
		chestSpr.texture =  chest.armorTexture
		newDefense += chest.defense
		AchievementData.unlockMedal("equipArmor")
	else:
		chestSpr.texture = null
	if legs is ItemArmorLegs:
		legsSpr.texture =  legs.armorTexture
		newDefense += legs.defense
		AchievementData.unlockMedal("equipArmor")
	else:
		legsSpr.texture = null
	
	# check for vanity
	if vanityHelmet is ItemArmorHelmet:
		helmetSpr.texture =  vanityHelmet.armorTexture

	if vanityChest is ItemArmorChest:
		chestSpr.texture =  vanityChest.armorTexture

	if vanityLegs is ItemArmorLegs:
		legsSpr.texture =  vanityLegs.armorTexture
	
	Stats.updateStats()
	newDefense += Stats.getAdditiveDefense()
	
	var maxHealth :int = 100
	if GlobalRef.claimedPraffinBossPrize:
		maxHealth += 50
	if GlobalRef.claimedWormBossPrize:
		maxHealth += 50
	if GlobalRef.claimedFinalBossPrize:
		maxHealth += 100
	
	healthComponent.defense = newDefense
	healthComponent.maxHealth = maxHealth
	GlobalRef.hotbar.updateDefense(newDefense)

######################################################################
############################### MATHS ################################
######################################################################

func getPlanetPosition():
	if GlobalRef.playerGravityOverride != -1:
		return GlobalRef.playerGravityOverride
	if !is_instance_valid(planetOn):
		return 0
	var p = planetOn.posToTile(position)
	if p == null:
		var angle1 = Vector2(1,1)
		var angle2 = Vector2(-1,1)
		
		var dot1 = int(position.dot(angle1) >= 0)
		var dot2 = int(position.dot(angle2) > 0) * 2
		
		return [0,1,3,2][dot1 + dot2]
	return planetOn.DATAC.getPositionLookup(p.x,p.y)

func isOnFloor(rot):
	#improve this
	$FloorAngles.rotation = rot
	
	$FloorAngles/FloorCast1.force_raycast_update()
	$FloorAngles/FloorCast2.force_raycast_update()
	
	if $FloorAngles/FloorCast1.is_colliding():
		return true
	if $FloorAngles/FloorCast2.is_colliding():
		return true
	return false

func isUnderCeiling(rot):
	#improve this
	$CeilingAngles.rotation = rot
	
	if $CeilingAngles/cCast1.is_colliding():
		return true
	if $CeilingAngles/cCast2.is_colliding():
		return true
	return false

func enteredNewChunk(newChunk):
	var planetRadius = planetOn.SIZEINCHUNKS * 32
	var newPos = (newChunk * 64) - Vector2(planetRadius,planetRadius) - Vector2(288,288)
	GlobalRef.lightmap.pushUpdate(planetOn,newPos)
	planetOn.loadChunkArea(newChunk)

func getEditingBody():
	# Determine whether or not to target ship
	var areas = shipFinder.get_overlapping_areas()
	var ship = null
	var editBody = planetOn
	if areas.size() > 0:
		ship = areas[0].get_parent()
		var mousePos = ship.get_local_mouse_position()
		var tile = ship.posToTile(mousePos)
		if tile != null:
			if ship.DATAC.getBGData(tile.x,tile.y) > 1:
				editBody = ship
			elif ship.DATAC.getTileData(tile.x,tile.y) > 1:
				editBody = ship
			else:
				for x in range(3):
					for y in range(3):
						if ship.DATAC.getTileData(tile.x+x-1,tile.y+y-1) > 1:
							editBody = ship
							break
						if ship.DATAC.getBGData(tile.x+x-1,tile.y+y-1) > 1:
							editBody = ship
							break
	
	return editBody

func getBodyOn():
	if shipOn != null:
		return shipOn
	if planetOn != null:
		return planetOn
	return null

func wallCheck(pos):
	
	$wallCheck/RayCast2D.target_position = pos - $wallCheck/RayCast2D.position
	$wallCheck/RayCast2D2.target_position = pos - $wallCheck/RayCast2D2.position
	
	$wallCheck/RayCast2D.force_raycast_update()
	$wallCheck/RayCast2D2.force_raycast_update()
	
	if $wallCheck/RayCast2D.is_colliding() and $wallCheck/RayCast2D2.is_colliding():
		return false

	return true

######################################################################
############################# LIGHTS #################################
##################### DO NOT TOUCH !!!!!!!!!!!!#######################
######################################################################

func updateLight():
	if !is_instance_valid(planetOn):
		return
	
	var pos = position
	var planetRadius = planetOn.SIZEINCHUNKS * 32
	
	var currentChunk = Vector2(int(pos.x+planetRadius)/64,int(pos.y+planetRadius)/64)
	if previousChunk != currentChunk:
		enteredNewChunk(currentChunk)
	previousChunk = currentChunk

func updateLightStatic():
	if !is_instance_valid(planetOn):
		return
	
	var pos = position

	var currentChunk = Vector2(int(pos.x+1024)/64,int(pos.y+1024)/64)
	var newPos = (currentChunk * 64) - Vector2(1024,1024) - Vector2(288,288)
	GlobalRef.lightmap.pushUpdate(planetOn,newPos)


######################################################
####################### OTHER ########################
######################################################

func _on_health_component_health_changed():
	PlayerData.sendHealthUpdate(healthComponent.health,healthComponent.maxHealth)

func spawnShip():
	var ins = shipDEBUG.instantiate()
	get_parent().add_child(ins)
	ins.global_position = get_global_mouse_position()

func dieAndRespawn():
	# player is DEAD bruh
	sprite.visible = false
	dead = true
	noClip = true
	noClipSpeed = 0 # enable a little bit of movement
	
	Saving.autosave()
	GlobalRef.hotbar.showDeathScreen(Stats.respawnWait)
	await get_tree().create_timer(Stats.respawnWait).timeout
	
	# respawn
	respawn()
	
	# reset variables
	healthComponent.clearAllStatus()
	healthComponent.heal( int(healthComponent.maxHealth * 0.6) )
	rotated = 0
	sprite.visible = true
	dead = false
	noClip = false
	PlayerData.selectSlot(PlayerData.selectedSlot)
	$CollisionShape2D.disabled = noClip

func respawn():
	
	if is_instance_valid(GlobalRef.playerSpawnPlanet):
		var spawn = GlobalRef.playerSpawn
		if spawn == null:
			spawn =  Vector2(GlobalRef.playerSpawnPlanet.DATAC.findSpawnPosition(BlockData.theChunker.returnLookup()))
		if GlobalRef.playerSpawnPlanet != planetOn:
			global_position = spawn + GlobalRef.playerSpawnPlanet.position
			state = 0 
			if is_instance_valid(planetOn):
				print(planetOn)
				detachFromPlanet()
			attachToPlanet(GlobalRef.playerSpawnPlanet)
		else:
			var t = planetOn.posToTile(spawn)
			if planetOn.DATAC.getTileData(t.x,t.y) != 55:
				var pee = lastPlanetOn.DATAC.findSpawnPosition(BlockData.theChunker.returnLookup())
				position = Vector2(pee)
				GlobalRef.sendChat("Bed was missing!")
				return
			position = spawn
	else:
		var pee = lastPlanetOn.DATAC.findSpawnPosition(BlockData.theChunker.returnLookup())
		position = Vector2(pee)
	
	airTime = 0.0 # cancel fall damage
	velocity = Vector2.ZERO # cancel vel
	
func _unhandled_input(event):
	
	if event is InputEventMouseButton:
		
		if event["button_index"] == 1:
			usingItem = event["pressed"]
			#useItem()
		
		if event["button_index"] == 2:
			if event["pressed"]:
				$rightClicker.onRightClick()
				

func toggleNoClip():
	noClip = !noClip
	$CollisionShape2D.disabled = noClip

func playFootstepSound():
	SoundManager.playSound("enemy/step",global_position,0.5,0.1)
	if stream != null:
		SoundManager.playSoundStream(stream,global_position,0.5,0.1)

func manaFilled():
	if is_instance_valid(manaFilledPart):
		manaFilledPart.position = Vector2(0,-6).rotated( rotated * (PI/2) )
		manaFilledPart.emitting = true

func spawnGiftParticle():
	var ins = gift.instantiate()
	ins.position = position
	get_parent().add_child(ins)

func dashingParticle():
	var vel = velocity.rotated(-getProperRotationSource()) 
	if dashDelay % 2 == 0 and abs(vel.x) > 150:
		var ins = aura.instantiate()
		ins.startFrame = $PlayerLayers/body.frame
		ins.position = position
		ins.rotation = sprite.rotation
		ins.modulate.a = min((abs(vel.x)-150.0) / 150.0,1.0)
		get_parent().add_child(ins)

func teleport():
	$rotateRand/teleport.emitting = true
	SoundManager.playSound("items/teleport",global_position,0.6,0.04)

func lerpCameraRotation(rot,delta):
	var interpolation :float= 1.0-pow(2.0,(-delta/0.06))
	var o :float = Options.options["cameraRotationOverwrite"]
	if o > 0.0:
		interpolation = o
	GlobalRef.camera.rotation = lerp_angle(GlobalRef.camera.rotation,rot,interpolation)
