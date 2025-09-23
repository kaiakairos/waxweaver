extends Node2D

var text = "empty message"
var color :Color = Color.WHITE


@onready var label = $Label

var ticks :float= 0.0

var lineHeight :int = 0

func _ready():
	modulate = color
	label.text = text
	lineHeight = label.get_line_count()

func _process(delta):
	ticks += delta
	
	if ticks > 5.0:
		modulate.a -= 0.5 * delta
	
	if modulate.a <= 0.0:
		queue_free()
