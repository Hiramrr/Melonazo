extends SceneTree
## Límites de llegada, progreso y recompensas. Usa un guardado separado.


func _initialize() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	var config := root.get_node("Config")
	var juego := root.get_node("Juego")
	var arte = load("res://recursos/arte_xalapa.tres")
	var fotografias: Dictionary = arte.fotografias.duplicate()
	arte.fotografias.erase("cucosta")
	juego.archivo_guardado = "user://prueba_ruta_%d.json" % OS.get_process_id()
	juego.visitados = []
	juego.record_m = 0.0
	juego.intentos = 0
	juego.tamano = 1
	juego.accesorios = []
	assert(config.meta_m > config.costa_m and config.costa_m > config.salida_xalapa_m)
	assert(config.salida_xalapa_m == float(config.postales[8]["metros"]), "La salida de Xalapa empieza en La Joya")
	var anterior := -1.0
	var ids: Array = []
	for postal in config.postales:
		assert(float(postal["metros"]) > anterior, "Las postales deben estar ordenadas y no compartir posición")
		assert(not postal["id"] in ids, "Los lugares deben tener identificadores distintos")
		ids.append(postal["id"])
		anterior = float(postal["metros"])
	assert(ids == ["xallitic", "juarez", "lagos", "aguila", "fei", "macuiltepetl", "max", "experimental", "joya", "bosques_perote", "cofre_perote", "pico_orizaba", "estrella_puebla", "escaleras_tlaxcala", "angel", "teotihuacan", "monarca", "costa", "cucosta"], "La ruta debe seguir los 19 lugares elegidos en el PDF")
	assert(arte.fotografias.keys() == ids.filter(func(id: String) -> bool: return id != "cucosta"), "Cada lugar elegido debe tener una fotografía, salvo la retirada para esta prueba")
	assert(config.postales[-1]["id"] == "cucosta" and anterior == config.meta_m)
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_physics_process(false)
	r.fase = 2
	r.melon.en_suelo = false
	r._revisar_avance(config.meta_m * config.px_por_metro - 1.0, 1.0 / 120.0)
	assert(r.fase == 2, "No se gana antes de cruzar la meta")
	r.hud._actualizar_lugar(config.meta_m - 1.0, 300.0, 300.0)
	assert(r.hud.get_node("%Ruta").value < 1.0, "Volar alto no completa la barra de viaje")
	assert("CUCosta" in r.hud.get_node("%Destino").text)
	r._revisar_avance(config.meta_m * config.px_por_metro + 100.0, 1.0 / 120.0)
	assert(r.fase == 3 and r.melon.freeze and not r.melon.controlable, "La llegada detiene la carrera, también en el aire")
	assert(r.mejor_x == config.meta_m * config.px_por_metro and "cucosta" in r.postales_intento)
	assert(r.texto_fin == "¡Llegaste al CUCosta!")
	r.terreno.actualizar(config.meta_m * config.px_por_metro)
	var fin_terreno: float = r.terreno.tramos[-1].x1
	r.terreno.actualizar(config.meta_m * config.px_por_metro * 2.0)
	assert(r.terreno._fin.x == fin_terreno, "No se genera un camino infinito después de la meta")
	r._t_fin = 0.0
	r._process(0.01)
	assert(juego.intentos == 1 and juego.ultimo["llegada"] and juego.ultimo["distancia"] == config.meta_m)
	var saldo: int = juego.aplausos
	r._process(0.01)
	assert(juego.intentos == 1 and juego.aplausos == saldo, "La llegada solo cobra una vez")
	await create_timer(0.7).timeout
	assert(current_scene.name == "Resultados")
	assert(current_scene.get_node("%Titulo").text == "¡Llegaste al CUCosta!")
	var postal = current_scene.get_node("Margen/Columnas/Postal")
	assert(postal.lugar_id == "cucosta" and not postal.con_foto and not postal.visible, "Sin foto del CUCosta no se muestra otra ciudad ni una ilustración")
	assert(postal.arte.paisaje == null, "Las fotografías solo aparecen al terminar")
	juego.registrar_intento(config.meta_m + 300.0, 0, 0, false)
	assert(juego.ultimo["distancia"] == config.meta_m and juego.ultimo["por_visitas"] == 0)
	juego.registrar_intento(config.meta_m - 1.0, 0, 0, false)
	assert(not juego.ultimo["llegada"], "Un intento corto no cuenta como llegada")
	juego.registrar_intento(config.meta_m, 0, 0, true)
	assert(not juego.ultimo["llegada"], "Un melón roto no completa el viaje")
	arte.fotografias = fotografias
	for i in config.postales.size():
		var lugar: Dictionary = config.postales[i]
		var datos: Dictionary = fotografias[lugar["id"]]
		assert(datos["textura"] is Texture2D and not datos["dato_curioso"].is_empty())
		assert(datos["fuente_dato"].begins_with("https://"))
		var limite: float = float(config.postales[i + 1]["metros"]) if i + 1 < config.postales.size() else config.meta_m + 100.0
		for metros in [float(lugar["metros"]), limite - 0.1]:
			juego.ultimo = {"distancia": metros}
			var panel = load("res://pantallas/resultados/postal_resultados.gd").new()
			root.add_child(panel)
			assert(panel.lugar_id == lugar["id"], "La postal corresponde al lugar de este intento, aunque el récord sea mayor")
			assert(panel.con_foto and panel.visible, "Todos los destinos tienen foto")
			assert(panel.get_node("MargenFoto/Foto/Imagen").texture == datos["textura"])
			assert(panel.get_node("MargenFoto/Foto/DatoCurioso").text == "Dato curioso\n" + datos["dato_curioso"])
			for enlace in panel.find_children("*", "LinkButton", true, false):
				assert(enlace.uri.begins_with("https://"), "No deben aparecer enlaces vacíos para las fotos aportadas por el equipo")
			panel.queue_free()
	DirAccess.remove_absolute(juego.archivo_guardado)
	DirAccess.remove_absolute(juego.archivo_guardado + ".tmp")
	print("OK: llegada aérea, recompensas únicas y foto con dato curioso en los 19 destinos elegidos y sus límites.")
	quit()
