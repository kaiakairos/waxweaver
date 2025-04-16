extends Sprite2D

var secs :float= 0
func _physics_process(delta):
	secs += delta
	if secs > 0.34: # tick animations 3x/sec
		if frame < 2:
			frame += 1
		else:
			frame = 0
		secs = 0
