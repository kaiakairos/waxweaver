extends Node2D

@onready var sprite = $Sprite2D
var rot = 0

var pos = null
var body = null

var multiplayerInstance :bool = false

func _ready():
	sprite.rotation = rot * (PI/2)
	set_process(false)
	await get_tree().create_timer(0.1).timeout
	sprite.frame = 1
	await get_tree().create_timer(0.1).timeout
	sprite.frame = 2
	
	set_process(true)

func _process(delta):
	if !multiplayerInstance:
		if body != PlayerData.chestOBJ or pos != PlayerData.currentSelectedChest:
			end()
			set_process(false)
			return
	else:
		if !Network.multiplayerOpenedChests.has(pos):
			end()
			set_process(false)
			return

func end():
	await get_tree().create_timer(0.1).timeout
	sprite.frame = 1
	await get_tree().create_timer(0.1).timeout
	sprite.frame = 0
	queue_free()
