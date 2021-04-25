extends Node

var pointer = 0
var text = ""
var lines
var player_name = "dummy"
var game_phase = 1

const GET_BTN_TEXT = 0
const GET_GOTO = 1
const GET_ACTION = 2
const GET_CHARACTER = 3

func _ready():
	Engine.target_fps = 30

func get_next_line(goto : int):
	if text.empty():
		var text = read(game_phase)
		lines = text.split("\n")
	if goto >= lines.size():
		return {"goto": -1}
	var next_line = lines[goto]
	pointer = goto
	var parsed_line = parse(next_line)
	return parsed_line

#Parse variables
func parse(text : String):
	var new_text = text
	var buttons = []
	var goto = null
	var action = null
	var character = null
	var pose = null
	var eyes = null
	var mouth = null
	#Option menu
	if '#' in text:
		var question_and_options = text.split('#')
		var options = question_and_options[1].split(';')
		for option in options:
			var btn_text = parse_get(option, GET_BTN_TEXT)
			var btn_goto = parse_get(option, GET_GOTO)
			var new_btn = {"text": btn_text, "goto": btn_goto}
			buttons.push_back(new_btn)
		new_text = question_and_options[0]
	else:
		goto = parse_get(new_text, GET_GOTO)
		action = parse_get(new_text, GET_ACTION)
	#Character information
	character = parse_get(new_text, GET_CHARACTER)
	if character != null and ',' in character:
		var splitchar = character.split(',')
		if splitchar.size() > 1:
			character = splitchar[0]
			pose = splitchar[1] as int
			eyes = splitchar[2] as int
			mouth = splitchar[3] as int
	new_text = parse_var(new_text)
	new_text = clean(new_text)
	return {"text": new_text, "buttons": buttons, "goto": goto, "action": action,
	        "character": character, "pose": pose, "eyes": eyes, "mouth": mouth}

# Parse buttons, actions etc.
func parse_get(text : String, mode : int):
	var regex = RegEx.new()
	var pattern = ""
	if mode == GET_BTN_TEXT:
		pattern = "^([^<>]+)"
	elif mode == GET_ACTION:
		pattern = "\\{(.+?)\\}"
	elif mode == GET_GOTO:
		pattern = "<(\\d+?)>"
	elif mode == GET_CHARACTER:
		pattern = "<(\\$|([A-Za-z][A-Za-z,0-9]+?))>"
	regex.compile(pattern)
	var result = regex.search(text)
	if result:
		return (int(result.get_string(1)) - 1 if mode == GET_GOTO else parse_var(result.get_string(1)))
	return (pointer + 1 if mode == GET_GOTO else null)

# Parse the player's name and newline chars
func parse_var(text : String):
	text = text.replace('$', player_name)
	text = text.replace('/n', '\n')
	return text

func clean(text : String):
	var regex = RegEx.new()
	#Clean up brackets
	regex.compile("[\\{<](.*?)[\\}>]")
	for result in regex.search_all(text):
		text = text.replace(result.get_string(), "")
	return text

