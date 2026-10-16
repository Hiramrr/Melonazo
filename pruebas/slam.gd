extends SceneTree
## Slam con física real y guardado separado del progreso del jugador.

var config: Node
var juego: Node
var comprobaciones := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos += 1
		push_error(mensaje)


func preparar(tamano: int):
	juego.tamano = tamano
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_process(false)
	for i in r.terreno.melones.size():
		var rival = r.terreno.melones[i]
		rival.en_bajada = false
		rival.configurar({"tamano": 2, "piel": i % config.pieles.size(), "patron": 0,
			"cara": 1, "detalle": 0, "cuerpo_propio": "", "rayas_propio": "", "dibujo": [], "accesorios": []})
		rival.position = Vector2(700 + i * 800, r.terreno.tramos[0].altura(700 + i * 800) - rival.radio)
		rival.anterior = rival.position
	r.fase = 2
	r.melon.controlable = true
	return r


func _verificar() -> void:
	config = root.get_node("Config")
	juego = root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_slam_%d.json" % OS.get_process_id()
	juego.niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	juego.accesorios = []
	config.semilla_terreno = 42
	# Estas caídas apuntan a objetivos concretos, sin otros melones que intercepten el golpe.
	var primer_melon: float = config.primer_melon_camino_x
	config.primer_melon_camino_x = INF
	var teclas := []
	for evento in InputMap.action_get_events("slam"):
		teclas.append(evento.physical_keycode)
	comprobar(KEY_S in teclas and KEY_DOWN in teclas, "S y flecha abajo activan slam")
	var r = await preparar(1)
	r.set_physics_process(false)
	var m = r.melon
	m.set_physics_process(false)
	m.rebotes = 0
	m.controlable = false
	comprobar(not m.iniciar_slam(), "Slam bloqueado antes del puente y al terminar")
	m.controlable = true
	m.en_suelo = true
	comprobar(not m.iniciar_slam(), "No se puede hacer slam desde el suelo")
	m.en_suelo = false
	m.roto = true
	comprobar(not m.iniciar_slam(), "Un melón roto no puede hacer slam")
	m.roto = false
	m.t_planeo = 2.0
	m.t_paraguas = 2.0
	m.t_rebote = 0.2
	comprobar(m.iniciar_slam() and m.rebotes == 0, "Slam funciona sin cargas de salto")
	comprobar(m.t_planeo == 0.0 and m.t_paraguas == 0.0 and m.t_rebote == 0.0, "El picado cancela planeo, paraguas y rebote pendiente")
	m.rebotes = 2
	comprobar(not m.iniciar_slam() and not m.saltar(), "No se puede reiniciar el picado ni cancelarlo saltando")
	var otro = r.terreno.melones[0]
	otro.anterior = otro.global_position
	m.origen_slam = otro.global_position + Vector2(0, -180)
	m.position = otro.global_position + Vector2(0, 100)
	m.linear_velocity = Vector2(700, 8000)
	comprobar(otro.recibir_slam(m), "El barrido detecta un objetivo atravesado entre pasos")
	comprobar(not m.slam_activo and m._v_fijar.x > 700 and m._v_fijar.y < 0 and m.rebotes == 2, "Acertar acelera y eleva sin gastar saltos")
	comprobar(not otro.recibir_slam(m), "Cada objetivo solo da un impulso")
	comprobar(not m.iniciar_slam(), "La recarga impide otro slam inmediato")
	m.t_slam = 0.0
	comprobar(m.iniciar_slam(), "Slam vuelve a estar disponible al terminar su recarga")
	otro = r.terreno.melones[1]
	otro.anterior = otro.global_position
	m.origen_slam = otro.global_position + Vector2(-100, 10)
	m.position = otro.global_position + Vector2(10, 20)
	comprobar(not otro.recibir_slam(m), "Un golpe lateral no cuenta como acierto")
	m.origen_slam = otro.global_position + Vector2(200, -180)
	m.position = otro.global_position + Vector2(200, 100)
	comprobar(not otro.recibir_slam(m), "Pasar lejos no da impulso")
	m.linear_velocity.x = otro.velocidad
	comprobar(is_equal_approx(otro.margen_slam(m), config.slam_margen.x), "A poca velocidad el margen permanece pequeño")
	m.linear_velocity.x = 20000.0
	comprobar(is_equal_approx(otro.margen_slam(m), config.slam_margen.y), "El margen tiene un límite incluso a velocidad extrema")
	m.linear_velocity.x = 700.0
	m.origen_slam = otro.global_position + Vector2(0, 180)
	m.position = otro.global_position + Vector2(0, -180)
	comprobar(not otro.recibir_slam(m), "La tolerancia no permite acertar desde abajo")
	for tamano in 3:
		m.configurar(tamano, [], juego.resistencia_max(), juego.rebotes_max())
		var tolerancia: float = otro.margen_slam(m)
		for margen in [0.0, tolerancia - 8.0, tolerancia + 8.0]:
			otro.usado = false
			m.slam_activo = true
			var dx: float = 0.0 if margen == 0.0 else otro.radio + m.radio + margen
			m.origen_slam = otro.global_position + Vector2(dx, -180)
			m.position = otro.global_position + Vector2(dx, -10)
			comprobar(otro.recibir_slam(m) == (margen < tolerancia), "El tamaño %d admite un roce y rechaza un fallo claro, margen %.0f" % [tamano, margen])
		m.slam_activo = false
		m.t_slam = 0.0
		m.linear_velocity = Vector2(1000, 0)
		var tiempo: float = (300.0 - (otro.radio + m.radio) * 0.5) / config.slam_caida
		m.position = otro.global_position + Vector2(-(1000.0 - otro.velocidad) * tiempo, -300)
		comprobar(r.hud._hay_melon_debajo(r), "El aviso anticipa el avance durante el picado, tamaño %d" % tamano)
		m.position = otro.global_position + Vector2(100, -300)
		comprobar(not r.hud._hay_melon_debajo(r), "El aviso no recomienda un enemigo que vas a sobrepasar, tamaño %d" % tamano)
	var x: float = otro.position.x
	otro.avanzar(r.terreno, 0.2)
	comprobar(otro.position.x > x, "Los objetivos avanzan por el camino")
	var borde: float = r.terreno.tramos[0].x1
	otro.position.x = borde - 1.0
	otro.avanzar(r.terreno, 0.1)
	comprobar(otro.position.x > borde, "Los objetivos cruzan entre tramos")
	var cantidad: int = r.terreno.melones.size()
	m.position.x = 10000.0
	r.terreno.actualizar_melones(m, 0.0)
	comprobar(r.terreno.melones.size() < cantidad, "Se retiran los objetivos usados y los que quedan atrás")
	for tamano in 3:
		await probar_caida(tamano, true)
		await probar_caida(tamano, false)
		for rapidez in [600.0, 1000.0, 1400.0]:
			var aciertos := 0
			for desfase in [-0.35, -0.16, -0.08, -0.04, 0.0, 0.04, 0.08, 0.16, 0.35]:
				var acierto: bool = await probar_punteria(tamano, rapidez, desfase)
				aciertos += int(acierto)
				if absf(desfase) <= 0.04:
					comprobar(acierto, "Slam admite un pequeño error de tiempo, tamaño %d, velocidad %.0f, desfase %.2f" % [tamano, rapidez, desfase])
				elif absf(desfase) >= 0.35:
					comprobar(not acierto, "Slam rechaza un mal cálculo de tiempo, tamaño %d, velocidad %.0f, desfase %.2f" % [tamano, rapidez, desfase])
			print("Puntería tamaño %d, %.0f px/s: %d/9 aciertos al variar el momento del slam." % [tamano, rapidez, aciertos])
	if FileAccess.file_exists(juego.archivo_guardado):
		DirAccess.remove_absolute(juego.archivo_guardado)
	config.primer_melon_camino_x = primer_melon
	print("Slam: %d comprobaciones, %d fallos." % [comprobaciones, fallos])
	quit(1 if fallos else 0)


