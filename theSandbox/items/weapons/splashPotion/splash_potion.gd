extends Enemy

@onready var sprite = $Sprite

var secsAlive :float=0.0

var landed :bool = false

var itemData :ItemSplashPotion= null

func _ready():
	$Sprite.texture = itemData.texture
	var s :StatusInflictor= StatusInflictor.new()
	s.effectName = itemData.effect
	s.seconds = itemData.seconds
	var a :Array[StatusInflictor] = [s]
	$Hurtbox.statusInflictors = a
	
	$CPUParticles2D.modulate = itemData.color

func setItemData(i):
	itemData = i

func _process(delta):
	secsAlive += delta
	
	if landed:
		return
	
	var vel = getVelocity()
	
	if secsAlive > (1/6):
		vel.y += 1000 * delta
	
	setVelocity(vel)
	
	if vel.x > 0:
		sprite.rotate(64.0 * delta)
	else:
		sprite.rotate(-64.0 * delta)
	
	var collider = move_and_collide(velocity*delta)
	if collider:
		landed = true
		splash()
		
	if secsAlive > 30:
		queue_free()
	

func splash():
	$Sprite.hide()
	$Hurtbox/CollisionShape2D.call_deferred("set_disabled",false)
	SoundManager.playSound("mining/glassBreak1",global_position,0.4,0.1)
	$CPUParticles2D.emitting = true
	
	await get_tree().create_timer(0.1).timeout
	
	$Hurtbox/CollisionShape2D.call_deferred("set_disabled",true)
	
	await get_tree().create_timer(1.0).timeout
	
	queue_free()
	
