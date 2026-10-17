extends SceneTree
## Carreras con física real. Nunca escribe en el guardado del jugador.

var juego: Node
var config: Node
var fallos := 0
var pasivas := 0
var mayor_distancia := 0.0
var mayor_duracion := 0.0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _verificar() -> void:
	juego = root.get_node("Juego")
	config = root.get_node("Config")
	juego.archivo_guardado = "user://prueba_balance_%d.json" % OS.get_process_id()
	aislar_progreso()
	# Sin controles ni siquiera se sale de Xalapa en la ruta extendida.
	var tope_pasivo: float = config.salida_xalapa_m
	for semilla in [1509, 42, 7301]:
		config.semilla_terreno = semilla
		for tamano in 3:
			for nivel in [0, 6]:
				for fuerza in [0.1, 0.7, 0.95]:
					var r: Dictionary = await carrera(tamano, nivel, false, false, fuerza)
					pasivas += 1
					mayor_distancia = maxf(mayor_distancia, r["metros"])
					mayor_duracion = maxf(mayor_duracion, r["segundos"])
					var caso := "semilla %d, tamaño %d, mejora %d, fuerza %.2f" % [semilla, tamano, nivel, fuerza]
					comprobar(r["termino"], "La carrera pasiva no termina: " + caso)
					comprobar(r["metros"] < (tope_pasivo * 0.5 if nivel == 0 else tope_pasivo), "Sin jugar no se supera la primera mitad de Xalapa sin mejoras ni se sale de la ciudad con mejoras: " + caso + " · %.1f m" % r["metros"])
					comprobar(r["impulsos_poderes"] <= 3, "La carrera pasiva encadena demasiados chiles: " + caso)
					comprobar(r["papalotes"] == 0, "Los papalotes requieren pulsar E: " + caso)
	config.semilla_terreno = 1509
	var pasiva: Dictionary = await carrera(1, 0, false, true)
	var activa: Dictionary = await carrera(1, 0, true, true)
	comprobar(pasiva["termino"] and activa["termino"], "Ambas carreras con equipo inicial deben terminar")
	comprobar(activa["metros"] > pasiva["metros"] * 1.5, "Los rebotes, accesorios y empujones deben mejorar la distancia")
	# Un lanzamiento al 70%, sin bonus ni mejoras, debe permitir avanzar 400 m.
	var primeras: Array = []
	for semilla in [1509, 42, 7301]:
		config.semilla_terreno = semilla
		var r: Dictionary = await carrera(1, 0, true, true, 0.7)
		primeras.append(roundf(r["metros"]))
		comprobar(r["termino"] and r["metros"] >= 400.0, "Un lanzamiento sin bonus debe rendir con equipo inicial: semilla %d, %.1f m" % [semilla, r["metros"]])
	# Cambiar la fuerza cambia los aterrizajes; ambos niveles deben superar el inicio.
	var medias: Array = []
	for nivel in [0, 3, 6]:
		var suma := 0.0
		for semilla in [1509, 42, 7301]:
			config.semilla_terreno = semilla
			var r: Dictionary = await carrera(1, nivel, true, true)
			suma += r["metros"]
		medias.append(suma / 3.0)
	config.semilla_terreno = 1509
	comprobar(medias[1] > medias[0] * 1.15 and medias[2] > medias[0] * 1.15 and medias[2] >= 1000.0, "Las mejoras deben superar el alcance inicial: %s" % str(medias))
	comprobar(medias[0] < 900.0, "El equipo inicial debe promediar menos de novecientos metros con controles")
	var llegadas := 0
	for semilla in [1509, 42, 7301]:
		config.semilla_terreno = semilla
		var r: Dictionary = await carrera(1, 6, true, true, 0.91, true)
		if r["llegada"]:
			llegadas += 1
		print("Ruta completa, semilla %d: %.0f m, %.1f s, %d slams, llegada %s." % [semilla, r["metros"], r["segundos"], r["slams"], r["llegada"]])
	comprobar(llegadas > 0, "Las mejoras, accesorios y slams permiten completar los 5200 metros con física real")
	DirAccess.remove_absolute(juego.archivo_guardado)
	DirAccess.remove_absolute(juego.archivo_guardado + ".tmp")
	print("Balance: %d carreras pasivas. Máximo %.1f m, %.1f s. Equipo inicial sin controles %.1f m, con controles %.1f m. Progresión con controles (mejoras 0/3/6) %.0f/%.0f/%.0f m. Fallos %d." % [pasivas, mayor_distancia, mayor_duracion, pasiva["metros"], activa["metros"], medias[0], medias[1], medias[2], fallos])
	print("Equipo inicial, fuerza al 70%% y sin mejoras: %s m." % str(primeras))
	quit(1 if fallos else 0)


