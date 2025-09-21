extends Enemy

var life :float= 0.0
var dead :bool= false

var deadTicks :float=0.0

func _process(delta):
	
	if dead:
		deadTicks += delta
		if deadTicks > 1.0:
			queue_free()
		return
	
	var vel = getVelocity()
	vel.y += 1000 * delta
	setVelocity(vel)
	var collider = move_and_collide(velocity*delta)
	if collider:
		setWater(2.0)
		if Network.isMultiplayerGame:
			var pos = getPos()
			Network.send_p2p_packet(0,{"packetType":"waterAdd","amount":2.0,"posX":pos.x,"posY":pos.y})
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
