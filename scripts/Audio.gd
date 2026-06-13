extends Node

# SFX leves para dar "suco" ao jogo. Carrega WAVs de res://art/sfx/ e toca via pool
# de AudioStreamPlayers para permitir sobreposicao (ex: rajada de moedas).

const SFX_DIR := "res://art/sfx/"
const SFX_NAMES := ["coin", "collect", "levelup", "click", "unlock", "error"]
const POOL_SIZE := 12

var _streams: Dictionary = {}
var _players: Array = []
var _next: int = 0
var enabled: bool = true

# Evita empilhar o MESMO som muitas vezes no mesmo frame (estoura volume).
var _last_play_ms: Dictionary = {}
const MIN_GAP_MS := 30

func _ready() -> void:
	for n in SFX_NAMES:
		var path: String = SFX_DIR + String(n) + ".wav"
		if ResourceLoader.exists(path):
			var s = load(path)
			if s is AudioStream:
				if s is AudioStreamWAV:
					s.loop_mode = AudioStreamWAV.LOOP_DISABLED
				_streams[n] = s
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(name: String, pitch_jitter: float = 0.06, volume_db: float = 0.0) -> void:
	if not enabled:
		return
	if not _streams.has(name):
		return
	var now := Time.get_ticks_msec()
	var last: int = int(_last_play_ms.get(name, -10000))
	if now - last < MIN_GAP_MS:
		return
	_last_play_ms[name] = now
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db
	p.play()

# Conveniencias semanticas
func coin() -> void: play("coin", 0.12)
func collect() -> void: play("collect", 0.05)
func levelup() -> void: play("levelup", 0.03, 1.0)
func click() -> void: play("click", 0.08, -4.0)
func unlock() -> void: play("unlock", 0.02, 1.0)
func error() -> void: play("error", 0.04, -2.0)
