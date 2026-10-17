extends SceneTree
## Retos, margen de E y rebotes adelantados. Usa un guardado separado.

var juego: Node
var config: Node


func _initialize() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	juego = root.get_node("Juego")
	config = root.get_node("Config")
	juego.archivo_guardado = "user://prueba_ritmo_%d.json" % OS.get_process_id()
	juego.reiniciar_progreso()
	juego.registrar_intento(299.0, 0, 0, false)
	assert(juego.retos_completados == 0 and juego.ultimo["por_reto"] == 0)
	juego.registrar_intento(300.0, 0, 0, false)
	assert(juego.retos_completados == 1 and juego.ultimo["por_reto"] == config.retos[0]["premio"])
	var saldo: int = juego.aplausos
	juego.registrar_intento(300.0, 0, 0, false, 0, 0.0, 0, {"rebotes": 1})
	assert(juego.retos_completados == 1 and juego.aplausos == saldo + 150, "El premio no se repite")
	juego.registrar_intento(300.0, 0, 0, false, 0, 0.0, 0, {"rebotes": 1})
	assert(juego.retos_completados == 1, "Las maniobras deben hacerse en un mismo intento")
	while not juego.reto_actual().is_empty():
		var indice: int = juego.retos_completados
		var reto: Dictionary = juego.reto_actual()
		if reto["dato"] == "llegada":
			juego.registrar_intento(config.meta_m, 0, 0, true)
			assert(juego.retos_completados == indice, "Romperse no cuenta como llegada")
		juego.registrar_intento(config.meta_m, 0, 99, false, 0, 400.0, 0, {"rebotes": 20, "papalotes": 20, "slams": 20})
		assert(juego.retos_completados == indice + 1, "Solo se completa el reto activo")
		assert(juego.ultimo["por_reto"] == reto["premio"])
		var r: Dictionary = juego.ultimo
		assert(r["total"] == r["por_distancia"] + r["por_altura"] + r["por_carisma"] + r["por_recolectados"] + r["por_visitas"] + r["por_reto"])
	juego.retos_completados = 0
	juego.cargar()
	assert(juego.retos_completados == config.retos.size(), "Los retos sobreviven al cerrar el juego")
	juego.registrar_intento(config.meta_m, 0, 99, false)
	assert(juego.ultimo["por_reto"] == 0 and juego.ultimo["reto"].is_empty())
	for valor in ["invalido", -3, 999]:
		var archivo := FileAccess.open(juego.archivo_guardado, FileAccess.WRITE)
		archivo.store_string(JSON.stringify({"retos_completados": valor}))
		archivo.close()
		juego.cargar()
		assert(juego.retos_completados == (config.retos.size() if valor is int and valor > 0 else 0))
	var viejo := FileAccess.open(juego.archivo_guardado, FileAccess.WRITE)
	viejo.store_string('{"version":2,"aplausos":123}')
	viejo.close()
	juego.cargar()
	assert(juego.retos_completados == 0 and juego.aplausos == 123, "Los guardados anteriores conservan su saldo")
	juego.reiniciar_progreso()
	juego.niveles["fuerza"] = 6
	config.semilla_terreno = 42
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_process(false)
	r.set_physics_process(false)
	r.fase = 2
	var melon = r.melon
	melon.controlable = true
	assert(melon.vel_crucero == config.vel_crucero + 6 * config.crucero_por_nivel)
	assert(melon._impulso_hasta_crucero(melon.vel_crucero - 50, 420) == melon.vel_crucero)
	assert(melon._impulso_hasta_crucero(melon.vel_crucero + 100, 420) == melon.vel_crucero + 100)
	for tramo in r.terreno.tramos:
		for p in tramo.personas:
			p.usado = true
		for p in tramo.papalotes:
			p.usado = true
	var persona = r.terreno.tramos[0].personas[0]
	persona.usado = false
	melon.position = persona.position + Vector2(-config.publico_rango - 40, -40)
	Input.action_press("empujon")
	r._actualizar_interacciones(1.0 / 120.0)
	assert(not persona.usado)
	Input.action_release("empujon")
	await physics_frame
	melon.position = persona.position + Vector2(0, -40)
	r._actualizar_interacciones(0.05)
	assert(persona.usado and r.empujones == 1, "E adelantada se activa al entrar en rango")
	await physics_frame
	await physics_frame
	persona.usado = false
	r._actualizar_interacciones(0.01)
	assert(not persona.usado, "Una pulsación no activa dos ayudas")
	melon.en_suelo = true
	r.hud._actualizar_indicacion(r)
	assert(r.hud.tecla.text == "E" and r.hud.indicacion.text.contains("empujón"))
	melon.position = persona.position + Vector2(-config.publico_rango - 40, -40)
	Input.action_press("empujon")
	r._actualizar_interacciones(1.0 / 120.0)
	Input.action_release("empujon")
	await physics_frame
	await physics_frame
	r._actualizar_interacciones(config.margen_ayuda + 0.01)
	melon.position = persona.position + Vector2(0, -40)
	r._actualizar_interacciones(0.01)
	assert(not persona.usado, "La pulsación caduca si se hizo demasiado pronto")
	persona.usado = true
	melon.rebotes = 0
	r._actualizar_interacciones(0.01)
	r.hud._actualizar_indicacion(r)
	assert(not r.hud.tecla.visible, "Sin ayudas cercanas no se anuncia una E que no hace nada")
	# En suelo plano, pulsar fuera de la ventana verde prepara el rebote.
	melon.position = Vector2(200, -100)
	melon.freeze = false
	melon.en_suelo = false
	melon.t_aire = 0.2
	melon.rebotes = 2
	melon.t_bloqueo = 0.0
	melon._dv = Vector2.ZERO
	melon.linear_velocity = Vector2(100, 300)
	var avisos: Array[String] = []
	melon.aviso.connect(func(texto: String) -> void: avisos.append(texto))
	var pulso := false
	for i in 180:
		await physics_frame
		Input.action_release("rebote")
		if not pulso and melon.t_impacto > config.ventana_rebote + 0.03 and melon.t_impacto < config.tolerancia_rebote:
			Input.action_press("rebote")
			pulso = true
		if r.maniobras["rebotes"] > 0:
			break
	assert(pulso and r.maniobras["rebotes"] == 1 and melon.rebotes == 1, "El rebote adelantado consume una sola carga al aterrizar")
	assert(not avisos.has("¡Salto aéreo!"), "Preparar el rebote no salta por error")
	Input.action_release("rebote")
	DirAccess.remove_absolute(juego.archivo_guardado)
	DirAccess.remove_absolute(juego.archivo_guardado + ".tmp")
	current_scene.queue_free()
	current_scene = null
	await process_frame
	print("OK: diez retos, cobro único, guardados anteriores, fuerza sostenida, E adelantada y rebote con física real.")
	quit()
