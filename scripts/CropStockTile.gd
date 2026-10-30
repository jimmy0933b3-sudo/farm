extends PanelContainer
## Shared original illustrated stock counter for the garden and farm.
const CropArt=preload("res://scripts/CropArt.gd")
const Rules=preload("res://scripts/GardenRules.gd")
var crop_id: String="carrot"
var count: int=0
var art: Control
var quantity: Label
var caption: Label

func setup(id: String,amount: int=0) -> void:
	crop_id=id
	count=maxi(0,amount)
	if is_inside_tree():
		_refresh()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(146,57)
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFF9E9")
	style.border_color=Color("#A3BE98")
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.content_margin_left=5
	style.content_margin_right=8
	style.content_margin_top=3
	style.content_margin_bottom=3
	add_theme_stylebox_override("panel",style)
	var row=HBoxContainer.new()
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",5)
	add_child(row)
	art=CropArt.new()
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size=Vector2(57,50)
	row.add_child(art)
	var col=VBoxContainer.new()
	col.mouse_filter=Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation",0)
	row.add_child(col)
	caption=Label.new()
	caption.add_theme_font_size_override("font_size",15)
	caption.add_theme_color_override("font_color",Color("#31594A"))
	col.add_child(caption)
	quantity=Label.new()
	quantity.add_theme_font_size_override("font_size",24)
	quantity.add_theme_color_override("font_color",Color("#234A3A"))
	col.add_child(quantity)
	_refresh()

func set_count(amount: int) -> void:
	count=maxi(0,amount)
	if quantity!=null:
		_refresh()

func _refresh() -> void:
	var crop: Dictionary=Rules.crop_for(crop_id)
	if crop.is_empty() or quantity==null:
		return
	art.setup(crop_id,3)
	caption.text=str(crop["name"])
	quantity.text="× %d" % count
	var style=get_theme_stylebox("panel").duplicate()
	style.bg_color=Color("#FFF9E9") if count>0 else Color("#F1F1EA")
	style.border_color=Color("#79A877") if count>0 else Color("#B1B9B0")
	add_theme_stylebox_override("panel",style)
