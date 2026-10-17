extends "res://pruebas/balance.gd"
## Compara el ajuste con las reglas anteriores, usando los mismos controles y semillas.


func _verificar() -> void:
	config = root.get_node("Config")
	juego = root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_impulsos_%d.json" % OS.get_process_id()
	aislar_progreso()
	var primer_melon: float = config.primer_melon_camino_x
	var rampa: float = config.rampa_impulso
	var toldo: float = config.toldo_avance
	for semilla in [1509, 42, 7301]:
		config.semilla_terreno = semilla
		change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
		await process_frame
		await process_frame
		var r = current_scene
		r.set_process(false)
		r.set_physics_process(false)
		comprobar(r.terreno.melones.size() == config.rivales_salida, "La salida conserva sus seis rivales")
		var posiciones: Array[float] = []
		var conocidos: Array = []
		for x in range(0, int(config.meta_m * config.px_por_metro) + 1, 1000):
			r.terreno.actualizar(x)
			for tramo in r.terreno.tramos:
				for p in tramo.puntos:
					comprobar(is_equal_approx(p.y, config.calle_y), "Todo el terreno después del lanzamiento es plano")
			var cantidad: int = r.terreno.melones.size()
			r.terreno.actualizar(x)
			comprobar(r.terreno.melones.size() == cantidad, "Actualizar no duplica los melones del camino")
			for m in r.terreno.melones:
				if not m.en_bajada and m not in conocidos:
					conocidos.append(m)
					posiciones.append(m.position.x)
					comprobar(m.position.x < config.meta_m * config.px_por_metro, "No aparecen objetivos después de la meta")
					comprobar(m.aspecto.get("dibujo", []).is_empty(), "Los melones nuevos no copian el dibujo del jugador")
			r.melon.position.x = x
			r.terreno.actualizar_melones(r.melon, 0.0)
			comprobar(r.terreno.melones.size() <= 20, "La ruta retira objetivos lejanos y mantiene una cantidad acotada")
		posiciones.sort()
		var largo: float = config.meta_m * config.px_por_metro - config.primer_melon_camino_x
		comprobar(posiciones.size() >= floori(largo / config.separacion_melones.y) and posiciones.size() <= ceili(largo / config.separacion_melones.x) * 2, "Las ayudas cubren la ruta extendida, incluidas las parejas")
		comprobar(posiciones[0] == config.primer_melon_camino_x and posiciones[-1] >= config.meta_m * config.px_por_metro - config.separacion_melones.y, "Los apoyos llegan hasta el último tramo")
		for i in range(1, posiciones.size()):
			var separacion := posiciones[i] - posiciones[i - 1]
			comprobar(separacion >= minf(config.separacion_pareja_melones.x, config.separacion_melones.x) and separacion <= config.separacion_melones.y, "La separación de apoyos y parejas se conserva al cambiar de tramo")
	var anteriores: Array = []
	var nuevas: Array = []
	var slams := [0, 0]
	for nivel in [0, 3, 6]:
		var sumas := [0.0, 0.0]
		for semilla in [1509, 42, 7301]:
			config.semilla_terreno = semilla
			for ajuste in 2:
				config.primer_melon_camino_x = INF if ajuste == 0 else primer_melon
				config.rampa_impulso = 240.0 if ajuste == 0 else rampa
				config.toldo_avance = 0.0 if ajuste == 0 else toldo
				var datos: Dictionary = await carrera(1, nivel, true, true, 0.91, true)
				comprobar(datos["termino"], "La carrera sigue terminando al perder el impulso")
				sumas[ajuste] += datos["metros"]
				slams[ajuste] += datos["slams"]
				print("Impulsos nivel %d, semilla %d, ajuste %d: %.0f m, %d slams." % [nivel, semilla, ajuste, datos["metros"], datos["slams"]])
		anteriores.append(sumas[0] / 3.0)
		nuevas.append(sumas[1] / 3.0)
	comprobar(slams[1] > slams[0], "Hay más oportunidades reales de acertar slams")
	comprobar(nuevas[0] > anteriores[0] and nuevas[1] >= anteriores[1] and nuevas[2] >= anteriores[2], "Las ayudas permiten llegar con menos mejoras al apuntar los slams")
	config.primer_melon_camino_x = primer_melon
	config.rampa_impulso = rampa
	config.toldo_avance = toldo
	var sin_apuntar := 0.0
	for semilla in [1509, 42, 7301]:
		config.semilla_terreno = semilla
		var datos: Dictionary = await carrera(1, 0, true, true, 0.91, true, false)
		comprobar(datos["termino"] and datos["metros"] < config.meta_m, "Pulsar slam sin apuntar no completa el viaje")
		sin_apuntar += datos["metros"] / 3.0
	comprobar(sin_apuntar < nuevas[0] * 0.6, "Apuntar sigue siendo necesario para aprovechar los melones")
	DirAccess.remove_absolute(juego.archivo_guardado)
	print("Impulsos: medias anteriores %s m, nuevas %s m; sin apuntar %.0f m; slams %s; fallos %d." % [str(anteriores), str(nuevas), sin_apuntar, str(slams), fallos])
	quit(1 if fallos else 0)
