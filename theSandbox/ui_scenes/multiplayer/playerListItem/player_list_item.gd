extends Control

var playerID :int = 0
var username :String = "Player"

var tick :float = 0.0
var offset :int = 0

func _ready():
	$Label.text = username
	offset = randi_range(0,40)
	Steam.connect("persona_state_change",updateUsername)
	Steam.connect("avatar_loaded",onAvatarLoaded)
	Steam.getPlayerAvatar(2,playerID)

func _process(delta):
	tick += delta
	if tick > 190.0 + float(offset):
		Steam.getPlayerAvatar(2,playerID) # reload avatar occasionally to account for failures
		tick = 0.0
	
func updateUsername(id,flags):
	if id != playerID:
		return
	username = Steam.getFriendPersonaName(playerID)
	$Label.text = username

func onAvatarLoaded(id,width,data):
	if id != playerID:
		return
	var img = Image.create_from_data(width,width,false,Image.FORMAT_RGBA8,data)
	var texture = ImageTexture.create_from_image(img)
	$TextureRect.texture = texture
