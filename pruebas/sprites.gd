extends SceneTree
## Godot --headless --path . --script res://pruebas/sprites.gd
## Comprueba las hojas de LibreSprite, sus referencias y las pantallas que las usan.

func _initialize() -> void:
	call_deferred("_verificar")

func _verificar() -> void:
	var sprites = load("res://globales/sprites.gd")
	var config := root.get_node("Config")
	var total := 0
	for grupo in sprites.HOJAS:
		var hoja: Dictionary = sprites.HOJAS[grupo]
		var datos: Dictionary = hoja.datos.data
		var textura: Texture2D = hoja.textura
		assert(textura.get_size() == Vector2(datos.meta.size.w, datos.meta.size.h), "Medidas distintas en PNG y JSON: " + grupo)
		assert(datos.meta.image == grupo + ".png" and datos.meta.format == "RGBA8888")
		for id in datos.frames:
			var d: Dictionary = datos.frames[id]
			var f: Dictionary = d.frame
			var rect := Rect2(f.x, f.y, f.w, f.h)
			assert(rect.has_area() and Rect2(Vector2.ZERO, textura.get_size()).encloses(rect), "Cuadro fuera de la hoja: " + id)
			assert(not d.rotated and not d.trimmed and d.duration > 0)
			assert(Vector2(f.w, f.h) == Vector2(d.sourceSize.w, d.sourceSize.h))
			assert(sprites.textura(grupo + "/" + id) == sprites.textura(grupo + "/" + id), "La región debe reutilizar su textura")
			total += 1
	for id in config.orden_accesorios:
		assert(sprites.datos("accesorios/" + id).has("frame"))
	for pareja in [["patron_", config.patrones], ["cara_", config.caras], ["detalle_", config.detalles]]:
		for dato in pareja[1]:
			assert(sprites.datos("melon/" + pareja[0] + dato.id).has("frame"))
	assert(sprites.animacion("paisaje/aves_", 8, 0) == "paisaje/aves_0")
	assert(sprites.animacion("paisaje/aves_", 8, 0.131) == "paisaje/aves_1")
	assert(sprites.animacion("paisaje/aves_", 8, 1.041) == "paisaje/aves_0")
	var ultimo: Image = sprites.textura("transiciones/cortina_15").get_image()
	assert(ultimo.is_invisible(), "La cortina debe abrirse por completo")
	for carpeta in ["melon", "mundo", "pantallas", "interfaz", "globales"]:
		_revisar_codigo("res://" + carpeta)
	var juego := root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_sprites_%d.json" % OS.get_process_id()
	for escena in ["menu", "taller", "almanaque", "recorrido", "resultados"]:
		assert(change_scene_to_file("res://pantallas/%s/%s.tscn" % [escena, escena]) == OK)
		for i in 5:
			await process_frame
		assert(current_scene != null)
	var animacion := root.get_node("Animacion")
	animacion.cambiar_escena("res://pantallas/taller/taller.tscn")
	assert(animacion.get("_cortina").visible)
	await create_timer(0.7).timeout
	assert(not animacion.get("_cortina").visible and current_scene.name == "Taller")
	if FileAccess.file_exists(juego.archivo_guardado):
		DirAccess.remove_absolute(juego.archivo_guardado)
	print("OK: %d cuadros PNG + JSON Hash, referencias, tiempos de animación y cinco pantallas sin dibujo vectorial." % total)
	quit()

func _revisar_codigo(carpeta: String) -> void:
	var dir := DirAccess.open(carpeta)
	for archivo in dir.get_files():
		if archivo.get_extension() not in ["gd", "tscn", "tres"]:
			continue
		var texto := FileAccess.get_file_as_string(carpeta.path_join(archivo))
		for llamada in ["draw_circle(", "draw_arc(", "draw_line(", "draw_rect(", "draw_polygon(", "draw_colored_polygon(", "draw_polyline(", "draw_multiline(", 'type="Line2D"', 'type="Polygon2D"', ".svg"]:
			assert(not texto.contains(llamada), "Dibujo vectorial en " + carpeta.path_join(archivo) + ": " + llamada)
	for subcarpeta in dir.get_directories():
		_revisar_codigo(carpeta.path_join(subcarpeta))
