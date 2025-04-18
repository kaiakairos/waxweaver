extends Enemy

@onready var sprite = $Knife

var ticksAlive :float=0

func _process(delta):
	ticksAlive += delta
	var vel = getVelocity()
	
	if ticksAlive > 0.166:
		vel.y += 1000 * delta
	
	setVelocity(vel)
	
	if vel.x > 0:
		sprite.rotate(64.0 * delta)
	else:
		sprite.rotate(-64.0 * delta)
	
	var collider = move_and_collide(velocity*delta)
	if collider:
		set_process(false)
		SoundManager.playSound("items/arrowLand",global_position,1.0,0.1)
		sprite.rotation = collider.get_normal().angle() - (PI/2)
		sprite.z_index = -2
		
	if ticksAlive > 300.0:
		queue_free()

func _on_hurtbox_hitsomething():
	queue_free()


func _on_player_body_entered(body):
	if !is_processing():
		PlayerData.addItem(3169,1)
		var itemData = ItemData.getItem(3169)
		Indicators.itemPopup(itemData.itemName,1,global_position)
		SoundManager.playSound("inventory/pickupItem",global_position,1.0,0.12,"INVENTORY")
		queue_free()
