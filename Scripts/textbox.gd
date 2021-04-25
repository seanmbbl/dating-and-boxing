extends Control

var c_button = preload("res://Objects/CustomButton.tscn")

var text_to_scroll = ""
var feed
var text_pointer = 0
var accept_pressed = false
var goto = 0
var buttons_active = false
var end_not_reached = false
var curr_char = {"name": "self", "pose": 0, "eyes": 0, "mouth": 0}
var fcount = 0
var is_blinking = false
var blink_frames = [1, 0, 1, 0, -1, 0, -1]
var blink_interval

var wendy : Sprite
var eyes : Sprite
var mouth : Sprite
var sfx_player : AudioStreamPlayer

func _ready():
	blink_interval = floor(rand_range(200, 300)) as int
	wendy = get_parent().get_node("Char")
	eyes = get_parent().get_node("Char/Eyes")
	mouth = get_parent().get_node("Char/Mouth")
	sfx_player = get_parent().get_node("SFXPlayer")
	if $"/root/Interpreter".game_phase == 4:
		get_parent().get_node("BGMPlayer").pitch_scale = 1.25
		get_parent().get_node("BG").texture = load("res://Art/bg_boxing.png")

func _process(delta):
	accept_pressed = Input.is_action_just_pressed("ui_accept")
	if text_to_scroll.empty():
		feed = $"/root/Interpreter".get_next_line(goto)
		goto = feed.goto
		end_not_reached = (goto == null or goto > 0)
		if end_not_reached and feed.action != null:
			get_func_from_feed(feed.action)
		if end_not_reached and feed.character != null:
			set_namebox(feed.character)
	if end_not_reached:
		scrolling_text()
	elif $"/root/Interpreter".game_phase == 4:
		get_tree().change_scene("res://_Scenes/EndScreen.tscn")
	else:
		get_tree().change_scene("res://_Scenes/Intermission.tscn")
	
	fcount += 1
	if fcount > 60000 and not is_blinking:
		fcount = 0
	blink()

func scrolling_text():
	if text_pointer >= feed.text.length():
		move_mouth(true)
		if buttons_active:
			return
		if accept_pressed:
			if feed.buttons.size() > 0:
				create_buttons()
				return
			flush()
		return
		
	text_to_scroll += feed.text[text_pointer]
	text_pointer += 1
	$Label.text = text_to_scroll
	move_mouth()

func get_func_from_feed(action : String):
	var str_func_array = action.split(':')
	var param_array = str_func_array[1].split(',')
	var ref = funcref(self, str_func_array[0])
	ref.call_func(param_array)

func create_buttons():
	var n = feed.buttons.size()
	for i in range(n):
		var button_feed = feed.buttons[i]
		var button = c_button.instance()
		button.text = button_feed.text
		button.connect("pressed", self, "get_button_goto_and_destroy", [button_feed])
		button.connect("mouse_entered", self, "play_sfx", [["button_hover"]])
		var button_size = button.rect_size
		button.rect_position = Vector2(get_viewport().size.x / 2 - button_size.x / 2, 
		                               -get_viewport().size.y / 3 + ((i - n) * button_size.y * 1.5))
		add_child(button)
	buttons_active = true

func get_button_goto_and_destroy(btn_feed):
	flush()
	goto = btn_feed.goto
	play_sfx(["button_click"])
	#Destroy buttons
	for node in get_children():
		if node is Button:
			node.queue_free()
	buttons_active = false

func set_namebox(name):
	var is_visible = name != "Narrator"
	curr_char.name = name
	$Namebox.visible = is_visible
	if is_visible:
		$Namebox/Label.text = name
		if feed.pose != null:
			wendy.frame = feed.pose
			curr_char.pose = feed.pose
		if feed.eyes != null:
			eyes.frame = feed.eyes * 3
			curr_char.eyes = feed.eyes * 3
		if feed.mouth != null:
			mouth.frame = feed.mouth * 3
			curr_char.mouth = feed.mouth * 3

func move_mouth(close_mouth = false):
	if curr_char.name != "Wendy":
		return
	if close_mouth:
		mouth.frame -= mouth.frame % 3
	elif fcount % 3 == 0:
		mouth.frame = curr_char.mouth + ((mouth.frame + 1) % 3)

func blink():
	is_blinking = (fcount % blink_interval == 0 or eyes.frame % 3 > 0)
	if is_blinking:
		eyes.frame = eyes.frame + blink_frames[fcount % blink_interval]
		if (fcount % blink_interval) >= blink_frames.size() - 1:
			is_blinking = false
			blink_interval = floor(rand_range(150, 450)) as int

func flush():
	text_to_scroll = ""
	text_pointer = 0
	$Label.text = ""

func play_sfx(sfx):
	sfx_player.stream = load("res://SFX/snd_" + sfx[0] + ".wav")
	sfx_player.play()