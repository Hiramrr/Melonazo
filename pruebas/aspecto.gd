extends SceneTree
## Godot --path . --script res://pruebas/aspecto.gd
## Catálogo con render real. No guarda ni cambia el progreso del jugador.

class Catalogo extends Node2D:
	var pagina := "pieles"

	func _texto(pos: Vector2, texto: String, ancho := 280.0, fuente := 18) -> void:
		draw_set_transform(Vector2.ZERO)
		draw_string(ThemeDB.fallback_font, pos, texto, HORIZONTAL_ALIGNMENT_CENTER, ancho, fuente, Color("253e32"))

	func _melon(pos: Vector2, radio: float, ids: Array = [], roto := false) -> void:
		draw_set_transform(pos)
		load("res://melon/aspecto.gd").dibujar_melon(self, radio, ids, roto)
		draw_set_transform(Vector2.ZERO)

	func _draw() -> void:
		var juego := get_node("/root/Juego")
		var config := get_node("/root/Config")
		var estado := {}
		for propiedad in ["piel", "patron", "cara", "detalle", "cuerpo_propio", "rayas_propio", "dibujo"]:
			estado[propiedad] = juego.get(propiedad)
		juego.cuerpo_propio = ""
		juego.rayas_propio = ""
		juego.dibujo = []
		juego.piel = 0
		juego.patron = 0
		juego.cara = 0
		juego.detalle = 0
		draw_rect(Rect2(0, 0, 1280, 960), Color("f6f0df"))
		match pagina:
			"pieles":
				for i in config.pieles.size():
					juego.piel = i
					juego.patron = 2 if i == 1 else 0
					juego.cara = i
					_melon(Vector2(160 + i % 4 * 320, 160 + i / 4 * 325), 67, [config.orden_accesorios[i]])
					_texto(Vector2(20 + i % 4 * 320, 290 + i / 4 * 325), config.pieles[i]["nombre"])
			"expresiones":
				for i in config.caras.size():
					juego.cara = i
					_melon(Vector2(71 + i * 142, 130), 48)
					_texto(Vector2(i * 142, 215), config.caras[i]["nombre"], 142, 16)
				juego.cara = 0
				for i in config.patrones.size():
					juego.patron = i
					_melon(Vector2(106 + i * 213, 380), 60)
					_texto(Vector2(i * 213, 480), config.patrones[i]["nombre"], 213, 16)
				juego.patron = 0
				for i in config.detalles.size():
					juego.detalle = i
					_melon(Vector2(106 + i * 213, 650), 60)
					_texto(Vector2(i * 213, 750), config.detalles[i]["nombre"], 213, 16)
				juego.detalle = 0
				_melon(Vector2(180, 860), 40, [], true)
				_texto(Vector2(0, 930), "Melón roto", 360)
				juego.cuerpo_propio = "faf0d7"
				juego.rayas_propio = "e87458"
				_melon(Vector2(600, 860), 40)
				_texto(Vector2(420, 930), "Colores personalizados", 360)
				juego.dibujo = [{"color": Color("467d88"), "grosor": 0.08, "puntos": PackedVector2Array([Vector2(-0.4, -0.4), Vector2(0.4, -0.4)])}]
				_melon(Vector2(1020, 860), 40)
				_texto(Vector2(840, 930), "Dibujo libre", 360)
			"accesorios":
				for i in config.orden_accesorios.size():
					var id: String = config.orden_accesorios[i]
					var pos := Vector2(160 + i % 4 * 320, 160 + i / 4 * 350)
					_melon(pos, 65, [id])
					_texto(Vector2(pos.x - 140, pos.y + 110), config.accesorios[id].nombre)
					for lado in [28, 44]:
						var rect := Rect2(pos + Vector2(-68 if lado == 28 else 20, 130), Vector2.ONE * lado)
						draw_rect(rect, Color("e2e8d8"))
						config.accesorios[id].dibujar_icono(self, rect)
			"escala":
				for columna in 3:
					_texto(Vector2(240 + columna * 340, 40), "Radio %d" % config.tamanos[columna]["radio"], 320)
				for i in config.orden_accesorios.size():
					var id: String = config.orden_accesorios[i]
					_texto(Vector2(0, 125 + i * 105), config.accesorios[id].nombre, 230, 16)
					for columna in 3:
						for slot in 3:
							var ids: Array = [null, null, null]
							ids[slot] = id
							_melon(Vector2(290 + columna * 340 + slot * 105, 115 + i * 105), config.tamanos[columna]["radio"], ids)
		for propiedad in estado:
			juego.set(propiedad, estado[propiedad])


func _initialize() -> void:
	call_deferred("_revisar")


func _revisar() -> void:
	assert(DisplayServer.get_name() != "headless", "La revisión de arte necesita una ventana con render real")
	if root.get_node("Config").orden_accesorios.size() != 8:
		push_error("No se cargaron los ocho accesorios")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("user://revision_grafica")
	root.size = Vector2i(1280, 960)
	var catalogo := Catalogo.new()
	root.add_child(catalogo)
	for pagina in ["pieles", "expresiones", "accesorios", "escala"]:
		catalogo.pagina = pagina
		catalogo.queue_redraw()
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var imagen := root.get_texture().get_image()
		assert(not imagen.is_empty())
		assert(imagen.save_png("user://revision_grafica/aspecto-" + pagina + ".png") == OK)
	if not await _verificar_iconos():
		quit(1)
		return
	print("OK: 4 capturas y 16 iconos sin recortes; pieles, expresiones, patrones, detalles y tres tamaños/ángulos.")
	quit()


func _verificar_iconos() -> bool:
	var config := root.get_node("Config")
	for id in config.orden_accesorios:
		for lado in [28, 44]:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(96, 96)
			viewport.transparent_bg = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			var rect := Rect2(Vector2(24, 24), Vector2.ONE * lado)
			var lienzo := Node2D.new()
			lienzo.draw.connect(config.accesorios[id].dibujar_icono.bind(lienzo, rect))
			viewport.add_child(lienzo)
			root.add_child(viewport)
			for i in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			var imagen := viewport.get_texture().get_image()
			var usados := imagen.get_used_rect()
			if not usados.has_area() or not Rect2i(rect.grow(1)).encloses(usados):
				push_error("Icono vacío o fuera de su casilla: %s a %d px, %s" % [id, lado, usados])
				viewport.queue_free()
				return false
			viewport.queue_free()
	return true
