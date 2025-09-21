extends Node2D

var tick :float = 0.0

var basetilex :int = 0
var basetiley :int = 0

var planet :Planet = null

func _ready():
	$Pinwheel.rotation = randf_range(0.0,7.0)

func _process(delta):
	$Pinwheel.rotate(delta * 8.0)
	
	tick += delta
	if tick > 0.1:
		var baseTile = planet.DATAC.getTileData(basetilex,basetiley)
		if baseTile != 168:
			queue_free()
		tick = 0.0
	
	var chunk = Vector2(int(basetilex)/8,int(basetiley)/8)
	if !planet.chunkDictionary.has(chunk):
		queue_free()

func checkIsPostion(x:int,y:int):
	return basetilex == x and basetiley == y
