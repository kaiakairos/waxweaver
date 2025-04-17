extends Enemy

var life :float= 0.0
var dead :bool= false

var deadSecs :float=0.0

func _physics_process(delta):
	
	if dead:
		deadSecs += delta
		if deadSecs > 1.0:
			queue_free()
		return
	
	var vel = getVelocity()
	vel.y += 1000 * delta
	setVelocity(vel)
	var collider = move_and_collide(velocity*delta)
	if collider:
		setWater(2.0)
		SoundManager.playSound("enemy/swim2",global_position,4.0,0.1)
		deactivate()
	
	life += delta
	if life > 5.0:
		deactivate()
	if getWater() > 0.9:
		deactivate()
		SoundManager.playSound("enemy/swim2",global_position,4.0,0.1)
	
	setLight(0.2)

func _on_hurtbox_hitsomething():
	deactivate()

func deactivate():
	dead = true
	$CPUParticles2D.emitting = false
