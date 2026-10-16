extends SceneTree
## Colección, migración y navegación. Solo escribe en un archivo de prueba.

var juego: Node
var comprobaciones := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		push_error(mensaje)
		quit(1)
		assert(condicion, mensaje)
	comprobaciones += 1


func _esperar() -> void:
	for i in 8:
		await process_frame


func _clic(control: Control) -> void:
	for presionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.pressed = presionado
		evento.position = control.get_global_rect().get_center()
		evento.global_position = evento.position
		control.get_viewport().push_input(evento, true)
		await process_frame


func _verificar() -> void:
	juego = root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_almanaque_%d.json" % OS.get_process_id()
	juego.reiniciar_progreso()
	juego.nombre_melon = "Niebla de Xallitic"
	juego.tamano = 2
	juego.piel = 2
	juego.patron = 3
	juego.cara = 5
	juego.detalle = 2
	juego.estela = 3
	juego.cuerpo_propio = "80cfc0"
	juego.rayas_propio = "234a70"
	juego.accesorios = ["rebozo", "sombrero"]
	juego.dibujo = [{"color": Color.RED, "grosor": 0.1,
		"puntos": PackedVector2Array([Vector2(-0.2, 0.3), Vector2(0.4, 0.5)])}]
	var original: Dictionary = juego.datos_melon()
	comprobar(juego.guardar_melon() == 0, "Guardar la primera ficha")
	comprobar(juego.guardar_melon() == 0 and juego.melones_guardados.size() == 1, "Guardar dos veces no duplica una ficha idéntica")
	juego.nombre_melon = "Otro melón"
	juego.dibujo[0]["puntos"].append(Vector2.ZERO)
	juego.accesorios.clear()
	comprobar(juego.melones_guardados[0] == original, "Los cambios del taller no modifican la copia guardada")
	comprobar(juego.guardar_melon() == 1, "Guardar otro melón con otro dibujo")
	juego.melones_guardados.clear()
	juego.cargar()
	comprobar(juego.melones_guardados.size() == 2 and juego.melones_guardados[0] == original, "Recargar conserva todos los campos y trazos de la colección")
	var progreso := [juego.aplausos, juego.niveles.duplicate(), juego.record_m, juego.visitados.duplicate()]
	comprobar(juego.usar_melon(0) and juego.datos_melon() == original, "Usar restaura nombre, tamaño, colores, dibujo, estela y equipo")
	comprobar(progreso == [juego.aplausos, juego.niveles, juego.record_m, juego.visitados], "Usar una ficha conserva el progreso global")
	juego.dibujo[0]["puntos"].append(Vector2.ONE * 0.1)
	comprobar(juego.melones_guardados[0] == original, "Usar una ficha tampoco comparte el dibujo con el taller")
	comprobar(not juego.usar_melon(-1) and not juego.eliminar_melon(99) and juego.guardar_melon(99) == -1, "Los índices inválidos no alteran la colección")
	comprobar(juego.guardar_melon(0) == 0 and juego.melones_guardados.size() == 2, "Actualizar reemplaza solo la ficha elegida")
	comprobar(juego.eliminar_melon(1) and juego.melones_guardados.size() == 1, "Eliminar una ficha")
	juego.cargar()
	comprobar(juego.melones_guardados.size() == 1, "Eliminar queda guardado en disco")
	var archivo := FileAccess.open(juego.archivo_guardado, FileAccess.WRITE)
	archivo.store_string('{"version":1,"aplausos":321,"nombre_melon":"Melón anterior","piel":3}')
	archivo.close()
	juego.cargar()
	comprobar(juego.melones_guardados.is_empty() and juego.nombre_melon == "Melón anterior" and juego.aplausos == 321 and juego.piel == 3, "Los guardados anteriores abren con una colección vacía y conservan el melón")
	var danados := {"melones_guardados": [null, "mal", {}, {"nombre_melon": 3},
		{"nombre_melon": "  ", "tamano": 999, "piel": -9, "cuerpo_propio": "mal",
		"accesorios": ["inexistente", "jarana", "rebozo", "rebozo"],
		"dibujo": [{"c": "ff0000", "g": 9, "p": [99, 0]}]}]}
	archivo = FileAccess.open(juego.archivo_guardado, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(danados))
	archivo.close()
	juego.cargar()
	comprobar(juego.melones_guardados.size() == 1, "El cargador descarta las fichas dañadas")
	var reparado: Dictionary = juego.melones_guardados[0]
	comprobar(reparado["nombre_melon"] == "Melón" and reparado["tamano"] == 2 and reparado["piel"] == 0 and reparado["cuerpo_propio"] == "", "El cargador valida nombres, tamaños y colores de cada ficha")
	comprobar(reparado["accesorios"] == ["rebozo"] and reparado["dibujo"][0]["puntos"][0] == Vector2.RIGHT, "El cargador valida equipo, compras y dibujo de cada ficha")
	var muchas: Array = []
	for i in juego.MAX_MELONES + 5:
		muchas.append({"nombre_melon": str(i)})
	archivo = FileAccess.open(juego.archivo_guardado, FileAccess.WRITE)
	archivo.store_string(JSON.stringify({"melones_guardados": muchas}))
	archivo.close()
	juego.cargar()
	comprobar(juego.melones_guardados.size() == juego.MAX_MELONES, "La carga respeta la capacidad de la colección")
	comprobar(juego.guardar_melon() == -1 and juego.guardar_melon(0) == 0, "Una colección llena permite actualizar sin perder otras fichas")
	juego.reiniciar_progreso()
	juego.cargar()
	comprobar(juego.melones_guardados.is_empty(), "Reiniciar limpia y guarda la colección")
	change_scene_to_file("res://pantallas/taller/taller.tscn")
	await _esperar()
	var taller := current_scene
	comprobar(taller.get_node("%BtnAlmanaque") != null and taller.get_node("%BtnGuardarMelon") != null, "El taller ofrece guardar y abrir el almanaque")
	taller.get_node("%BtnGuardarMelon").pressed.emit()
	comprobar(juego.melones_guardados.size() == 1, "El botón del taller guarda el melón")
	taller.get_node("%BtnAlmanaque").pressed.emit()
	await _esperar()
	var almanaque := current_scene
	comprobar(almanaque.name == "Almanaque" and almanaque.lista.get_child_count() == 1, "El almanaque muestra la colección")
	var antes: Dictionary = juego.datos_melon()
	await _clic(almanaque.get_node("%Accesorios"))
	comprobar(almanaque.lista.get_child_count() == root.get_node("Config").orden_accesorios.size() and not almanaque.btn_usar.visible, "Accesorios muestra sus fichas de consulta")
	await _clic(almanaque.lista.get_child(3))
	comprobar(almanaque.seleccionado == 3, "El clic sobre el dibujo de una ficha la selecciona")
	almanaque.get_node("%Poderes").pressed.emit()
	almanaque._elegir(3)
	comprobar(almanaque.nombre.text == "Tamal de hoja" and almanaque.datos.text.contains("instantáneo"), "Poderes muestra el efecto de la ficha elegida")
	comprobar(juego.datos_melon() == antes, "Consultar el almanaque no cambia al melón actual")
	almanaque.get_node("%MisMelones").pressed.emit()
	juego.nombre_melon = "Melón actualizado"
	almanaque.get_node("%Actualizar").pressed.emit()
	comprobar(almanaque.confirmar.visible and juego.melones_guardados[0]["nombre_melon"] == "Melón", "Actualizar pide confirmación antes de reemplazar")
	await _esperar()
	almanaque.confirmar.get_cancel_button().pressed.emit()
	await _esperar()
	comprobar(not almanaque.confirmar.visible and juego.melones_guardados[0]["nombre_melon"] == "Melón", "Cancelar conserva la ficha anterior")
	almanaque.get_node("%Actualizar").pressed.emit()
	almanaque.confirmar.hide()
	almanaque.confirmar.confirmed.emit()
	comprobar(juego.melones_guardados[0]["nombre_melon"] == "Melón actualizado", "Confirmar actualiza la ficha")
	almanaque.get_node("%Eliminar").pressed.emit()
	comprobar(almanaque.confirmar.visible and juego.melones_guardados.size() == 1, "Eliminar pide confirmación antes de borrar")
	almanaque.confirmar.hide()
	almanaque.confirmar.confirmed.emit()
	comprobar(almanaque.seleccionado == -1 and almanaque.vacio.visible and not almanaque.btn_usar.visible, "Eliminar la última ficha muestra el estado vacío")
	almanaque.get_node("%Guardar").pressed.emit()
	juego.nombre_melon = "Temporal"
	almanaque.get_node("%Usar").pressed.emit()
	await _esperar()
	comprobar(current_scene.name == "Taller" and juego.nombre_melon == "Melón actualizado", "Usar melón vuelve al taller con la ficha elegida")
	current_scene.get_node("%BtnAlmanaque").pressed.emit()
	await _esperar()
	var escapar := InputEventAction.new()
	escapar.action = "ui_cancel"
	escapar.pressed = true
	current_scene._unhandled_input(escapar)
	await _esperar()
	comprobar(current_scene.name == "Taller", "Esc vuelve del almanaque sin acceder a un viewport eliminado")
	juego.archivo_guardado += "/sin_permisos.json"
	current_scene.get_node("%BtnGuardarMelon").pressed.emit()
	comprobar(not current_scene.get_node("%ErrorGuardo").text.is_empty() and not juego.melones_guardados.is_empty(), "El error de escritura se informa y conserva la colección en memoria")
	juego.archivo_guardado = juego.archivo_guardado.get_base_dir()
	DirAccess.remove_absolute(juego.archivo_guardado)
	DirAccess.remove_absolute(juego.archivo_guardado + ".tmp")
	print("OK: %d comprobaciones de colección, guardado y almanaque." % comprobaciones)
	quit()
