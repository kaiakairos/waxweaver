extends Enemy

var life :float= 0.0
var dead :bool= false

var deadSecs :float=0.0

var hitplayer :bool = false

func _ready():
	if hitplayer:
		$Hurtbox.enemyBox = true

func _physics_process(delta):
	if dead:
		deadSecs += delta
		if deadSecs > 1.0:
			queue_free()
		return
	
	var vel = getVelocity()
	#vel.y += 1000 * delta # not effected by gravity
	setVelocity(vel)
	var collider = move_and_collide(velocity*delta)
	if collider:
		velocity = velocity.bounce(collider.get_normal())
		SoundManager.playSound("enemy/step",global_position,0.8,0.1)
	
	life += delta
	if life > 5.0:
		deactivate()
	if $RayCast2D.is_colliding():
		deactivate()
	if getWater() > 0.9:
		deactivate()
		SoundManager.playSound("enemy/swim2",global_position,4.0,0.1)

func _on_hurtbox_hitsomething():
	deactivate()

func deactivate():
	dead = true
	$Hurtbox.queue_free()
	$CPUParticles2D.emitting = false
	$IceShard.hide()
