extends Node
## Autoload "Juego": el progreso del jugador, compartido por todas las pantallas.
##
## Guarda lo que debe sobrevivir al cambiar de escena o cerrar el juego:
## aplausos, mejoras, accesorios, aspecto del melón, récord y pasaporte.
## También calcula las recompensas de cada carrera (registrar_intento).
##
## El progreso se escribe en user://progreso.json (ver guardar() y cargar()).
## Las reglas y precios no viven aquí, sino en Config.

const ARCHIVO := "user://progreso.json"

# --- Guardado ----------------------------------------------------------------
var archivo_guardado := ARCHIVO         # las pruebas lo cambian para no tocar el real
var guardado_error := ""                # mensaje para el taller; vacío = todo bien
var _guardado_bloqueado := false        # true si no se pudo respaldar un archivo dañado

# --- Progreso ----------------------------------------------------------------
var aplausos := 0                       # moneda del juego
var record_m := 0.0
var niveles := {"fuerza": 0, "resistencia": 0, "rebotes": 0}
var desbloqueados: Array = []           # ids de accesorios comprados
var visitados: Array = []               # ids de postales del pasaporte
var intentos := 0
var ultimo: Dictionary = {}             # desglose de la última carrera (pantalla Resultados)

# --- Melón elegido en el taller ----------------------------------------------
var nombre_melon := "Melón"
var tamano := 1                         # índice en Config.tamanos
var accesorios: Array = []              # ids equipados, en orden de tecla 1-2-3

# --- Aspecto (índices en las listas de Config) -------------------------------
var piel := 0
var patron := 0
var cara := 0
var detalle := 0
var estela := 0
var cuerpo_propio := ""                 # color html; vacío = el de la piel
var rayas_propio := ""
# Dibujo libre: [{"color": Color, "grosor": float, "puntos": PackedVector2Array}]
# en unidades del radio, así sirve para cualquier tamaño y gira con el melón.
var dibujo: Array = []


func _ready() -> void:
	aplausos = Config.aplausos_iniciales
	desbloqueados = Config.accesorios_iniciales.duplicate()
	accesorios = ["llantitas", "rebozo"]
	cargar()


# --- Consultas ---------------------------------------------------------------

## Suma el carisma de una lista de accesorios (los null se ignoran).
func carisma_de(ids: Array) -> int:
	var total := 0
	for id in ids:
		if id != null and Config.accesorios.has(id):
			total += Config.accesorios[id].carisma
	return total


## Color del cuerpo: el propio si se eligió uno, si no el de la piel.
func color_cuerpo() -> Color:
	return Color.from_string(cuerpo_propio, Config.pieles[piel]["cuerpo"])


func color_rayas() -> Color:
	return Color.from_string(rayas_propio, Config.pieles[piel]["rayas"])


# --- Compras -----------------------------------------------------------------

## Precio del siguiente nivel: costo_base * crecimiento^nivel.
func costo_mejora(id: String) -> int:
	var m: Dictionary = Config.mejoras[id]
	return int(round(float(m["costo_base"]) * pow(float(m["crecimiento"]), niveles[id])))


func mejora_al_max(id: String) -> bool:
	return niveles[id] >= int(Config.mejoras[id]["max"])


## Sube un nivel la mejora si hay saldo. Devuelve false si no se pudo.
func comprar_mejora(id: String) -> bool:
	if not Config.mejoras.has(id) or mejora_al_max(id) or aplausos < costo_mejora(id):
		return false
	aplausos -= costo_mejora(id)
	niveles[id] += 1
	guardar()
	return true


## Compra un accesorio. Devuelve false si ya estaba o no alcanza el saldo.
func desbloquear(id: String) -> bool:
	if not Config.accesorios.has(id):
		return false
	var costo: int = Config.accesorios[id].costo
	if id in desbloqueados or aplausos < costo:
		return false
	aplausos -= costo
	desbloqueados.append(id)
	guardar()
	return true


# --- Valores derivados de las mejoras ----------------------------------------

## Multiplicador de la velocidad de lanzamiento.
func mult_fuerza() -> float:
	return 1.0 + niveles["fuerza"] * Config.fuerza_por_nivel


## Golpes que aguanta el melón con el tamaño elegido.
func resistencia_max() -> float:
	return float(Config.tamanos[tamano]["resistencia"]) + niveles["resistencia"] * Config.resistencia_por_nivel


## Cargas de salto y rebote impulsado al empezar cada carrera.
func rebotes_max() -> int:
	return Config.rebotes_base + niveles["rebotes"] * Config.rebotes_por_nivel


