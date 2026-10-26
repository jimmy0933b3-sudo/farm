extends SceneTree
## Regression for real finger and mouse swipes over ANIMAL buttons.
## Includes ocean park cards, 39-sticker album, coloring gallery and care tabs.
const DragScroll=preload("res://scripts/TouchAnimalScroll.gd")
const ChoiceArt=preload("res://scripts/ChoiceArt.gd")
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1024,600)
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.progress.unlock("cow")
	print("TRACE scroll: home")
	game.show_home()
	await process_frame
	var icons={}
	for node in _children(game):
		if node.get_script()==ChoiceArt:
			icons[str(node.get("item_id"))]=true
	if not icons.has("ocean_park") or not icons.has("forest") or not icons.has("zoo"):
		_fail("Merged home must show forest and ocean parks")
		return
	if icons.has("ocean") or icons.has("forest_explore"):
		_fail("Exploration icons must be nested inside their own parks")
		return
	print("TRACE scroll: ocean park")
	game._go("ocean_park")
	await process_frame
	if game.screen!="ocean_park" or game.current_zone!="ocean":
		_fail("Ocean park did not open animal introduction zone")
		return
	var ocean_scroll=_find_scrolls(game)
	if ocean_scroll.is_empty():
		_fail("Ocean park animal cards need draggable ScrollContainer")
		return
	var num_ocean=0
	for node in _children(game):
		if node is Button and str(node.text)=="":
			for item in _children(node):
				if item.get_script()==preload("res://scripts/AnimalArt.gd"):
					num_ocean+=1
	if num_ocean!=7:
		_fail("Ocean park should show seven animal image cards, got "+str(num_ocean))
		return
	var has_ocean_explore=false
	for node in _children(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="ocean":
			has_ocean_explore=true
	if not has_ocean_explore:
		_fail("Ocean Park must include a visible ocean exploration action")
		return
	print("TRACE scroll: forest")
	game.show_zone("forest")
	await process_frame
	var has_forest_explore=false
	for node in _children(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="forest_explore":
			has_forest_explore=true
	if not has_forest_explore:
		_fail("Forest Park must include a forest exploration action")
		return
	print("TRACE scroll: album")
	game.show_album()
	await process_frame
	var scrollers=_find_scrolls(game)
	if scrollers.size()!=1:
		_fail("Album missing a dedicated touch scroll")
		return
	var scroll=scrollers[0]
	var grid=scroll.get_child(0)
	if grid.get_child_count()!=39:
		_fail("Album did not show all 39 animal cards")
		return
	if scroll.get_v_scroll_bar().max_value-scroll.size.y<100.0:
		_fail("Album cannot move vertically across rows of animal cards")
		return
	var first=grid.get_child(0)
	var start=scroll.get_global_rect().position+Vector2(28,scroll.size.y*.74)
	var down=InputEventScreenTouch.new()
	down.index=0
	down.pressed=true
	down.position=start
	scroll._input(down)
	var drag=InputEventScreenDrag.new()
	drag.index=0
	drag.position=start+Vector2(0,-245)
	scroll._input(drag)
	if scroll.scroll_vertical<150:
		_fail("Finger swipe from animal card did not scroll album")
		return
	first.pressed.emit()
	if game.screen!="album":
		_fail("Animal card activated while the child was swiping to scroll")
		return
	var release=InputEventScreenTouch.new()
	release.index=0
	release.pressed=false
	release.position=drag.position
	scroll._input(release)
	first.pressed.emit()
	if game.screen!="album":
		_fail("Swiped card activated when finger lifted")
		return
	down.position=start
	scroll._input(down)
	first.pressed.emit()
	if game.screen!="animal":
		_fail("An ordinary stationary tap should still open collected animal")
		return
	print("TRACE scroll: care")
	game.show_care()
	await process_frame
	var horizontal=false
	for area in _find_scrolls(game):
		if area.horizontal_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED:
			horizontal=true
			area._start(area.get_global_rect().position+Vector2(60,25))
			area._drag(area.get_global_rect().position+Vector2(-155,25))
			if area.scroll_horizontal<=0:
				_fail("Care residents do not scroll left and right")
				return
	if not horizontal:
		_fail("Care animal selection still lacks horizontal scrolling")
		return
	# Test many collected species for the other two scrollable catalogs.
	for info in game.animals:
		game.progress.unlock(str(info["id"]))
	print("TRACE scroll: coloring")
	game.show_coloring()
	await process_frame
	if not is_instance_valid(game.coloring_game.gallery_scroll):
		_fail("Coloring gallery cannot scroll")
		return
	var color_scroll=game.coloring_game.gallery_scroll
	if color_scroll.get_v_scroll_bar().max_value<=color_scroll.size.y+50:
		_fail("Coloring animal gallery is not vertically scrollable")
		return
	print("TRACE scroll: farm")
	game.show_private_farm()
	await process_frame
	if not is_instance_valid(game.private_farm_game.available_scroll):
		_fail("Private Farm available animal list is not touch scrollable")
		return
	var farm_scroll=game.private_farm_game.available_scroll
	if farm_scroll.get_child(0).get_child_count()<19:
		_fail("Private Farm lost animal choices")
		return
	if farm_scroll.get_v_scroll_bar().max_value<=farm_scroll.size.y+50:
		_fail("Private farm catalog cannot scroll over many animal cards")
		return
	game.show_home()
	await process_frame
	game._go("ocean")
	await process_frame
	if game.screen!="ocean_search":
		_fail("Original ocean find-six game no longer exists")
		return
	print("PASS: merged park exploration menus, album swipe/tap isolation, care tabs, coloring and private farm lists")
	game.queue_free()
	await process_frame
	quit(0)

func _find_scrolls(node: Node) -> Array:
	var result: Array=[]
	for item in _children(node):
		if item.get_script()==DragScroll:
			result.append(item)
	return result
func _children(node: Node) -> Array:
	var all: Array=[]
	for child in node.get_children():
		all.append(child)
		all.append_array(_children(child))
	return all
func _fail(reason: String) -> void:
	push_error("SCROLL TEST FAILED: "+reason)
	quit(1)
