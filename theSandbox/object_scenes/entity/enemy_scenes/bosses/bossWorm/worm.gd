extends Enemy

@onready var segmentScene = preload("res://object_scenes/entity/enemy_scenes/bosses/bossWorm/worm_segment.tscn")
@onready var eyes = $Eyes
@onready var bodyLine = $Line2D
@onready var segmentContainer = $Segments

@onready var healthcomponent = $HealthComponent # for boss meter

var currentDir :float = 0.0

@export var speeednis :float = 300.0
@export var dotMult :float = 1.0
@export var turnSpeed :float = 0.02

var state :int = 0 # orbit, dash, playerDied

var dashAngle :Vector2 = Vector2.ZERO
var dashTicks :int = 0

@onready var baseTexture = preload("res://object_scenes/entity/enemy_scenes/bosses/bossWorm/body.png")
@onready var metalTexture = preload("res://object_scenes/entity/enemy_scenes/bosses/bossWorm/metal.png")

var isMetal :bool = false
var isTransforming :bool = false

var tick :int = 0

var shakeCamera = true
var slow = false

func _ready():
	for i in range(40):
		var ins = segmentScene.instantiate()
		ins.hc = $HealthComponent
		segmentContainer.add_child(ins)

func _physics_process(delta):
	var oldPosition = position
	
	if GlobalRef.player.dead and state != 2:
		state = 2
	
	match state:
		0:
			orbit(delta)
		1:
			dash(delta)
		2:
			playerDead(delta)
	
	var hp = healthComp.getHealthPercent()
	if hp > 0.1 and hp < 0.75:
		if randi() % 300 == 0:
			tranform()
			
	if hp < 0.1 and !isMetal:
		tranform()
	
	eyes.rotation = velocity.angle()
	moveBody(oldPosition,position)
	
	if shakeCamera:
		tick += 1
		if getSurface() < 0:
			if !slow:
				SoundManager.playSound("enemy/boss/worm/groundBurst",global_position,1.5)
				$rumble.stop()
			slow = true
			
		if slow:
			if tick % 3 == 0:
				GlobalRef.camera.shake(1)
		else:
			GlobalRef.camera.shake(2)
		if tick > 540:
			GlobalRef.camera.resetShake()
			shakeCamera = false



func orbit(delta):
	
	var targetDir :float= getExactDirToPlayer().angle()
	
	currentDir = lerp_angle(currentDir,targetDir,turnSpeed)
	
	var dot = Vector2.from_angle(currentDir).dot( Vector2.from_angle(targetDir) )
	
	var dotty :float= (dot + 1.0) + 0.01
	
	velocity += to_local(GlobalRef.player.global_position) * turnSpeed * dotty
	if velocity.length() > speeednis:
		velocity = velocity.normalized() * speeednis
	
	move_and_slide()
	
	if randi() % 300 == 0:
		enterDashState()
	if healthComp.getHealthPercent() < 0.2:
			enterDashRandom()

func dash(delta):
	var mult = (1.0 - healthComp.getHealthPercent()) + 0.5
	velocity = dashAngle.normalized() * 300 * mult
	move_and_slide()
	
	dashTicks -= 1
	if dashTicks <= 0:
		
		state = 0
		if healthComp.getHealthPercent() < 0.2:
			enterDashRandom()

func playerDead(delta):
	var vel = getVelocity()
	vel = lerp(vel,Vector2(0,330),0.1)
	setVelocity(vel)
	move_and_slide()
	
	if to_local(GlobalRef.player.global_position).length() > 1200:
		queue_free()

func moveBody(oldPos:Vector2,newPos:Vector2):
	var change :Vector2 = newPos - oldPos
	var previousSegment = self
	bodyLine.clear_points()
	
	bodyLine.add_point(Vector2.ZERO)
	for segment in segmentContainer.get_children():
		segment.position -= change
		
		var segmentSpace :Vector2= segment.global_position - previousSegment.global_position
		if segmentSpace.length() > 24:
			segment.global_position = previousSegment.global_position + (segmentSpace.normalized() * 24)
		
		
		previousSegment = segment
		bodyLine.add_point(segment.position)

func enterDashState():
	dashAngle = to_local(GlobalRef.player.global_position)
	dashTicks = 60
	state = 1

func enterDashRandom():
	var rX = randi_range(-200,200)
	var rY = randi_range(-200,200)
	
	if randi() % 6 == 0: # 1 in 6 chance to dash directly to the player
		rX = 0
		rY = 0
	
	dashAngle = to_local(GlobalRef.player.global_position + Vector2(rX,rY))
	dashTicks = 40 + (randi() % 40)
	state = 1

func tranform():
	
	if isTransforming:
		return
	
	isTransforming = true
	if isMetal:
		SoundManager.playSound("enemy/boss/worm/becomeNormal",global_position,1.0)
	else:
		SoundManager.playSound("enemy/boss/worm/becomeMetal",global_position,1.0)
	
	var tween = get_tree().create_tween()
	tween.tween_property(bodyLine,"modulate",Color(5.0,5.0,5.0,1.0),0.5)
	
	await tween.finished
	
	if isMetal:
		bodyLine.texture = baseTexture
		healthComp.damageTypeImmunities = []
	else:
		bodyLine.texture = metalTexture
		healthComp.damageTypeImmunities = [0]  # make immune to melee
	
	isMetal = !isMetal
	
	bodyLine.modulate = Color.WHITE
	
	for segment in segmentContainer.get_children():
		segment.emitParticle()
	
	await get_tree().create_timer(6.0).timeout
	isTransforming = false


func _on_health_component_died():
	var offset :Vector2 = Vector2(0,-64).rotated( getWorldRot(GlobalRef.player) )
	global_position = GlobalRef.player.global_position + offset
	
	# this segment offsets the worm when it dies to make sure worm drops items
	# above player rather than in the ground
	
	AchievementData.unlockMedal("defeatWorm")
