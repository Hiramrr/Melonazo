extends SceneTree
var fallos := 0
func _initialize() -> void:
	call_deferred("verificar")
func comprobar(valor: bool, texto: String) -> void:
	if not valor:
		fallos += 1
		push_error(texto)
func verificar() -> void:
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_physics_process(false)
	r.fase = r.Fase.RECORRIDO
	var moneda = load("res://mundo/obstaculos/obstaculo.gd").new()
	moneda.tipo = "aplauso"
	r.add_child(moneda)
	r._al_tocar_obstaculo(r.melon, moneda)
	var audio = r.get_node("AudioMonedas")
	comprobar(r.recolectados == 1 and audio.playing, "Recoger moneda reproduce sonido")
	var reproduccion = audio.get_stream_playback()
	audio._process(0.2)
	Sonidos.monedas(r)
	comprobar(audio.get_stream_playback() == reproduccion and is_equal_approx(audio.restante, 0.3), "Monedas seguidas prolongan sin reiniciar ni superponer")
	reproduccion = null
	paused = true
	await process_frame
	comprobar(audio.stream_paused, "La pausa detiene las monedas")
	paused = false
	audio._process(0.31)
	comprobar(not audio.playing, "El sonido termina al dejar de recoger")
	root.get_node("Juego").ultimo = {"total": 50, "distancia": 10}
	change_scene_to_file("res://pantallas/resultados/resultados.tscn")
	await process_frame
	await process_frame
	comprobar(get_nodes_in_group("audio_monedas").is_empty(), "No arrastra sonido de carrera al cargar resultados")
	var escuchado := false
	for i in 2000:
		await process_frame
		var a = current_scene.get_node_or_null("AudioMonedas")
		if a != null and a.playing:
			escuchado = true
		if current_scene.lbl_total.text == "+50":
			break
	comprobar(escuchado, "El conteo del total tiene sonido")
	await create_timer(0.2).timeout
	comprobar(not current_scene.get_node("AudioMonedas").playing, "El sonido termina con el conteo")
	root.get_node("Juego").ultimo = {"total": 0}
	change_scene_to_file("res://pantallas/resultados/resultados.tscn")
	await process_frame
	await process_frame
	await create_timer(2.0).timeout
	comprobar(current_scene.get_node_or_null("AudioMonedas") == null, "Total cero no reproduce monedas")
	current_scene.queue_free()
	await process_frame
	await process_frame
	root.get_node("Musica").stop()
	await create_timer(0.1).timeout
	print("Audio de monedas: %d fallos." % fallos)
	quit(1 if fallos else 0)
