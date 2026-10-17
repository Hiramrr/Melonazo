extends SceneTree
## Música con audio real o Dummy. Usa un guardado separado.

var musica: AudioStreamPlayer
var config: Node
var juego: Node
var captura: AudioEffectCapture
var pico_mezcla := 0.0
var muestras := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_verificar")


func _comprobar(condicion: bool, mensaje := "Comprobación de audio fallida") -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)
		quit(1)


func _abrir(pantalla: String) -> Node:
	_comprobar(change_scene_to_file("res://pantallas/%s/%s.tscn" % [pantalla, pantalla]) == OK)
	await process_frame
	await process_frame
	current_scene.set_process(false)
	current_scene.set_physics_process(false)
	await create_timer(0.6).timeout
	return current_scene


func _revisar_mezcla() -> void:
	_comprobar(root.find_children("*", "AudioStreamPlayer", true, false) == [musica], "Solo existe un reproductor de música")
	var buffer := captura.get_buffer(captura.get_frames_available())
	muestras += buffer.size()
	for frame in buffer:
		_comprobar(is_finite(frame.x) and is_finite(frame.y), "La mezcla no contiene muestras inválidas")
		pico_mezcla = maxf(pico_mezcla, maxf(absf(frame.x), absf(frame.y)))
	_comprobar(pico_mezcla < 1.0, "La mezcla de música y efectos no satura")


func _verificar_efectos() -> void:
	var origen := Node2D.new()
	current_scene.add_child(origen)
	origen.position = root.get_visible_rect().get_center()
	for i in 20:
		Sonidos._tocar(origen, Sonidos.MUERTE[1])
	_comprobar(get_node_count_in_group(Sonidos.GRUPO) == 2, "Una ráfaga no acumula efectos sin límite")
	await create_timer(0.05).timeout
	paused = true
	await process_frame
	for efecto in get_nodes_in_group(Sonidos.GRUPO):
		_comprobar(efecto.stream_paused, "La pausa también detiene los efectos")
	Sonidos.muerte(origen)
	_comprobar(get_node_count_in_group(Sonidos.GRUPO) == 2, "No se crean efectos durante la pausa")
	paused = false
	origen.queue_free()
	await create_timer(0.2).timeout
	_comprobar(get_node_count_in_group(Sonidos.GRUPO) == 2, "El efecto continúa aunque desaparezca su emisor")
	await create_timer(0.5).timeout
	_comprobar(get_node_count_in_group(Sonidos.GRUPO) == 0, "Los efectos se liberan al terminar")
	origen = Node2D.new()
	current_scene.add_child(origen)
	Sonidos.muerte(origen)
	await _abrir("taller")
	_comprobar(get_node_count_in_group(Sonidos.GRUPO) == 0, "Cambiar de escena retira sus efectos")


