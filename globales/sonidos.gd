class_name Sonidos
extends RefCounted
## Efectos de sonido sueltos. Cada uno crea su propio reproductor, que se borra
## solo al terminar; así suena aunque el nodo que lo pidió desaparezca.
##
## Uso: Sonidos.muerte(nodo)   cuando un melón se rompe (jugador o rival)

const MUERTE: Array[AudioStream] = [
	preload("res://recursos/sonidos/slash.wav"),
	preload("res://recursos/sonidos/splash.wav"),
]


## Uno de los sonidos de MUERTE al azar, con un poco de variación de tono.
static func muerte(donde: Node2D) -> void:
	_tocar(donde, MUERTE.pick_random(), randf_range(0.92, 1.08))


static func _tocar(donde: Node2D, stream: AudioStream, tono := 1.0) -> void:
	if not donde.is_inside_tree() or donde.get_tree().current_scene == null:
		return
	var reproductor := AudioStreamPlayer2D.new()
	reproductor.stream = stream
	reproductor.pitch_scale = tono
	reproductor.max_distance = 4000.0
	donde.get_tree().current_scene.add_child(reproductor)
	reproductor.global_position = donde.global_position
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()