# --- Fin de carrera ----------------------------------------------------------

## Calcula y cobra los aplausos de una carrera, marca las postales nuevas,
## actualiza el récord y guarda. El desglose queda en "ultimo".
func registrar_intento(distancia_m: float, carisma: int, recolectados: int, roto: bool, poderes := 0, altura_m := 0.0) -> void:
	distancia_m = maxf(0.0, distancia_m)
	altura_m = maxf(0.0, altura_m)
	var por_distancia := int(distancia_m * Config.aplausos_por_metro)
	var por_altura := int(altura_m * Config.aplausos_por_metro_altura)
	var por_carisma := carisma * Config.aplausos_por_carisma
	var por_recolectados := recolectados * Config.valor_aplauso_suelto
	var nuevas: Array = []
	for postal in Config.postales:
		if distancia_m >= float(postal["metros"]) and postal["id"] not in visitados:
			visitados.append(postal["id"])
			nuevas.append(postal["nombre"])
	var por_visitas: int = nuevas.size() * Config.bonus_postal
	var total := por_distancia + por_altura + por_carisma + por_recolectados + por_visitas
	var nuevo := distancia_m > record_m
	if nuevo:
		record_m = distancia_m
	aplausos += total
	intentos += 1
	ultimo = {
		"distancia": distancia_m, "record_nuevo": nuevo, "carisma": carisma,
		"recolectados": recolectados, "roto": roto, "por_distancia": por_distancia,
		"por_carisma": por_carisma, "por_recolectados": por_recolectados, "total": total,
		"por_visitas": por_visitas, "visitas_nuevas": nuevas, "poderes": poderes,
		"altura": altura_m, "por_altura": por_altura,
	}
	guardar()


## Vuelve a los valores de una partida nueva y los guarda: aplausos, récord,
## mejoras, accesorios, postales, intentos, aspecto y dibujo. Pensado para
## probar el juego desde cero (botón "Reiniciar progreso" del taller).
func reiniciar_progreso() -> void:
	aplausos = Config.aplausos_iniciales
	record_m = 0.0
	niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	desbloqueados = Config.accesorios_iniciales.duplicate()
	visitados = []
	intentos = 0
	ultimo = {}
	nombre_melon = "Melón"
	tamano = 1
	accesorios = ["llantitas", "rebozo"]
	piel = 0
	patron = 0
	cara = 0
	detalle = 0
	estela = 0
	cuerpo_propio = ""
	rayas_propio = ""
	dibujo = []
	_guardado_bloqueado = false
	guardar()


# --- Guardar y cargar --------------------------------------------------------

## Escribe el progreso en un archivo temporal y luego lo renombra, así un
## cierre inesperado nunca deja el guardado a medias.
func guardar() -> void:
	if _guardado_bloqueado:
		return
	var datos := {"version": 1, "aplausos": aplausos, "record_m": record_m,
		"niveles": niveles, "desbloqueados": desbloqueados, "tamano": tamano,
		"accesorios": accesorios, "piel": piel, "cara": cara, "estela": estela,
		"patron": patron, "detalle": detalle, "cuerpo_propio": cuerpo_propio,
		"rayas_propio": rayas_propio, "dibujo": _dibujo_a_json(),
		"nombre_melon": nombre_melon, "visitados": visitados, "intentos": intentos}
	var temporal := archivo_guardado + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		guardado_error = "No se pudo guardar el progreso. Revisa el espacio y los permisos de la carpeta de usuario."
		return
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.flush()
	var error := archivo.get_error()
	archivo.close()
	if error != OK or DirAccess.rename_absolute(temporal, archivo_guardado) != OK:
		guardado_error = "No se pudo terminar el guardado. Tu progreso sigue en esta sesión."
		return
	guardado_error = ""


