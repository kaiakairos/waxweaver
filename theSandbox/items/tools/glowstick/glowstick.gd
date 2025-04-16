extends Enemy

@onready var sprite = $Sprite

var secsAlive :float=0

var landed :bool = false

func _process(delta):
	secsAlive += delta
	var vel = getVelocity()
	
	if secsAlive > (1/6):
		vel.y += 1000 * delta
	
	setVelocity(vel)
	
	if !landed:
		if vel.x > 0:
			sprite.rotate(64.0 * delta)
		else:
			sprite.rotate(-64.0 * delta)
	
	var collider = move_and_collide(velocity*delta)
	if collider:
		velocity = velocity.bounce(collider.get_normal()) * 0.5
		landed = true
		
	if secsAlive > 150:
		queue_free()
	
	setLight(0.7)
