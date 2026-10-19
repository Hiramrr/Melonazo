extends SceneTree
## Fotos por lugar, progreso y tarjetas sin desbordamiento. Usa un guardado separado.


func _initialize() -> void:
	AudioServer.set_bus_mute(0, true)
	call_deferred("_verificar")


func _rejilla(pasaporte) -> RejillaTarjetas:
	for hijo in pasaporte.lista.get_children():
		if hijo is RejillaTarjetas:
			return hijo
	return null


func _verificar() -> void:
	root.mode = Window.MODE_WINDOWED
	var juego := root.get_node("Juego")
	var config := root.get_node("Config")
	var arte: ArteXalapa = load("res://recursos/arte_xalapa.tres")
	juego.archivo_guardado = "user://prueba_pasaporte_%d.json" % OS.get_process_id()
	juego.reiniciar_progreso()
	juego.visitados = ["xallitic"]
	juego.record_m = 450.0
	change_scene_to_file("res://pantallas/taller/taller.tscn")
	await process_frame
	await process_frame
	var pasaporte = current_scene.get_node("%Pasaporte")
	var pestanas: TabContainer = current_scene.get_node("%Pestanas")
	pestanas.current_tab = pestanas.get_tab_idx_from_control(pasaporte)
	await create_timer(1.0).timeout
	for resolucion in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = resolucion
		for i in 12:
			await process_frame
		assert(root.get_visible_rect().encloses(current_scene.get_node("%BtnPuente").get_global_rect()), "El pasaporte conserva el botón para salir a la ruta")
		var rejilla := _rejilla(pasaporte)
		assert(rejilla.get_child_count() == config.postales.size(), "El pasaporte conserva los 19 lugares")
		var limites: Rect2 = pasaporte.get_global_rect()
		for i in config.postales.size():
			var lugar: Dictionary = config.postales[i]
			var tarjeta: Tarjeta = rejilla.get_child(i)
			assert(tarjeta.titulo == lugar["nombre"], "Las tarjetas conservan el orden de la ruta")
			assert(tarjeta.cuerpo.get_child_count() == 1, "Cada lugar tiene una foto, incluso sin visitarlo")
			var foto: FotoLugar = tarjeta.cuerpo.get_child(0)
			assert(foto.get_node("Imagen").texture == arte.fotografias[lugar["id"]]["textura"], "La foto corresponde al lugar de su tarjeta")
			assert(foto.get_node_or_null("DatoCurioso") == null, "La nota no se duplica en la foto")
			var rect := tarjeta.get_global_rect()
			assert(rect.position.x >= limites.position.x and rect.end.x <= limites.end.x, "Las tarjetas caben en el pasaporte a %s" % resolucion)
			for enlace in foto.find_children("*", "LinkButton", true, false):
				assert(enlace.uri.begins_with("https://"), "Los créditos conservan enlaces válidos")
				var rect_enlace: Rect2 = enlace.get_global_rect()
				assert(rect_enlace.position.x >= rect.position.x and rect_enlace.end.x <= rect.end.x, "Los créditos caben en cada tarjeta a %s" % resolucion)
		assert(rejilla.get_child(0).estado == "¡VISITADO!" and rejilla.get_child(0).descripcion == config.postales[0]["nota"], "Visitar conserva el sello y revela la nota")
		assert(rejilla.get_child(1).estado == "A 300 m · faltan 0 m" and rejilla.get_child(1).descripcion.is_empty(), "La foto no cambia el progreso ni revela notas pendientes")
		if DisplayServer.get_name() != "headless":
			pasaporte.scroll_vertical = int(rejilla.position.y)
			await process_frame
			await process_frame
			RenderingServer.force_draw()
			await process_frame
			assert(root.get_texture().get_image().save_png("/tmp/melonazo-pasaporte-%dx%d.png" % [resolucion.x, resolucion.y]) == OK)
			pasaporte.scroll_vertical = 0
	assert(arte.fotografias["xallitic"].has("dato_curioso"), "El pasaporte conserva los datos de la postal de resultados")
	var fotografias := arte.fotografias.duplicate()
	arte.fotografias.erase("juarez")
	arte.fotografias["lagos"] = {"textura": null}
	pasaporte.refrescar()
	var rejilla := _rejilla(pasaporte)
	assert(rejilla.get_child_count() == config.postales.size(), "Refrescar conserva una tarjeta por lugar")
	assert(rejilla.get_child(1).cuerpo.get_child_count() == 0 and rejilla.get_child(2).cuerpo.get_child_count() == 0, "Sin foto asignada, la tarjeta no muestra la de otro lugar")
	arte.fotografias.clear()
	juego.visitados.clear()
	pasaporte.refrescar()
	for tarjeta in _rejilla(pasaporte).get_children():
		assert(tarjeta.cuerpo.get_child_count() == 0 and tarjeta.descripcion.is_empty(), "El pasaporte también funciona sin fotografías ni visitas")
	arte.fotografias = fotografias
	current_scene.queue_free()
	await process_frame
	await process_frame
	root.get_node("Musica").stop()
	await create_timer(0.1).timeout
	DirAccess.remove_absolute(juego.archivo_guardado)
	DirAccess.remove_absolute(juego.archivo_guardado + ".tmp")
	print("OK: fotos de los 19 lugares, sellos, créditos a ambas resoluciones y fotos ausentes.")
	quit()
