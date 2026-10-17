extends SceneTree
## Música con audio real o Dummy. Usa un guardado separado.

var musica: AudioStreamPlayer
var config: Node
var juego: Node


func _initialize() -> void:
	call_deferred("_verificar")


func _abrir(pantalla: String) -> Node:
	assert(change_scene_to_file("res://pantallas/%s/%s.tscn" % [pantalla, pantalla]) == OK)
	await process_frame
	await process_frame
	current_scene.set_process(false)
	current_scene.set_physics_process(false)
	await create_timer(0.6).timeout
	return current_scene


func _verificar() -> void:
	musica = root.get_node("Musica")
	config = root.get_node("Config")
	juego = root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_musica_%d.json" % OS.get_process_id()
	for pista in [musica.MENU, musica.TIENDITA, musica.LENTA, musica.MEDIA, musica.RAPIDA]:
		assert(pista is AudioStreamOggVorbis and pista.loop and pista.get_length() > 30.0)
	assert(not musica.DERROTA.loop and musica.DERROTA.get_length() > 4.0)
	await _abrir("menu")
	assert(musica.stream == musica.MENU and musica.playing)
	await _abrir("taller")
	assert(musica.stream == musica.TIENDITA and musica.playing)
	var reproduccion := musica.get_stream_playback()
	await _abrir("almanaque")
	await _abrir("taller")
	assert(musica.get_stream_playback() == reproduccion, "Consultar el almanaque no reinicia Tiendita")
	var r = await _abrir("recorrido")
	assert(musica.stream == musica.LENTA and musica.playing, "La salida comienza con Base Lenta")
	r.fase = r.Fase.RECORRIDO
	r.melon.en_suelo = false
	for caso in [[0.5 - 0.001, musica.LENTA], [0.5, musica.MEDIA], [0.8 - 0.001, musica.MEDIA], [0.8, musica.RAPIDA]]:
		r._revisar_avance(config.meta_m * caso[0] * config.px_por_metro, 1.0 / 120.0)
		await create_timer(0.6).timeout
		assert(musica.stream == caso[1] and musica.playing, "La pista cambia en el límite de distancia")
	reproduccion = musica.get_stream_playback()
	for i in 10:
		r._revisar_avance(config.meta_m * 0.6 * config.px_por_metro, 1.0 / 120.0)
		await process_frame
	assert(musica.get_stream_playback() == reproduccion, "Retroceder o actualizar cada cuadro no reinicia ni baja la intensidad")
	r.hud._alternar_pausa()
	await process_frame
	assert(paused and musica.stream_paused, "La pausa detiene la música")
	r.hud._alternar_pausa()
	await process_frame
	assert(not musica.stream_paused and musica.get_stream_playback() == reproduccion, "Continuar conserva la reproducción")
	# Una nueva petición durante un fundido debe sustituir la anterior.
	musica.tocar(musica.MEDIA)
	musica.tocar(musica.LENTA)
	await create_timer(0.6).timeout
	assert(musica.stream == musica.LENTA)
	r._fin("¡Se detuvo!")
	await create_timer(0.6).timeout
	assert(musica.stream == musica.DERROTA and musica.playing)
	reproduccion = musica.get_stream_playback()
	r._t_fin = 0.0
	r._process(0.01)
	await process_frame
	await process_frame
	assert(current_scene.name == "Resultados" and musica.get_stream_playback() == reproduccion, "Derrota continúa entre la carrera y Resultados")
	musica.seek(musica.DERROTA.get_length() - 0.1)
	await create_timer(0.5).timeout
	assert(not musica.playing, "Derrota termina sin repetirse")
	musica.tocar(musica.DERROTA)
	await create_timer(0.1).timeout
	assert(not musica.playing, "Pedir Derrota de nuevo no repite el cierre")
	r = await _abrir("recorrido")
	assert(musica.stream == musica.LENTA and musica.playing, "Un intento nuevo reinicia Base Lenta")
	r.melon.roto = true
	r._on_melon_roto()
	await create_timer(0.6).timeout
	assert(musica.stream == musica.DERROTA, "Romper el melón también toca Derrota")
	r.hud._alternar_pausa()
	r.hud._volver()
	await process_frame
	await process_frame
	await create_timer(0.6).timeout
	assert(not paused and musica.stream == musica.TIENDITA and musica.playing, "Abandonar vuelve a la música del taller")
	r = await _abrir("recorrido")
	r.fase = r.Fase.RECORRIDO
	r._revisar_avance(config.meta_m * config.px_por_metro, 1.0 / 120.0)
	await create_timer(0.6).timeout
	assert(musica.stream == musica.MENU and musica.playing, "Llegar a la meta toca Menú")
	reproduccion = musica.get_stream_playback()
	r._t_fin = 0.0
	r._process(0.01)
	await process_frame
	await process_frame
	assert(current_scene.name == "Resultados" and musica.get_stream_playback() == reproduccion)
	DirAccess.remove_absolute(juego.archivo_guardado)
	print("OK: seis pistas, límites de progreso, pausa, fundidos, derrota única, reintento y llegada.")
	quit()
