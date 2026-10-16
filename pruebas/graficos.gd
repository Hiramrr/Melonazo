extends SceneTree
## Revisión con render real. Guarda capturas en user://revision_grafica/.
const ARTE := preload("res://recursos/arte_xalapa.tres")
var capturas := 0


func _initialize() -> void:
	call_deferred("_revisar")


## espera = segundos extra antes de la captura, para que terminen las animaciones
## de entrada (taller, pausa y resultados).
func _foto(nombre: String, controles: Array = [], espera := 0.0) -> void:
	for i in 8:
		await process_frame
	if espera > 0.0:
		await create_timer(espera).timeout
	var limites := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for id in controles:
		var control: Control = current_scene.get_node(id)
		assert(limites.encloses(control.get_global_rect()), "Control fuera de pantalla: " + id)
	if current_scene.name == "Recorrido" and current_scene.fase < 2:
		var camara: Camera2D = current_scene.camara
		var izquierda := camara.get_screen_center_position().x - limites.size.x / (2.0 * camara.zoom.x)
		assert(izquierda >= current_scene.bajada.x0 - 1.0, "La cámara muestra el borde vacío de la salida")
	RenderingServer.force_draw()  # También captura si la ventana queda detrás del editor.
	await process_frame
	var error := root.get_texture().get_image().save_png("user://revision_grafica/" + nombre + ".png")
	assert(error == OK, "No se pudo guardar la captura")
	capturas += 1


