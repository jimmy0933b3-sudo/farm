extends VBoxContainer
## Permanent, separate monster sticker collection. Locked entries stay discoverable.
const MonsterArt=preload("res://scripts/MonsterArt.gd")
var monsters: Array=[]
var progress
var narrator
var detail: Label

func setup(catalog: Array, store, voice) -> void:
	monsters=catalog
	progress=store
	narrator=voice

func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",9)
	var count: int=0
	for info in monsters:
		if progress.data.get("monster_found",[]).has(str(info["id"])):
			count+=1
	var title=Label.new()
	title.text="👾 已收集 %d / %d 位怪獸朋友，點一張貼紙聽故事！" % [count,monsters.size()]
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",23)
	title.add_theme_color_override("font_color",Color("#294D60"))
	add_child(title)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=4 if get_viewport_rect().size.x>=1100.0 else 3
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	for monster in monsters:
		var id=str(monster.get("id",""))
		var owned=progress.data.get("monster_found",[]).has(id)
		var card=Button.new()
		card.custom_minimum_size=Vector2(190,164)
		card.text=""
		var style=StyleBoxFlat.new()
		style.bg_color=Color("#E2F6DE") if owned else Color("#EEEAF2")
		style.border_color=Color("#599F80") if owned else Color("#A3A3B5")
		style.set_border_width_all(3)
		style.set_corner_radius_all(18)
		card.add_theme_stylebox_override("normal",style)
		card.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		card.pressed.connect(Callable(self,"_show_detail").bind(monster,owned))
		grid.add_child(card)
		var stack=VBoxContainer.new()
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(stack)
		var art=MonsterArt.new()
		art.setup(monster)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art.custom_minimum_size=Vector2(170,124)
		art.size_flags_vertical=Control.SIZE_EXPAND_FILL
		if not owned:
			art.modulate=Color("#C0C0CE")
		stack.add_child(art)
		var caption=Label.new()
		caption.text=("✓ " if owned else "🔎 ")+str(monster["name"])
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size",19)
		caption.add_theme_color_override("font_color",Color("#294D60"))
		stack.add_child(caption)
	detail=Label.new()
	detail.text="在三個怪獸樂園找找看，點到怪獸就會得到收藏貼紙。"
	detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size",18)
	detail.add_theme_color_override("font_color",Color("#294D60"))
	add_child(detail)

func _show_detail(info: Dictionary, owned: bool) -> void:
	var sentence: String=("%s：%s" % [str(info["name"]),str(info.get("desc",""))]) if owned else "還沒找到%s！去怪獸樂園找找吧。" % str(info["name"])
	detail.text=sentence
	if narrator!=null:
		narrator.speak(sentence)
