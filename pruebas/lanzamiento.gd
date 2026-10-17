extends SceneTree
## Bajada, fuerza y bloqueo de controles con física real y guardado separado.

const ACCIONES := ["derecha", "rebote", "slam", "acc_1", "acc_2", "acc_3", "empujon"]
var juego: Node
var config: Node
var fallos := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _verificar() -> void:
	juego = root.get_node("Juego")
	config = root.get_node("Config")
	juego.archivo_guardado = "user://prueba_lanzamiento_%d.json" % OS.get_process_id()
	juego.niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	juego.accesorios = []
	juego.valentinas = 0
	config.semilla_terreno = 42
	await probar_parrilla()
	for tamano in 3:
		var suave: Dictionary = await carrera(tamano, 0.0)
		var fuerte: Dictionary = await carrera(tamano, 0.95)
		comprobar(suave["cruzo"] and fuerte["cruzo"], "Ambas fuerzas permiten cruzar Xallitic, tamaño %d" % tamano)
		comprobar(fuerte["velocidad"] > suave["velocidad"] + 80.0, "La fuerza conserva su efecto al salir del trampolín, tamaño %d" % tamano)
		comprobar(fuerte["metros"] > suave["metros"], "Más fuerza aumenta el alcance sin controles, tamaño %d" % tamano)
		print("Tamaño %d, fuerza 0/95%%: %.0f/%.0f px/s al cruzar, %.0f/%.0f m de alcance." % [tamano, suave["velocidad"], fuerte["velocidad"], suave["metros"], fuerte["metros"]])
	juego.accesorios = ["llantitas", "rebozo", "sombrero"]
	var pasiva: Dictionary = await carrera(1, 0.7)
	var con_teclas: Dictionary = await carrera(1, 0.7, true)
	var misma_bajada: bool = pasiva["trayectoria"].size() == con_teclas["trayectoria"].size()
	for i in mini(pasiva["trayectoria"].size(), con_teclas["trayectoria"].size()):
		misma_bajada = misma_bajada and pasiva["trayectoria"][i].distance_to(con_teclas["trayectoria"][i]) < 0.01
	comprobar(misma_bajada, "Pulsar movimiento, salto, accesorios y E no cambia la bajada")
	comprobar(is_equal_approx(pasiva["velocidad"], con_teclas["velocidad"]), "Las teclas no alteran la velocidad al salir del trampolín")
	if FileAccess.file_exists(juego.archivo_guardado):
		DirAccess.remove_absolute(juego.archivo_guardado)
	print("Lanzamiento: %d fallos." % fallos)
	quit(1 if fallos else 0)


func carrera(tamano: int, fuerza: float, pulsar := false) -> Dictionary:
	seed(42)
	juego.tamano = tamano
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	# Medimos la fuerza de salida sin que recoger un poder o tocar una rampa cambie el alcance.
	r.terreno.obstaculo_tocado.disconnect(r._al_tocar_obstaculo)
	r.terreno.poder_recogido.disconnect(r._al_recoger_poder)
	r.terreno.pajaro_tocado.disconnect(r._al_tocar_pajaro)
	for tramo in r.terreno.tramos:
		for obstaculo in tramo.get_node("Obstaculos").get_children():
			obstaculo.free()
	comprobar(r.fase == 0 and r.melon.freeze and r.hud.lanzamiento.visible and r.bajada.barrera.visible, "La salida espera con la barrera puesta mientras eliges potencia")
	comprobar(r.melon.position.x < config.bajada_fin.x and r.melon.position.y < 0.0, "El melón sale desde arriba de Xallitic")
	r.fuerza = fuerza
	var espacio := InputEventAction.new()
	espacio.action = "rebote"
	espacio.pressed = true
	r._unhandled_input(espacio)
	comprobar(not r.bajada.barrera.visible, "Elegir la potencia retira la barrera y suelta al melón")
	comprobar(r.fase == 1 and r.melon.freeze and not r.melon.controlable, "Durante la bajada el melón rueda sin controles")
	comprobar(not r.melon.saltar(), "No se puede saltar en la bajada")
	comprobar(not r.melon.iniciar_slam(), "No se puede hacer slam en la bajada")
	var slots: Array = r.melon.slots.duplicate()
	for i in 3:
		r.melon.usar(i)
	comprobar(r.melon.slots == slots, "No se pueden consumir accesorios en la bajada")
	var salida: float = r._velocidad_salida
	r.fuerza = 1.0 - fuerza
	r._unhandled_input(espacio)
	r._lanzar()
	comprobar(r._velocidad_salida == salida, "No se puede cambiar la potencia ni volver a lanzar durante la bajada")
	r.fuerza = fuerza
	r.hud._alternar_pausa()
	comprobar(paused and r.hud.pausa.visible, "La pausa está disponible durante la bajada")
	r.hud._alternar_pausa()
	var datos := {"cruzo": false, "velocidad": 0.0, "metros": 0.0, "trayectoria": PackedVector2Array()}
	for cuadro in 30 * 120:
		await physics_frame
		for accion in ACCIONES:
			Input.action_release(accion)
		if not is_instance_valid(r) or current_scene != r:
			break
		datos["metros"] = maxf(0.0, r.mejor_x) / config.px_por_metro
		if r.fase == 1:
			comprobar(not r.melon.controlable, "Los controles siguen bloqueados antes de salir del trampolín")
			comprobar(r.altura_max_m == 0.0, "La cuesta inicial no regala un bono de altura")
			datos["trayectoria"].append(r.melon.position)
			if pulsar and r.melon.position.x < 0.0 and cuadro % 2 == 0:
				for accion in ACCIONES:
					Input.action_press(accion)
		elif r.fase == 2 and not datos["cruzo"]:
			datos["cruzo"] = true
			datos["velocidad"] = r.melon.linear_velocity.x
			comprobar(r._x_bajada >= config.bajada_fin.x and r.melon.controlable and not r.melon.freeze, "Solo se habilitan física libre y controles al dejar el trampolín")
			comprobar(r.melon.rebotes == juego.rebotes_max(), "La bajada conserva las cargas de salto")
			comprobar(r.melon.slots == slots, "La bajada conserva los accesorios equipados")
			if pulsar:
				r.melon.t_bloqueo = 0.0
				comprobar(r.melon.saltar(), "El salto vuelve a funcionar después del trampolín")
				r.melon.usar(0)
				comprobar(r.melon.slots[0] == null, "Los accesorios vuelven a funcionar después del trampolín")
	comprobar(current_scene != r, "La carrera termina también después de la nueva salida")
	return datos


