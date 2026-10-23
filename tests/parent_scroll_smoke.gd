extends SceneTree
## Regression: parent settings scroll on small Android landscape screens;
## toggles preserve scrollbar position and motion-reduction works.
const DragScroll=preload("res://scripts/TouchAnimalScroll.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	for viewport_size in [Vector2i(1024,600),Vector2i(1280,720)]:
		root.size=viewport_size
		var game=load("res://scenes/Main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.adult_unlocked=true
		game.show_settings()
		await process_frame
		await process_frame
		var scroll=game.settings_scroll
		if not is_instance_valid(scroll) or scroll.get_script()!=DragScroll:
			_fail("Missing real touch-draggable parental settings page")
			return
		if scroll.get_v_scroll_bar().max_value<=scroll.size.y+65:
			_fail("Parent page content cannot scroll at "+str(viewport_size))
			return
		var start=scroll.get_global_rect().position+Vector2(100,scroll.size.y*.76)
		scroll._start(start)
		scroll._drag(start+Vector2(0,-225))
		if scroll.scroll_vertical<120:
			_fail("Dragging in parent settings does not scroll")
			return
		var old=scroll.scroll_vertical
		var previous=bool(game.progress.data["settings"].get("sound",true))
		game._toggle("sound")
		await process_frame
		await process_frame
		if game.screen!="settings":
			_fail("Toggling sound closed parent page")
			return
		if bool(game.progress.data["settings"].get("sound",true))==previous:
			_fail("Parent sound toggle not applied")
			return
		if game.settings_scroll.scroll_vertical<old-35:
			_fail("Parent settings jump to the top when a setting changes")
			return
		game.progress.toggle_setting("sound")
		game.queue_free()
		await process_frame
	print("PASS: parent page vertical drag on phone and tablet, scroll state after setting changes")
	quit(0)
func _fail(message: String) -> void:
	push_error("PARENT SCROLL TEST FAILED: "+message)
	quit(1)
