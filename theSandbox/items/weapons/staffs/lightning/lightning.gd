extends Enemy

@onready var ray = $RayCast2D
@onready var line = $Line2D
@onready var alsoline = $Line2D2
@onready var s = preload("res://items/weapons/staffs/lightning/lightningexplosion.tscn")

var timeAlive :float = 0

var shotByPlayer :bool = true

var zapped :bool = false

func _ready():
	rotation = velocity.angle()
	if shotByPlayer:
		position = GlobalRef.player.position + Vector2(0,-2).rotated(getWorldRot(self))

func zap():
	
	if shotByPlayer:
		position = GlobalRef.player.position + Vector2(0,-2).rotated(getWorldRot(self))
	
	var dis :int= 160
	
	ray.force_raycast_update()
	
	if ray.is_colliding():
		dis = to_local(ray.get_collision_point()).length()
	line.clear_points()
	line.add_point(Vector2.ZERO)
	for p in range( (dis/20)-1 ):
		line.add_point(Vector2( p * 20, randi_range(-20,20) ))
	
	line.add_point(Vector2(dis,0))
	
	alsoline.add_point(Vector2.ZERO)
	for p in range( (dis/20)-1 ):
		alsoline.add_point(Vector2( p * 20, randi_range(-20,20) ))
	
	alsoline.add_point(Vector2(dis,0))
	
	setLight(1.4)
	setLightPos(4.0,planet.to_local( global_position + Vector2(dis,0).rotated(rotation) ))
	
	# spawn hurtbox
	var ins = s.instantiate()
	ins.position = position + Vector2(dis,0).rotated(rotation)
	get_parent().add_child(ins)
	
func _process(delta):
	
	if timeAlive >= 1 and !zapped:
		zap()
		zapped = true
	
	timeAlive += 60.0*delta
	
	if timeAlive > 3.0:
		queue_free()
