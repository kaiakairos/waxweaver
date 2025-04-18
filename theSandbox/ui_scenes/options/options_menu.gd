extends Node2D

@onready var sfxSlider = $ScrollContainer/g/buttons/sfxslider/sfxslide
@onready var musicSlider = $ScrollContainer/g/buttons/musicslider/musslide
@onready var ambientSlider = $ScrollContainer/g/buttons/ambientslider/ambslide
@onready var rotationSlider = $ScrollContainer/g/buttons/rotateSlider/rotslide

signal menuClosed

func _ready():
	loadOptions()

func loadOptions():
	sfxSlider.value = Options.options["sfxVolume"]
	musicSlider.value = Options.options["musicVolume"]
	ambientSlider.value = Options.options["ambientVolume"]
	rotationSlider.value = int(Options.options["cameraRotationOverwrite"] * 100.0)
	
	setShadowText()
	setAutosaveText()
	changevsynctext()
	
	if Options.options["maxfps"] == 0:
		$ScrollContainer/g/buttons/maxfps/maxfpsslider.value = 300
		$ScrollContainer/g/buttons/maxfps/maxfpslabel.text = "unlimited"
	else:
		$ScrollContainer/g/buttons/maxfps/maxfpsslider.value = Options.options["maxfps"]
		$ScrollContainer/g/buttons/maxfps/maxfpslabel.text = str(Options.options["maxfps"])

func _on_dropshadow_pressed():
	Options.options["showShadow"] = !Options.options["showShadow"]
	Options.applyOptions()
	setShadowText()

func setShadowText():
	if Options.options["showShadow"]:
		$ScrollContainer/g/buttons/dropshadow.buttonText = "show drop shadow: true"
	else:
		$ScrollContainer/g/buttons/dropshadow.buttonText = "show drop shadow: false"

func _on_done_pressed():
	closeMenu()

func closeMenu():
	hide()
	emit_signal("menuClosed")




func _on_sfxslide_value_changed(value):
	Options.options["sfxVolume"] = value
	Options.applyOptions()
	$ScrollContainer/g/buttons/sfxslider/Label.text = str(value*100)


func _on_musslide_value_changed(value):
	Options.options["musicVolume"] = value
	Options.applyOptions()
	$ScrollContainer/g/buttons/musicslider/Label.text = str(value*100)


func _on_ambslide_value_changed(value):
	Options.options["ambientVolume"] = value
	Options.applyOptions()
	$ScrollContainer/g/buttons/ambientslider/Label.text = str(value*100)


func _on_sfx_pressed():
	sfxSlider.value = 1.5
func _on_music_pressed():
	musicSlider.value = 1.5
func _on_ambient_pressed():
	ambientSlider.value = 1.5


func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	


func _on_autosaving_pressed():
	Options.options["autosaving"] = !Options.options["autosaving"]
	Options.applyOptions()
	setAutosaveText()

func setAutosaveText():
	$ScrollContainer/g/buttons/autosaving.buttonText = "autosaving: " + str(Options.options["autosaving"])


func _on_rotslide_value_changed(value):
	if value == 0:
		Options.options["cameraRotationOverwrite"] = -1.0
		$ScrollContainer/g/buttons/rotateSlider/Label.text = "normal"
	else:
		Options.options["cameraRotationOverwrite"] = value * 0.01
		$ScrollContainer/g/buttons/rotateSlider/Label.text = str(value)

func _on_rotation_pressed():
	Options.options["cameraRotationOverwrite"] = -1.0
	$ScrollContainer/g/buttons/rotateSlider/Label.text = "normal"
	rotationSlider.value = 0
	


func _on_maxfps_pressed():
	Options.options["maxfps"] = 60
	Options.applyOptions()
	$ScrollContainer/g/buttons/maxfps/maxfpslabel.text = "60"
	$ScrollContainer/g/buttons/maxfps/maxfpsslider.value = 60
	

func _on_maxfpsslider_value_changed(value):
	if value == 300:
		value = 0
	Options.options["maxfps"] = value
	Options.applyOptions()
	if value != 0:
		$ScrollContainer/g/buttons/maxfps/maxfpslabel.text = str(value)
	else:
		$ScrollContainer/g/buttons/maxfps/maxfpslabel.text = "unlimited"


func _on_vsync_pressed():
	Options.options["vsync"] = int(Options.options["vsync"] + 1) % 4
	Options.applyOptions()
	changevsynctext()

func changevsynctext():
	match Options.options["vsync"]:
		0: $ScrollContainer/g/buttons/maxfps/vsync.buttonText = "vsync: disabled"
		1: $ScrollContainer/g/buttons/maxfps/vsync.buttonText = "vsync: enabled"
		2: $ScrollContainer/g/buttons/maxfps/vsync.buttonText = "vsync: adaptive"
		3: $ScrollContainer/g/buttons/maxfps/vsync.buttonText = "vsync: mailbox"
