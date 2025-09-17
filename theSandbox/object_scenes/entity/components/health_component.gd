extends Node
class_name HealthComponent

## COOL EXPORTS ##
#self explanitory
@export var maxHealth :int= 100
var health :int= 0
# simple knockback multiplier
@export var knockbackResist :float = 1.0
@export var defense :int = 0

## list of items enemy will drop
@export var loottable :Loot
@export var moneyToDrop :int = 0

@export var statusImmunities :Array[String] = []

@onready var parent = get_parent()
@export var isPlayer :bool = false
@export var deleteOnDeath :bool = true

@export var attackVolume :float = 0.8

signal healthChanged
signal smacked
signal statusUpdated
signal died

# status stuff
var statusEffects :Array[StatusEffect] = []

## Used for being immune to certain types of damage hitbox
@export var damageTypeImmunities :Array = []

var god :bool= false # prevents damage and knockback if true

var alreadyDead :bool = false

func _ready():
	health = maxHealth
	statusEffects = []

func heal(amount):
	
	if isPlayer:
		amount = Stats.getBonusHealing(amount)
	
	health += amount
	health = min(health,maxHealth)
	
	if isPlayer:
		Indicators.damnPopup(amount,parent.global_position,"healPlayer")
	else:
		Indicators.damnPopup(amount,parent.global_position,"heal")
	
	emit_signal("healthChanged")

func damage(amount,area:Hurtbox=null,hitCrit:bool=false,source:String="idk",type:int=0):
	
	if isPlayer:
		if parent.dead:
			return
		# scan for confusion
		if Stats.specialProperties.has("inflictConfusion") and is_instance_valid(area):
			if randi() % 5 == 0: # 20% chance
				var node :Enemy= null
				if area.get_parent() is Enemy:
					node = area.get_parent()
				else:
					node = area.get_parent().get_parent()
				if is_instance_valid(node) and node is Enemy:
					if is_instance_valid(node.healthComp):
						node.healthComp.inflictStatus("confused",20.0)
	
	if god:
		return
	
	SoundManager.playSound("enemy/attackEnemy",parent.global_position,attackVolume,0.2)
	var trueAmount = amount
	var def = defense
	if checkIfHasEffect("fragile"):
		def /= 2
	if checkIfHasEffect("tough"):
		def += 5
	
	if area != null:
		if area.ignoreDefense:
			def = 0
	
	trueAmount -= def
	trueAmount = max(trueAmount,1)
	
	var peebus :String = ""
	
	if hitCrit:
		trueAmount *= 2
		peebus = "critEnemy"
	
	if damageTypeImmunities.has(type):
		SoundManager.playSound("mining/mineFail",parent.global_position,0.7,0.05)
		trueAmount = 0 # CANCEL all damage if immune
	
	health -= trueAmount
	
	health = max(health,0)
	
	if isPlayer:
		Indicators.damnPopup(trueAmount,parent.global_position,"player")
	else:
		Indicators.damnPopup(trueAmount,parent.global_position,peebus)
	
	emit_signal("healthChanged")
	emit_signal("smacked")
	
	if health <= 0:
		die(source)

func damagePassive(amount,source:String="idk"): # does damage while ignoring defense
	
	if isPlayer:
		if parent.dead:
			return
	
	var trueAmount = amount
	trueAmount = max(trueAmount,1)
	
	health -= trueAmount
	health = max(health,0)
	
	if isPlayer:
		Indicators.damnPopup(trueAmount,parent.global_position,"player")
	else:
		Indicators.damnPopup(trueAmount,parent.global_position)
	
	emit_signal("healthChanged")
	
	if health <= 0:
		die(source)

func dealKnockback(amount:float,dir:Vector2,mult:float):
	
	if god:
		return
	
	if isPlayer and Stats.specialProperties.has("knockbackImmune"):
		return
	
	var q = getWorldPosition()
	dir = dir.rotated(-q*(PI/2)).normalized()
	var b = (int(dir.x > 0.0) * 2) - 1
	var newDir = Vector2(amount * b * mult,amount * -2 * sqrt(mult))
	newDir = newDir.rotated(q*(PI/2))
	
	if knockbackResist > 0.0:
		parent.velocity = newDir * knockbackResist
	if isPlayer:
		parent.beingKnockedback = true
	
