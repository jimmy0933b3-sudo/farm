extends RefCounted
## Button-only bilingual labels. Keep narration, descriptions and animal facts
## in Mandarin. Preserve the original wording, so switching is fully reversible.
const EN={
	"返回":"Back","家長":"Parent","確認":"Confirm","取消":"Cancel",
	"首頁":"Home","回首頁":"Home","🏠 回首頁":"🏠 Home",
	"再找一次":"Find Again","再玩一次":"Play Again","🔁 再玩一次":"🔁 Replay",
	"🪽 再飛一次":"🪽 Fly Again","回樂園":"Park",
	"回森林樂園":"Forest Park","回鳥類樂園":"Bird Park","🐦 回鳥類樂園":"🐦 Bird Park",
	"回怪獸樂園":"Monster Park","👾 回怪獸樂園":"👾 Monster Park",
	"🌳 回私人農場":"🌳 My Farm","昆蟲樂園":"Insect Park","動物園樂園":"Zoo",
	"海底樂園":"Ocean Park","森林樂園":"Forest Park",
	"🏠 首頁":"🏠 Home","🌱 農田":"🌱 Garden",
	"動物之家":"Animal Home","去動物之家照顧牠":"Care for Animal",
	"摸摸牠":"Pet","一起玩小遊戲":"Play Game",
	"聽昆蟲聲音":"Insect Sound","聽動物叫聲":"Animal Sound",
	"聽聽昆蟲介紹":"Insect Story","聽聽動物介紹":"Animal Story",
	"再聽一次":"Listen Again","再聽叫聲":"Hear Again",
	"下一步":"Next","上一步":"Undo","完成":"Done","開始":"Start",
	"關閉":"Close","回去":"Back","完成作品 ★":"Finish ★",
	"完成這一步 ✓":"Finish Step ✓","重新畫":"Restart",
	"全部重畫":"Reset All","聽玩法":"How to Play",
	"移回圖鑑":"Remove","聽聲音":"Sound","洗澡":"Bath","玩耍":"Play","休息":"Rest",
	"📖 鳥類圖鑑":"📖 Bird Album","🏆 飛行大賽":"🏆 Flight Race",
	"📖 怪獸圖鑑":"📖 Monster Album","🏎️ 怪獸賽車場":"🏎️ Monster Race",
	"🏁 開始比賽！":"🏁 Start Race!","🏁 開始飛行大賽":"🏁 Start Flight!",
	"⬅️ 往左":"⬅️ Left","往右 ➡️":"Right ➡️",
	"⬆️ 上升":"⬆️ Up","⬇️ 下降":"⬇️ Down",
	"🚀 加速":"🚀 Boost","✨ 加速":"✨ Boost",
	"✓ 開":"✓ On","○ 關":"○ Off",
	"🌱 Garden":"🌱 Garden","🏎️ Racing":"🏎️ Racing",
	"Bath":"Bath","Play":"Play","Rest":"Rest","Sound":"Sound","Remove":"Remove",
	"💗 摸摸牠":"💗 Pet","🪽 飛起來":"🪽 Fly",
	"✨ 鳥兒特技":"✨ Special Move","🔊 聽介紹":"🔊 Story",
	"🐾 帶蔬菜餵動物":"🐾 Feed Animals",
	"🌾":"🌾","🐾":"🐾",
	"💧 湖畔濕地":"💧 Wetland","🌳 森林樹梢":"🌳 Treetops",
	"⛰️ 高空山谷":"⛰️ Valley","🌙 月夜森林":"🌙 Night Woods",
	"💧 湖畔微風盃":"💧 Lake Cup","🌳 森林天空盃":"🌳 Forest Cup",
	"⛰️ 山谷盤旋盃":"⛰️ Canyon Cup","🌙 月夜飛行盃":"🌙 Moon Cup",
	"農田":"Garden","私人農場":"My Farm","動物圖鑑":"Animal Album",
	"農場樂園":"Farm Park","森林樂園":"Forest Park","動物園樂園":"Zoo Park",
	"我的開心農田":"My Garden","動物著色屋":"Animal Coloring",
	"動物畫畫學堂":"Drawing Academy","動物探險島":"Animal Island",
	"鳥類樂園":"Bird Park","怪獸樂園":"Monster Park",
	"可樂小動物樂園":"Cola Pet Park",
	"動物園":"Zoo","著色屋":"Coloring Room","畫畫屋":"Drawing Room",
	"開始探險":"Explore","開始遊戲":"Start Game",
	"🐄 乳牛":"🐄 Cow",
	"乳牛":"Cow","小豬":"Pig","綿羊":"Sheep","公雞":"Rooster",
	"鴨子":"Duck","馬":"Horse","兔子":"Rabbit","松鼠":"Squirrel",
	"狐狸":"Fox","鹿":"Deer","熊":"Bear","貓頭鷹":"Owl",
	"刺蝟":"Hedgehog","浣熊":"Raccoon","野豬":"Boar","猴子":"Monkey",
	"蛇":"Snake","天竺鼠":"Guinea Pig","狐獴":"Meerkat",
	"小丑魚":"Clownfish","海龜":"Sea Turtle","海豚":"Dolphin",
	"章魚":"Octopus","海馬":"Seahorse","河豚":"Pufferfish",
	"駱駝":"Camel","獅子":"Lion","老虎":"Tiger","大象":"Elephant",
	"河馬":"Hippo","海豹":"Seal","獨角仙":"Rhinoceros Beetle",
	"鍬形蟲":"Stag Beetle","蝴蝶":"Butterfly","瓢蟲":"Ladybug",
	"蜜蜂":"Bee","螳螂":"Mantis","糞金龜":"Dung Beetle",
	"象鼻蟲":"Weevil","娃娃魚":"Axolotl","狗狗":"Dog","貓咪":"Cat",
	"黃金鼠":"Golden Hamster",
	"鴛鴦":"Mandarin Duck","小水鴨":"Teal","八哥":"Myna",
	"麻雀":"Sparrow","水雉":"Jacana","五色鳥":"Barbet",
	"夜鷺":"Night Heron","家燕":"Swallow","老鷹":"Eagle",
	"鳳頭蒼鷹":"Crested Goshawk","魚鷹":"Osprey",
	"火球波波":"Fire Bobo","水滴嚕嚕":"Water Lulu",
	"草芽芽":"Sprout","泡泡噗噗":"Bubble",
	"石頭咚咚":"Stone","果凍QQ":"Jelly",
	"閃電奇奇":"Spark","棉花糖糖":"Cloud",
	"星角亮亮":"Star","三眼豆豆":"Three Eyes",
	"小翼飛飛":"Little Wing","彩虹長長":"Rainbow",
	"胡蘿蔔":"Carrot","小白菜":"Cabbage","南瓜":"Pumpkin",
	"吃人花":"Chomper Flower"
}
const SPECIAL_ZH={
	"🌱 Garden":"🌱 農田","🏎️ Racing":"🏎️ 賽車場",
	"Bath":"洗澡","Play":"玩耍","Rest":"休息","Sound":"聽聲音","Remove":"移回圖鑑"
}

