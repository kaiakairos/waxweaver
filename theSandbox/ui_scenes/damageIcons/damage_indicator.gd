extends Node2D

var velocity :Vector2 = Vector2.ZERO
var number :int = 0

var type :String = "normal"

var tick = 0

var flashSpeed = 0.1

func _ready():
	rotation = GlobalRef.camera.rotation
	
	$Label.text = str(number)
	velocity = Vector2(1,0).rotated(randf_range(-PI,PI))
	velocity.y = abs(velocity.y) * -2.5
	match type:
		"heal" : 
			modulate = Color.SPRING_GREEN
		"player" : 
			modulate = Color.CORAL
			flashSpeed = 1.0
			z_index += 2
		"healPlayer" :
			modulate = Color.SPRING_GREEN
		"critEnemy" :
			flashSpeed = 1.0
			z_index += 1
	
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _process(delta):
	tick += 60 * delta
	position += velocity * 60 * delta
	
	var l = 1 - pow(2, ( -delta/0.03803 ) )
	velocity = lerp(velocity,Vector2.ZERO,l)
	
	modulate.a = 0.5 + (sin(tick * flashSpeed) * 0.25)
	