func _revisar() -> void:
	DirAccess.make_dir_recursive_absolute("user://revision_grafica")
	var arte: ArteXalapa = ARTE
	var ilustracion: Texture2D = arte.paisaje
	var fotografias := arte.fotografias.duplicate()
	var juego := root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_graficos_%d.json" % OS.get_process_id()
	var ultimo: Dictionary = juego.ultimo.duplicate(true)
	var esperadas := 3
	for resolucion in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = resolucion
		var prefijo := "%dx%d-" % [resolucion.x, resolucion.y]
		change_scene_to_file("res://pantallas/taller/taller.tscn")
		await process_frame
		await process_frame
		var pestanas: TabContainer = current_scene.get_node("%Pestanas")
		esperadas += pestanas.get_tab_count() + 10
		for pesta in pestanas.get_tab_count():
			current_scene.get_node("%Pestanas").current_tab = pesta
			await _foto(prefijo + "taller-" + str(pesta), ["%BtnPuente", "%Balance", "%Vista", "%BtnAlmanaque"], 1.0 if pesta == 0 else 0.0)
		var melon_original: Dictionary = juego.datos_melon()
		var coleccion_original: Array = juego.melones_guardados.duplicate(true)
		juego.melones_guardados.clear()
		change_scene_to_file("res://pantallas/almanaque/almanaque.tscn")
		await _foto(prefijo + "almanaque-vacio", ["%Volver", "%Guardar", "%Ilustracion"])
		for i in 6:
			juego.nombre_melon = ["Don Melón", "Niebla de Xallitic", "Cantalupo con sueño", "Melón dorado", "Bugambilia", "Café de la tarde"][i]
			juego.piel = [0, 2, 1, 7, 3, 4][i]
			juego.patron = i
			juego.cara = i
			juego.detalle = i
			juego.estela = i % 5
			juego.cuerpo_propio = ""
			juego.rayas_propio = ""
			juego.accesorios = ["rebozo", "sombrero"] if i % 2 == 0 else ["llantitas"]
			juego.dibujo = [{"color": Color("cf5142"), "grosor": 0.09, "puntos": PackedVector2Array([Vector2(-0.6, 0.5), Vector2(0, 0.7), Vector2(0.6, 0.5)])}]
			juego.guardar_melon()
		current_scene._refrescar()
		await _foto(prefijo + "almanaque-melones", ["%Volver", "%Guardar", "%Ilustracion", "%Usar", "%Actualizar", "%Eliminar"])
		var lista: GridContainer = current_scene.lista
		assert(lista.get_child_count() == 6 and lista.get_child(0).get_global_rect().size.x >= 138, "Las fichas deben conservar su ancho mínimo")
		for categoria in [1, 2]:
			current_scene._cambiar_categoria(categoria)
			await _foto(prefijo + "almanaque-" + str(categoria), ["%Volver", "%Ilustracion"])
		current_scene._cambiar_categoria(0)
		current_scene._pedir_confirmacion("eliminar")
		await _foto(prefijo + "almanaque-confirmacion")
		current_scene.confirmar.hide()
		var fichas_carrera: Array = juego.melones_guardados.duplicate(true)
		for propiedad in juego.PROPIEDADES_MELON:
			juego.set(propiedad, melon_original[propiedad])
		juego.melones_guardados.assign(fichas_carrera)
		esperadas += 5
		change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
		await _foto(prefijo + "recorrido", ["Interfaz/%Distancia", "Interfaz/%Equipo", "Interfaz/%Fuerza", "Interfaz/%Indicacion"])
		juego.melones_guardados.assign(coleccion_original)
		var transformacion: Transform2D = current_scene.get_viewport().get_canvas_transform()
		var pantalla := Rect2(Vector2.ZERO, root.get_visible_rect().size)
		for rival in current_scene.terreno.melones:
			assert(pantalla.has_point(transformacion * rival.global_position), "Un rival queda fuera de la salida")
		current_scene.fase = 0
		await _foto(prefijo + "fuerza", ["Interfaz/%Fuerza", "Interfaz/%Indicacion"])
		current_scene._lanzar()
		for i in 36:
			await physics_frame
		await _foto(prefijo + "bajada-xallitic", ["Interfaz/%Indicacion"])
		assert(not current_scene.hud.tecla.visible and not current_scene.hud.ayuda.visible, "La bajada no debe ofrecer controles de carrera")
		esperadas += 1
		var slots: Array = current_scene.melon.slots.duplicate()
		current_scene.melon.slots = [null, null, null]
		await _foto(prefijo + "sin-accesorios", ["Interfaz/%Equipo"])
		assert(current_scene.hud.slots[0].nombre.text == "Vacío", "El HUD conserva un accesorio que ya no está equipado")
		current_scene.melon.slots = slots
		current_scene.fase = 2
		current_scene.postales_intento = ["xallitic"]
		current_scene.camara.position_smoothing_enabled = false
		current_scene.melon.controlable = true
		current_scene.melon.position = current_scene.terreno.tramos[0].papalotes[0].position + Vector2(-90, 30)
		await _foto(prefijo + "ruta-aerea", ["Interfaz/%Vuelo", "Interfaz/%Indicacion", "Interfaz/%Equipo"])
		assert(current_scene.hud.tecla.text == "E" and current_scene.hud.indicacion.text.begins_with("Papalote"), "Falta la indicación para activar el papalote")
		var poder_x: float = root.get_node("Config").primer_poder_x
		current_scene.melon.position = Vector2(poder_x - 160.0, current_scene.terreno.tramos[0].altura(poder_x) - 110.0)
		await _foto(prefijo + "premios-calle", ["Interfaz/%Vuelo", "Interfaz/%Equipo"])
		var objetivo = current_scene.terreno.melones[0]
		objetivo.en_bajada = false
		objetivo.position = Vector2(900, current_scene.terreno.tramos[0].altura(900) - objetivo.radio)
		objetivo.anterior = objetivo.position
		current_scene.melon.position = objetivo.position + Vector2(-40, -180)
		current_scene.melon.en_suelo = false
		current_scene.melon.iniciar_slam()
		await _foto(prefijo + "slam", ["Interfaz/%Indicacion", "Interfaz/%Ayuda"])
		assert(current_scene.hud.indicacion.text.contains("El suelo frena"), "Falta el aviso del slam activo")
		current_scene.melon.slam_activo = false
		esperadas += 1
		current_scene.melon.position = Vector2(2200, current_scene.terreno.tramos[0].altura(2200) - 1100)
		current_scene.postales_intento = ["xallitic", "diamante", "catedral"]
		await _foto(prefijo + "vuelo-alto", ["Interfaz/%Vuelo", "Interfaz/%Indicacion"])
		assert(current_scene.get_node("Paisaje/NubesCercanas").visible, "Faltan las nubes al subir sobre la ciudad")
		current_scene.melon.position = Vector2(2200, current_scene.terreno.tramos[0].altura(2200) - 3000)
		await _foto(prefijo + "cielo-alto", ["Interfaz/%Vuelo", "Interfaz/%Indicacion"])
		for metros in [1850.0, 2350.0, 2590.0]:
			current_scene.terreno.actualizar(metros * root.get_node("Config").px_por_metro)
			var tramo = current_scene.terreno.tramo_en(metros * root.get_node("Config").px_por_metro)
			current_scene.melon.position = Vector2(metros * root.get_node("Config").px_por_metro, tramo.altura(metros * root.get_node("Config").px_por_metro) - 80.0)
			await _foto(prefijo + "ruta-" + str(int(metros)), ["Interfaz/%Lugar", "Interfaz/%Destino"])
			esperadas += 1
		current_scene.hud._alternar_pausa()
		await _foto(prefijo + "pausa", ["Interfaz/%Continuar", "Interfaz/%Volver", "Interfaz/%Columna"], 0.6)
		current_scene.hud._alternar_pausa()
		change_scene_to_file("res://pantallas/resultados/resultados.tscn")
		await _foto(prefijo + "resultados", ["%BtnVolver", "%Total", "%Distancia"], 3.0)
		var nombres: Array = []
		for postal in root.get_node("Config").postales:
			nombres.append(postal["nombre"])
		juego.ultimo = {"distancia": root.get_node("Config").meta_m, "llegada": true, "record_nuevo": true, "por_distancia": 1300, "por_carisma": 90,
			"por_recolectados": 60, "por_visitas": 480, "visitas_nuevas": nombres, "poderes": 12,
			"altura": 320.0, "por_altura": 320, "total": 4709}
		change_scene_to_file("res://pantallas/resultados/resultados.tscn")
		await _foto(prefijo + "resultados-completos", ["%BtnVolver", "%Total", "%Distancia", "%Titulo", "%Destino"], 3.0)
		var panel_meta = current_scene.get_node("Margen/Columnas/Postal")
		assert(panel_meta.lugar_id == "cucosta" and panel_meta.con_foto == fotografias.has("cucosta"), "La llegada solo muestra la foto de la meta cuando está asignada")
		juego.ultimo = ultimo
	# Cada fotografía debe corresponder al lugar alcanzado en este intento.
	var config := root.get_node("Config")
	for lugar in config.postales:
		if not fotografias.has(lugar["id"]):
			continue
		var datos: Dictionary = fotografias[lugar["id"]]
		assert(datos["textura"] is Texture2D and not datos["autor"].is_empty())
		assert(datos["fuente"].begins_with("https://commons.wikimedia.org/"))
		assert(datos["url_licencia"].begins_with("https://creativecommons.org/"))
		juego.ultimo = {"distancia": lugar["metros"]}
		change_scene_to_file("res://pantallas/resultados/resultados.tscn")
		await _foto("foto-" + lugar["id"])
		var panel := current_scene.get_node("Margen/Columnas/Postal")
		assert(panel.get_node("MargenFoto/Foto/Imagen").texture == datos["textura"])
		esperadas += 1
	juego.ultimo = ultimo
	arte.fotografias.clear()
	change_scene_to_file("res://pantallas/resultados/resultados.tscn")
	await _foto("sin-fotos-resultados")
	assert(not current_scene.get_node("Margen/Columnas/Postal").con_foto)
	esperadas += 1
	# Comprueba que quitar todo el arte no impida abrir las tres pantallas.
	arte.paisaje = null
	for escena in ["taller", "recorrido", "resultados"]:
		change_scene_to_file("res://pantallas/%s/%s.tscn" % [escena, escena])
		await _foto("sin-imagen-" + escena)
	arte.paisaje = ilustracion
	arte.fotografias = fotografias
	if FileAccess.file_exists(juego.archivo_guardado):
		DirAccess.remove_absolute(juego.archivo_guardado)
	assert(capturas == esperadas, "Faltan capturas de revisión")
	print("OK: %d capturas, controles dentro de pantalla, fotos por lugar y modo sin imágenes." % capturas)
	quit()
