extends Enemy

var life :float= 0.0
var dead :bool= false

var deadSecs :float=0.0

@onready var penis = preload("res://object_scenes/particles/explosion/explosion_particle.tscn")

var radius = 3

var immortalTiles :Array[int]= [5,63,34,128,113,147]

func _physics_process(delta):
	
	if dead:
		deadSecs += delta
		if deadSecs > 1.0:
			queue_free()
		return
	
	setLight(0.5)
	velocity *= 1.05
	
	var collider = move_and_collide(velocity*delta)
	if collider:
		explode()
	
	life += delta
	if life > 3.0:
		deactivate()
	

func _on_hurtbox_hitsomething():
	explode()

func deactivate():
	dead = true
	$CPUParticles2D.emitting = false

func explode():
	
	# spawn explosive particle + hitbox
	
	var ins = penis.instantiate()
	ins.position = position
	ins.radius = radius
	get_parent().call_deferred("add_child",ins)
	
	var size :int= (radius * 2) + 1
	var pos = getPos()
	
	var changes :Dictionary= {}
	
	for x in range(size): # break tiles
		for y in range(size):
			var tile = Vector2(pos.x + x - radius,pos.y + y - radius)
			var p :Vector2 = Vector2(4,4) + planet.tileToPos(tile)
			var id = planet.DATAC.getTileData(tile.x,tile.y)
			if immortalTiles.has(id):
				continue
			if p.distance_to(position) < radius * 8:
				changes[Vector2i(pos.x + x - radius,pos.y + y - radius)] = -1
	
	setLight(3.0)
	planet.editTiles(changes)
	deactivate()