static func translate_label(source: String,language: String) -> String:
	if language=="zh":
		return str(SPECIAL_ZH.get(source,source))
	if EN.has(source):
		return str(EN[source])
	# Buttons may carry a decorative icon before a Chinese label.
	var p=source.find(" ")
	if p>0 and p<7:
		var prefix=source.substr(0,p+1)
		var tail=source.substr(p+1)
		if EN.has(tail):
			return prefix+str(EN[tail])
	# Numbered cards or action labels may be constructed dynamically.
	if source.begins_with("🚀 ") and source.ends_with(" 秒"):
		return source.replace(" 秒","s")
	return source

static func _translate_control(node: Control,language: String) -> void:
	var current=""
	if node is Button:
		current=node.text
	elif node is Label:
		current=node.text
	if current.is_empty():
		return
	var previous=str(node.get_meta("ui_last_display",""))
	var original=str(node.get_meta("ui_original_label",current))
	if not previous.is_empty() and current!=previous:
		original=current
	var localized=translate_label(original,language)
	node.set_meta("ui_original_label",original)
	node.set_meta("ui_last_display",localized)
	if current!=localized:
		if node is Button:
			node.text=localized
		elif node is Label:
			node.text=localized

static func apply_to(root: Node,language: String,in_button: bool=false) -> void:
	# Many buttons render their label as a nested Label beside a picture.
	# Translate those too, without changing ordinary text, TTS or subtitles.
	if root is Button or (in_button and root is Label):
		_translate_control(root,language)
	var inside=in_button or root is Button
	for child in root.get_children():
		apply_to(child,language,inside)
