extends Sprite

#Animation timer
var anim_timer = 0
var anim_frame = 0
var anim_complete = false
var anim_shorten = false

#Hit, Counter, Block
var has_player_thrown_punch = false

#Values
var hp = 10
var stun_counter = 0
var kd_count = 0
var is_stunned = false
var is_high_punch = false

#DEBUG
var debug_item

#Animations
var idle_guard_up = [[0, 1], [3, 3]]
var idle_guard_down = [[2, 3], [3, 3]]
var attack_jab = [[4, 5], [6, 8], [1]]
var attack_double_jab = [[4, 5, 6, 9, 0], [5, 2, 2, 2, 2], [1]]
var attack_cross = [[8, 9, 7], [8, 1, 10], [2]]
var attack_hook = [[14, 6, 9], [8, 3, 10], [2]]
var attack_uppercut = [[10, 9, 7, 11], [8, 1, 1, 10], [3]]
var stunned = [[18, 19, 18, 19], [3, 3, 3, 3]]
var knocked_down_high = [[16, 20, 21, 22], [2, 2, 2, 1]]
var knocked_down_low = [[20, 21, 22], [3, 3, 1]]
var get_back_up = [[23, 10, 0], [3, 2, 6]]
var hit_high = [[16], [4]]
var hit_low = [[20], [4]]
var countered_high = [[13], [5]]
var countered_low = [[17], [5]]
var block_high = [[15], [4]]
var block_low = [[12], [4]]
var punish_high = [[15, 4, 5], [2, 2, 6], [2]]
var punish_low = [[12, 8, 9], [2, 2, 6], [2]]
var idle_quick = [[0, 1, 0, 1], [2, 2, 2, 1]]

#Hurt frames
var hit_high_frames = [2, 3, 5, 7, 9, 11, 18, 19]
var hit_low_frames = [0, 1, 5, 7, 9, 11, 18, 19]
var counter_high_frames = [6, 8]
var counter_low_frames = [4, 6]
var block_high_frames = [0, 1, 4, 14]
var block_low_frames = [2, 3, 8, 10, 14]
var hurt_frames = [5, 9]

var phase = 0

var animation_list
var anim_overwrite
var next_animation
var idle_counter
var player

var AI_LEVEL

var CHANCE_JAB
var CHANCE_CROSS
var CHANCE_HOOK
var CHANCE_UPPER
var CHANCE_IDLE
var IDLE_UP = 40
var IDLE_DOWN = 20
var KD_MAX = 3

#SFX
var sfx_kd = preload("res://SFX/snd_whoosh.wav")
var sfx_landing = preload("res://SFX/snd_badoosh.wav")

func _ready():
	animation_list = [idle_guard_up, idle_guard_down, attack_jab, attack_cross, attack_hook, attack_uppercut]
	next_animation = animation_list[rand_int(0, 1)]
	idle_counter = 3 + rand_int(0, 2)
	debug_item = 0 
	player = get_parent().get_node("Player")
	
	AI_LEVEL = $"/root/Interpreter".game_phase
	CHANCE_JAB = 40 - (AI_LEVEL * 5)
	CHANCE_CROSS = 25
	CHANCE_HOOK = 15 + (AI_LEVEL * 2)
	CHANCE_UPPER = 20 + (AI_LEVEL * 3)
	CHANCE_IDLE = 40 - (AI_LEVEL * 5)
	IDLE_UP = 50 - (AI_LEVEL * 10)
	IDLE_DOWN = 10 + (AI_LEVEL * 10)

func _process(delta):
	if player.phase > 1:
		animate(idle_guard_up, delta)
		idle_counter = 2
	elif phase == 0:
		phase_fight(delta)
	elif phase > 0:
		phase_enemy_kd(delta)

func phase_fight(delta):
	if is_stunned and not has_player_thrown_punch:
		flip_h = false
		animate(stunned, delta)
	elif not has_player_thrown_punch:
		flip_h = false
		animate(next_animation, delta)
	elif hp <= 0:
		flip_h = false
		phase = 1
	else:
		animate(anim_overwrite, delta)
	
	if anim_complete:
		if stun_counter > 0:
			is_stunned = true
			stun_counter = max(0, stun_counter - 1)
		elif idle_counter > 0:
			idle_counter -= 1
		else:
			if rand_int(0, 100) < CHANCE_IDLE:
				next_animation = idle_guard_up if rand_bool() else idle_guard_down
				CHANCE_IDLE = max(0, CHANCE_IDLE - IDLE_DOWN)
				idle_counter = 2 + rand_int(0, 2)
			else:
				choose_attack()
				CHANCE_IDLE = min(100, CHANCE_IDLE + IDLE_UP)
			is_stunned = false

