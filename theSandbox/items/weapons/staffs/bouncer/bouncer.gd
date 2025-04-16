extends Enemy

var life :float= 0.0
var dead :bool= false

var deadSecs :float=0.0

var bounces :int = 0

func _process(delta):
	
	if dead:
		deadSecs += delta
		if deadSecs > 1.0:
			queue_free()
		return
	
	var vel = getVelocity()
	#vel.y += 1000 * delta       this thing is just the firebolt without gravity
	setVelocity(vel)
	var collider = move_and_collide(velocity*delta)
	if collider:
		velocity = velocity.bounce(collider.get_normal())
		SoundManager.playSound("enemy/step",global_position,0.8,0.1)
		setLight(1.0)
		$Hurtbox.damage += 2
		bounces += 1
		if bounces >= 12:
			deactivate()
	
	life += delta
	if life > 5.0:
		deactivate()
	if $RayCast2D.is_colliding():
		deactivate()
	

func _on_hurtbox_hitsomething():
	deactivate()

func deactivate():
	dead = true
	$Hurtbox.queue_free()
	$CPUParticles2D.emitting = false
