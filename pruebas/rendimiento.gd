extends SceneTree
## Ejecutar con render real. Comprueba que el dibujo libre no se rehace cada cuadro.

var dibujos := {"aspecto": 0, "efectos": 0, "cielo": 0, "rival": 0}


func _initialize() -> void:
	call_deferred("_verificar")


func _esperar() -> void:
	for i in 4:
		await process_frame
		await RenderingServer.frame_post_draw


func _verificar() -> void:
	assert(DisplayServer.get_name() != "headless", "Esta prueba necesita render real")
	DisplayServer.window_move_to_foreground()
	var juego := root.get_node("Juego")
	var puntos := PackedVector2Array()
	var cantidad: int = root.get_node("Config").max_puntos_dibujo
	for i in cantidad:
		puntos.append(Vector2.from_angle(i * 0.05) * (0.3 + 0.5 * i / cantidad))
	juego.dibujo = [{"color": Color.RED, "grosor": 0.05, "puntos": puntos}]
	var melon = load("res://melon/melon.tscn").instantiate()
	melon.freeze = true
	root.add_child(melon)
	melon.position = Vector2(300, 300)
	melon.configurar(1, ["flor", "jarana"], 3, 2)
	melon.controlable = true
	melon.get_node("Lienzo/Dibujo").draw.connect(func() -> void: dibujos["aspecto"] += 1)
	melon.draw.connect(func() -> void: dibujos["efectos"] += 1)
	await _esperar()
	var iniciales: int = dibujos["aspecto"]
	var efectos_iniciales: int = dibujos["efectos"]
	for i in 20:
		melon.rotation += 0.1
		melon.position.x += 1.0
		await process_frame
		await RenderingServer.frame_post_draw
	assert(dibujos["aspecto"] == iniciales, "Mover y girar no debe rehacer el dibujo del melón")
	var imagen: Image = melon.get_node("Lienzo").get_texture().get_image()
	assert(not imagen.is_invisible(), "La textura contiene el melón y sus accesorios")
	melon.get_node("Lienzo/Dibujo").modulate.a = 0.5
	await _esperar()
	assert(imagen.get_data() == melon.get_node("Lienzo").get_texture().get_image().get_data(), "La GPU conserva la textura hasta pedir una actualización")
	melon.get_node("Lienzo/Dibujo").modulate.a = 1.0
	assert(dibujos["efectos"] > efectos_iniciales, "Los efectos siguen actualizándose")
	melon.usar(0)
	await _esperar()
	assert(dibujos["aspecto"] == iniciales + 1, "Consumir un accesorio actualiza el dibujo una vez")
	melon.resistencia = 1
	melon.golpe()
	await _esperar()
	assert(melon.roto and dibujos["aspecto"] == iniciales + 2, "Romperse actualiza el dibujo una vez")
	var accesorios: Array = root.get_node("Config").orden_accesorios
	for i in range(0, accesorios.size(), 3):
		melon.configurar(2, accesorios.slice(i, i + 3), 3, 2)
		await _esperar()
		var contenido: Rect2i = melon.get_node("Lienzo").get_texture().get_image().get_used_rect()
		assert(contenido.position.x > 0 and contenido.position.y > 0 and contenido.end.x < 512 and contenido.end.y < 512, "Los accesorios del melón grande caben completos en la textura")
	var cielo = load("res://mundo/paisaje/capa_cielo.gd").new()
	cielo.tipo = "fondo"
	root.add_child(cielo)
	cielo.draw.connect(func() -> void: dibujos["cielo"] += 1)
	cielo.actualizar(Vector2(1280, 720), Vector2.ZERO, 0.0)
	await _esperar()
	var cielo_inicial: int = dibujos["cielo"]
	for i in 8:
		cielo.actualizar(Vector2(1280, 720), Vector2(i, 0), i * 0.1)
		await process_frame
		await RenderingServer.frame_post_draw
	assert(dibujos["cielo"] == cielo_inicial, "El fondo conserva su dibujo mientras no cambia la altura ni el tamaño")
	cielo.actualizar(Vector2(1280, 720), Vector2(0, -900), 1.0)
	await _esperar()
	assert(dibujos["cielo"] == cielo_inicial + 1, "Subir cambia el color del cielo")
	cielo.actualizar(Vector2(960, 540), Vector2(0, -900), 1.0)
	await _esperar()
	assert(dibujos["cielo"] == cielo_inicial + 2, "Redimensionar vuelve a cubrir la pantalla")
	var rival = load("res://mundo/ayudas/melon_rodante.tscn").instantiate()
	rival.configurar(juego.datos_melon())
	root.add_child(rival)
	rival.get_node("Lienzo/Dibujo").draw.connect(func() -> void: dibujos["rival"] += 1)
	await _esperar()
	var dibujos_rival: int = dibujos["rival"]
	assert(not rival.get_node("Lienzo").get_texture().get_image().is_invisible(), "El rival conserva su dibujo guardado en una textura")
	for i in 12:
		rival.position.x += 2.0
		rival.get_node("Aspecto").rotation += 0.1
		await process_frame
		await RenderingServer.frame_post_draw
	assert(dibujos["rival"] == dibujos_rival, "Los rivales no rehacen el dibujo del almanaque mientras ruedan")
	print("OK: textura de %d puntos conservada al mover y girar; equipo, rotura, efectos y cielo actualizados." % cantidad)
	quit()
