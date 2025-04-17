extends Enemy

var dead :bool= false

var penis :bool = true

var life :float = 0.0

func _ready():
	$start.emitting = true
	
	if penis:
		$Hurtbox.damage = 25
		$Hurtbox.enemyBox = false

func _physics_process(delta):
	if dead:
		return
	var t = to_local(GlobalRef.player.global_position).normalized()
	if penis:
		t = to_local( get_global_mouse_position() ).normalized()
	
	var speed :float= 200
	var dot = velocity.normalized().dot( to_local(GlobalRef.player.global_position).normalized() )
	if dot > 0.8:
		speed = 240
	
	velocity = lerp(velocity,t*speed,0.05)
	var c = move_and_collide(velocity * delta)
	
	if c:
		startDelete()
	
	setLight(0.8)
	
	if life > 10.0:
		startDelete()
	life += delta

func startDelete():
	dead = true
	$flame.emitting = false
	$end.emitting = true
	$Hurtbox/CollisionShape2D.call_deferred("set_disabled",true)


func _on_end_finished():
	queue_free()


func _on_hurtbox_hitsomething():
	startDelete()
