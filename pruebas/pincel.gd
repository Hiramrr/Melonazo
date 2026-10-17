extends SceneTree
## Godot --path . --script res://pruebas/pincel.gd
## Verifica con render real que los giros no creen picos ni huecos, y que el
## trazo sea pixel art: sin bordes suavizados.

class Lienzo extends Node2D:
	var puntos := PackedVector2Array()
	var radio := 160.0
	var grosor := 0.3

	func _draw() -> void:
		load("res://melon/aspecto.gd").dibujar_trazos(self, radio, [{"color": Color.WHITE, "grosor": grosor, "puntos": puntos}])


func _initialize() -> void:
	call_deferred("_revisar")


func _revisar() -> void:
	assert(DisplayServer.get_name() != "headless", "Esta prueba necesita render real")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384, 384)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var lienzo := Lienzo.new()
	lienzo.position = Vector2(viewport.size) * 0.5
	viewport.add_child(lienzo)
	root.add_child(viewport)
	var casos := {
		"punto": PackedVector2Array([Vector2.ZERO]),
		"recta": PackedVector2Array([Vector2(-0.6, 0), Vector2(0.6, 0)]),
		"giro_cerrado": PackedVector2Array([Vector2(-0.6, 0.2), Vector2(0.6, 0.2), Vector2(-0.6, 0.3)]),
		"esquina": PackedVector2Array([Vector2(-0.6, 0), Vector2.ZERO, Vector2(0, 0.6)]),
		"ida_y_vuelta": PackedVector2Array([Vector2(-0.6, 0), Vector2(0.6, 0), Vector2(-0.6, 0)]),
		"cruce": PackedVector2Array([Vector2(-0.6, -0.6), Vector2(0.6, 0.6), Vector2(0.6, -0.6), Vector2(-0.6, 0.6)]),
		"puntos_repetidos": PackedVector2Array([Vector2(-0.6, 0), Vector2.ZERO, Vector2.ZERO, Vector2(0, 0.6)]),
	}
	var comprobaciones := 0
	for nombre in casos:
		lienzo.puntos = casos[nombre]
		for radio in [160.0, 32.0]:
			lienzo.radio = radio
			for grosor in [0.3, 0.1, 0.03]:
				lienzo.grosor = grosor
				lienzo.queue_redraw()
				for i in 3:
					await process_frame
				await RenderingServer.frame_post_draw
				var imagen := viewport.get_texture().get_image()
				var error := _verificar_imagen(imagen, lienzo)
				if not error.is_empty():
					DirAccess.make_dir_recursive_absolute("user://revision_grafica")
					imagen.save_png("user://revision_grafica/pincel-fallo.png")
					push_error("%s, radio %.0f, grosor %.2f: %s" % [nombre, radio, grosor, error])
					quit(1)
					return
				comprobaciones += 1
	print("OK: %d trazos sin picos ni huecos, con giros, retrocesos, cruces y puntos repetidos." % comprobaciones)
	quit()


func _verificar_imagen(imagen: Image, lienzo: Lienzo) -> String:
	# Un píxel del arte mide radio / 16 en pantalla; sus esquinas quedan a
	# 0.71 píxeles del arte de su centro, que es lo que decide si se pinta.
	var pixel := lienzo.radio / 16.0
	var ancho := maxf(0.5 * pixel, lienzo.radio * lienzo.grosor * 0.5)
	var margen := pixel * 0.75 + 1.0
	for y in imagen.get_height():
		for x in imagen.get_width():
			var p := (Vector2(x, y) + Vector2.ONE * 0.5 - lienzo.position) / lienzo.radio
			var distancia := p.distance_to(lienzo.puntos[0])
			for i in range(1, lienzo.puntos.size()):
				var q := Geometry2D.get_closest_point_to_segment(p, lienzo.puntos[i - 1], lienzo.puntos[i])
				distancia = minf(distancia, p.distance_to(q))
			distancia *= lienzo.radio
			var alpha := imagen.get_pixel(x, y).a
			if alpha > 0.1 and alpha < 0.9:
				return "Borde suavizado en %s" % Vector2i(x, y)
			if alpha > 0.1 and distancia > ancho + margen:
				return "Pico fuera del grosor en %s" % Vector2i(x, y)
			if alpha < 0.9 and distancia < ancho - margen:
				return "Hueco dentro del trazo en %s" % Vector2i(x, y)
	return ""
