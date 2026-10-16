extends SceneTree
## Ejecutar con Godot --headless --path . --script res://pruebas/verificar.gd
## Usa su propio guardado y nunca modifica progreso.json.

var juego: Node
var config: Node
var comprobaciones := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		push_error("FALLO: " + mensaje)
		quit(1)
		assert(condicion, mensaje)
	comprobaciones += 1


## Mueve el ratón a pos (coordenadas del viewport) con el botón izquierdo
## apretado, o lo aprieta (presionado = true) o suelta (false) ahí.
func _raton(pos: Vector2, presionado = null) -> void:
	var evento: InputEventMouse
	if presionado == null:
		evento = InputEventMouseMotion.new()
		evento.button_mask = MOUSE_BUTTON_MASK_LEFT
	else:
		var boton := InputEventMouseButton.new()
		boton.button_index = MOUSE_BUTTON_LEFT
		boton.pressed = presionado
		evento = boton
	evento.position = pos
	evento.global_position = pos
	root.push_input(evento, true)
	await process_frame


func _verificar() -> void:
	juego = root.get_node("Juego")
	config = root.get_node("Config")
	juego.archivo_guardado = "user://prueba_automatica_%d.json" % OS.get_process_id()
	juego.aplausos = 1000
	juego.record_m = 0.0
	juego.intentos = 0
	juego.visitados = []
	juego.niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	juego.desbloqueados = config.accesorios_iniciales.duplicate()
	juego.accesorios = ["llantitas", "rebozo"]
	juego.tamano = 1
	juego.piel = 0
	juego.cara = 0
	juego.estela = 0
	juego.rayas_propio = ""
	juego.nombre_melon = "Prueba xalapeña"
	comprobar(ProjectSettings.get_setting("application/config/name") == "¡Rueda, Melón!", "Nombre del proyecto")
	for accion in ["izquierda", "derecha", "rebote", "acc_1", "acc_2", "acc_3", "empujon", "confirmar", "pausar"]:
		comprobar(InputMap.has_action(accion), "Entrada configurada: " + accion)
	comprobar(juego.comprar_mejora("fuerza"), "Compra con saldo")
	comprobar(juego.aplausos == 1000 - int(config.mejoras["fuerza"]["costo_base"]) and juego.niveles["fuerza"] == 1, "Compra descuenta una vez")
	juego.aplausos = 0
	comprobar(not juego.comprar_mejora("fuerza"), "Compra sin saldo no altera progreso")
	comprobar(juego.niveles["fuerza"] == 1, "Nivel conservado tras compra fallida")
	juego.aplausos = 1000
	comprobar(juego.desbloquear("flor"), "Desbloqueo de accesorio xalapeño")
	comprobar(not juego.desbloquear("flor") and juego.aplausos == 760, "No cobrar doble por desbloqueo")
	juego.registrar_intento(210.0, 3, 2, false, 2)
	comprobar(juego.visitados.size() == 3, "Pasaporte registra los tres primeros sitios")
	var esperado: int = int(210.0 * config.aplausos_por_metro) + 3 * config.aplausos_por_carisma \
		+ 2 * config.valor_aplauso_suelto + 3 * config.bonus_postal
	comprobar(juego.ultimo["por_visitas"] == 3 * config.bonus_postal and juego.ultimo["total"] == esperado, "Desglose de premios")
	juego.registrar_intento(100.0, 0, 0, false)
	comprobar(juego.ultimo["por_visitas"] == 0 and juego.record_m == 210, "No repetir premios ni bajar récord")
	juego.piel = 3
	juego.cara = 4
	juego.estela = 2
	juego.guardar()
	comprobar(juego.guardado_error == "", "Guardado sin errores")
	juego.piel = 0
	juego.nombre_melon = "Otro"
	juego.cargar()
	comprobar(juego.piel == 3 and juego.nombre_melon == "Prueba xalapeña" and juego.intentos == 2, "Carga conserva aspecto, nombre e intentos")
	comprobar(config.accesorios.size() == 8 and config.orden_accesorios[0] == "sombrero", "Accesorios cargados desde su carpeta y ordenados")
	comprobar(config.accesorios_iniciales == ["sombrero", "llantitas", "rebozo"], "Accesorios iniciales salen de cada archivo")
	for id in config.orden_accesorios:
		var acc = config.accesorios[id]
		comprobar(is_instance_of(acc, load("res://melon/accesorios/accesorio.gd")) and acc.id == id and acc.forma.size() >= 3, "Accesorio completo: " + id)
	juego.patron = 2
	juego.detalle = 3
	juego.cuerpo_propio = "ff8800"
	juego.dibujo = [{"color": Color.RED, "grosor": 0.1, "puntos": PackedVector2Array([Vector2(0.1, 0.2), Vector2(-0.3, 0.4)])}]
	juego.guardar()
	juego.patron = 0
	juego.detalle = 0
	juego.cuerpo_propio = ""
	juego.dibujo = []
	juego.cargar()
	comprobar(juego.patron == 2 and juego.detalle == 3 and juego.color_cuerpo().is_equal_approx(Color("ff8800")), "Carga conserva patrón, detalle y color propio")
	comprobar(juego.color_rayas() == config.pieles[juego.piel]["rayas"], "Sin color propio se usa el de la piel")
	comprobar(juego.dibujo.size() == 1 and juego.dibujo[0]["puntos"][1].is_equal_approx(Vector2(-0.3, 0.4)), "Carga conserva el dibujo libre")
	juego.dibujo = []
	var archivo := FileAccess.open(juego.archivo_guardado, FileAccess.WRITE)
	archivo.store_string('{"dibujo":[{"c":"zz","g":0.1,"p":[0,0]},{"c":"ff0000","g":9,"p":[5,0,"x",1]},"malo"],"cuerpo_propio":"no es color","patron":77,"tamano":99,"piel":-2,"cara":"malo","aplausos":-20,"niveles":{"fuerza":99},"desbloqueados":["no_existe","flor"],"accesorios":["no_existe","flor","flor"],"visitados":["no_existe","xallitic"]}')
	archivo.close()
	juego.cargar()
	comprobar(juego.tamano == 2 and juego.piel == 0 and juego.cara == 0 and juego.aplausos == 0, "Carga limita valores inválidos")
	comprobar(juego.accesorios == ["flor"] and juego.visitados == ["xallitic"], "Carga descarta ids desconocidos y duplicados")
	comprobar(juego.niveles["fuerza"] == 6, "Carga limita mejoras al máximo")
	comprobar(juego.dibujo.size() == 1 and juego.dibujo[0]["puntos"].size() == 1 and juego.dibujo[0]["puntos"][0] == Vector2(1, 0), "Carga descarta trazos inválidos y limita puntos")
	comprobar(juego.dibujo[0]["grosor"] == config.grosor_dibujo.y and juego.cuerpo_propio == "" and juego.patron == config.patrones.size() - 1, "Carga limita grosor, color y patrón")
	archivo = FileAccess.open(juego.archivo_guardado, FileAccess.WRITE)
	archivo.store_string("guardado roto")
	archivo.close()
	juego.cargar()
	comprobar(not juego.guardado_error.is_empty() and not FileAccess.file_exists(juego.archivo_guardado), "Guardado roto se respalda antes de continuar")
	var carpeta := DirAccess.open("user://")
	var respaldo := ""
	for nombre in carpeta.get_files():
		if nombre.begins_with(juego.archivo_guardado.get_file() + ".danado-"):
			respaldo = "user://" + nombre
	juego.guardar()
	comprobar(not respaldo.is_empty() and FileAccess.get_file_as_string(respaldo) == "guardado roto", "Guardar conserva copia original dañada")
	DirAccess.remove_absolute(respaldo)
	var ruta_prueba: String = juego.archivo_guardado
	juego.archivo_guardado = "user://carpeta_inexistente_%d/progreso.json" % OS.get_process_id()
	juego.guardar()
	comprobar(not juego.guardado_error.is_empty(), "Fallo de escritura se informa sin perder estado")
	juego.archivo_guardado = ruta_prueba


	juego.tamano = 1
	juego.niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	juego.accesorios = ["llantitas", "rebozo"]
	var melon = load("res://melon/melon.tscn").instantiate()
	melon.freeze = true
	root.add_child(melon)
	melon.configurar(1, ["rebozo", "flor", "jarana"], 3, juego.rebotes_max())
	melon.set_physics_process(false)
	melon.controlable = true
	melon.resistencia = 2
	melon.rebotes = juego.rebotes_max() - 1
	melon.recibir_poder("tamal")
	comprobar(melon.resistencia == 3 and melon.rebotes == juego.rebotes_max(), "Tamal repara y recupera rebote")
	melon.recibir_poder("tamal")
	comprobar(melon.resistencia == 3 and melon.rebotes == juego.rebotes_max(), "Tamal respeta máximos")
	melon.recibir_poder("niebla")
	melon.golpe()
	comprobar(melon.resistencia == 3, "Niebla protege de golpes")
	melon.t_niebla = 0
	melon.recibir_poder("chile")
	melon.golpe()
	comprobar(melon.resistencia == 3 and melon.t_embestida > 0, "Chile protege y embiste")
	melon.t_chile = 0
	melon.golpe()
	comprobar(melon.resistencia == 2, "Sin poderes los golpes dañan")
	melon.recibir_poder("cafe")
	comprobar(melon.t_cafe == config.poderes["cafe"]["duracion"], "Café inicia duración")
	melon.usar(0)
	comprobar(melon.slots[0] == null and melon.escudo and melon.t_planeo == config.accesorios["rebozo"].duracion, "Rebozo se consume y protege")
	melon.usar(1)
	comprobar(melon.resistencia == 3 and melon.t_iman > 0, "Flor repara y atrae aplausos")
	melon.usar(2)
	comprobar(melon.rebotes == juego.rebotes_max() + 1 and melon.carisma() == 0, "Jarana suma rebote y pierde carisma al usar")
	melon.recibir_poder("tamal")
	comprobar(melon.rebotes == juego.rebotes_max() + 1, "Tamal conserva los rebotes extra de la jarana")
	melon.position = Vector2(0, -4000)
	melon.freeze = false
	melon.linear_velocity = Vector2(2500, 0)
	for i in 8:
		await physics_frame
	comprobar(melon.linear_velocity.x > 2200, "Café no frena al melón que supera su velocidad objetivo")
	melon.queue_free()
	await process_frame
	for proteccion in ["niebla", "chile", "ninguna"]:
		var suelo := StaticBody2D.new()
		var zona := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(4000, 40)
		zona.shape = rect
		suelo.add_child(zona)
		suelo.position = Vector2(0, 100)
		root.add_child(suelo)
		var caida = load("res://melon/melon.tscn").instantiate()
		caida.position = Vector2(0, -500)
		root.add_child(caida)
		caida.configurar(1, [], 3, 1)
		caida.escudo = true
		if proteccion != "ninguna":
			caida.controlable = true
			caida.recibir_poder(proteccion)
			caida._dv = Vector2.ZERO
		caida.linear_velocity = Vector2(0, 1400)
		for i in 65:
			await physics_frame
		comprobar(caida.resistencia == 3, "Caída fuerte protegida con " + proteccion)
		comprobar(caida.escudo == (proteccion != "ninguna"), "Escudo se conserva solo si otro poder protege: " + proteccion)
		caida.queue_free()
		suelo.queue_free()
		await process_frame

	change_scene_to_file("res://pantallas/taller/taller.tscn")
	await process_frame
	await process_frame
	var taller = current_scene
	var pestanas: TabContainer = taller.get_node("%Pestanas")
	comprobar(taller.get_node("%Vista") != null, "Taller con nodos editables")
	var titulos: Array = []
	for i in pestanas.get_tab_count():
		titulos.append(pestanas.get_tab_title(i))
	comprobar(titulos == ["Tu melón", "Dibujo", "Accesorios", "Mejoras", "Pasaporte"], "Pestañas del taller en orden y con su título")
	comprobar(taller.get_node("%TuMelon").listas.size() == 5, "Taller ofrece piel, patrón, cara, detalle y estela")
	var panel = taller.get_node("%Dibujo")
	pestanas.current_tab = pestanas.get_tab_idx_from_control(panel)
	var antes: int = juego.dibujo.size()
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	panel.entrada_vista(clic, Vector2(-0.5, 0.0))
	var arrastre := InputEventMouseMotion.new()
	panel.entrada_vista(arrastre, Vector2(0.5, 0.2))
	panel.entrada_vista(arrastre, Vector2(3.0, 0.2))
	clic.pressed = false
	panel.entrada_vista(clic, Vector2(3.0, 0.2))
	comprobar(juego.dibujo.size() == antes + 1 and juego.dibujo[-1]["puntos"].size() == 3, "Pincel crea un trazo con sus puntos")
	comprobar(juego.dibujo[-1]["puntos"][-1].length() <= 1.0, "El trazo no se sale del melón")
	panel.goma.button_pressed = true
	clic.pressed = true
	panel.entrada_vista(clic, Vector2(0.5, 0.2))
	clic.pressed = false
	panel.entrada_vista(clic, Vector2(0.5, 0.2))
	panel.pincel.button_pressed = true
	comprobar(juego.dibujo.size() == antes, "Goma borra el trazo que toca")
	panel.entrada_vista(arrastre, Vector2.ZERO)
	clic.pressed = true
	panel.entrada_vista(clic, Vector2(0.1, 0.1))
	clic.pressed = false
	panel.entrada_vista(clic, Vector2(0.1, 0.1))
	panel.deshacer()
	comprobar(juego.dibujo.size() == antes, "Deshacer quita el último trazo")
	# Con el ratón de verdad: los eventos pasan por el viewport y deben llegar a la vista.
	var centro: Vector2 = taller.get_node("%Vista").get_global_rect().get_center()
	await _raton(centro + Vector2(-30, 0), true)
	await _raton(centro + Vector2(0, 5))
	await _raton(centro + Vector2(30, 10))
	await _raton(centro + Vector2(30, 10), false)
	comprobar(juego.dibujo.size() == antes + 1 and juego.dibujo[-1]["puntos"].size() == 3, "El ratón dibuja sobre la vista previa del taller")
	juego.dibujo = []
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var recorrido = current_scene
	comprobar(recorrido.terreno.tramos.size() >= 2 and recorrido.melon.freeze, "Terreno listo antes del lanzamiento")
	comprobar(recorrido.get_node("Mundo/Terreno").get_child_count() == recorrido.terreno.tramos.size(), "Tramos en contenedor propio")
	comprobar(recorrido.terreno.tramos[0].get_node("Postales").get_child_count() == 3, "Primer tramo contiene Xallitic, Diamante y Catedral")
	var consumibles: Array = []
	for t in recorrido.terreno.tramos:
		for nodo in t.get_node("Coleccionables").get_children():
			if nodo is Area2D and nodo.has_signal("recogido"):
				consumibles.append(nodo)
	comprobar(consumibles.size() >= 1 and consumibles.size() <= 3, "Los primeros tramos contienen pocos poderes")
	comprobar(consumibles[0].tipo == "cafe" and consumibles[1].tipo == "chile", "Poderes alternan de forma reproducible")
	var ultimo_x := -1.0
	for t in recorrido.terreno.tramos:
		for nodo in t.get_node("Coleccionables").get_children():
			if nodo is Area2D and nodo.has_signal("recogido"):
				var altura: float = t.altura(nodo.position.x) - nodo.position.y
				comprobar(altura >= config.altura_poderes.x - 0.01, "Un poder exige elevarse sobre el suelo")
				if ultimo_x >= 0:
					var distancia: float = nodo.position.x - ultimo_x
					comprobar(distancia >= config.separacion_poderes.x and distancia <= config.separacion_poderes.y, "Separación de poderes se respeta entre tramos")
				ultimo_x = nodo.position.x
	# Reentrar en un área no debe generar impulso gratis otra vez.
	recorrido.fase = 2
	recorrido.melon.controlable = true
	var rampa = load("res://mundo/obstaculos/rampa.tscn").instantiate()
	root.add_child(rampa)
	recorrido._al_tocar_obstaculo(recorrido.melon, rampa)
	var impulso: Vector2 = recorrido.melon._dv
	recorrido._al_tocar_obstaculo(recorrido.melon, rampa)
	comprobar(not rampa.activo and recorrido.melon._dv == impulso, "Rampa da un solo impulso por carrera")
	var toldo = load("res://mundo/obstaculos/toldo.tscn").instantiate()
	root.add_child(toldo)
	recorrido.melon.linear_velocity = Vector2(80, 300)
	recorrido._al_tocar_obstaculo(recorrido.melon, toldo)
	var salida: Vector2 = recorrido.melon._v_fijar
	recorrido.melon.linear_velocity = Vector2(0, 1200)
	recorrido._al_tocar_obstaculo(recorrido.melon, toldo)
	comprobar(not toldo.activo and recorrido.melon._v_fijar == salida, "Toldo no relanza al melón al reentrar")
	comprobar(is_equal_approx(salida.x, 80) and is_equal_approx(salida.y, -270), "Toldo conserva parte de la caída sin añadir velocidad mínima")
	rampa.queue_free()
	toldo.queue_free()
	recorrido.melon._dv = Vector2.ZERO
	recorrido.melon._fijar = false

	recorrido.angulo = 25.0
	recorrido.fuerza = 0.91
	recorrido._lanzar()
	comprobar(not recorrido.melon.freeze and recorrido.melon.controlable, "Lanzamiento habilita física y controles")
	consumibles[0]._recoger(recorrido.melon)
	consumibles[0]._recoger(recorrido.melon)
	comprobar(recorrido.poderes_recogidos == 1, "Un consumible solo se cobra una vez")
	recorrido.hud._alternar_pausa()
	comprobar(paused and recorrido.hud.pausa.visible, "Pausa detiene el árbol y muestra controles")
	recorrido.hud._alternar_pausa()
	comprobar(not paused, "Continuar restaura el árbol")
	for i in 3600:
		await physics_frame
		if not is_instance_valid(recorrido) or current_scene != recorrido:
			break
	comprobar(current_scene.name == "Resultados", "La carrera termina y muestra resultados")
	comprobar(juego.ultimo["distancia"] > 50 and juego.ultimo["poderes"] >= 1, "Resultados registran una carrera real")
	current_scene._volver()
	await process_frame
	await process_frame
	comprobar(current_scene.name == "Taller", "Ciclo completo vuelve al taller")
	DirAccess.remove_absolute(juego.archivo_guardado)
	DirAccess.remove_absolute(juego.archivo_guardado + ".tmp")
	print("OK: %d comprobaciones, carrera completa y guardado aislado." % comprobaciones)
	quit()
