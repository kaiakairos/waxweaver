extends Node2D

var state :int=0 
# 0: main 
# 1: save files 
# 2: naming new save
# 3: are you sure?
# 4: options
# 5: web disclaimer
# 6: controls + tutorial
# 7: credits
# 8: medals
# 9: rename world

@onready var selectedslot = $savefiles/ScrollContainer/VBoxContainer/saveslot

var waitUntilMusic :int= 0

var holdToClearSave :int = 0

var enableConsole :int = 0

var renameWorldContainer:String = "save1"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$mainButtons/versionLabel.text = "v1." + str( GlobalRef.version )
	SoundManager.deleteMusicNode()
	SoundManager.randomMusicTick = 170
	
	GlobalRef.playerGravityOverride = -1 # ensure gravity is reset
	GlobalRef.bossEvil = false
	GlobalRef.emit_signal("changeEvilState")
	
	CreatureData.creatureAmount = 0 # ensures mob cap is reset if u leave game
	CreatureData.passiveAmount = 0
	
	if OS.has_feature("web"): # hide file directory buttons if on web
		$savefiles/openDirectory.hide()
		$savefiles/reloadSaves.hide()
		
		if !Saving.checkforgamesave(): # loads disclaimer if on web and there are no saves
			enterState(5)

func _process(delta):
	$bg/backgroundLayer.scroll(Vector2(0.1 * delta * 60.0,0))
	$MouseIcon.position = get_local_mouse_position()
	if waitUntilMusic == 1200:
		$Music.play()
	waitUntilMusic += 1
	if Input.is_action_pressed("pause"):
		holdToClearSave += 1
		if holdToClearSave > 600:
			print("reset all medal progress. you now have no medals!")
			holdToClearSave = 0
			Saving.clearSave("medals")
			AchievementData.unlockedmedals = {}
			get_tree().reload_current_scene()
	else:
		holdToClearSave = 0
	
	if Input.is_action_just_pressed("fullscreen"):
		fullscreentoggle()
	
	
	if Input.is_action_just_pressed("openCommand"):
		enableConsole += 1
		if enableConsole >= 5:
			GlobalRef.commandLineAvailable = true
	
func enterState(newstate):
	match newstate:
		1:
			$savefiles.show()
			$mainButtons.hide()
			$createNewWorld.hide()
			$areyousure.hide()
			$renameWorld.hide()
		0:
			if state == 1:
				$savefiles.hide()
			$mainButtons.show()
			
		2:
			$createNewWorld.show()
			$savefiles.hide()
		3:
			$areyousure.show()
			$savefiles.hide()
		4:
			$mainButtons.hide()
			$optionsMenu.show()
		5:
			$mainButtons.hide()
			$disclaimer.show()
		6:
			$mainButtons.hide()
			$tutorial.show()
		7:
			$mainButtons.hide()
			$credits.show()
		8:
			$mainButtons.hide()
			$achievementsMenu.show()
		9:
			$renameWorld.show()
			$savefiles.hide()
	
	$bg/AnimatedSprite2D.visible = newstate == 0
	$bg/AnimatedSprite2D2.visible = newstate == 0

	state = newstate

func _on_quit_pressed():
	if !OS.has_feature("web"):
		get_tree().quit()


func _on_play_pressed():
	enterState(1)


func _on_back_save_pressed():
	enterState(0)

func createNewSave(slot):
	selectedslot = slot
	enterState(2)

func _on_confirm_pressed():
	Saving.worldName = $createNewWorld/TextEdit.text
	$createNewWorld/Label.text = "generating... please be patient"
	await get_tree().create_timer(0.5).timeout
	selectedslot.createNewWorld()


func _on_cancel_pressed():
	enterState(1)

func areyousuredelete(slot):
	selectedslot = slot
	enterState(3)


func _on_yes_pressed():
	enterState(1)
	selectedslot.deleteSave()


func _on_discord_pressed():
	Saving.open_site("https://discord.com/invite/d6N8tbgW98")


func _on_open_directory_pressed():
	Saving.open_site(ProjectSettings.globalize_path("user://"))


func _on_reload_saves_pressed():
	for child in $savefiles/ScrollContainer/VBoxContainer.get_children():
		child.setData()


func _on_options_menu_menu_closed():
	enterState(0)


func _on_options_pressed():
	enterState(4)


func _on_okay_disclaimer_pressed():
	$disclaimer.hide()
	enterState(0)


func _on_gobacktutorial_pressed():
	$tutorial.hide()
	enterState(0)


func _on_tutorial_pressed():
	enterState(6)


func _on_text_edit_text_changed():
	
	$createNewWorld/TextEdit.text = $createNewWorld/TextEdit.text.replace("\n","")
	$createNewWorld/TextEdit.set_caret_column( $createNewWorld/TextEdit.text.length() )
	
	if $createNewWorld/TextEdit.text.length() > 20:
		$createNewWorld/TextEdit.text = $createNewWorld/TextEdit.text.left(20)
		$createNewWorld/TextEdit.set_caret_column(20)


func _on_credits_pressed():
	enterState(7)


func _on_gobackcredits_pressed():
	$credits.hide()
	enterState(0)


func _on_medals_pressed():
	enterState(8)

func renameWorld(worldName:String,save:String):
	$renameWorld/renameTextEdit.text = worldName
	renameWorldContainer = save
	enterState(9)


func _on_achievements_menu_menu_closed():
	$achievementsMenu.hide()
	enterState(0)


func fullscreentoggle():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	


func _on_renamecancel_pressed():
	enterState(1)


func _on_renameconfirm_pressed():
	var data = Saving.read_save(renameWorldContainer)
	data["worldname"] = $renameWorld/renameTextEdit.text
	Saving.write_save(renameWorldContainer,data)
	_on_reload_saves_pressed()
	enterState(1)


func _on_rename_text_edit_text_changed():
	$renameWorld/renameTextEdit.text = $renameWorld/renameTextEdit.text.replace("\n","")
	$renameWorld/renameTextEdit.set_caret_column( $renameWorld/renameTextEdit.text.length() )
	
	if $renameWorld/renameTextEdit.text.length() > 20:
		$renameWorld/renameTextEdit.text = $renameWorld/renameTextEdit.text.left(20)
		$renameWorld/renameTextEdit.set_caret_column(20)
