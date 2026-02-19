extends Node

## Audio management system.
## Autoload singleton — access via Audio.
## Procedural placeholder sounds for Phase 2. Replace with real assets later.

var master_volume: float = 1.0
var sfx_volume: float = 0.8
var music_volume: float = 0.5

## Cached procedural sounds
var _place_sound: AudioStreamWAV
var _connect_sound: AudioStreamWAV
var _delete_sound: AudioStreamWAV
var _start_sound: AudioStreamWAV
var _success_sound: AudioStreamWAV
var _click_sound: AudioStreamWAV

## Pool of AudioStreamPlayer nodes for concurrent sounds
var _players: Array[AudioStreamPlayer] = []
const PLAYER_POOL_SIZE: int = 8


func _ready() -> void:
	# Create player pool
	for i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

	# Generate procedural placeholder sounds
	_place_sound = _generate_tone(440.0, 0.08, 0.6)
	_connect_sound = _generate_tone(660.0, 0.06, 0.5)
	_delete_sound = _generate_tone(220.0, 0.12, 0.4)
	_start_sound = _generate_sweep(300.0, 600.0, 0.2, 0.5)
	_success_sound = _generate_sweep(400.0, 800.0, 0.3, 0.6)
	_click_sound = _generate_tone(880.0, 0.03, 0.3)


## Play sound for component placement
func play_place() -> void:
	_play(_place_sound)


## Play sound for wire connection
func play_connect() -> void:
	_play(_connect_sound)


## Play sound for component deletion
func play_delete() -> void:
	_play(_delete_sound)


## Play sound for simulation start
func play_start() -> void:
	_play(_start_sound)


## Play sound for success/completion
func play_success() -> void:
	_play(_success_sound)


## Play sound for UI click
func play_click() -> void:
	_play(_click_sound)


## Play a positional sound at a world location
func play_at(stream: AudioStreamWAV, world_pos: Vector2, volume_db: float = 0.0) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	player.global_position = world_pos
	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


## Internal: play a sound from the pool
func _play(stream: AudioStreamWAV) -> void:
	if stream == null:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * master_volume)
			player.play()
			return
	# All players busy — skip this sound


## Generate a simple sine tone
func _generate_tone(freq: float, duration: float, volume: float = 1.0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit mono

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = 1.0 - (float(i) / float(num_samples))  # Linear decay
		envelope *= envelope  # Quadratic decay for snappier feel
		var sample: float = sin(t * freq * TAU) * envelope * volume
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


## Generate a frequency sweep
func _generate_sweep(freq_start: float, freq_end: float, duration: float, volume: float = 1.0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = lerpf(freq_start, freq_end, t)
		var envelope: float = 1.0 - t
		phase += freq / float(sample_rate)
		var sample: float = sin(phase * TAU) * envelope * volume
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
