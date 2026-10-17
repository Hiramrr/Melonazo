extends SceneTree
## Rivales que juegan como el jugador: vuelan, recogen poderes y papalotes, hacen
## slam entre ellos y se rompen. Nunca escribe en el guardado del jugador.

const SEMILLAS := [1509, 42, 7301]
const SEGUNDOS := 50.0
const DT := 1.0 / 120.0
const EDAD_CORTE := 10.0              # s de vida a los que se mide cuántos siguen enteros

var config: Node
var juego: Node
var comprobaciones := 0
var fallos := 0

# Métricas acumuladas de todas las carreras.
var pasos_vivos := 0
var pasos_aire := 0
var maniobras := {}
var avisos := 0
var rotos := 0
var aplastados := 0                   # usado pasó a true sin slam del jugador: slam de un rival
var vistos := 0
var llegaron_corte := 0
var enteros_corte := 0
var metros_max := 0.0
var papalote_cerca := INF             # menor distancia de un rival entero a un papalote libre
var papalotes_libres := 0             # pasos en que algún papalote libre quedó a menos de 400 px


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _verificar() -> void:
	config = root.get_node("Config")
	juego = root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_rivales_%d.json" % OS.get_process_id()
	juego.valentinas = 0
	juego.melones_guardados.clear()
	juego.niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	juego.accesorios = []
	var api := _revisar_api()
	if api:
		for semilla in SEMILLAS:
			await carrera(semilla)
		var aire := float(pasos_aire) / maxf(1.0, pasos_vivos)
		var vivos_corte := float(enteros_corte) / maxf(1.0, llegaron_corte)
		var poderes := 0
		var papalotes := 0
		var slams := 0
		for tipo in maniobras:
			var t := String(tipo).to_lower()
			if t.contains("poder") or t in ["chile", "cafe", "café", "pizza"]:
				poderes += maniobras[tipo]
			elif t.contains("papalote"):
				papalotes += maniobras[tipo]
			elif t.contains("slam"):
				slams += maniobras[tipo]
		print("Rivales: %d vistos en %d carreras de %.0f s. Aire %.2f del tiempo vivo, %d rotos, %d aplastados por rivales, %.0f m máximo." % [vistos, SEMILLAS.size(), SEGUNDOS, aire, rotos, aplastados, metros_max])
		print("Rivales: a los %.0f s de vida siguen enteros %d/%d (%.2f). Avisos %d. Maniobras %s." % [EDAD_CORTE, enteros_corte, llegaron_corte, vivos_corte, avisos, str(maniobras)])
		print("Rivales: papalote libre más cercano %.0f px (rango %.0f); %d muestras a menos de 400 px." % [papalote_cerca, config.papalote_rango, papalotes_libres])
		comprobar(aire >= 0.6, "Los rivales pasan la mayor parte del tiempo en el aire: %.2f" % aire)
		comprobar(poderes > 0, "Algún rival recoge un poder")
		comprobar(papalotes > 0, "Algún rival usa un papalote")
		comprobar(slams > 0 or aplastados > 0, "Algún rival hace slam a otro")
		comprobar(rotos > 0, "Algún rival se rompe")
		comprobar(llegaron_corte > 0 and vivos_corte >= 0.5, "No se rompen todos de golpe: %.2f enteros a los %.0f s" % [vivos_corte, EDAD_CORTE])
		await probar_dano()
		await probar_sin_saltos()
	if FileAccess.file_exists(juego.archivo_guardado):
		DirAccess.remove_absolute(juego.archivo_guardado)
	print("Rivales: %d comprobaciones, %d fallos." % [comprobaciones, fallos])
	quit(1 if fallos else 0)


## Falla con un mensaje claro si la API acordada todavía no existe o no compila.
func _revisar_api() -> bool:
	# El generador primero: precarga la escena del rival, como al abrir el recorrido.
	# Al revés, el ciclo de precargas deja la escena del rival sin script.
	var ok := _revisar_script("res://mundo/terreno/generador_terreno.gd",
		["objetivos_rival", "actualizar_melones"], ["rival_aviso"], ["melones"])
	ok = _revisar_script("res://mundo/ayudas/melon_rodante.gd",
		["terminado", "recibir_poder", "impulsar_papalote", "frenar", "danar", "recibir_slam_rival", "avanzar"],
		["se_rompio", "maniobra"], ["roto", "resistencia", "slam_activo", "usado", "en_suelo", "saltos"]) and ok
	return ok


