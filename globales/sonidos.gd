class_name Sonidos
extends RefCounted
## Hasta dos efectos a la vez, con margen de volumen para mezclarse con la música.
## Cada reproductor se borra al terminar y sobrevive al nodo que lo pidió.
##
## Uso: Sonidos.muerte(nodo)   cuando un melón se rompe (jugador o rival)

const MUERTE: Array[AudioStream] = [
	preload("res://recursos/sonidos/slash.wav"),
	preload("res://recursos/sonidos/splash.wav"),
]
const GRUPO := &"efectos_sonido"
const MAX_SIMULTANEOS := 2
const VOLUMEN_DB := -12.0


## Uno de los sonidos de MUERTE al azar, con un poco de variación de tono.
static func muerte(donde: Node2D) -> void:
	_tocar(donde, MUERTE.pick_random(), randf_range(0.92, 1.08))


static func _tocar(donde: Node2D, stream: AudioStream, tono := 1.0) -> void:
	if not donde.is_inside_tree() or donde.get_tree().current_scene == null:
		return
	if donde.get_tree().paused or donde.get_tree().get_node_count_in_group(GRUPO) >= MAX_SIMULTANEOS:
		return
	var reproductor := AudioStreamPlayer2D.new()
	reproductor.stream = stream
	reproductor.pitch_scale = tono
	reproductor.volume_db = VOLUMEN_DB
	reproductor.max_distance = 4000.0
	donde.get_tree().current_scene.add_child(reproductor)
	reproductor.add_to_group(GRUPO)
	reproductor.global_position = donde.global_position
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()
