extends Node2D

var old :float = 0.0

var yeah :bool = false

func _ready():
	$CPUParticles2D.emitting = true
	SoundManager.playSound("items/lightning",global_position,0.75,0.02)

func _process(delta):
	old += 60.0 * delta
	if old >= 3.0 and !yeah:
		$Hurtbox.queue_free()
		$Hurtbox2.queue_free()
		yeah = true
	if old > 60.0:
		queue_free()
