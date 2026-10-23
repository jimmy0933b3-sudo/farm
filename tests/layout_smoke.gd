extends SceneTree
## Test real scene rectangles at landscape tablet sizes instead of just
## checking scripts compile. Prevents offscreen controls and overlapping cards.
const ChoiceArt = preload("res://scripts/ChoiceArt.gd")
const ForestHideSpot = preload("res://scripts/ForestHideSpot.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in [Vector2i(1280,720),Vector2i(1024,600)]:
		root.size = viewport_size
		await process_frame
		var game = load("res://scenes/Main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.show_home()
		await process_frame
		var cards: Array=[]
		for node in _descendants(game):
			if node is Button and _has_picture(node):
				cards.append(node)
		if cards.size()!=8:
			_fail("Home must show exactly 8 fully illustrated actions, got "+str(cards.size()))
			return
		for i in range(cards.size()):
			var a: Rect2=cards[i].get_global_rect()
			if a.position.x < 0.0 or a.end.x > game.size.x+1.0:
				_fail("Home card out of horizontal bounds at "+str(viewport_size))
				return
			for j in range(i+1,cards.size()):
				if a.intersects(cards[j].get_global_rect()):
					_fail("Home cards overlap at "+str(viewport_size))
					return
		game._go("forest_explore")
		await process_frame
		if game.screen!="forest_search":
			_fail("Large forest screen did not open")
			return
		var map=game.forest_game.stage
		if map.size.y < 190.0:
			_fail("Forest stage is too short for child touch targets")
			return
		if map.get_global_rect().end.y > game.size.y+3.0:
			_fail("Forest gameplay background is below bottom edge at "+str(viewport_size))
			return
		for spot in game.forest_game.spots:
			if spot is BaseButton:
				_fail("A forest hideout still inherits a white Button background")
				return
			if not spot is ForestHideSpot:
				_fail("Unknown hideout type")
				return
		for child in _descendants(game.forest_game):
			if child is Button:
				var rect: Rect2=child.get_global_rect()
				if rect.end.y > game.size.y+3.0 or rect.position.y < -2.0:
					_fail("Forest HUD button is clipped off-screen at "+str(viewport_size))
					return
		game.queue_free()
		await process_frame
	print("PASS: 1280x720 and 1024x600 no card overlap; forest HUD bounded and hideouts unthemed")
	quit(0)

func _has_picture(button: Button) -> bool:
	for child in _descendants(button):
		if child.get_script()==ChoiceArt:
			return true
	return false

func _descendants(node: Node) -> Array:
	var all: Array=[]
	for child in node.get_children():
		all.append(child)
		all.append_array(_descendants(child))
	return all

func _fail(reason: String) -> void:
	push_error("LANDSCAPE LAYOUT FAIL: "+reason)
	quit(1)
