extends Node
## Tiny offline chimes for a children's kart game. Generated at startup as PCM;
## these are game UI effects, NEVER substitutes for animal recordings.
var sounds: Dictionary = {}
var player: AudioStreamPlayer
var enabled: bool = true

func _ready() -> void:
	player=AudioStreamPlayer.new()
	player.volume_db=-12.0
	add_child(player)
	for key in ["count","go","star","boost","shield","bump","pass","finish"]:
		sounds[key]=_tone(key)

func play_effect(key: String) -> void:
	if not enabled or not sounds.has(key):
		return
	player.stop()
	player.stream=sounds[key]
	player.play()

func _tone(kind: String) -> AudioStreamWAV:
	var notes: Array = []
	match kind:
		"count": notes=[523.25]
		"go": notes=[523.25,659.26,784.0]
		"star": notes=[783.99,1046.5]
		"boost": notes=[392.0,587.33,783.99]
		"shield": notes=[659.26,783.99]
		"bump": notes=[246.94,196.0]
		"pass": notes=[587.33,880.0]
		"finish": notes=[523.25,659.26,783.99,1046.5]
	var sample_rate: int=22050
	var duration_per_note: float=.095 if kind!="finish" else .15
	var count: int=int(float(notes.size())*duration_per_note*sample_rate)
	var data=PackedByteArray()
	data.resize(count*2)
	for i in range(count):
		var time: float=float(i)/float(sample_rate)
		var note_index: int=mini(int(time/duration_per_note),notes.size()-1)
		var local: float=fposmod(time,duration_per_note)
		var attack: float=clampf(local/.012,0.0,1.0)
		var release: float=clampf((duration_per_note-local)/.042,0.0,1.0)
		var envelope: float=attack*release
		var fundamental: float=float(notes[note_index])
		var voice: float=sin(TAU*fundamental*time)*.75+sin(TAU*fundamental*2.0*time)*.18
		data.encode_s16(i*2,int(clampf(voice*envelope*.27,-1.0,1.0)*32700.0))
	var clip=AudioStreamWAV.new()
	clip.format=AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate=sample_rate
	clip.stereo=false
	clip.data=data
	return clip
