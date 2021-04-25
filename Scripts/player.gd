extends Sprite

var hp = 10
var has_player_thrown_punch = false
var kd_count = 0

#Animation timer
var anim_timer = 0
var anim_frame = 0
var anim_complete = false
var origin_pos

var phase = 0

#Animations
var idle = [[0, 1], [3, 3]]
var punch_low = [[2, 3, 2], [0.25, 2.5, 0.5]]
var punch_high = [[4, 5, 4], [0.25, 2.5, 0.5]]
var dodge = [[1, 6, 7, 6, 1], [0.5, 0.5, 2, 0.5, 0.5]]
var get_hit = [[7, 8], [1, 4]]
var knocked_down = [[7, 8, 9], [1, 1, 8]]
var get_back_up = [[0, 1, 0, 1], [6, 6, 6, 6]]

var anim_overwrite
var enemy
var direction = 1
var counter = 0
var is_dodging = false

var KD_MAX = 3

#SFX
var sfx_kd = preload("res://SFX/snd_player_knockeddown.wav")
var sfx_landing = preload("res://SFX/snd_badoosh.wav")

func _ready():
	origin_pos = Vector2(position.x, position.y)
	enemy = get_parent().get_node("Enemy")

func _process(delta):
	if phase == 0:
		phase_fight(delta)
	elif phase > 0:
		phase_kd(delta)

func phase_fight(delta):
	#Input
	if enemy.phase < 2 and frame < 2:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			anim_complete = true
			has_player_thrown_punch = true
		if Input.is_action_just_pressed("ui_up"):
			anim_overwrite = punch_high
			flip_h = !flip_h
			enemy.receive_punch(1, true)
		if Input.is_action_just_pressed("ui_down"):
			anim_overwrite = punch_low
			flip_h = !flip_h
			enemy.receive_punch(1, false)
		if Input.is_action_just_pressed("ui_left"):
			anim_overwrite = dodge
			flip_h = false
			direction = -1
		if Input.is_action_just_pressed("ui_right"):
			anim_overwrite = dodge
			flip_h = true
			direction = 1
	
	is_dodging = frame == 6 or frame == 7
	
	if has_player_thrown_punch:
		animate(anim_overwrite, delta)
		if anim_overwrite == dodge:
			move_dodge(direction, delta)
	elif enemy.phase < 2:
		animate(idle, delta)
	
	if anim_complete:
		counter = 0
		position.x = origin_pos.x
		is_dodging = false
	
	if hp <= 0:
		phase = 1

#Player needs to get up from the mat
func phase_kd(delta):
	if phase == 1:
		play_sfx(sfx_kd)
		animate(knocked_down, delta)
		if position.y < 650:
			position.y += (delta * 300)
		else:
			play_sfx(sfx_landing)
			enemy.anim_complete = true
			enemy.anim_overwrite = enemy.idle_guard_down
			enemy.next_animation = enemy.idle_guard_down
			kd_count += 1
			phase = 3 if kd_count == KD_MAX else 2
	if phase == 2:
		if Input.is_action_pressed("ui_accept"):
			animate(get_back_up, delta)
			position.y -= (delta * 200)
			if anim_complete:
				enemy.idle_counter = 1
				hp = 10 - (kd_count * 3)
				phase = 0
				position.y = origin_pos.y

func receive_hit(damage):
	anim_complete = true
	has_player_thrown_punch = true
	anim_overwrite = get_hit
	hp -= damage
	position.x = origin_pos.x
	play_sfx(load("res://SFX/snd_player_damaged_" + rand_ot() + ".wav"))

func move_dodge(dir, delta):
	position.x += (5 - counter) * dir
	counter += delta * 30

func animate(animation, delta):
	if anim_complete:
		anim_complete = false
		anim_frame = 0
		anim_timer = animation[1][anim_frame]
	anim_timer -= (delta * 10)
	if anim_timer <= 0:
		if anim_frame >= (animation[0].size() - 1):
			anim_complete = true
			has_player_thrown_punch = false
			return
		anim_frame += 1
		anim_timer = animation[1][anim_frame]
	frame = animation[0][anim_frame]

func play_sfx(sfx : AudioStream):
	if $SFXPlayer.playing and $SFXPlayer.stream == sfx:
		return
	$SFXPlayer.stream = sfx
	$SFXPlayer.play()

func rand_ot():
	var r1 = randf()
	var r2 = randf()
	return '1' if r1 > r2 else '2'