func _revisar_script(ruta: String, metodos: Array, senales: Array, propiedades: Array) -> bool:
	var script := load(ruta) as GDScript
	if script == null or not script.can_instantiate():
		comprobar(false, "%s no compila" % ruta)
		return false
	var nombres := {}
	for d in script.get_script_method_list():
		nombres["m:" + d["name"]] = true
	for d in script.get_script_signal_list():
		nombres["s:" + d["name"]] = true
	for d in script.get_script_property_list():
		nombres["p:" + d["name"]] = true
	var ok := true
	for n in metodos:
		if not nombres.has("m:" + n):
			ok = false
			comprobar(false, "%s no tiene func %s()" % [ruta, n])
	for n in senales:
		if not nombres.has("s:" + n):
			ok = false
			comprobar(false, "%s no tiene signal %s" % [ruta, n])
	for n in propiedades:
		if not nombres.has("p:" + n):
			ok = false
			comprobar(false, "%s no tiene var %s" % [ruta, n])
	return ok


## Recorrido sin jugar: el jugador no colisiona ni hace slam; solo marca dónde se generan
## y se borran las cosas, y sigue a los rivales para que no queden atrás.
func preparar(semilla: int):
	config.semilla_terreno = semilla
	seed(semilla)
	juego.tamano = 1
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_process(false)
	r.set_physics_process(false)
	var m = r.melon
	m.set_physics_process(false)
	m.freeze = true
	m.controlable = false
	m.slam_activo = false
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for i in r.terreno.melones.size():
		var rival = r.terreno.melones[i]
		var x: float = 700.0 + i * 500.0
		rival.en_bajada = false
		rival.preparar_carrera(rng.randf_range(config.velocidad_melones.x, config.velocidad_melones.y), rng.randi())
		rival.position = Vector2(x, r.terreno.tramos[0].altura(x) - rival.radio)
		rival.anterior = rival.position
		rival.velocidad = Vector2(rival.rapidez, 0)
		rival.en_suelo = true
	r.fase = 2
	return r


func colocar_jugador(r, x: float) -> void:
	var tramo = r.terreno.tramo_en(x)
	var y: float = (tramo.altura(x) if tramo != null else 0.0) - 2500.0
	r.melon.position = Vector2(x, y)
	r.melon.linear_velocity = Vector2.ZERO


func carrera(semilla: int) -> void:
	var r = await preparar(semilla)
	var info := {}                    # instance_id -> {"nacio": t, "rival": nodo, "usado": bool, "roto": bool}
	r.terreno.rival_aviso.connect(func(_texto, _posicion) -> void: avisos += 1)
	var x_jugador := 0.0
	var t := 0.0
	var pasos := int(SEGUNDOS / DT)
	for paso in pasos:
		t = paso * DT
		# Registra rivales nuevos.
		for rival in r.terreno.melones:
			var id: int = rival.get_instance_id()
			if id in info:
				continue
			vistos += 1
			info[id] = {"nacio": t, "rival": rival, "usado": rival.usado, "roto": rival.roto, "corte": false}
			rival.maniobra.connect(func(_quien, tipo: String) -> void:
				maniobras[tipo] = maniobras.get(tipo, 0) + 1)
		# El jugador sigue al rival entero más rezagado que aún va por delante de él, sin retroceder.
		var xs: Array[float] = []
		for rival in r.terreno.melones:
			if not rival.roto:
				xs.append(rival.global_position.x)
		xs.sort()
		var objetivo := x_jugador + 900.0 * DT
		if xs.size() > 0:
			objetivo = xs[xs.size() / 2] - 400.0
		x_jugador = maxf(x_jugador, minf(objetivo, x_jugador + 3000.0 * DT))
		colocar_jugador(r, x_jugador)
		r.terreno.actualizar(x_jugador)
		r.terreno.actualizar_melones(r.melon, DT)
		await physics_frame
		for id in info:
			var d: Dictionary = info[id]
			var rival = d["rival"]
			if not is_instance_valid(rival) or rival not in r.terreno.melones:
				continue
			metros_max = maxf(metros_max, rival.global_position.x / config.px_por_metro)
			if not rival.roto:
				pasos_vivos += 1
				pasos_aire += int(not rival.en_suelo)
				if paso % 6 == 0:
					medir_papalotes(r, rival)
			if rival.usado and not d["usado"]:
				aplastados += 1
			d["usado"] = rival.usado
			if rival.roto and not d["roto"]:
				rotos += 1
			d["roto"] = rival.roto
			if not d["corte"] and t - d["nacio"] >= EDAD_CORTE:
				d["corte"] = true
				llegaron_corte += 1
				enteros_corte += int(not rival.roto)
	print("Carrera semilla %d: jugador en %.0f m, %d rivales vistos, %d en juego al final." % [semilla, x_jugador / config.px_por_metro, info.size(), r.terreno.melones.size()])


