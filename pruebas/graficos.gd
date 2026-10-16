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
			await _foto(prefijo + "taller-" + str(pesta), ["%BtnPuente", "%Balance", "%Vista"], 1.0 if pesta == 0 else 0.0)
		change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
		await _foto(prefijo + "recorrido", ["Interfaz/%Distancia", "Interfaz/%Equipo", "Interfaz/%Fuerza", "Interfaz/%Indicacion"])
		current_scene.fase = 1
		await _foto(prefijo + "fuerza", ["Interfaz/%Fuerza", "Interfaz/%Indicacion"])
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
		current_scene.melon.position = Vector2(2200, current_scene.terreno.tramos[0].altura(2200) - 1100)
		current_scene.postales_intento = ["xallitic", "diamante", "catedral"]
		await _foto(prefijo + "vuelo-alto", ["Interfaz/%Vuelo", "Interfaz/%Indicacion"])
		assert(current_scene.get_node("Paisaje/NubesCercanas").visible, "Faltan las nubes al subir sobre la ciudad")
		current_scene.melon.position = Vector2(2200, current_scene.terreno.tramos[0].altura(2200) - 3000)
		await _foto(prefijo + "cielo-alto", ["Interfaz/%Vuelo", "Interfaz/%Indicacion"])
		current_scene.hud._alternar_pausa()
		await _foto(prefijo + "pausa", ["Interfaz/%Continuar", "Interfaz/%Volver"], 0.6)
		current_scene.hud._alternar_pausa()
		change_scene_to_file("res://pantallas/resultados/resultados.tscn")
		await _foto(prefijo + "resultados", ["%BtnVolver", "%Total", "%Distancia"], 3.0)
		var nombres: Array = []
		for postal in root.get_node("Config").postales:
			nombres.append(postal["nombre"])
		juego.ultimo = {"distancia": 12530, "record_nuevo": true, "por_distancia": 3759, "por_carisma": 90,
			"por_recolectados": 60, "por_visitas": 480, "visitas_nuevas": nombres, "poderes": 12,
			"altura": 320.0, "por_altura": 320, "total": 4709}
		change_scene_to_file("res://pantallas/resultados/resultados.tscn")
		await _foto(prefijo + "resultados-completos", ["%BtnVolver", "%Total", "%Distancia", "%Titulo"], 3.0)
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
