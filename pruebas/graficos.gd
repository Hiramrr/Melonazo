extends SceneTree
## Revisión con render real. Guarda capturas en user://revision_grafica/.
const ARTE := preload("res://recursos/arte_xalapa.tres")
var capturas := 0


func _initialize() -> void:
	call_deferred("_revisar")


func _foto(nombre: String, controles: Array = []) -> void:
	for i in 8:
		await process_frame
	var limites := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for id in controles:
		var control: Control = current_scene.get_node(id)
		assert(limites.encloses(control.get_global_rect()), "Control fuera de pantalla: " + id)
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("user://revision_grafica/" + nombre + ".png")
	assert(error == OK, "No se pudo guardar la captura")
	capturas += 1


func _revisar() -> void:
	DirAccess.make_dir_recursive_absolute("user://revision_grafica")
	var arte: ArteXalapa = ARTE
	var ilustracion: Texture2D = arte.paisaje
	var fotografias := arte.fotografias.duplicate()
	var juego := root.get_node("Juego")
	var ultimo: Dictionary = juego.ultimo.duplicate(true)
	var esperadas := 3
	for resolucion in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = resolucion
		var prefijo := "%dx%d-" % [resolucion.x, resolucion.y]
		change_scene_to_file("res://escenas/Taller.tscn")
		await process_frame
		await process_frame
		var pestanas: TabContainer = current_scene.get_node("%Pestanas")
		esperadas += pestanas.get_tab_count() + 8
		for pesta in pestanas.get_tab_count():
			current_scene.get_node("%Pestanas").current_tab = pesta
			await _foto(prefijo + "taller-" + str(pesta), ["%BtnPuente", "%Balance", "%Vista"])
		change_scene_to_file("res://escenas/Recorrido.tscn")
		await _foto(prefijo + "recorrido", ["Interfaz/%Distancia", "Interfaz/%Equipo", "Interfaz/%Fuerza", "Interfaz/%Indicacion"])
		current_scene.fase = 1
		await _foto(prefijo + "fuerza", ["Interfaz/%Fuerza", "Interfaz/%Indicacion"])
		var slots: Array = current_scene.melon.slots.duplicate()
		current_scene.melon.slots = [null, null, null]
		await _foto(prefijo + "sin-accesorios", ["Interfaz/%Equipo"])
		assert(current_scene.hud._nombres[0].text == "Vacío", "El HUD conserva un accesorio que ya no está equipado")
		current_scene.melon.slots = slots
		current_scene.fase = 2
		current_scene.postales_intento = ["xallitic"]
		current_scene.camara.position_smoothing_enabled = false
		current_scene.melon.controlable = true
		current_scene.melon.position = current_scene.tramos[0].papalotes[0].position + Vector2(-90, 30)
		await _foto(prefijo + "ruta-aerea", ["Interfaz/%Vuelo", "Interfaz/%Indicacion", "Interfaz/%Equipo"])
		assert(current_scene.hud.indicacion.text.begins_with("E · Papalote"), "Falta la indicación para activar el papalote")
		current_scene.melon.position = current_scene.tramos[0].papalotes[2].position + Vector2(-90, 30)
		current_scene.postales_intento = ["xallitic", "diamante", "catedral"]
		await _foto(prefijo + "vuelo-alto", ["Interfaz/%Vuelo", "Interfaz/%Indicacion"])
		assert(current_scene.get_node("Paisaje/NubesCercanas").visible, "Faltan las nubes al subir sobre la ciudad")
		current_scene.hud._alternar_pausa()
		await _foto(prefijo + "pausa", ["Interfaz/%Continuar", "Interfaz/%Volver"])
		current_scene.hud._alternar_pausa()
		change_scene_to_file("res://escenas/Resultados.tscn")
		await _foto(prefijo + "resultados", ["%BtnVolver", "%Total", "%Distancia"])
		var nombres: Array = []
		for postal in root.get_node("Config").postales:
			nombres.append(postal["nombre"])
		juego.ultimo = {"distancia": 12530, "record_nuevo": true, "por_distancia": 3759, "por_carisma": 90,
			"por_recolectados": 60, "por_visitas": 480, "visitas_nuevas": nombres, "poderes": 12, "total": 4389}
		change_scene_to_file("res://escenas/Resultados.tscn")
		await _foto(prefijo + "resultados-completos", ["%BtnVolver", "%Total", "%Distancia", "%Titulo"])
		juego.ultimo = ultimo
	# Cada fotografía debe corresponder al último lugar alcanzado que tenga foto.
	var config := root.get_node("Config")
	for lugar in config.postales:
		if not fotografias.has(lugar["id"]):
			continue
		var datos: Dictionary = fotografias[lugar["id"]]
		assert(datos["textura"] is Texture2D and not datos["autor"].is_empty())
		assert(datos["fuente"].begins_with("https://commons.wikimedia.org/"))
		assert(datos["url_licencia"].begins_with("https://creativecommons.org/"))
		juego.ultimo = {"distancia": lugar["metros"]}
		change_scene_to_file("res://escenas/Resultados.tscn")
		await _foto("foto-" + lugar["id"])
		var panel := current_scene.get_node("Margen/Columnas/Postal")
		assert(panel.get_node("MargenFoto/Foto/Imagen").texture == datos["textura"])
		esperadas += 1
	juego.ultimo = ultimo
	arte.fotografias.clear()
	change_scene_to_file("res://escenas/Resultados.tscn")
	await _foto("sin-fotos-resultados")
	assert(not current_scene.get_node("Margen/Columnas/Postal").con_foto)
	esperadas += 1
	# Comprueba que quitar todo el arte no impida abrir las tres pantallas.
	arte.paisaje = null
	for escena in ["Taller", "Recorrido", "Resultados"]:
		change_scene_to_file("res://escenas/" + escena + ".tscn")
		await _foto("sin-imagen-" + escena.to_lower())
	arte.paisaje = ilustracion
	arte.fotografias = fotografias
	assert(capturas == esperadas, "Faltan capturas de revisión")
	print("OK: %d capturas, controles dentro de pantalla, fotos por lugar y modo sin imágenes." % capturas)
	quit()
