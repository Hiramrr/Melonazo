extends SceneTree
var fallos := 0

func _initialize() -> void:
	call_deferred("verificar")

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func verificar() -> void:
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_physics_process(false)
	r.fuerza = 0.95
	r._lanzar()
	var cuenta = r.cuenta_salida
	var inicio: Vector2 = r.melon.position
	var posiciones = r.terreno.melones.map(func(m): return m.position)
	comprobar(r.fase == r.Fase.CUENTA and cuenta.audio.playing, "Elegir potencia inicia la cuenta y el audio")
	comprobar(not r.hud.lanzamiento.visible and r.bajada.barrera.visible, "Potencia cerrada y barrera retenida")
	var velocidad: float = r._velocidad_salida
	r._lanzar()
	comprobar(r.cuenta_salida == cuenta and r._velocidad_salida == velocidad, "No se reinicia la cuenta al pulsar otra vez")
	r._physics_process(2.99)
	comprobar(r.fase == r.Fase.CUENTA and r.melon.position == inicio, "El jugador espera hasta el segundo 3")
	comprobar(posiciones == r.terreno.melones.map(func(m): return m.position), "Los rivales también esperan")
	paused = true
	await process_frame
	comprobar(cuenta.audio.stream_paused and cuenta.tiempo == 2.99, "Pausa detiene audio y cuenta")
	paused = false
	r._physics_process(0.01)
	comprobar(r.fase == r.Fase.BAJADA and not r.bajada.barrera.visible, "La salida se abre en el segundo 3")
	comprobar(r.melon.position.x > inicio.x, "Jugador arranca al segundo 3")
	comprobar(r.terreno.melones[0].position.x > posiciones[0].x, "Rivales arrancan a la vez")
	comprobar(cuenta.audio.playing, "El final del audio sigue durante la salida")
	comprobar(not r.melon.controlable and not r.melon.saltar(), "La bajada conserva su bloqueo de controles")
	var musica = root.get_node("Musica")
	comprobar(musica._pista == musica.RAPIDA, "La salida empieza con música rápida")
	var restante: float = musica._salida_rapida_restante
	paused = true
	musica.actualizar_recorrido(0.0, 10.0)
	comprobar(musica._salida_rapida_restante == restante, "Pausa conserva los cinco segundos de salida")
	paused = false
	musica.actualizar_recorrido(0.0, restante - 0.01)
	comprobar(musica._pista == musica.RAPIDA, "Sigue rápida antes de cinco segundos aunque vaya lento")
	musica.actualizar_recorrido(0.0, 0.01)
	comprobar(musica._pista == musica.LENTA, "Al cumplir cinco segundos vuelve a la velocidad actual")
	for caso in [[80.0, musica.MEDIA], [150.0, musica.RAPIDA]]:
		musica.iniciar_salida()
		musica.actualizar_recorrido(caso[0], 5.0)
		comprobar(musica._pista == caso[1], "La salida da paso a la pista correspondiente a la velocidad")
	musica.iniciar_salida()
	musica.tocar(musica.DERROTA)
	comprobar(musica._salida_rapida_restante == 0.0, "Finalizar cancela la música forzada de salida")
	current_scene.queue_free()
	await process_frame
	await process_frame
	root.get_node("Musica").stop()
	await create_timer(0.1).timeout
	print("Cuenta de salida: %d fallos." % fallos)
	quit(1 if fallos else 0)
