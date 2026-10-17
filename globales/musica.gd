extends AudioStreamPlayer
## Autoload "Musica": una pista entre pantallas, con fundidos breves.

const MENU := preload("res://recursos/musica/menu.ogg")
const TIENDITA := preload("res://recursos/musica/tiendita.ogg")
const LENTA := preload("res://recursos/musica/base_lenta.ogg")
const MEDIA := preload("res://recursos/musica/base_media.ogg")
const RAPIDA := preload("res://recursos/musica/base_rapida.ogg")
const DERROTA := preload("res://recursos/musica/derrota.ogg")
const VOLUMEN_DB := -10.0

var _pista: AudioStream
var _transicion: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func tocar(pista: AudioStream) -> void:
	# Conserva la posición y no repite Derrota al entrar en Resultados.
	if _pista == pista:
		return
	_pista = pista
	if _transicion:
		_transicion.kill()
	_transicion = create_tween()
	if playing:
		_transicion.tween_property(self, "volume_db", -50.0, 0.2)
	_transicion.tween_callback(func() -> void:
		stream = pista
		volume_db = -50.0
		play())
	_transicion.tween_property(self, "volume_db", VOLUMEN_DB, 0.3)


func actualizar_recorrido(metros: float) -> void:
	if metros >= Config.meta_m * 0.8:
		tocar(RAPIDA)
	elif metros >= Config.meta_m * 0.5:
		tocar(MEDIA)
	else:
		tocar(LENTA)
