extends Node
## Android system Mandarin TTS + bundled genuine animal field recordings.
## Never synthesize a fake animal voice by shifting a sine-wave pitch.

const WAV_FOLDER = "res://assets/audio/animals/"
const LABELS = {
	"cow":"乳牛","pig":"小豬","sheep":"綿羊","chicken":"公雞",
	"duck":"鴨子","horse":"馬","rabbit":"兔子","squirrel":"松鼠",
	"fox":"狐狸","deer":"鹿","bear":"熊","owl":"貓頭鷹",
	"hedgehog":"刺蝟","raccoon":"浣熊","boar":"野豬","monkey":"猴子",
	"snake":"蛇","guinea_pig":"天竺鼠","meerkat":"狐獴"
}

var player: AudioStreamPlayer
var voice_id: String = ""
var tts_available: bool = false
var enabled: bool = true
var speech_enabled: bool = true

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -4.0
	add_child(player)
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		for locale in ["zh_TW", "zh", "zh_CN"]:
			var voices = DisplayServer.tts_get_voices_for_language(locale)
			if not voices.is_empty():
				voice_id = str(voices[0])
				break
		tts_available = not voice_id.is_empty()

func speak(message: String) -> bool:
	if not enabled or not speech_enabled or not tts_available:
		return false
	if message.is_empty():
		return false
	DisplayServer.tts_speak(message,voice_id,85,1.06,0.86,0,true)
	return true

func stop_speaking() -> void:
	if tts_available:
		DisplayServer.tts_stop()

func has_natural_sound(id: String) -> bool:
	return ResourceLoader.exists(WAV_FOLDER+id+".wav")

func play_animal(id: String) -> void:
	if not enabled:
		return
	var path = WAV_FOLDER+id+".wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			player.stop()
			player.stream = stream
			player.play()
			return
	# No fabricated animal noise. Use spoken name only when a genuine recording
	# is not supplied. Quiet wildlife is never misrepresented.
	speak("這是"+str(LABELS.get(id,"動物"))+"。我們一起觀察牠。")

func play_good() -> void:
	speak("答對了！你好棒！")

func play_try_again() -> void:
	speak("沒關係，再試試看。")