func probar_caida(tamano: int, acertar: bool) -> void:
	var r = await preparar(tamano)
	r.set_physics_process(false)
	for tramo in r.terreno.tramos:
		for contenedor in ["Coleccionables", "Obstaculos", "Aire"]:
			for nodo in tramo.get_node(contenedor).get_children():
				nodo.queue_free()
		tramo.papalotes.clear()
	await process_frame
	var m = r.melon
	var objetivo = r.terreno.melones[0]
	if not acertar:
		for otro in r.terreno.melones:
			otro.queue_free()
		r.terreno.melones.clear()
	var origen: Vector2 = objetivo.global_position if acertar else Vector2(700, r.terreno.tramos[0].altura(700) - 30)
	m.position = origen + Vector2(-60, -260)
	m.linear_velocity = Vector2(600, 0)
	m.en_suelo = false
	m.t_aire = 0.0
	var cargas: int = m.rebotes
	var resultado := {"texto": ""}
	m.aviso.connect(func(texto: String) -> void:
		if texto.begins_with("¡Slam acertado!") or texto.begins_with("Slam fallado"):
			resultado["texto"] = texto)
	m.freeze = false
	r.set_physics_process(true)
	Input.action_press("slam")
	await physics_frame
	await physics_frame
	Input.action_release("slam")
	comprobar(m.slam_activo and m.linear_velocity.y >= config.slam_caida - 20.0, "S activa el picado con física real, tamaño %d" % tamano)
	r.hud.actualizar(r)
	comprobar(r.hud.indicacion.text.contains("El suelo frena"), "El HUD explica el riesgo durante el slam")
	var posicion: Vector2 = m.position
	paused = true
	for i in 4:
		await process_frame
	comprobar(m.position == posicion and m.slam_activo, "La pausa conserva posición y estado del slam")
	paused = false
	for i in 120:
		await physics_frame
		if not resultado["texto"].is_empty():
			break
	await physics_frame
	comprobar(not resultado["texto"].is_empty() and not m.slam_activo, "La caída resuelve el slam, tamaño %d" % tamano)
	comprobar(m.rebotes == cargas, "Ni acertar ni fallar consume saltos")
	print("Slam físico tamaño %d, acierto %s: %s, v %s" % [tamano, acertar, resultado["texto"], m.linear_velocity])
	if acertar:
		comprobar(resultado["texto"].begins_with("¡Slam acertado!") and m.linear_velocity.x > 700 and m.linear_velocity.y < -700, "Acertar a un melón en movimiento impulsa hacia arriba y adelante, tamaño %d" % tamano)
	else:
		comprobar(resultado["texto"].begins_with("Slam fallado") and m.linear_velocity.x < 400, "Fallar contra el suelo reduce velocidad, tamaño %d" % tamano)
		var despues: float = m.linear_velocity.x
		for i in 6:
			await physics_frame
		comprobar(m.linear_velocity.x > despues * 0.8, "El fallo penaliza una sola vez")


