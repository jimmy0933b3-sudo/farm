extends SceneTree
## The homepage introduction plays only once in each app session.
## Returning from any activity must not enqueue another narration.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene=load("res://scenes/Main.tscn")
	var game=scene.instantiate()
	root.add_child(game)
	await process_frame
	var original: Dictionary=game.progress.data.duplicate(true)
	# First home entry must narrate, even when a saved interior opened at startup.
	game.show_home()
	await process_frame
	if not game.home_intro_spoken or not game.sound.last_spoken_text.contains("歡迎來到動物探險島"):
		_fail("First visit to homepage should say welcome once")
		return
	# Neither tapping home again nor coming back from a park may repeat it.
	game.sound.last_spoken_text="narration-sentinel-home"
	game.show_home()
	await process_frame
	if game.sound.last_spoken_text!="narration-sentinel-home":
		_fail("Showing homepage twice must not narrate again")
		return
	game.show_zone("farm")
	await process_frame
	if not game.sound.last_spoken_text.contains("農場"):
		_fail("Ordinary interior park narration must remain enabled")
		return
	game.sound.last_spoken_text="narration-sentinel-park"
	game.show_home()
	await process_frame
	if game.sound.last_spoken_text!="narration-sentinel-park":
		_fail("Returning from a park replayed homepage introduction")
		return
	game.show_album()
	await process_frame
	game.sound.last_spoken_text="narration-sentinel-album"
	game.show_home()
	await process_frame
	if game.sound.last_spoken_text!="narration-sentinel-album":
		_fail("Returning from sticker album replayed homepage introduction")
		return
	game.show_coloring()
	await process_frame
	game.sound.last_spoken_text="narration-sentinel-coloring"
	game.show_home()
	await process_frame
	if game.sound.last_spoken_text!="narration-sentinel-coloring":
		_fail("Returning from coloring room replayed homepage introduction")
		return
	# Closing and launching a fresh Main node creates a new session.
	# Simulate a saved interior as the initial screen for this session.
	game.progress.data["last_screen"]="farm"
	game.progress.save()
	game.queue_free()
	await process_frame
	var relaunched=scene.instantiate()
	root.add_child(relaunched)
	await process_frame
	if relaunched.screen!="farm" or relaunched.home_intro_spoken:
		_fail("New session should start from saved interior with no home narration yet")
		return
	relaunched.show_home()
	await process_frame
	if not relaunched.home_intro_spoken or not relaunched.sound.last_spoken_text.contains("歡迎來到動物探險島"):
		_fail("First home visit in a new session should introduce it again")
		return
	relaunched.progress.data=original
	relaunched.progress.save()
	print("PASS: one homepage narration per app session, silent returns from park/album/coloring, intro resets on new launch")
	relaunched.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("HOME NARRATION FAILED: "+reason)
	quit(1)
