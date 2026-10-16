extends SceneTree
## Saltos y papalotes con física real, sin modificar el progreso del jugador.

var juego: Node
var config: Node
var comprobaciones := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _verificar() -> void:
	juego = root.get_node("Juego")
	config = root.get_node("Config")
	juego.archivo_guardado = "user://prueba_vuelo_%d.json" % OS.get_process_id()
	juego.tamano = 1
	juego.niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	var melon = load("res://melon/melon.tscn").instantiate()
	root.add_child(melon)
	melon.freeze = true
	melon.set_physics_process(false)
	melon.configurar(1, [], juego.resistencia_max(), juego.rebotes_max())
	melon.controlable = true
	melon.linear_velocity = Vector2(300, 500)
	comprobar(melon.saltar() and melon.rebotes == juego.rebotes_max() - 1, "Saltar consume una carga")
	comprobar(melon.linear_velocity.y + melon._dv.y <= -config.salto_aereo_vel, "El salto frena la caída y eleva al melón")
	comprobar(not melon.saltar(), "No se puede repetir el salto durante su bloqueo")
	melon.t_bloqueo = 0.0
	melon.rebotes = 0
	comprobar(not melon.saltar(), "No hay saltos sin cargas")
	var papalote = load("res://mundo/ayudas/papalote.tscn").instantiate()
	root.add_child(papalote)
	papalote.position = Vector2(config.papalote_rango + 10, 0)
	comprobar(not papalote.impulsar(melon) and not papalote.usado, "E no alcanza papalotes lejanos")
	papalote.position = melon.position
	melon.controlable = false
	comprobar(not papalote.impulsar(melon), "El papalote no funciona antes de lanzar ni al terminar")
	melon.controlable = true
	melon._dv = Vector2.ZERO
	comprobar(papalote.impulsar(melon) and melon.rebotes == 0 and melon.escudo, "El papalote impulsa y protege sin regalar saltos")
	var impulso: Vector2 = melon._dv
	comprobar(not papalote.impulsar(melon) and melon._dv == impulso, "Cada papalote funciona una sola vez")
	melon.t_bloqueo = 0.0
	melon.rebotes = 1
	comprobar(melon.saltar() and is_equal_approx(melon.linear_velocity.y + melon._dv.y, -config.papalote_elevacion), "Pulsar Espacio y E juntos no duplica el impulso vertical")
	var otro = load("res://mundo/ayudas/papalote.tscn").instantiate()
	root.add_child(otro)
	melon.rebotes = juego.rebotes_max() + 1
	melon._dv = Vector2.ZERO
	melon.linear_velocity = Vector2(config.papalote_avance + 200.0, -config.papalote_elevacion - 200.0)
	otro.impulsar(melon)
	comprobar(melon.rebotes == juego.rebotes_max() + 1, "El papalote conserva las cargas extra sin sumar más del máximo")
	comprobar(melon._dv == Vector2.ZERO, "Un papalote no frena un vuelo que ya supera su impulso")
	melon.position = Vector2(0, -4000)
	melon.linear_velocity = Vector2(300, 0)
	melon.freeze = false
	Input.action_press("derecha")
	for i in 48:
		await physics_frame
	Input.action_release("derecha")
	var velocidad_derecha: float = melon.linear_velocity.x
	comprobar(velocidad_derecha > 300 and melon.angular_velocity > 0, "D permite avanzar y girar en el aire")
	Input.action_press("izquierda")
	for i in 48:
		await physics_frame
	Input.action_release("izquierda")
	comprobar(melon.linear_velocity.x < velocidad_derecha - 50 and melon.angular_velocity < 0, "A permite frenar y girar en el aire")
	melon.queue_free()
	papalote.queue_free()
	otro.queue_free()
	await process_frame
	var puntos_altos := 0
	for semilla in [1509, 42, 7301]:
		config.semilla_terreno = semilla
		for tamano in 3:
			for mover in [false, true]:
				var r: Dictionary = await carrera(tamano, mover)
				print("Vuelo semilla %d, tamaño %d, D %s: %.0f m, altura %.0f m, %.1f s sobre 40 m, %d papalotes, %d puntos recogidos sobre 40 m." % [semilla, tamano, mover, r["metros"], r["altura"], r["en_alto"], r["papalotes"], r["puntos_altos"]])
				comprobar(r["papalotes"] >= 2, "Se pueden encadenar ayudas aéreas sin mejoras")
				comprobar(r["termino"] and r["metros"] < 2500.0, "La ruta aérea termina al perder los impulsos, incluso manteniendo D")
				comprobar(r["altura"] >= 140.0 and r["en_alto"] >= 6.0, "Sin mejoras se puede subir a la niebla y sostener el vuelo")
				puntos_altos += r["puntos_altos"]
	comprobar(puntos_altos > 0, "Los puntos altos se recogen durante un vuelo real sin mejoras")
	juego.niveles = {"fuerza": 6, "resistencia": 5, "rebotes": 5}
	var alcance_mejorado := 0.0
	var llegadas := 0
	for semilla in [1509, 42, 7301]:
		config.semilla_terreno = semilla
		for mover in [false, true]:
			var r: Dictionary = await carrera(1, mover)
			print("Vuelo con mejoras máximas, semilla %d, D %s: %.0f m, %d papalotes." % [semilla, mover, r["metros"], r["papalotes"]])
			comprobar(r["termino"] and r["metros"] < 3500.0, "Con mejoras máximas los controles básicos tampoco mantienen un vuelo sin fin")
			alcance_mejorado = maxf(alcance_mejorado, r["metros"])
			if r["llegada"]:
				llegadas += 1
				comprobar(r["duracion"] >= 30.0, "El viaje completo requiere al menos medio minuto de juego")
				print("Llegada al CUCosta en %.1f s, sin accesorios." % r["duracion"])
	comprobar(alcance_mejorado >= config.meta_m and llegadas > 0, "Combinar mejoras, saltos y papalotes permite completar el viaje al CUCosta")
	DirAccess.remove_absolute(juego.archivo_guardado)
	DirAccess.remove_absolute(juego.archivo_guardado + ".tmp")
	print("Vuelo: %d comprobaciones, %d fallos." % [comprobaciones, fallos])
	quit(1 if fallos else 0)