func receive_punch(damage, is_high_punch):
	anim_complete = true
	has_player_thrown_punch = true
	if (is_high_punch and frame in hit_high_frames) or (!is_high_punch and frame in hit_low_frames):
		anim_overwrite = hit_high if is_high_punch else hit_low
		stun_counter = max(0, stun_counter - 1)
		hp -= 1
		idle_counter = 0
		flip_h = player.flip_h
		play_sfx(load("res://SFX/snd_player_punch_" + rand_ot() + ".wav"))
	elif (is_high_punch and frame in counter_high_frames) or (!is_high_punch and frame in counter_low_frames):
		anim_overwrite = countered_high if is_high_punch else countered_low
		stun_counter = 3 if AI_LEVEL < 4 else 2
		hp -= 1
		flip_h = player.flip_h
		play_sfx(load("res://SFX/snd_wendy_countered_" + rand_ot() + ".wav"))
	elif (is_high_punch and frame in block_high_frames) or (!is_high_punch and frame in block_low_frames):
		play_sfx(load("res://SFX/snd_blocked_punch_" + rand_ot() + ".wav"))
		if(rand_int(2, 10) > AI_LEVEL * 2):
			anim_overwrite = block_high if is_high_punch else block_low
		else:
			anim_overwrite = punish_high if is_high_punch else punish_low
		idle_counter = 0
		CHANCE_IDLE = max(0, CHANCE_IDLE - IDLE_DOWN)
	else:
		play_sfx(load("res://SFX/snd_whiff_" + rand_ot() + ".wav"))
		has_player_thrown_punch = false

func phase_enemy_kd(delta):
	is_stunned = false
	if phase == 1:
		play_sfx(sfx_kd)
		if is_high_punch:
			animate(knocked_down_high, delta)
			position.x += (delta * 100)
			position.y -= (delta * 100)
		else:
			animate(knocked_down_low, delta)
			position.x += (delta * 100)
			position.y -= (delta * 100)
		if anim_complete:
			play_sfx(sfx_landing)
			kd_count += 1
			phase = 5 if kd_count == KD_MAX else 2
			stun_counter = 1.5 + (kd_count * (5 - AI_LEVEL))
	if phase == 2:
		stun_counter -= delta
		if stun_counter < 0:
			stun_counter = 0
			phase = 3
	if phase == 3:
		animate(get_back_up, delta)
		hp = 10 - (((4 - AI_LEVEL) * 2) * kd_count)
		if anim_complete: phase = 4
	if phase == 4:
		animate(idle_quick, delta)
		position.x -= (delta * 100)
		position.y += (delta * 100)
		if anim_complete: 
			phase = 0

func choose_attack():
	randomize()
	var rn = rand_int(0, 100)
	if rn < CHANCE_JAB:
		if AI_LEVEL == 4:
			next_animation = attack_double_jab
		else:
			next_animation = attack_jab
		CHANCE_JAB -= 9
		CHANCE_CROSS += 3
		CHANCE_HOOK += 3
		CHANCE_UPPER += 3
		return
	rn -= max(0, CHANCE_JAB)
	if rn < CHANCE_CROSS:
		next_animation = attack_cross
		CHANCE_JAB += 3
		CHANCE_CROSS -= 9
		CHANCE_HOOK += 3
		CHANCE_UPPER += 3
		return
	rn -= max(0, CHANCE_CROSS)
	if rn < CHANCE_HOOK:
		if AI_LEVEL < 2:
			next_animation = attack_jab
		else:
			next_animation = attack_hook
		CHANCE_JAB += 3
		CHANCE_CROSS += 3
		CHANCE_HOOK -= 9
		CHANCE_UPPER += 3
		return
	rn -= max(0, CHANCE_HOOK)
	if rn < CHANCE_UPPER:
		if AI_LEVEL < 2:
			next_animation = attack_cross
		elif AI_LEVEL < 3:
			next_animation = attack_hook
		else:
			next_animation = attack_uppercut
		CHANCE_JAB += 3
		CHANCE_CROSS += 3
		CHANCE_HOOK += 3
		CHANCE_UPPER -= 9
		return
	next_animation = idle_guard_up

#Animations & Logic to set hit frames
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
		anim_timer = 4 if anim_shorten else animation[1][anim_frame]
		anim_shorten = false
	frame = animation[0][anim_frame]
	# Register hit
	if anim_timer < animation[1][anim_frame] and anim_timer > (animation[1][anim_frame] - 0.5):
		if frame in hurt_frames:
			if not player.is_dodging:
				player.receive_hit(animation[2][0])
				if next_animation == attack_double_jab:
					return
				if anim_timer > 5:
					anim_timer = 5
				else:
					anim_shorten = true
					if animation[0].size() > 3:
						anim_frame += 1
			else:
				play_sfx(load("res://SFX/snd_whiff_" + rand_ot() + ".wav"))

func play_sfx(sfx : AudioStream):
	if $SFXPlayer.playing and $SFXPlayer.stream == sfx:
		return
	$SFXPlayer.stream = sfx
	$SFXPlayer.play()

func rand_int(x, y):
	randomize()
	return x + (randi() % (y + 1))

func rand_bool():
	var r1 = randf()
	var r2 = randf()
	return r1 > r2

func rand_ot():
	var r1 = randf()
	var r2 = randf()
	return '1' if r1 > r2 else '2'