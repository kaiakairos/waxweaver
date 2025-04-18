@tool
extends Button

@export var buttonText :String = "text" :
	get:
		return buttonText
	set(value):
		buttonText = value
		$shadow.text = buttonText
		$Node2D/text.text = buttonText

var focused :bool= false

func _ready():
	
	$shadow.text = buttonText
	$Node2D/text.text = buttonText
	
	size = $shadow.size

func _physics_process(delta):
	
	if Engine.is_editor_hint():
		return
	
	size = $shadow.size
	if focused:
		$Node2D.position = lerp($Node2D.position,Vector2(2,-2),0.2)
		$Node2D.modulate = lerp( $Node2D.modulate, Color(1,0.784,0.333), 0.2 )
	else:
		$Node2D.position = lerp($Node2D.position,Vector2(0,0),0.2)
		$Node2D.modulate = lerp( $Node2D.modulate, Color.WHITE, 0.2 )

func _on_mouse_entered():
	focused = true
	$buttonUp.play()
	

func _on_mouse_exited():
	focused = false
	if $buttonSelect.playing:
		$buttonDown.play()


func _on_button_down():
	$Node2D.position = Vector2(-2,2)
	$Node2D.modulate = Color(1,0.463,0.333)
	$buttonSelect.play()
