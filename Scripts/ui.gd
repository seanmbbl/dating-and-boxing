extends Node

var enemy : Sprite
var player : Sprite
var bgm_player: AudioStreamPlayer
var sfx_player_announcer : AudioStreamPlayer
var time
var time_int
var sprtr
var ref_count

#SFX
var sfx_ko = preload("res://SFX/snd_announcer_knockout.wav")
var sfx_tencount = preload("res://SFX/snd_announcer_tencount.wav")

func _ready():
	var parent = get_parent()
	enemy = parent.get_node("Enemy")
	player = parent.get_node("Player")
	bgm_player = parent.get_node("BGMPlayer")
	sfx_player_announcer = parent.get_node("AnnouncerPlayer")
	time = 0.0
	ref_count = 0.0

func _process(delta):
	show_HUD(delta)
	if enemy.phase == player.phase:
		time += delta
	
	# Player wins
	if enemy.phase == 5:
		if not $WinScreen.visible:
			bgm_player.volume_db = -10
			sfx_player_announcer.stream = sfx_ko
			sfx_player_announcer.play()
			$Count.text = "KO"
		$WinScreen.visible = true
		if Input.is_action_just_pressed("ui_accept"):
			if $"/root/Interpreter".game_phase < 4:
				$"/root/Interpreter".game_phase += 1
				get_tree().change_scene("res://_Scenes/Talk.tscn")
			else:
				get_tree().change_scene("res://_Scenes/EndScreen.tscn")
	
	# Player needs to get up after a knockdown
	$KDScreen.visible = (player.phase == 2 and not Input.is_action_pressed("ui_accept"))
	
	# Player loses
	if player.phase == 3:
		if not $LoseScreen.visible:
			bgm_player.volume_db = -10
			sfx_player_announcer.stream = sfx_ko
			sfx_player_announcer.play()
			$Count.text = "KO"
		$LoseScreen.visible = true
		if Input.is_key_pressed(KEY_SPACE):
			get_tree().reload_current_scene()
	
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func show_HUD(delta):
	$Enemy_HP_Bar.rect_size.x = enemy.hp * 31
	$Player_HP_Bar.rect_size.x = player.hp * 31
	$Enemy_KDC.frame = enemy.kd_count
	$Player_KDC.frame = player.kd_count
	time_int = int(floor(time))
	sprtr = ':0' if (time_int % 60) < 10 else ':'
	$Time.text = String(time_int / 60) + sprtr + String(time_int % 60)
	
	
	#Ten Count
	if enemy.phase == 2 or player.phase == 2:
		if ref_count == 0:
			bgm_player.volume_db = -10
			sfx_player_announcer.stream = sfx_tencount
			sfx_player_announcer.play()
		ref_count += (delta * 1.04)
		$Count.text = String(int(floor(ref_count)) + 1)
		if ref_count > 9.7:
			if player.phase == 2:
				player.phase = 3
			else:
				enemy.phase = 5
	#Tencount stops
	elif enemy.phase != 5 and player.phase != 3:
		bgm_player.volume_db = 0
		$Count.text = ""
		ref_count = 0
		sfx_player_announcer.stop()