func probar_parrilla() -> void:
	var coleccion: Array = juego.melones_guardados.duplicate(true)
	var jugador: Dictionary = juego.datos_melon()
	juego.melones_guardados.clear()
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	comprobar(r.terreno.melones.size() == config.rivales_salida, "Hay una parrilla completa con el almanaque vacío")
	var posiciones: Array = r.terreno.melones.map(func(m: Node2D) -> Vector2: return m.position)
	for i in 20:
		await physics_frame
	comprobar(posiciones == r.terreno.melones.map(func(m: Node2D) -> Vector2: return m.position), "Los rivales esperan la salida mientras eliges potencia")
	for i in 3:
		var ficha := jugador.duplicate(true)
		ficha["nombre_melon"] = "Rival guardado %d" % i
		ficha["tamano"] = i
		ficha["cuerpo_propio"] = ["d86b51", "89ad73", "b7a6d5"][i]
		ficha["accesorios"] = ["sombrero"]
		ficha["dibujo"] = [{"color": Color.RED, "grosor": 0.1, "puntos": PackedVector2Array([Vector2.ZERO, Vector2(0.5, 0.5)])}]
		juego.melones_guardados.append(ficha)
	var fichas: Array = juego.melones_guardados.duplicate(true)
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	r = current_scene
	r.set_process(false)
	comprobar(r.terreno.melones.size() == config.rivales_salida, "Las fichas guardadas y los diseños extra completan la parrilla")
	for ficha in fichas:
		var coincidencias: Array = r.terreno.melones.filter(func(m: Node2D) -> bool:
			var aspecto: Dictionary = m.aspecto.duplicate()
			aspecto.erase("tipo")
			return aspecto == ficha)
		comprobar(coincidencias.size() == 1, "Cada melón del almanaque participa una vez con su apariencia completa")
		if not coincidencias.is_empty():
			comprobar(coincidencias[0].radio == config.tamanos[ficha["tamano"]]["radio"], "El rival conserva el tamaño guardado")
	r.terreno.melones[0].aspecto["dibujo"][0]["puntos"][0] = Vector2.ONE
	comprobar(juego.melones_guardados == fichas and juego.datos_melon() == jugador, "Los rivales no modifican el almanaque ni el melón del jugador")
	posiciones = r.terreno.melones.map(func(m: Node2D) -> Vector2: return m.position)
	var rivales: Array = r.terreno.melones.duplicate()
	r.fuerza = 0.7
	r._lanzar()
	for i in 20:
		await physics_frame
	for i in r.terreno.melones.size():
		comprobar(r.terreno.melones[i].position.x > posiciones[i].x, "Todos los rivales arrancan con el jugador")
	r.hud._alternar_pausa()
	posiciones = r.terreno.melones.map(func(m: Node2D) -> Vector2: return m.position)
	for i in 4:
		await process_frame
	comprobar(posiciones == r.terreno.melones.map(func(m: Node2D) -> Vector2: return m.position), "La pausa detiene también a los rivales")
	r.hud._alternar_pausa()
	for i in 10 * 120:
		await physics_frame
		var en_bajada := false
		for rival in r.terreno.melones:
			comprobar(rival.position.distance_to(rival.anterior) < 30.0, "Los rivales bajan y caen del trampolín sin teletransportarse")
			en_bajada = en_bajada or rival.en_bajada
		if not en_bajada:
			break
	comprobar(rivales.all(func(m: Node2D) -> bool: return is_instance_valid(m) and m in r.terreno.melones and not m.en_bajada), "Los mismos rivales continúan después del trampolín")
	for i in 120:
		await physics_frame
	comprobar(rivales.all(func(m: Node2D) -> bool: return is_instance_valid(m) and m.position.x > config.bajada_fin.x + 150.0), "Los rivales salen del trampolín a la calle sin atorarse")
	r.terreno.actualizar(10000.0)
	comprobar(r.terreno.melones.size() > config.rivales_salida, "El camino añade nuevos melones después de la parrilla")
	juego.melones_guardados.assign(coleccion)
