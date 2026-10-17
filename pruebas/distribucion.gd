extends SceneTree
## Comprueba cobertura del cielo, variedad y aislamiento del azar del suelo.

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
	var config := root.get_node("Config")
	config.generar_adelante = config.meta_m * config.px_por_metro
	var franjas: Array = config.franjas_premios_aire.duplicate()
	for semilla in [1509, 42, 7301, 7, 99, 2026]:
		config.semilla_terreno = semilla
		var normal := generar(true)
		var repetida := generar(false)
		comprobar(normal == repetida, "Una semilla repite exactamente la distribución")
		config.franjas_premios_aire = []
		var sin_premios := generar(false)
		config.franjas_premios_aire = franjas
		comprobar(normal["suelo"] == sin_premios["suelo"], "Los premios aéreos no cambian terreno ni objetos del suelo")
		comprobar(normal["papalotes"] == sin_premios["papalotes"], "Los premios no desplazan los papalotes")
	config.semilla_terreno = -1
	comprobar(generar(false) != generar(false), "Los intentos normales tienen distribuciones diferentes")
	print("Distribución: %d comprobaciones, %d fallos." % [comprobaciones, fallos])
	quit(1 if fallos else 0)


func generar(revisar: bool) -> Dictionary:
	var config := root.get_node("Config")
	var terreno = load("res://mundo/terreno/generador_terreno.gd").new()
	root.add_child(terreno)
	terreno.iniciar()
	var suelo: Array = []
	var aire: Array = []
	var papalotes: Array = []
	var tipos: Dictionary = {}
	var rutas: Array = []
	for franja in config.franjas_premios_aire:
		rutas.append([])
	var ultimo_x := -1.0
	var monedas_bajas: Array[float] = []
	var monedas: Array[Vector2] = []
	var poderes_bajos: Array[float] = []
	var pajaros: Array[Vector2] = []
	for tramo in terreno.tramos:
		suelo.append([tramo.puntos, tramo.empedrado, tramo.casas])
		for contenedor in ["Obstaculos", "Coleccionables", "Publico"]:
			for nodo in tramo.get_node(contenedor).get_children():
				suelo.append([nodo.scene_file_path, nodo.position, nodo.rotation])
				if contenedor != "Coleccionables":
					continue
				var altura: float = tramo.altura(nodo.position.x) - nodo.position.y
				if nodo.scene_file_path.ends_with("/aplauso.tscn"):
					monedas_bajas.append(nodo.position.x)
					monedas.append(nodo.position)
					if revisar:
						comprobar(altura >= config.altura_aplausos.x and altura <= config.altura_aplausos.y + 25.0, "Las monedas bajas quedan al alcance de un salto corto")
				elif nodo.scene_file_path.ends_with("/poder.tscn"):
					poderes_bajos.append(nodo.position.x)
					if revisar:
						comprobar(altura >= config.altura_poderes.x and altura <= config.altura_poderes.y, "Los poderes quedan visibles y requieren saltar")
		for p in tramo.papalotes:
			papalotes.append([p.position, p.corriente])
			if revisar and ultimo_x >= 0:
				var distancia: float = p.position.x - ultimo_x
				comprobar(distancia >= config.separacion_papalotes.x and distancia <= config.separacion_papalotes.y, "Los papalotes conservan su separación entre tramos")
			if revisar:
				var altura_papalote: float = tramo.altura(p.position.x) - p.position.y
				comprobar(altura_papalote >= config.altura_papalotes.x - 0.01 and altura_papalote <= config.altura_papalotes.y + 0.01, "Las ayudas ascienden sin salir del cielo jugable")
			ultimo_x = p.position.x
		for nodo in tramo.get_node("Aire").get_children():
			if nodo.scene_file_path.ends_with("/pajaro.tscn"):
				pajaros.append(nodo.position)
				continue
			var es_poder: bool = nodo.scene_file_path.ends_with("/poder.tscn")
			if nodo.scene_file_path.ends_with("/aplauso.tscn"):
				monedas.append(nodo.position)
			aire.append([nodo.scene_file_path, nodo.position, nodo.tipo if es_poder else ""])
			if not revisar or nodo.scene_file_path.ends_with("/papalote.tscn"):
				continue
			if es_poder:
				tipos[nodo.tipo] = true
			var altura: float = tramo.altura(nodo.position.x) - nodo.position.y
			var franja := 0
			for i in range(1, config.franjas_premios_aire.size()):
				var limites: Vector2 = config.franjas_premios_aire[i]
				if altura >= limites.x - 120.0:
					franja = i
			rutas[franja].append(nodo.position.x)
			if altura > 900.0:
				comprobar(nodo.position.x >= tramo.x0 and nodo.position.x <= tramo.x1, "Los premios altos quedan dentro del tramo que los conserva")
	if revisar:
		comprobar(monedas.size() <= terreno._fin.x / 1000.0 * 12, "La cantidad total de monedas no vuelve a saturar el recorrido")
		for moneda in monedas:
			var cercanas := 0
			for otra in monedas:
				if absf(otra.x - moneda.x) <= 750.0 and absf(otra.y - moneda.y) <= 500.0:
					cercanas += 1
			comprobar(cercanas <= 16, "Una vista de juego no contiene más de 16 monedas")
		comprobar(monedas_bajas.size() > 0 and monedas_bajas[0] < 1000.0, "Hay monedas visibles desde el primer lanzamiento")
		comprobar(poderes_bajos.size() > 0 and poderes_bajos[0] == config.primer_poder_x and poderes_bajos[0] < 1000.0, "El primer poder aparece antes de cien metros")
		for i in range(1, monedas_bajas.size()):
			comprobar(monedas_bajas[i] - monedas_bajas[i - 1] < 2000.0, "Las monedas mantienen grupos separados a lo largo de la calle")
		for i in range(1, poderes_bajos.size()):
			var anterior := poderes_bajos[i - 1]
			var holgura: float = lerpf(1.0, config.escasez_poderes, terreno.dificultad(anterior))
			var separacion := poderes_bajos[i] - anterior
			comprobar(separacion >= config.separacion_poderes.x * holgura - 0.01 and separacion <= config.separacion_poderes.y * holgura + 0.01, "Los poderes se espacian gradualmente sin huecos extra entre tramos")
		comprobar(not pajaros.is_empty() and pajaros[0].x >= config.primer_pajaro_x, "Los pájaros aparecen después de la salida")
		for pajaro in pajaros:
			comprobar(pajaro.x <= config.meta_m * config.px_por_metro + 200.0, "No hay pájaros después de la meta")
		comprobar(papalotes.size() < terreno._fin.x / 900.0, "La densidad de papalotes baja respecto a la ruta anterior")
		comprobar(tipos.size() == config.orden_poderes.size(), "Todos los poderes aparecen en el cielo")
		for ruta in rutas:
			ruta.sort()
			comprobar(ruta.size() >= 18, "Todas las alturas tienen puntos a lo largo del recorrido")
			comprobar(ruta[0] < 2500.0 and ruta[-1] > terreno._fin.x - 2300.0, "Las rutas altas cubren tanto el inicio como el final generado")
			for i in range(1, ruta.size()):
				comprobar(ruta[i] - ruta[i - 1] <= 2600.0, "La separación de premios respeta los huecos previstos en cada franja")
	root.remove_child(terreno)
	terreno.free()
	return {"suelo": suelo, "aire": aire, "papalotes": papalotes}
