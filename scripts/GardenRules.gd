extends RefCounted
## Four original plant species; the fictional carnivorous flower is collectible, not pet food.
const CROPS=[
	{"id":"carrot","name":"胡蘿蔔","emoji":"🥕","seconds":30,"harvest":2,"color":"#F3A85D"},
	{"id":"cabbage","name":"小白菜","emoji":"🥬","seconds":45,"harvest":2,"color":"#8BC48A"},
	{"id":"pumpkin","name":"南瓜","emoji":"🎃","seconds":60,"harvest":2,"color":"#EFA45D"},
	{"id":"carnivorous_flower","name":"吃人花","emoji":"🌺","seconds":90,"harvest":1,"color":"#D35F8B"}
]
const ALLOWED={
	"carrot":["cow","pig","sheep","chicken","duck","horse","guinea_pig","rabbit","deer","camel","elephant"],
	"cabbage":["cow","pig","sheep","chicken","duck","guinea_pig","rabbit","elephant"],
	"pumpkin":["cow","pig","sheep","chicken","duck","horse","guinea_pig","rabbit","deer","camel","elephant","hippo","boar"]
}

static func crop_for(id: String) -> Dictionary:
	for crop in CROPS:
		if str(crop["id"])==id:
			return crop
	return {}

static func suitable(animal_id: String,crop_id: String) -> bool:
	return str(animal_id) in ALLOWED.get(crop_id,[])

static func empty_plot() -> Dictionary:
	return {"crop":"","planted_at":0,"ready_at":0}

static func stage(plot: Dictionary,now: int) -> int:
	if str(plot.get("crop","")).is_empty():
		return 0
	if now>=int(plot.get("ready_at",0)):
		return 3
	var crop=crop_for(str(plot["crop"]))
	var duration=maxi(1,int(plot.get("ready_at",now+1))-int(plot.get("planted_at",now)))
	var elapsed=maxi(0,now-int(plot.get("planted_at",now)))
	return 2 if elapsed*2>=duration else 1

static func wait_text(seconds: int) -> String:
	var remaining=maxi(0,seconds)
	if remaining>=60:
		return "%d分%02d秒" % [int(remaining/60),remaining%60]
	return "%d秒" % remaining