func die(source:String="idk"):
	
	if deleteOnDeath:
		SoundManager.playSound("enemy/killSquish",parent.global_position,0.5, 0.1 )
	
	emit_signal("died")
	
	if isPlayer:
		clearAllStatus()
		parent.dieAndRespawn()
		
		var chatName = "Player"
		var chatmsg = ""
		if Network.isMultiplayerGame:
			chatName = Steamworks.steam_username
		
		if source != "idk":
			chatmsg = chatName + " died from: " + source
		else:
			chatmsg = chatName + " died"
			
		GlobalRef.sendError(chatmsg)
		if Network.isMultiplayerGame:
			Network.send_p2p_packet(0,{"packetType":"chatMessage","text":chatmsg,"type":"red"})
		
		var moneyLost = int(PlayerData.money * 0.3)
		PlayerData.loseMoney(moneyLost)
		if moneyLost > 0:
			GlobalRef.sendError("You lost " + str(moneyLost) + " monies")
		return
	
	if deleteOnDeath:
		if !alreadyDead:
			rollDrops()
			rewardMoney()
	
	alreadyDead = true
	
	if deleteOnDeath:
		CreatureData.creatureDeleted(parent)

func forceDrops():
	rollDrops()
	rewardMoney()

func getWorldPosition():
	var angle1 = Vector2(1,1)
	var angle2 = Vector2(-1,1)
		
	var dot1 = int(parent.position.dot(angle1) >= 0)
	var dot2 = int(parent.position.dot(angle2) > 0) * 2
	
	
	return [0,1,3,2][dot1 + dot2]

func rollDrops():
	if loottable == null:
		return
	
	var drops :Array[LootItem] = loottable.getLoot()
	for loot in drops:
		dropItem(loot.id,loot.amount)

func dropItem(itemID,amount):
	if itemID == -1:
		return
	var ins = BlockData.groundItemScene.instantiate()
	ins.itemID = itemID
	ins.amount = amount
	ins.position = parent.position
	parent.get_parent().call_deferred("add_child",ins)

func inflictStatus(effect:String,seconds:float):
	if statusImmunities.has(effect): # return if immune to status
		return
	
	for i in statusEffects: # check if already has effect, set time if does
		if is_instance_valid(i):
			if i.name == effect:
				i.time = seconds
				return
	
	# add new effect
	var f := "res://object_scenes/specialResource/statusEffects/resources/"
	var s = load(f + effect + ".tres").duplicate()
	s.time = seconds
	s.name = effect
	s.healthComponent = self
	
	if s.particle != null: # particle effect stuff
		s.p = s.particle.instantiate()
		s.p.hc = self
		add_child(s.p)
	
	statusEffects.append( s )
	s.onInfliction()
	emit_signal("statusUpdated")
	Stats.emit()
	if isPlayer:
		GlobalRef.hotbar.updateStatus()

func clearAllStatus():
	for effect in statusEffects:
		effect.time = -10.0

func _process(delta):

	var names = []
	for effect in statusEffects:
		if effect.time <= 0.0 and is_instance_valid(effect):
			effect.onGone()
			statusEffects.erase(effect)
			emit_signal("statusUpdated")
		if is_instance_valid(effect):
			names.append(effect.name)
			effect.proc(delta)
			for i in effect.incompatibleEffects:
				if checkIfHasEffect(i):
					effect.time = -10.0
					continue
	
func checkIfHasEffect(effect:String):
	for i in statusEffects:
		if is_instance_valid(i):
			if i.name == effect:
				return true
	return false

func getWorld():
	if isPlayer:
		return parent.getBodyOn()
	return parent.get_parent().get_parent()

func getHealthPercent():
	return float(health)/float(maxHealth)

func rewardMoney():
	if moneyToDrop <= 0:
		return
	var moneyRand = moneyToDrop + randi_range(-2,2)
	PlayerData.addMoney(max(moneyRand,1))
	Indicators.moneyPopup(max(moneyRand,1),parent.global_position)
