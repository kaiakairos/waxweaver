extends Node

var defaultOptions :Dictionary= {
	"showShadow":true,
	"musicVolume":1.5,
	"sfxVolume":1.5,
	"ambientVolume":1.5,
	"autosaving":true,
	"cameraRotationOverwrite":-1.0,
	"maxfps":60,
	"vsync":1,
}

var options :Dictionary = {}

signal updatedOptions

func _ready():
	options = defaultOptions.duplicate()
	var saved = Saving.read_save("options")
	if saved != null:
		for key in saved:
			options[key] = saved[key]
			# we do this iteration in case new options have appeared. 
			# this will make future default values not get overridden
	
	applyOptions()

func applyOptions():
	
	# sets audio bus volume
	var musicBus= AudioServer.get_bus_index("MUSIC")
	AudioServer.set_bus_volume_db(musicBus, linear_to_db(options["musicVolume"]) )
	var sfxBus= AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfxBus, linear_to_db(options["sfxVolume"]) )
	var ambientBus= AudioServer.get_bus_index("AMBIENT")
	AudioServer.set_bus_volume_db(ambientBus, linear_to_db(options["ambientVolume"]) )
	
	Engine.max_fps = options["maxfps"]
	match options["vsync"]:
		0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		3:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
	
	Saving.write_save("options",options)
	emit_signal("updatedOptions")
