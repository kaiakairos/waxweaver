extends Node2D

var dir :int = 1 # can be 1 or -1

var aliveTime :float= 2
var jitterSecs :float= 0
var jitterState :bool= false
var jitterFrequency :float= 0.08

var charged :bool = false

@onready var ray = $RayCast2D
func _ready():
	ray.force_raycast_update()
	$AudioStreamPlayer2D.play()
	
func _process(delta):
	jitterSecs += delta
	var shouldJitter :bool= jitterSecs > jitterFrequency
	$AudioStreamPlayer2D.pitch_scale += delta*0.6
	if shouldJitter:
		jitterState = !jitterState
		jitterSecs = 0
		if charged:
			if jitterState:
				$Line2D.width = 12
			else:
				$Line2D.width = 8
		else:
			if jitterState:
				$Line2D.width = 2
			else:
				$Line2D.width = 0
		
		if aliveTime < (8.0/6.0):
			charged = true
			$AudioStreamPlayer2D.pitch_scale = 2.0
			$Hurtbox/CollisionShape2D.call_deferred("set_disabled",false)
	
	aliveTime -= delta
	rotate(dir * 0.8 * delta)
	
	
	var l = 600
	if ray.is_colliding():
		l = to_local(ray.get_collision_point()).length()
	
	$Line2D.points[1].x = l
	$Hurtbox/CollisionShape2D.shape.size.x = l
	$Hurtbox/CollisionShape2D.position.x = l * 0.5
	$CPUParticles2D.position.x = l + 4
	
	
	if aliveTime < 0:
		queue_free()
	
