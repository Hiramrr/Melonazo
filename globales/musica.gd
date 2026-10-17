extends AudioStreamPlayer
## Autoload "Musica": una pista entre pantallas, con fundidos breves.

const MENU := preload("res://recursos/musica/menu.ogg")
const TIENDITA := preload("res://recursos/musica/tiendita.ogg")
const LENTA := preload("res://recursos/musica/base_lenta.ogg")
const MEDIA := preload("res://recursos/musica/base_media.ogg")
const RAPIDA := preload("res://recursos/musica/base_rapida.ogg")
const DERROTA := preload("res://recursos/musica/derrota.ogg")
const VOLUMEN_DB := -10.0
const VELOCIDAD_MEDIA := 60.0 # m/s horizontales
const VELOCIDAD_RAPIDA := 120.0
const MARGEN_VELOCIDAD := 5.0
const DURACION_MEZCLA := 1.5
const VELOCIDAD_SOSTENIDA := 2.0
const PERMANENCIA_MINIMA := 6.0
const DURACION_SALIDA_RAPIDA := 5.0

var _pista: AudioStream
var _transicion: Tween
var _saliente: AudioStreamPlayer
var _candidata: AudioStream
var _tiempo_candidata := 0.0
var _permanencia := 0.0
var _posiciones: Dictionary = {}
var _salida_rapida_restante := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_saliente = AudioStreamPlayer.new()
	add_child(_saliente)


func tocar(pista: AudioStream) -> void:
	if not _es_carrera(pista):
		_salida_rapida_restante = 0.0
	# Conserva la posición y no repite Derrota al entrar en Resultados.
	if _pista == pista:
		return
	_candidata = null
	_tiempo_candidata = 0.0
	_permanencia = 0.0
	if pista == LENTA and not _es_carrera(_pista):
		_posiciones.clear()
	if _es_carrera(_pista) and _es_carrera(pista) and playing:
		_mezclar_carrera(pista)
		return
	_pista = pista
	if _transicion:
		_transicion.kill()
	_saliente.stop()
	# Un cruce recién iniciado puede estar a volumen cero (-INF dB).
	volume_db = maxf(volume_db, -50.0)
	_transicion = create_tween()
	# Si se cancela un cambio antes de sustituir la pista, conserva su posición.
	if stream == pista and playing:
		_transicion.tween_property(self, "volume_db", VOLUMEN_DB, 0.3)
		return
	if playing:
		_transicion.tween_property(self, "volume_db", -50.0, 0.2)
	_transicion.tween_callback(func() -> void:
		stop()
		stream = pista
		volume_db = -50.0
		play())
	_transicion.tween_property(self, "volume_db", VOLUMEN_DB, 0.3)


func _es_carrera(pista: AudioStream) -> bool:
	return pista == LENTA or pista == MEDIA or pista == RAPIDA


func _mezclar_carrera(pista: AudioStream) -> void:
	if _transicion:
		_transicion.kill()
	_posiciones[stream] = get_playback_position()
	_saliente.stream = stream
	_saliente.volume_linear = volume_linear
	_saliente.play(get_playback_position())
	stream = pista
	_pista = pista
	volume_linear = 0.0
	play(float(_posiciones.get(pista, 0.0)))
	# Superponer las pistas evita el hueco de silencio del fundido secuencial.
	_transicion = create_tween().set_parallel(true)
	_transicion.tween_property(self, "volume_linear", db_to_linear(VOLUMEN_DB), DURACION_MEZCLA)
	_transicion.tween_property(_saliente, "volume_linear", 0.0, DURACION_MEZCLA)
	_transicion.chain().tween_callback(func() -> void:
		_posiciones[_saliente.stream] = _saliente.get_playback_position()
		_saliente.stop())


func iniciar_salida() -> void:
	# Cada salida empieza desde el inicio de la pista rápida.
	_posiciones.erase(RAPIDA)
	if _pista == RAPIDA and playing:
		seek(0.0)
		_candidata = null
		_tiempo_candidata = 0.0
		_permanencia = 0.0
	tocar(RAPIDA)
	_salida_rapida_restante = DURACION_SALIDA_RAPIDA


func actualizar_recorrido(velocidad_m_s: float, delta := 0.0) -> void:
	if get_tree().paused:
		return
	var termino_salida := false
	if _salida_rapida_restante > 0.0:
		_salida_rapida_restante = maxf(0.0, _salida_rapida_restante - delta)
		if _salida_rapida_restante > 0.000001:
			return
		_salida_rapida_restante = 0.0
		termino_salida = true
	if not _es_carrera(_pista):
		tocar(LENTA)
		return
	_permanencia += delta
	var rapidez := absf(velocidad_m_s)
	# El margen al frenar evita alternar pistas alrededor de un límite.
	var limite_rapida := VELOCIDAD_RAPIDA
	var limite_media := VELOCIDAD_MEDIA
	if _pista == RAPIDA:
		limite_rapida -= MARGEN_VELOCIDAD
	if _pista == MEDIA or _pista == RAPIDA:
		limite_media -= MARGEN_VELOCIDAD
	var siguiente: AudioStream = LENTA
	if rapidez >= limite_rapida:
		siguiente = RAPIDA
	elif rapidez >= limite_media:
		siguiente = MEDIA
	if termino_salida:
		# A los cinco segundos manda la velocidad, sin añadir otros seis de espera.
		_permanencia = PERMANENCIA_MINIMA
		tocar(siguiente)
		return
	if siguiente == _pista:
		_candidata = null
		_tiempo_candidata = 0.0
		return
	if siguiente != _candidata:
		_candidata = siguiente
		_tiempo_candidata = 0.0
	_tiempo_candidata += delta
	if _tiempo_candidata >= VELOCIDAD_SOSTENIDA and _permanencia >= PERMANENCIA_MINIMA:
		tocar(siguiente)
