extends Node
## Simple offline synthesized cues. Not a substitute for natural animal recordings.
var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)

func play_animal(id: String) -> void:
	var note: float = float({"cow":145,"pig":230,"sheep":290,"chicken":620,"duck":450,"horse":185,"rabbit":510,"squirrel":740,"fox":365,"deer":260,"bear":125,"owl":400}.get(id,440))
	_tone(note, 0.52, 1)

func play_good() -> void:
	_tone(620.0, 0.36, 2)

func play_try_again() -> void:
	_tone(280.0, 0.22, 0)

func _tone(freq: float, duration: float, variant: int) -> void:
	var sample_rate = 22050
	var count = int(float(sample_rate) * duration)
	var raw = PackedByteArray()
	raw.resize(count * 2)
	for i in range(count):
		var t = float(i) / float(sample_rate)
		var envelope = minf(1.0, t*14.0) * minf(1.0, (duration-t)*8.0)
		var bend = 1.0 + 0.11*sin(t*18.0) if variant == 1 else 1.0
		var melody = freq * (1.28 if variant == 2 and t > duration*0.52 else 1.0)
		var wave = sin(TAU*melody*t*bend)*0.63 + sin(TAU*melody*2.0*t)*0.18
		var sample = clampi(int(wave*envelope*11500.0), -32767, 32767)
		raw.encode_s16(i*2,sample)
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	audio.data = raw
	player.stream = audio
	player.play()
