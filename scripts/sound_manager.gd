extends Node

var sample_rate = 22050

func _ready():
	pass

func play_splash():
	var player = AudioStreamPlayer.new()
	player.stream = _generate_splash()
	player.volume_db = -6.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_chest_open():
	var player = AudioStreamPlayer.new()
	player.stream = _generate_chest_open()
	player.volume_db = -4.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_whale():
	var player = AudioStreamPlayer.new()
	player.stream = _generate_whale()
	player.volume_db = -3.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_catch():
	var player = AudioStreamPlayer.new()
	player.stream = _generate_catch_ring()
	player.volume_db = -5.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_shark():
	var player = AudioStreamPlayer.new()
	player.stream = _generate_shark_hiss()
	player.volume_db = -4.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_squid_squeal():
	var player = AudioStreamPlayer.new()
	player.stream = _generate_squid_squeal()
	player.volume_db = -7.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _generate_splash() -> AudioStreamWAV:
	var duration = 0.4
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = max(0.0, 1.0 - t / duration)
		# White noise with low-pass feel
		var noise = (randf() * 2.0 - 1.0) * envelope
		# Add a low frequency splash thud
		var thud = sin(t * 120.0 * TAU) * envelope * envelope * 0.5
		var sample = clampf((noise * 0.6 + thud) * 0.8, -1.0, 1.0)
		var value = int(sample * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_chest_open() -> AudioStreamWAV:
	var duration = 0.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = max(0.0, 1.0 - t / duration)
		# Creaky door: rising frequency with harmonics
		var freq = 200.0 + t * 400.0
		var creak = sin(t * freq * TAU) * 0.4
		creak += sin(t * freq * 1.5 * TAU) * 0.2
		# Add a hinge squeak
		var squeak = sin(t * (800.0 + sin(t * 30.0) * 200.0) * TAU) * 0.2 * envelope
		var sample = clampf((creak + squeak) * envelope * 0.7, -1.0, 1.0)
		var value = int(sample * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_whale() -> AudioStreamWAV:
	var duration = 1.2
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = sin(t / duration * PI) * 0.8
		# Deep whale call: low frequency sweep
		var freq = 80.0 + sin(t * 2.0) * 30.0
		var tone = sin(t * freq * TAU) * 0.5
		# Add harmonics for richness
		tone += sin(t * freq * 2.0 * TAU) * 0.2
		tone += sin(t * freq * 3.0 * TAU) * 0.1
		# Slight warble
		var warble = sin(t * (freq * 1.5 + sin(t * 5.0) * 20.0) * TAU) * 0.15
		var sample = clampf((tone + warble) * envelope, -1.0, 1.0)
		var value = int(sample * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_catch_ring() -> AudioStreamWAV:
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = max(0.0, 1.0 - t / duration)
		# Bright bell ring: multiple high harmonics
		var ring = sin(t * 880.0 * TAU) * 0.3
		ring += sin(t * 1320.0 * TAU) * 0.25
		ring += sin(t * 1760.0 * TAU) * 0.2
		ring += sin(t * 2640.0 * TAU) * 0.1
		var sample = clampf(ring * envelope * envelope * 0.9, -1.0, 1.0)
		var value = int(sample * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_squid_squeal() -> AudioStreamWAV:
	# Shrill squeal that runs the length of the squid's 3 second fade-in
	var duration = 3.0
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = t / duration
		# Fast attack, piercing sustain, tapering tail
		var envelope = min(t / 0.12, 1.0) * max(0.0, 1.0 - pow(progress, 3.0))
		# Shrill core tone that arcs upward, with a tight warble
		var base_freq = 1500.0 + 750.0 * sin(progress * PI)
		var freq = base_freq + sin(t * 24.0 * TAU) * 100.0
		var squeal = sin(t * freq * TAU) * 0.5
		squeal += sin(t * freq * 2.0 * TAU) * 0.25
		squeal += sin(t * freq * 3.0 * TAU) * 0.12
		# Airy edge on the shriek
		var hiss = (randf() * 2.0 - 1.0) * 0.08
		var sample = clampf((squeal + hiss) * envelope * 0.8, -1.0, 1.0)
		var value = int(sample * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_shark_hiss() -> AudioStreamWAV:
	var duration = 0.7
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = sin(t / duration * PI) * 0.7
		var noise = (randf() * 2.0 - 1.0)
		var hiss = noise * 0.5
		var rumble = sin(t * 60.0 * TAU) * 0.2 * envelope
		var sibilant = sin(t * 4000.0 * TAU + noise * 3.0) * 0.15
		var sample = clampf((hiss + rumble + sibilant) * envelope, -1.0, 1.0)
		var value = int(sample * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
