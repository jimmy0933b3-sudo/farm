extends ScrollContainer
## Drag-first, preschool-sized animal grid scroller.
## A card tap activates only when the finger has not moved to scroll.
## Supports both touchscreen drag and desktop mouse drag.
const TAP_SLOP: float = 15.0
var active_finger: int = -1
var mouse_down: bool = false
var press_position: Vector2 = Vector2.ZERO
var last_position: Vector2 = Vector2.ZERO
var moved: float = 0.0
var block_card_press: bool = false

func _init() -> void:
	# Defaults must apply BEFORE pages configure horizontal scrolling.
	# Resetting orientation in _ready would break the Care list.
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	# ScrollContainer's default touch handling conflicts with nested Buttons.
	# This scroller handles both touch and mouse with the same threshold.
	scroll_deadzone=100000
	follow_focus=false

func wire_button(button: Button, action: Callable) -> void:
	button.mouse_filter=Control.MOUSE_FILTER_PASS
	button.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.pressed.connect(Callable(self,"_card_pressed").bind(action))

func _card_pressed(action: Callable) -> void:
	if not block_card_press and action.is_valid():
		action.call()

func _in_view(point: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().has_point(point)

func _start(point: Vector2) -> void:
	press_position=point
	last_position=point
	moved=0.0
	block_card_press=false

func _drag(point: Vector2) -> void:
	var delta=point-last_position
	last_position=point
	moved=maxf(moved,point.distance_to(press_position))
	if moved>TAP_SLOP:
		block_card_press=true
		if vertical_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED:
			scroll_vertical=maxi(0,scroll_vertical-int(round(delta.y)))
		if horizontal_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED:
			scroll_horizontal=maxi(0,scroll_horizontal-int(round(delta.x)))

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and active_finger==-1 and _in_view(event.position):
			active_finger=event.index
			_start(event.position)
		elif not event.pressed and active_finger==event.index:
			active_finger=-1
			block_card_press=moved>TAP_SLOP
	elif event is InputEventScreenDrag and event.index==active_finger:
		_drag(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and active_finger==-1:
		if event.pressed and _in_view(event.position):
			mouse_down=true
			_start(event.position)
		elif not event.pressed and mouse_down:
			mouse_down=false
			block_card_press=moved>TAP_SLOP
	elif event is InputEventMouseMotion and mouse_down and active_finger==-1:
		_drag(event.position)
