extends Control
## Keeps a persistent animal on screen while each care action plays.
signal action_finished(action: String)

const AnimalArt = preload("res://scripts/AnimalArt.gd")
const CareEffects = preload("res://scripts/CareEffects.gd")

var animal_info: Dictionary = {}
var avatar: Control
var overlay: Control
var action: String = ""
var elapsed: float = 0.0
var duration: float = 1.8
var animating: bool = false
var reduce_motion: bool = false

func setup(info: Dictionary, motion_reduced: bool = false) -> void:
	animal_info = info
	reduce_motion = motion_reduced

func _ready() -> void:
	avatar = AnimalArt.new()
	avatar.setup(animal_info)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(avatar)
	overlay = CareEffects.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	set_process(true)

func play_action(next_action: String) -> bool:
	if animating:
		return false
	if not next_action in ["feed","wash","play","sleep"]:
		return false
	action = next_action
	elapsed = 0.0
	animating = true
	avatar.set("mood",{"feed":"eating","wash":"clean","play":"play","sleep":"sleep"}[action])
	overlay.set("action",action)
	overlay.set("phase",0.0)
	avatar.queue_redraw()
	overlay.queue_redraw()
	return true

func _process(delta: float) -> void:
	if not animating:
		return
	elapsed += delta
	var phase = clampf(elapsed/duration,0.0,1.0)
	overlay.set("phase",phase)
	overlay.queue_redraw()
	avatar.pivot_offset = avatar.size * 0.5
	if not reduce_motion:
		match action:
			"feed":
				avatar.rotation = sin(phase*TAU*6.0)*0.015
			"wash":
				avatar.rotation = sin(phase*TAU*4.0)*0.025
			"play":
				avatar.position.y = -absf(sin(phase*TAU*3.0))*16.0
				avatar.rotation = sin(phase*TAU*3.0)*0.035
			"sleep":
				avatar.rotation = 0.0
				avatar.scale = Vector2.ONE*(1.0-0.018*sin(phase*TAU*2.0))
	avatar.queue_redraw()
	if phase >= 1.0:
		animating = false
		overlay.set("action","")
		overlay.queue_redraw()
		avatar.rotation = 0.0
		avatar.position = Vector2.ZERO
		avatar.scale = Vector2.ONE
		avatar.set("mood","sleep" if action=="sleep" else "happy")
		avatar.queue_redraw()
		action_finished.emit(action)
