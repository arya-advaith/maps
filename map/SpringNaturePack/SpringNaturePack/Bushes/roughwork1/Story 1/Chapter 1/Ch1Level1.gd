extends Control
var max_lives = 5
var current_lives = 5
var star_points = 0

var is_paused = false
var paused_game_time_left = 0.0
var paused_guess_time_left = 0.0

var questions = [
	"A red or green fruit that's often in pies",
	"A small purple fruit that grows in bunches",
	"A tropical fruit, king of fruits",
	"A juicy orange-pink fruit with a pit",
	"A yellow citrus fruit that's sour"
]

var words = ["apple", "grape", "mango", "peach", "lemon"]
var current_index = 0

func update_star_display():
	$StarLabel.text = "Stars: %d" % star_points

func _ready():
	$GuessTimer.timeout.connect(_on_GuessTimer_timeout)
	$SubmitButton.pressed.connect(_on_SubmitButton_pressed)
	$GameTimer.timeout.connect(_on_GameTimer_timeout)
	$PauseButton.pressed.connect(_on_PauseButton_pressed)
	$HintButton.pressed.connect(_on_HintButton_pressed)
	
	$GameTimer.start(60.0)
	update_lives_display()
	update_game_timer_label()
	update_question()

func update_question():
	var current_word = words[current_index]
	var question_text = questions[current_index]
	var blank_word = "_".repeat(current_word.length())
	
	$QuestionLabel.text = "Q%d: %s\n%s" % [current_index + 1, question_text, blank_word]
	$InputField.text = ""
	$FeedbackLabel.text = ""
	$InputField.editable = true
	$SubmitButton.disabled = false
	$GuessTimer.start(60.0)

func _on_SubmitButton_pressed():
	if current_index >= words.size():
		return
	
	var guess = $InputField.text.strip_edges().to_lower()
	var answer = words[current_index]

	if guess == answer:
		$GuessTimer.stop()
		$GameTimer.stop()
		$FeedbackLabel.text = "Correct!"
		star_points += 1
		update_star_display()
		$InputField.editable = false
		$SubmitButton.disabled = true

		await get_tree().create_timer(1.0).timeout

		current_index += 1
		if current_index < words.size():
			update_question()
			$GameTimer.start(60.0)
			update_game_timer_label()
		else:
			$QuestionLabel.text = "🎉 Congratulations!"
			$FeedbackLabel.text = "You earned: %d Stars" % star_points

			$InputField.visible = false
			$SubmitButton.visible = false
			$QuestionLabel.visible = false
			$HintButton.visible = false

			await get_tree().create_timer(3.0).timeout
			get_tree().change_scene_to_file("res://MainPage/MainMenu.tscn")
	else:
		$FeedbackLabel.text = "Wrong! Try again."

func _on_GuessTimer_timeout():
	current_lives -= 1
	update_lives_display()

	if current_lives <= 0:
		$FeedbackLabel.text = "Game Over! You lost all your lives."
		$InputField.editable = false
		$SubmitButton.disabled = true
		$GameTimer.stop()
	else:
		$FeedbackLabel.text = "Time's up! You lost a life!"
		$InputField.editable = false
		$SubmitButton.disabled = true
		$GameTimer.stop()

		await get_tree().create_timer(2.0).timeout
		update_question()
		$GameTimer.start(60.0)
		update_game_timer_label()

func _on_GameTimer_timeout():
	$GuessTimer.stop()
	current_lives -= 1
	update_lives_display()

	if current_lives <= 0:
		$InputField.editable = false
		$SubmitButton.disabled = true
		$FeedbackLabel.text = "Game over! You lost all your lives."
		$QuestionLabel.text = "Better luck next time!"
	else:
		$InputField.editable = false
		$SubmitButton.disabled = true
		$FeedbackLabel.text = "Game over! 60 seconds passed!"
		$QuestionLabel.text = "Time's up for this question!"
		await get_tree().create_timer(2.0).timeout
		update_question()
		$GameTimer.start(60.0)
		update_game_timer_label()

func update_game_timer_label():
	if is_paused:
		await get_tree().create_timer(0.5).timeout
		update_game_timer_label()
		return

	var game_time = int($GameTimer.time_left)
	$TimeLabel.text = "Time Left: %s seconds" % game_time
	await get_tree().create_timer(1.0).timeout

	if $GameTimer.time_left > 0:
		update_game_timer_label()

func update_lives_display():
	for i in range(max_lives):
		var heart = $LivesContainer.get_child(i)
		if i < current_lives:
			heart.visible = true
		else:
			heart.visible = false

func restart_game():
	update_lives_display()
	update_question()
	$GameTimer.start(60.0)
	update_game_timer_label()

func _on_PauseButton_pressed():
	if is_paused:
		if paused_game_time_left > 0.0:
			$GameTimer.start(paused_game_time_left)
		if paused_guess_time_left > 0.0:
			$GuessTimer.start(paused_guess_time_left)
			
		$InputField.editable = true
		$SubmitButton.disabled = false
		is_paused = false
		update_game_timer_label()
	else:
		paused_game_time_left = $GameTimer.time_left
		paused_guess_time_left = $GuessTimer.time_left
		
		$GameTimer.stop()
		$GuessTimer.stop()
		$InputField.editable = false
		$SubmitButton.disabled = true
		is_paused = true

func _on_HintButton_pressed():
	if star_points > 0:
		var answer = words[current_index]
		var hint_length = min(2, answer.length())
		var hint = answer.substr(0, hint_length) + "_".repeat(answer.length() - hint_length)
		$FeedbackLabel.text = "Hint: %s" % hint
		star_points -= 1
		update_star_display()
	else:
		$FeedbackLabel.text = "Not enough stars to use a hint!"
