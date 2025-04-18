extends Enemy

@onready var segmentScene = preload("res://object_scenes/entity/enemy_scenes/babyWorm/baby_worm_segment.tscn")
@onready var bodyLine = $Line2D
@onready var segmentContainer = $segments

var segmentDistance :int = 4

func _ready():
	for i in range(10):
		var ins = segmentScene.instantiate()
		ins.hc = $HealthComponent
		segmentContainer.add_child(ins)

func _physics_process(delta):
	var pos = position
	
	var speed :float= 60.0
	var dot = velocity.normalized().dot( to_local(GlobalRef.player.global_position).normalized() )
	if dot > 0.8:
		speed = 120.0
	
	velocity = lerp(velocity,to_local(GlobalRef.player.global_position).normalized() * speed,0.02)
	move_and_slide()
	
	moveBody(pos,position)
	var b = getTile() > 1
	if $dig.playing != b:
		$dig.playing = b
		

func moveBody(oldPos:Vector2,newPos:Vector2):
	var change :Vector2 = newPos - oldPos
	var previousSegment = self
	bodyLine.clear_points()
	
	bodyLine.add_point(Vector2.ZERO)
	for segment in segmentContainer.get_children():
		segment.position -= change
		
		var segmentSpace :Vector2= segment.global_position - previousSegment.global_position
		if segmentSpace.length() > segmentDistance:
			segment.global_position = previousSegment.global_position + (segmentSpace.normalized() * segmentDistance)
		
		
		previousSegment = segment
		bodyLine.add_point(segment.position)
