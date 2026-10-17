extends SceneTree
## Una imagen por punto de interés, sin colisión y sustituible sin alterar resultados.


func _initialize() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	var config := root.get_node("Config")
	var arte = load("res://recursos/arte_xalapa.tres")
	var terreno = load("res://mundo/terreno/generador_terreno.gd").new()
	root.add_child(terreno)
	terreno.iniciar()
	var encontrados: Array = []
	for lugar in config.postales:
		var id: String = lugar["id"]
		assert(arte.lugares_mapa.get(id) is Texture2D, "Cada punto de interés debe tener una imagen asignada")
		assert(not arte.fotografias[id]["dato_curioso"].is_empty(), "Las imágenes corresponden a los lugares con dato curioso")
		var x: float = maxf(float(lugar["metros"]) * config.px_por_metro, config.calle_inicio_x)
		terreno.actualizar(x)
		for tramo in terreno.tramos:
			for imagen in tramo.get_node("Postales").get_children():
				if imagen in encontrados:
					continue
				encontrados.append(imagen)
				assert(imagen.get_parent().z_index == -1, "Las imágenes quedan detrás del suelo y del melón")
				assert(imagen.find_children("*", "CollisionObject2D", true, false).is_empty(), "Los lugares no bloquean el paso")
		var imagenes: Array = encontrados.filter(func(p: Node) -> bool: return p.tipo == id)
		assert(imagenes.size() == 1, "Cada lugar aparece una sola vez, incluso en los límites de tramo")
		assert(imagenes[0].position == Vector2(x, terreno.tramo_en(x).altura(x)), "La imagen coincide con los metros del lugar y se apoya en el suelo")
	assert(encontrados.size() == config.postales.size(), "El mapa incluye los 19 puntos de interés")
	var foto: Texture2D = arte.fotografias["juarez"]["textura"]
	var imagen_original: Texture2D = arte.lugares_mapa["juarez"]
	arte.lugares_mapa["juarez"] = Sprites.textura("postales/juarez")
	assert(arte.fotografias["juarez"]["textura"] == foto, "Cambiar al sprite conserva la fotografía de resultados")
	arte.lugares_mapa["juarez"] = imagen_original
	print("OK: 19 imágenes de lugares, posiciones, límites de tramos y sustitución por sprite independiente de resultados.")
	quit()
