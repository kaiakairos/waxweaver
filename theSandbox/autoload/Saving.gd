extends Node

var loadedFile = "save1"
var worldName = "save1"
var worldType :int = 0 # normal, hardcore, creative

var shopItems :Array= []

# handles save files
# static save files, save1, save2, save3....

var mutliplayerInventories :Dictionary= {} # steamID : [ [-1,-1], [-1,-1], ... ]

func _ready():
	pass

func read_save(key): # returns dictionary or null
	if OS.has_feature('web'):
		var JSONstr = JavaScriptBridge.eval("window.localStorage.getItem('" + key + "');")
		if (JSONstr):
			return JSON.parse_string(JSONstr)
		else:
			return null
	else:
		var file = FileAccess.open("user://" + key + ".sdata", FileAccess.READ)
		if not file:
			return null
		var newData = JSON.parse_string(file.get_as_text())
		if newData == null: # assume parse failed, attept converting from bytes
			print("JSON save file parse failed, attempting to convert from bytes instead.")
			var bytes = FileAccess.get_file_as_bytes("user://" + key + ".sdata")
			newData = JSON.parse_string(bytes_to_var(bytes))
			
		file.close()
		return newData

func write_save(key,data):
	if OS.has_feature('web'):
		JavaScriptBridge.eval("window.localStorage.setItem('" + key + "', '" + JSON.stringify(data) + "');")
	else:
		var file = FileAccess.open("user://" + key + ".sdata", FileAccess.WRITE)
		file.store_line(JSON.stringify(data,"\t"))
		file.close()

func clearSave(key):
	
	if OS.has_feature('web'):
		var JSONstr = JavaScriptBridge.eval("window.localStorage.getItem('" + key + "');")
		if (JSONstr):
			JavaScriptBridge.eval("window.localStorage.removeItem('" + key + "');")
		else:
			return null
	else:
		var file = FileAccess.open("user://" + key + ".sdata", FileAccess.READ)
		if not file:
			return null
		file.close()
		var dir = DirAccess.open("user://")
		dir.remove(key + ".sdata")
	
func open_site(url):
	OS.shell_open(url)

func has_save(key):
	if OS.has_feature('web'):
		var JSONstr = JavaScriptBridge.eval("window.localStorage.getItem('" + key + "');")
		if (JSONstr):
			return true
		else:
			return false
	else:
		var file = FileAccess.open("user://" + key + ".sdata", FileAccess.READ)
		if not file:
			return false
		return true

func autosave():
	GlobalRef.system.saveGameToFile()

func downloadsave(key):
	if OS.has_feature('web'):
		var data = read_save(key)
		JavaScriptBridge.download_buffer( var_to_bytes(JSON.stringify(data)), key + ".sdata" )

func checkforgamesave():
	for i in range(10):
		if has_save("save" + str(i+1)):
			return true
	return false
			

func getWorldTypeName() -> String:
	match worldType:
		0:
			return "normal"
		1:
			return "permadeath"
		2:
			return "creative"
	
	return "normal"
	
func setWorldType(balls:String) -> void:
	match balls:
		"normal":
			worldType = 0
		"permadeath":
			worldType = 1
		"creative":
			worldType = 2