func carrera(tamano: int, mover: bool) -> Dictionary:
	seed(config.semilla_terreno)
	juego.tamano = tamano
	juego.accesorios = []
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var recorrido = current_scene
	var ultimo_x := -1.0
	for tramo in recorrido.terreno.tramos:
		for p in tramo.papalotes:
			if ultimo_x >= 0:
				var separacion: float = p.position.x - ultimo_x
				comprobar(separacion >= config.separacion_papalotes.x and separacion <= config.separacion_papalotes.y, "La ruta aérea continúa entre tramos sin huecos extra")
			ultimo_x = p.position.x
	recorrido.fuerza = 0.85
	recorrido._lanzar()
	if mover:
		Input.action_press("derecha")
	var datos := {"metros": 0.0, "altura": 0.0, "en_alto": 0.0, "papalotes": 0, "puntos_altos": 0, "duracion": 0.0, "llegada": false}
	# El grande salta antes de entrar en la ventana de rebote al bajar del puente.
	var primer_salto_x: float = config.primer_papalote_x - (360.0 if tamano == 2 else 300.0)
	recorrido.terreno.obstaculo_tocado.connect(func(_cuerpo: Node2D, objeto: Node2D) -> void:
		if objeto.tipo == "aplauso":
			var tramo = recorrido.terreno.tramo_en(objeto.position.x)
			if tramo != null and tramo.altura(objeto.position.x) - objeto.position.y > 400.0:
				datos["puntos_altos"] += 1)
	for cuadro in 60 * 120:
		await physics_frame
		datos["duracion"] += 1.0 / 120.0
		Input.action_release("rebote")
		Input.action_release("empujon")
		if not is_instance_valid(recorrido) or current_scene != recorrido or recorrido.fase == 3:
			break
		if recorrido.fase == 1:
			continue
		var m = recorrido.melon
		datos["metros"] = recorrido.mejor_x / config.px_por_metro
		datos["altura"] = maxf(datos["altura"], recorrido.altura_m)
		datos["papalotes"] = recorrido.papalotes_usados
		if recorrido.altura_m >= 40:
			datos["en_alto"] += 1.0 / 120.0
		if cuadro % 2 != 0:
			continue
		var entrando_al_cielo: bool = recorrido.papalotes_usados == 0 and m.position.x > config.primer_papalote_x - 180.0
		if is_instance_valid(recorrido.papalote_cercano):
			Input.action_press("empujon")
		elif m.position.x > primer_salto_x and m.rebotes > 0 and m.t_bloqueo <= 0.0 and (m.linear_velocity.y > 100.0 or entrando_al_cielo):
			var siguiente = null
			for tramo in recorrido.terreno.tramos:
				for p in tramo.papalotes:
					if not p.usado and p.position.x >= m.position.x - 100.0 and (siguiente == null or p.position.x < siguiente.position.x):
						siguiente = p
			if siguiente != null and m.position.y > siguiente.position.y + 60.0:
				Input.action_press("rebote")
	Input.action_release("rebote")
	Input.action_release("empujon")
	Input.action_release("derecha")
	if is_instance_valid(recorrido) and current_scene == recorrido:
		datos["metros"] = recorrido.mejor_x / config.px_por_metro
		datos["llegada"] = recorrido.fase == 3 and datos["metros"] >= config.meta_m and not recorrido.melon.roto
	datos["termino"] = not is_instance_valid(recorrido) or current_scene != recorrido or recorrido.fase != 2
	return datos
