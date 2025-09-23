extends Enemy

@onready var sprite = $sprite

@export var radius :int = 3
@export var delay :float = 4.0

@export var bounce :float = 0.5

var vol :Vector2 = Vector2.ZERO

var tick :float= 0.0

var flipLimit :float= 1.0

var red :bool= false

@onready var partScene = preload("res://object_scenes/particles/explosion/explosion_particle.tscn")

var immortalTiles :Array[int]= [5,63,34,128,113,147]
var itemData

var stuck :bool = false

func _ready():
	
	$sprite.texture = itemData.texture
	
	setVelocity(vol)
	
	var tween :Tween= get_tree().create_tween()
	tween.tween_property(self,"flipLimit",0.0,delay)
	
	await get_tree().create_timer(delay).timeout
	explode()
	

func _process(delta):
	
	var vel = getVelocity()
	vel.y += 1000 * delta
	
	if isOnFloor():
		vel.x = lerp(vel.x,0.0,1.0 - pow(0.02,delta))
		sprite.rotate( vel.x * delta * 0.2 )
	else:
		sprite.rotate( vel.x * delta * 0.1 )
	
		
	if stuck:
		vel = Vector2.ZERO
	setVelocity(vel)
	
	var collision = move_and_collide(velocity*delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		var weed = getVelocity()
		weed.y *= bounce
		if !isOnFloor():
			weed.x *= bounce
		setVelocity(weed)
		
		if itemData.sticky:
			stuck = true
			
	
	
	tick += delta
	
	if tick > flipLimit:
		tick = 0.0
		setColor()
	
func isOnFloor():
	$RayCast2D.rotation = getQuad(self) * (PI/2)
	$RayCast2D.force_raycast_update()
	return $RayCast2D.is_colliding()

func explode():
	
	# spawn explosive particle + hitbox
	
	var ins = partScene.instantiate()
	ins.position = position
	ins.radius = radius
	get_parent().add_child(ins)
	
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
	planet.editTiles(changes,true,0,2)
	queue_free()

func setColor():
	if red:
		sprite.modulate = Color.WHITE
	else:
		sprite.modulate = lerp(Color.RED,Color.WHITE,flipLimit)
	
	red = !red