func probar_punteria(tamano: int, rapidez: float, desfase: float) -> bool:
	var r = await preparar(tamano)
	r.set_physics_process(false)
	for tramo in r.terreno.tramos:
		for contenedor in ["Coleccionables", "Obstaculos", "Aire"]:
			for nodo in tramo.get_node(contenedor).get_children():
				nodo.queue_free()
		tramo.papalotes.clear()
	await process_frame
	var m = r.melon
	var objetivo = r.terreno.melones[0]
	var tiempo: float = (260.0 - (m.radio + objetivo.radio) * 0.5) / config.slam_caida
	m.position = objetivo.position + Vector2(-(rapidez - objetivo.velocidad) * (tiempo + desfase), -260)
	m.linear_velocity = Vector2(rapidez, 0)
	m.en_suelo = false
	var recomendaba: bool = r.hud._hay_melon_debajo(r)
	m.freeze = false
	r.set_physics_process(true)
	m.iniciar_slam()
	for i in 90:
		await physics_frame
		if not m.slam_activo:
			var acierto: bool = m._v_fijar.y < 0.0
			comprobar(not recomendaba or acierto, "El aviso de S recomienda una caída acertable, tamaño %d, velocidad %.0f, desfase %.2f" % [tamano, rapidez, desfase])
			return acierto
	return false