func medir_papalotes(r, rival) -> void:
	for tramo in r.terreno.tramos:
		if tramo.x1 < rival.global_position.x - 400.0 or tramo.x0 > rival.global_position.x + 400.0:
			continue
		for p in tramo.papalotes:
			if is_instance_valid(p) and not p.usado:
				var d: float = p.global_position.distance_to(rival.global_position)
				papalote_cerca = minf(papalote_cerca, d)
				papalotes_libres += int(d < 400.0)


## danar(99) rompe al rival; al terminar su animación el generador lo libera.
func probar_dano() -> void:
	var r = await preparar(SEMILLAS[0])
	if r.terreno.melones.is_empty():
		comprobar(false, "No hay rivales para probar danar()")
		return
	var rival = r.terreno.melones[0]
	var senal := {"rompio": false}
	rival.se_rompio.connect(func(_quien) -> void: senal["rompio"] = true)
	colocar_jugador(r, rival.global_position.x - 300.0)
	rival.danar(99.0)
	comprobar(rival.roto, "danar(99) rompe al rival")
	var termino := false
	var liberado := false
	for i in 10 * 120:
		r.terreno.actualizar_melones(r.melon, DT)
		await physics_frame
		if not is_instance_valid(rival):
			termino = true
			liberado = true
			break
		termino = termino or rival.terminado()
		if rival not in r.terreno.melones:
			liberado = true
			break
	comprobar(senal["rompio"], "Romperse emite se_rompio")
	comprobar(termino, "Un rival roto termina")
	comprobar(liberado, "El generador libera al rival que terminó")


## Con saltos = false el rival solo rueda: no salta, no juega y no se rompe al detenerse.
func probar_sin_saltos() -> void:
	var r = await preparar(SEMILLAS[1])
	for tramo in r.terreno.tramos:
		for contenedor in ["Coleccionables", "Obstaculos", "Aire"]:
			for nodo in tramo.get_node(contenedor).get_children():
				nodo.queue_free()
		tramo.papalotes.clear()
	await process_frame
	if r.terreno.melones.size() < 2:
		comprobar(false, "No hay rivales para probar saltos = false")
		return
	var quieto = r.terreno.melones[0]
	var rodante = r.terreno.melones[1]
	for rival in [quieto, rodante]:
		rival.saltos = false
		rival.en_suelo = true
	quieto.rapidez = 0.0
	quieto.velocidad = Vector2.ZERO
	var altura_max := 0.0
	var maniobras_sin_ia := {"n": 0}
	for rival in [quieto, rodante]:
		rival.maniobra.connect(func(_quien, _tipo) -> void: maniobras_sin_ia["n"] += 1)
	for i in 8 * 120:
		for rival in [quieto, rodante]:
			rival.avanzar(r.terreno, DT, rival.position + Vector2(0, -2500))
			var tramo = r.terreno.tramo_en(rival.position.x)
			if tramo != null:
				altura_max = maxf(altura_max, tramo.altura(rival.position.x) - rival.radio - rival.position.y)
	comprobar(not quieto.roto and not quieto.terminado(), "Sin IA un rival detenido no se rompe")
	comprobar(not rodante.roto, "Sin IA un rival rodando no se rompe")
	comprobar(altura_max < 60.0, "Sin IA el rival no salta: %.0f px" % altura_max)
	comprobar(maniobras_sin_ia["n"] == 0, "Sin IA no hay maniobras")
	print("Sin saltos: altura máxima %.0f px, quieto avanzó %.0f px." % [altura_max, quieto.position.x - 700.0])
