extends Label

var hint

#Set hint text
func _ready():
	var phase = $"/root/Interpreter".game_phase
	if phase == 1:
		hint = "Hit Wendy on the vulnerable part of her body.\nDodge her attacks with the right timing\nor intercept her attack with a punch of your own."
	if phase == 2:
		hint = "Wendy may counterattack if she blocks a punch.\nShe also has a new attack at her disposal:\na delayed hook."
	if phase == 3:
		hint = "Wendy will not hold back in this fight.\nHer new uppercut is very powerful\nand cannot be intercepted."
	if phase == 4:
		hint = "Welcome to the bonus fight.\nWendy is at her most agressive and will\npummel you into submission if you're not careful!"
	text = text + hint

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene("res://_Scenes/Main.tscn")