## Juego ya cargó el guardado real: sus Salsas Valentina y fichas cambiarían las carreras.
func aislar_progreso() -> void:
	juego.valentinas = 0
	juego.melones_guardados.clear()


func carrera(tamano: int, nivel: int, activa: bool, equipo := false, fuerza := 0.91, con_slam := false, apuntar_slam := true) -> Dictionary:
	seed(config.semilla_terreno)
	juego.tamano = tamano
	juego.accesorios = ["llantitas", "rebozo"] if equipo else []
	juego.valentinas = 0
	juego.niveles = {"fuerza": nivel, "resistencia": mini(nivel, 5), "rebotes": mini(nivel, 5)}
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var recorrido = current_scene
	var conteo_poderes := {"impulsos": 0, "slams": 0}
	recorrido.melon.aviso.connect(func(texto: String) -> void:
		if texto.begins_with("¡Slam acertado!"):
			conteo_poderes["slams"] += 1)
	recorrido.terreno.poder_recogido.connect(func(tipo: String) -> void:
		if tipo == "chile":
			conteo_poderes["impulsos"] += 1)
	recorrido.fuerza = fuerza
	recorrido._lanzar()
	var cuadros := 0
	var metros := 0.0
	var poderes := 0
	var papalotes := 0
	var llegada := false
	while is_instance_valid(recorrido) and current_scene == recorrido and cuadros < (120 if activa else 30) * 120:
		await physics_frame
		for accion in ["rebote", "empujon", "acc_1", "acc_2", "slam"]:
			Input.action_release(accion)
		cuadros += 1
		if not is_instance_valid(recorrido):
			break
		metros = recorrido.mejor_x / config.px_por_metro
		poderes = recorrido.poderes_recogidos
		papalotes = recorrido.papalotes_usados
		llegada = recorrido.fase == 3 and metros >= config.meta_m and not recorrido.melon.roto
		if activa and recorrido.fase == 2 and cuadros % 2 == 0:
			var melon = recorrido.melon
			if con_slam and melon.t_slam <= 0.0 and (not apuntar_slam or recorrido.hud._hay_melon_debajo(recorrido)):
				Input.action_press("slam")
			elif melon.rebotes > 0 and melon.t_bloqueo <= 0 and melon.t_impacto >= 0 and melon.t_impacto < config.ventana_rebote * 0.75:
				Input.action_press("rebote")
			if melon.en_suelo and melon.linear_velocity.x < 500 and cuadros > 240 and melon.slots[0] != null:
				Input.action_press("acc_1")
			if not melon.en_suelo and melon.linear_velocity.y > 150 and melon.position.x > 900 and melon.slots[1] != null:
				Input.action_press("acc_2")
			for tramo in recorrido.terreno.tramos:
				for persona in tramo.personas:
					if persona.en_rango and not persona.usado:
						Input.action_press("empujon")
	for accion in ["rebote", "empujon", "acc_1", "acc_2", "slam"]:
		Input.action_release(accion)
	return {"metros": metros, "segundos": cuadros / 120.0, "poderes": poderes, "impulsos_poderes": conteo_poderes["impulsos"], "papalotes": papalotes, "slams": conteo_poderes["slams"], "llegada": llegada, "termino": current_scene != recorrido}