func _verificar() -> void:
	musica = root.get_node("Musica")
	config = root.get_node("Config")
	juego = root.get_node("Juego")
	captura = AudioEffectCapture.new()
	captura.buffer_length = 2.0
	AudioServer.add_bus_effect(0, captura)
	process_frame.connect(_revisar_mezcla)
	juego.archivo_guardado = "user://prueba_musica_%d.json" % OS.get_process_id()
	for pista in [musica.MENU, musica.TIENDITA, musica.LENTA, musica.MEDIA, musica.RAPIDA]:
		_comprobar(pista is AudioStreamOggVorbis and pista.loop and pista.get_length() > 30.0)
		musica.tocar(pista)
		await create_timer(0.6).timeout
		musica.seek(pista.get_length() - 0.1)
		await create_timer(0.3).timeout
		_comprobar(musica.playing and musica.get_playback_position() < 1.0, "Cada pista musical completa su bucle")
	_comprobar(not musica.DERROTA.loop and musica.DERROTA.get_length() > 4.0)
	await _abrir("menu")
	_comprobar(musica.stream == musica.MENU and musica.playing)
	var original := musica.get_stream_playback()
	musica.tocar(musica.TIENDITA)
	await create_timer(0.05).timeout
	musica.tocar(musica.MENU)
	await create_timer(0.6).timeout
	_comprobar(musica.get_stream_playback() == original, "Cancelar un cambio conserva la posición de la pista actual")
	_comprobar(is_equal_approx(musica.volume_db, musica.VOLUMEN_DB), "Cancelar el cambio recupera el volumen")
	original = null
	await _abrir("taller")
	_comprobar(musica.stream == musica.TIENDITA and musica.playing)
	var reproduccion := musica.get_stream_playback()
	await _abrir("almanaque")
	await _abrir("taller")
	_comprobar(musica.get_stream_playback() == reproduccion, "Consultar el almanaque no reinicia Tiendita")
	var r = await _abrir("recorrido")
	_comprobar(musica.stream == musica.LENTA and musica.playing, "La salida comienza con Base Lenta")
	r.fase = r.Fase.RECORRIDO
	r.melon.en_suelo = false
	for caso in [[0.5 - 0.001, musica.LENTA], [0.5, musica.MEDIA], [0.8 - 0.001, musica.MEDIA], [0.8, musica.RAPIDA]]:
		r._revisar_avance(config.meta_m * caso[0] * config.px_por_metro, 1.0 / 120.0)
		await create_timer(0.6).timeout
		_comprobar(musica.stream == caso[1] and musica.playing, "La pista cambia en el límite de distancia")
	reproduccion = musica.get_stream_playback()
	for i in 10:
		r._revisar_avance(config.meta_m * 0.6 * config.px_por_metro, 1.0 / 120.0)
		await process_frame
	_comprobar(musica.get_stream_playback() == reproduccion, "Retroceder o actualizar cada cuadro no reinicia ni baja la intensidad")
	r.hud._alternar_pausa()
	await process_frame
	_comprobar(paused and musica.stream_paused, "La pausa detiene la música")
	r.hud._alternar_pausa()
	await process_frame
	_comprobar(not musica.stream_paused and musica.get_stream_playback() == reproduccion, "Continuar conserva la reproducción")
	# Una nueva petición durante un fundido debe sustituir la anterior.
	musica.tocar(musica.MEDIA)
	musica.tocar(musica.LENTA)
	await create_timer(0.6).timeout
	_comprobar(musica.stream == musica.LENTA)
	r._fin("¡Se detuvo!")
	await create_timer(0.6).timeout
	_comprobar(musica.stream == musica.DERROTA and musica.playing)
	reproduccion = musica.get_stream_playback()
	r._t_fin = 0.0
	r._process(0.01)
	await process_frame
	await process_frame
	_comprobar(current_scene.name == "Resultados" and musica.get_stream_playback() == reproduccion, "Derrota continúa entre la carrera y Resultados")
	musica.seek(musica.DERROTA.get_length() - 0.1)
	await create_timer(0.5).timeout
	_comprobar(not musica.playing, "Derrota termina sin repetirse")
	musica.tocar(musica.DERROTA)
	await create_timer(0.1).timeout
	_comprobar(not musica.playing, "Pedir Derrota de nuevo no repite el cierre")
	r = await _abrir("recorrido")
	_comprobar(musica.stream == musica.LENTA and musica.playing, "Un intento nuevo reinicia Base Lenta")
	r.melon.roto = true
	r._on_melon_roto()
	await create_timer(0.6).timeout
	_comprobar(musica.stream == musica.DERROTA, "Romper el melón también toca Derrota")
	r.hud._alternar_pausa()
	r.hud._volver()
	await process_frame
	await process_frame
	await create_timer(0.6).timeout
	_comprobar(not paused and musica.stream == musica.TIENDITA and musica.playing, "Abandonar vuelve a la música del taller")
	r = await _abrir("recorrido")
	r.fase = r.Fase.RECORRIDO
	r._revisar_avance(config.meta_m * config.px_por_metro, 1.0 / 120.0)
	await create_timer(0.6).timeout
	_comprobar(musica.stream == musica.MENU and musica.playing, "Llegar a la meta toca Menú")
	reproduccion = musica.get_stream_playback()
	r._t_fin = 0.0
	r._process(0.01)
	await process_frame
	await process_frame
	_comprobar(current_scene.name == "Resultados" and musica.get_stream_playback() == reproduccion)
	reproduccion = null
	await _verificar_efectos()
	_comprobar(muestras > 0 and pico_mezcla > 0.01, "La captura verifica audio real, también con el controlador Dummy")
	process_frame.disconnect(_revisar_mezcla)
	AudioServer.remove_bus_effect(0, 0)
	musica.stop()
	await create_timer(0.1).timeout
	DirAccess.remove_absolute(juego.archivo_guardado)
	if fallos == 0:
		print("OK: seis pistas, un reproductor, fundidos sin reinicios, pausa, derrota única, reintento, llegada y efectos limitados. Pico de mezcla: %.3f." % pico_mezcla)
	quit(1 if fallos > 0 else 0)