## Lee el progreso. Cada valor se valida: los índices se limitan, los ids
## desconocidos se descartan y un archivo ilegible se respalda como ".danado-*".
func cargar() -> void:
	if not FileAccess.file_exists(archivo_guardado):
		return
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(archivo_guardado))
	var datos = parser.data if error == OK else null
	if not datos is Dictionary:
		var respaldo := archivo_guardado + ".danado-" + str(Time.get_unix_time_from_system()).replace(".", "-")
		if DirAccess.rename_absolute(archivo_guardado, respaldo) == OK:
			guardado_error = "No se pudo leer el guardado. Guardamos una copia dañada en la carpeta de usuario."
		else:
			guardado_error = "No se pudo leer ni respaldar el guardado. El archivo original no se modificará."
			_guardado_bloqueado = true
		return
	aplausos = _entero(datos, "aplausos", 0, 0, 100000000)
	if datos.get("record_m") is float or datos.get("record_m") is int:
		record_m = clampf(float(datos["record_m"]), 0.0, 10000000.0)
	intentos = _entero(datos, "intentos", 0, 0, 10000000)
	tamano = _entero(datos, "tamano", 1, 0, Config.tamanos.size() - 1)
	piel = _entero(datos, "piel", 0, 0, Config.pieles.size() - 1)
	cara = _entero(datos, "cara", 0, 0, Config.caras.size() - 1)
	estela = _entero(datos, "estela", 0, 0, Config.estelas.size() - 1)
	patron = _entero(datos, "patron", 0, 0, Config.patrones.size() - 1)
	detalle = _entero(datos, "detalle", 0, 0, Config.detalles.size() - 1)
	cuerpo_propio = ""
	rayas_propio = ""
	for clave in ["cuerpo_propio", "rayas_propio"]:
		if datos.get(clave) is String and Color.html_is_valid(datos[clave]):
			set(clave, datos[clave])
	dibujo = _dibujo_de_json(datos.get("dibujo"))
	if datos.get("nombre_melon") is String:
		nombre_melon = String(datos["nombre_melon"]).strip_edges().left(24)
		if nombre_melon.is_empty():
			nombre_melon = "Melón"
	var guardados = datos.get("niveles", {})
	if guardados is Dictionary:
		for id in Config.orden_mejoras:
			niveles[id] = _entero(guardados, id, 0, 0, int(Config.mejoras[id]["max"]))
	desbloqueados = Config.accesorios_iniciales.duplicate()
	if datos.get("desbloqueados") is Array:
		for id in datos["desbloqueados"]:
			if id is String and Config.accesorios.has(id) and id not in desbloqueados:
				desbloqueados.append(id)
	accesorios.clear()
	if datos.get("accesorios") is Array:
		for id in datos["accesorios"]:
			if id in desbloqueados and id not in accesorios and accesorios.size() < Config.max_accesorios:
				accesorios.append(id)
	visitados.clear()
	if datos.get("visitados") is Array:
		for postal in Config.postales:
			if postal["id"] in datos["visitados"]:
				visitados.append(postal["id"])
	guardado_error = ""


## Lee un entero del diccionario y lo limita; si no es un número usa el defecto.
func _entero(datos: Dictionary, clave: String, defecto: int, minimo: int, maximo: int) -> int:
	var valor = datos.get(clave, defecto)
	if not valor is float and not valor is int:
		return defecto
	return clampi(int(valor), minimo, maximo)


## Convierte Juego.dibujo a datos simples para JSON: {c: color, g: grosor, p: [x, y, ...]}.
func _dibujo_a_json() -> Array:
	var salida: Array = []
	for trazo in dibujo:
		var plano: Array = []
		for p in trazo["puntos"]:
			plano.append_array([snappedf(p.x, 0.001), snappedf(p.y, 0.001)])
		salida.append({"c": (trazo["color"] as Color).to_html(false), "g": snappedf(trazo["grosor"], 0.001), "p": plano})
	return salida


## Inverso de _dibujo_a_json(). Descarta trazos dañados y respeta los límites de Config.
func _dibujo_de_json(datos: Variant) -> Array:
	var salida: Array = []
	if not datos is Array:
		return salida
	var total := 0
	for t in datos:
		if salida.size() >= Config.max_trazos or not t is Dictionary:
			break
		if not t.get("c") is String or not Color.html_is_valid(t["c"]) or not t.get("p") is Array:
			continue
		var g = t.get("g", 0.08)
		if not g is float and not g is int:
			continue
		var puntos := PackedVector2Array()
		var plano: Array = t["p"]
		for i in range(0, plano.size() - 1, 2):
			if (plano[i] is float or plano[i] is int) and (plano[i + 1] is float or plano[i + 1] is int):
				puntos.append(Vector2(plano[i], plano[i + 1]).limit_length(1.0))
		if puntos.is_empty() or total + puntos.size() > Config.max_puntos_dibujo:
			continue
		total += puntos.size()
		salida.append({"color": Color.html(t["c"]), "puntos": puntos,
			"grosor": clampf(float(g), Config.grosor_dibujo.x, Config.grosor_dibujo.y)})
	return salida