#Get dialogue
func read(phase : int):
	if phase == 1:
		return """<$>
There she is./nWendy Levinne./nBeautiful as ever.
I fantasized about her a lot,/nbut this is the first time I've been on a date with her.
My communication skills aren't the best,/nbut hopefully I'll be able to...
<Wendy,1,0,0>
Uh... $.../nwho are you talking to?
<$>
Oh! Wendy!/nI thought I was... uhh...
<Wendy>
You thought you were what?#Daydreaming<11>;Never Mind<16>
<Wendy,1,2,2>
{play_sfx:disgust}
Wow... this \"date\" is already off to a good start!/nAre you already dozing off?!
<$>
I will be focused on you for the rest of/nthe day, my dear!/nI swear!<18>
<Wendy,0,3,0>
Try not to be distracted by other thoughts/nduring our little date today, okay?
<Wendy,0,0,0>
Maybe we should do something to break the ice./nTo get to know each other better.
Do you have any hobbies?#Cooking<21>;Sporting<23>;Watching anime<33>
<Wendy,0,0,1>
Huh. Being able to cook well/nis always a plus in my book.<42>
<Wendy,0,1,1>
{play_sfx:hearts}
Really?/nI'm a sporty person too!
<Wendy,3,0,1>
To be precise, I love boxing./nNothing beats the feeling you get when you're/npunching the other person IN THE FACE!
Hey, why don't you come see me fighting?/nYou'll get a front row seat!
<$>
Really? That sounds great!
<Wendy,2,2,1>
And by \"front row seat\" I mean you/nget to fight me!/nIN THE RING!<48>
<Wendy,1,5,2>
{play_sfx:disgust}
Ugh... ARE YOU SERIOUS?!/nYou're the 5th person this week who/ngave me that exact answer!
<Narrator>
Note to self:/nPerhaps I should not tell her about my/n12-hour long anime marathon sessions.
<Wendy,0,2,0>
I almost wanted to end the date right here and now,/nbut I'll give you one more chance to talk yourself/nout of this mess.
<$>
Uhhh... okay..../n...what is your hobby..?
<Wendy,0,0,1>
My personal hobby is boxing./nI may not look very strong, but boxing/nis fighting backed by TECHNIQUE.
It's not the strongest boxer who always wins./nIt's the one who can exploit the other's weakness first.
In fact, why don't I give you a demonstration?
<Wendy,2,2,1>
And by \"demonstration\" I mean you get to fight me!/nIN THE RING!
That way, you can make up for/nnot paying attention in the beginning!
<$>
Uuuuhhhhhh.../nSure...?/nQuestion mark...?
<Wendy,3,1,1>
Great! See you at 8pm tonight!/nGood-bye!
<Narrator>
Wow... you really know how to dig yourself/ndeeper and deeper, don't you?
Welp, you don't have much of a choice now./nIf you want to win her heart,/nyou'll need to face her in the ring.

"""
	if phase == 2:
		return """<Wendy>
Whew, you're better at boxing/nthan I thought you would be...
<Wendy,2,2,1>
But I was holding back the entire fight./nYou should see me when I go all out!
<$>
Uh... I think I'll pass on that...
<Wendy,0,0,1>
Perhaps it's better to get know/neach other a little bit better.
Is there something you want to know about me?#School life<10>;Start of boxing<29>;Manga<38>
<$>
How are you doing at school?
<Wendy,0,3,0>
{play_sfx:confusion}
Uh... great..?/nMy grades are all just above/nwhat is needed to pass..?
<Narrator>
Shallow questions are not going to/nbring this relationship to a deeper level...
It would be better to ask her about her favorite...#Subject<18>;Teacher<24>
<Wendy,3,0,1>
My favorite subject is the arts.
Not because I'm very creative, but because/nthere aren't any real test you have to study for.
Just make something decent and you'll pass.
<Wendy,3,3,0>
Though P.E. would be my favorite/nif the teacher let us do boxing...<48>
<Wendy,0,0,0>
Hmmm.../nI guess that would be Mr. Willink.
He's the only teacher I ca listen to/nwithout falling aspleep halfway through.
<Wendy,0,3,0>
Though Mr. Smalls would be my favorite/nif he lets us do boxing during P.E.<48>
<$>
Where did your passion for boxing come from?
<Wendy,3,0,1>
{play_sfx:hearts}
My passion started when I was 5 years old./nI was watching an old boxing match between/nMuhammad Ali and George Foreman.
Foreman was considered one of the heaviest hitters/nin the history of boxing./nHe was the favorite to win.
And yet, Ali came victorious./nAll while taunting him during the bout./nThat moment really moved me.
<Wendy,0,1,1>
Ali became loved by the world by winning that bout,/nand I decided I wanted to be famous too someday.<55>
<$>
Do you like manga?
<Wendy,1,5,2>
{play_sfx:disgust}
...
<Wendy,1,2,2>
Hate it.
<$>
...
Perhaps I should change the subject...#School life<10>;Start of boxing<29>
<$>
You really like boxing a lot, huh?
<Wendy,0,4,1>
{play_sfx:idea}
Say, why don't we step into the ring/nonce more?
<Wendy,2,2,1>
If you do, perhaps you'll understand the beauty/nof boxing like I do.<63>
<$>
I'm sure you're dream will come true/nif you train hard enough.
<Wendy,0,4,1>
{play_sfx:idea}
Speaking of which,/n why don't we step into the ring once more?
<Wendy,2,2,1>
I'll need to train extra hard to become/nthe champion of the world.
And you'll make a good training partner!
<$>
Uh... okay.../nI've fought you before so I don't see/nwhy I wouldn't..?
<Wendy>
Just a heads-up:/nthis bout will not be as easy as the last!

"""
	if phase == 3:
		return """<Wendy,1,3,0>
...
<$>
What are you thinking about?
<Wendy,1,0,0>
Whenever we go dating,/nit always results in a boxing match/nbetween the two of us.
Isn't that a bit weird combination?/nDating and boxing?#No<8>;Not at all<8>;I don't see why<8>
<Wendy,0,0,1>
{play_sfx:hearts}
Yeah, I'm probably thinking about it too hard...
...
<Wendy,0,3,0>
...
And yet, I can't take my mind/noff of that idea...
<Narrator>
Perhaps I can ask her something/nto distract her from those thoughts...
<$>
Hey Wendy, what is your favorite...#Food<19>;Music<19>;Guilty pleasure<19>
<Wendy>
...
<$>
...
<Narrator>
She seems too distracted...#Shout at her<25>;Poke her<32>
<$>
HEY, WENDYYYYYYYY!!!!!!!!!
<Wendy,3,2,2>
{play_sfx:disgust}
Yikes, $!/nYou didn't need to yell!/nI can hear you just fine!
<$>
Then why are you not responding?<38>
<Narrator>
You gently poke Wendy on the nose.
<Wendy,0,0,0>
...?
<$>
Why can't you let the thought go?
<Wendy,0,0,2>
It all just seems so weird.../nYou and I go boxing, and whenever we do...
My affection for you just...
...
<Wendy,1,5,2>
HOLD ON!/nForget I said that!/nI didn't say anything at all!
<$>
Uhmmm... if I'm being honest...
...
<Narrator>
Should I tell Wendy I love her?#YES!<49>;Not yet<51>
<$>
Wendy, I...
<Wendy,0,2,0>
Look, I've decided there is only/none way out of this mess.
One final bout!
If I win, that's the end of it!/nNo more \"dating\"!
<Wendy,0,0,0>
If you win...
...
<Wendy,0,3,0>
Well, we can hang out some more/nif you like...
<$>
...
Sounds like a great idea!
<Wendy,2,2,1>
{play_sfx:idea}
In that case,/nyou'd better prepare yourself!
I'll whoop your ass in this last fight!/nNo more holding back!

"""
	if phase == 4:
		return """<Wendy>
Welp, you've beaten me fair and square./nI guess we're bound to do this/nevery now and then for some time...
<Wendy,0,4,1>
And if I'm being honest.../nI think I like it this way.
<Wendy,0,0,1>
The fighting keeps my head clear/nof those stupid evasive thoughts.
<$>
Perhaps it is better if we do/nsomething a bit more, uhm.../n\"date-like\" tomorrow.
I mean.../nAll we did up to now is fighting...
<Narrator>
Man, that sounds weird out of context...
<Wendy>
You're right./nLet's watch a movie together tomorrow!
<Wendy,3,1,1>
I hear there's a sequel/nto the Rocky series in theaters now!
<$>
Oh no... here we go again...

"""