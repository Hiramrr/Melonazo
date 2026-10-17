class_name GeneradorTerreno
extends Node2D
## Crea el camino hasta la meta, tramo por tramo, y lo llena de cosas.
##
## Vive en el nodo Mundo/Terreno de pantallas/recorrido/recorrido.tscn. Cada
## tramo (mundo/terreno/tramo.tscn) se agrega como hijo de este nodo.
##
## Uso desde Recorrido:
##   iniciar()          al empezar: fija la semilla y crea los primeros tramos
##   actualizar(x)      cada paso de física: crea tramos por delante del melón y
##                      borra los que quedaron muy atrás
##   tramo_en(x)        el tramo que contiene esa x (para medir la altura)
##
## Las señales avisan cuando el melón toca algo; Recorrido decide qué pasa.
## Todos los valores (largos, separaciones, pesos) están en Config, sección Terreno.
##
## Importante: la ruta depende del orden exacto de las llamadas a rng. Si cambias
## el orden de _crear_tramo() o _poblar(), cambia el camino de cada semilla.

signal obstaculo_tocado(cuerpo: Node2D, obstaculo: Obstaculo)  ## incluye aplausos sueltos
signal poder_recogido(tipo: String)
signal pajaro_tocado(pajaro: Pajaro)

const TramoEscena := preload("res://mundo/terreno/tramo.tscn")
const PersonaEscena := preload("res://mundo/ayudas/persona.tscn")
const PoderEscena := preload("res://mundo/ayudas/poder.tscn")
const PapaloteEscena := preload("res://mundo/ayudas/papalote.tscn")
const MelonRodanteEscena := preload("res://mundo/ayudas/melon_rodante.tscn")
const PajaroEscena := preload("res://mundo/obstaculos/pajaro.tscn")
const OBSTACULOS := {
	"coladera": preload("res://mundo/obstaculos/coladera.tscn"),
	"charco": preload("res://mundo/obstaculos/charco.tscn"),
	"puesto": preload("res://mundo/obstaculos/puesto.tscn"),
	"poste": preload("res://mundo/obstaculos/poste.tscn"),
	"banqueta": preload("res://mundo/obstaculos/banqueta.tscn"),
	"rampa": preload("res://mundo/obstaculos/rampa.tscn"),
	"toldo": preload("res://mundo/obstaculos/toldo.tscn"),
	"aplauso": preload("res://mundo/obstaculos/aplauso.tscn"),
}
const COLORES_CASAS: Array = [
	Color("e3b96f"), Color("ce8879"), Color("9fbab4"), Color("e9dfbf"),
	Color("b5bf96"), Color("c7a2aa"), Color("d59c69"),
]
const COLORES_ROPA: Array = [
	Color(0.85, 0.2, 0.25), Color(0.2, 0.55, 0.3), Color(0.95, 0.95, 0.95), Color(0.25, 0.4, 0.8),
	Color(0.95, 0.7, 0.15), Color(0.6, 0.3, 0.7),
]

var tramos: Array = []                 # Tramo vivos, de izquierda a derecha
var rng := RandomNumberGenerator.new() # forma del suelo, obstáculos, público, aplausos y poderes
var rng_aire := RandomNumberGenerator.new()  # papalotes; no cambian la ruta del suelo
var rng_premios := RandomNumberGenerator.new()  # puntos y poderes en altura
var rng_melones := RandomNumberGenerator.new()
var rng_pajaros := RandomNumberGenerator.new()   # pájaros; no cambian la ruta del suelo
var rng_aspecto := RandomNumberGenerator.new()   # diseños de los rivales sin ficha guardada
var melones: Array[MelonRodante] = []
var _siguiente_melon_x := 0.0

var _fin := Vector2.ZERO               # último punto del último tramo
var _n_tramos := 0
var _poderes_generados := 0
var _siguiente_poder_x := 0.0          # los poderes siguen su propia separación entre tramos
var _siguiente_pajaro_x := 0.0
var _papalotes_generados := 0
var _siguiente_papalote_x := 0.0
var _altura_papalote := 0.0
var _t_apuro := 0.0                    # s seguidos que el jugador lleva en apuros
var _t_rescate := 0.0                  # s que faltan para permitir otro rescate
var _siguientes_premios: Array[float] = []
var _grupos_premios: Array[int] = []
var _patrones_premios: Array[int] = []


## Fija la semilla (Config.semilla_terreno; -1 = al azar) y crea los primeros tramos.
func iniciar() -> void:
	_siguiente_melon_x = Config.primer_melon_camino_x
	_siguiente_poder_x = Config.primer_poder_x
	_siguiente_pajaro_x = Config.primer_pajaro_x
	_siguiente_papalote_x = Config.primer_papalote_x
	_altura_papalote = Config.altura_papalotes.x
	if Config.semilla_terreno >= 0:
		rng.seed = Config.semilla_terreno
	else:
		rng.randomize()
	rng_aire.seed = rng.seed + 871
	rng_premios.seed = rng.seed + 1747
	rng_melones.seed = rng.seed + 2633
	rng_pajaros.seed = rng.seed + 3511
	rng_aspecto.seed = rng.seed + 4153
	for i in Config.franjas_premios_aire.size():
		_siguientes_premios.append(900.0 + i * 320.0 + rng_premios.randf_range(0.0, 400.0))
		_grupos_premios.append(0)
		_patrones_premios.append(-1)
	while _fin.x < Config.generar_adelante:
		_crear_tramo()


## Mantiene terreno listo delante de x y libera el que quedó atrás.
func actualizar(x: float) -> void:
	var hasta := minf(x, Config.meta_m * Config.px_por_metro) + Config.generar_adelante
	while _fin.x < hasta:
		_crear_tramo()
	while tramos.size() > 1 and tramos[0].x1 < x - Config.borrar_atras:
		tramos.pop_front().queue_free()
	_poner_melones(x)


## Tramo que contiene x, o null si x está fuera del terreno generado.
func tramo_en(x: float) -> Tramo:
	for t in tramos:
		if x >= t.x0 and x <= t.x1:
			return t
	return null


## Viven fuera de los tramos porque avanzan de uno a otro.
func actualizar_melones(melon: Melon, delta: float) -> void:
	var x := melon.global_position.x
	for i in range(melones.size() - 1, -1, -1):
		var otro := melones[i]
		if otro.global_position.x >= x - Config.borrar_atras:
			otro.avanzar(self, delta, melon.global_position, melon.linear_velocity)
			otro.en_mira = false
			otro.recibir_slam(melon)
		if otro.global_position.x < x - Config.borrar_atras:
			melones.remove_at(i)
			otro.queue_free()
	melon.origen_slam = melon.global_position
	var marcado: MelonRodante = null
	var marca := MelonRodante.Marca.NINGUNA
	if melon.slam_activo:
		marcado = _guiar_slam(melon, delta)
		marca = MelonRodante.Marca.FIJADO
	elif melon.controlable and not melon.roto and not melon.en_suelo and melon.t_slam <= 0.0:
		marcado = objetivo_slam(melon, Config.slam_confianza_aviso)
		marca = MelonRodante.Marca.ACERTABLE
	for otro in melones:
		otro.marcar(marca if otro == marcado else MelonRodante.Marca.NINGUNA)
	_revisar_rescate(melon, delta)


# --- Rescates ----------------------------------------------------------------

## Si el jugador lleva un rato en apuros, pone por delante, a ras de calle, el
## poder que le hace falta. No usa rng: la ruta de cada semilla no cambia.
func _revisar_rescate(melon: Melon, delta: float) -> void:
	_t_rescate = maxf(0.0, _t_rescate - delta)
	var tipo := _poder_de_rescate(melon)
	if tipo == "":
		_t_apuro = 0.0
		return
	_t_apuro += delta
	if _t_apuro < Config.rescate_tras or _t_rescate > 0.0:
		return
	# Delante, pero antes de donde se detendría rodando.
	var vx := maxf(melon.linear_velocity.x, 0.0)
	var friccion: float = Config.tamanos[melon.tamano]["friccion_rodado"]
	var adelante := clampf(vx * vx / (2.0 * friccion) * 0.6, Config.rescate_distancia.x, Config.rescate_distancia.y)
	var x := melon.global_position.x + adelante
	var tramo := tramo_en(x)
	if tramo == null or x > Config.meta_m * Config.px_por_metro:
		return
	var poder := _crear_poder(tipo, Vector2(x, tramo.altura(x) - Config.rescate_altura))
	poder.name = "Rescate" + poder.name
	poder.scale = Vector2.ZERO
	tramo.get_node("Coleccionables").add_child(poder)
	poder.create_tween().tween_property(poder, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_t_apuro = 0.0
	_t_rescate = Config.rescate_espera


## El poder que más ayuda ahora, o "" si el jugador va bien.
func _poder_de_rescate(melon: Melon) -> String:
	if not melon.controlable or melon.roto:
		return ""
	# Solo el café: un chile de rescate empujaría solo al melón aunque nadie juegue.
	var lento := melon.en_suelo and melon.linear_velocity.x < Config.rescate_velocidad
	if not melon.puede_saltar() and lento:
		return "cafe"
	return ""


## Melón que el picado alcanza: el de menor desvío entre los que caben en
## MelonRodante.alcance_slam(). null si ninguno.
func objetivo_slam(melon: Melon, confianza := 1.0) -> MelonRodante:
	var mejor: MelonRodante = null
	var mejor_desvio := INF
	for otro in melones:
		var prevision := otro.prevision_slam(melon)
		if prevision.x < 0.0 or absf(prevision.y) > otro.alcance_slam(melon, prevision.x, confianza):
			continue
		if absf(prevision.y) < mejor_desvio:
			mejor = otro
			mejor_desvio = absf(prevision.y)
	return mejor


## Durante el picado corrige un poco la velocidad horizontal hacia el melón de abajo.
## La corrección tiene un límite: acercarse ayuda, pero un mal cálculo sigue fallando.
func _guiar_slam(melon: Melon, delta: float) -> MelonRodante:
	var otro := objetivo_slam(melon)
	if otro == null:
		return null
	otro.en_mira = true
	var prevision := otro.prevision_slam(melon)
	var correccion := prevision.y / maxf(prevision.x, delta)
	var limite := Config.slam_guiado * delta
	melon.empujar(Vector2(clampf(correccion, -limite, limite), 0.0))
	return otro


## 0..1 según qué tan lejos está x. Cerca de la salida el camino es amable.
func dificultad(x: float) -> float:
	var m := x / Config.px_por_metro
	return smoothstep(Config.dificultad_metros.x, Config.dificultad_metros.y, m)


# --- Forma del suelo ---------------------------------------------------------

func _crear_tramo() -> void:
	var t := TramoEscena.instantiate() as Tramo
	t.name = "Tramo%03d" % _n_tramos
	t.puntos = _puntos_tramo()
	if _n_tramos == 0:
		t.empedrado = true
	else:
		t.empedrado = rng.randf() < Config.prob_empedrado
	t.color_suelo = Color("aaa18e") if t.empedrado else Color("6d8a58")
	if t.x0 >= Config.costa_m * Config.px_por_metro:
		t.color_suelo = Color("c5ae7c")
	t.construir()
	add_child(t)
	_poblar(t)
	_fin = t.puntos[t.puntos.size() - 1]
	tramos.append(t)
	_n_tramos += 1


## Todo el recorrido queda a la misma altura; la curva solo vive en BajadaXallitic.
func _puntos_tramo() -> PackedVector2Array:
	var inicio := Config.calle_inicio_x if _n_tramos == 0 else _fin.x
	var fin := Config.calle_fin_x if _n_tramos == 0 else inicio + Config.largo_tramo
	var pts := PackedVector2Array()
	var n := int(round((fin - inicio) / Config.paso_puntos))
	for j in n + 1:
		pts.append(Vector2(lerpf(inicio, fin, float(j) / n), Config.calle_y))
	return pts


# --- Contenido de cada tramo -------------------------------------------------

## Llena un tramo recién creado. El orden de las secciones importa (ver arriba).
func _poblar(t: Tramo) -> void:
	var inicio := Config.inicio_obstaculos_x if _n_tramos == 0 else t.x0 + 150.0
	_poner_casas(t)
	_poner_obstaculos(t, inicio)
	_poner_publico(t)
	_poner_aplausos(t, maxf(t.x0 + 60.0, 280.0))
	_poner_poderes(t)
	_poner_papalotes(t)
	_poner_premios_aire(t)
	_poner_pajaros(t)
	_poner_marcadores(t)
	t.queue_redraw()
	t.get_node("Decoracion").queue_redraw()


func preparar_corredores(bajada: BajadaXallitic) -> void:
	var fichas := Juego.melones_guardados.duplicate(true)
	for i in Config.rivales_salida:
		var datos: Dictionary
		if not fichas.is_empty():
			datos = fichas.pop_at(rng_melones.randi_range(0, fichas.size() - 1))
		else:
			# El tamaño sigue la parrilla; el aspecto cambia en cada carrera.
			datos = {"nombre_melon": "Corredor %d" % (i + 1), "tamano": i % Config.tamanos.size(),
				"piel": rng_aspecto.randi_range(0, Config.pieles.size() - 1),
				"patron": rng_aspecto.randi_range(0, Config.patrones.size() - 1),
				"cara": rng_aspecto.randi_range(0, Config.caras.size() - 1),
				"detalle": rng_aspecto.randi_range(0, Config.detalles.size() - 1), "dibujo": [],
				"cuerpo_propio": "", "rayas_propio": "", "accesorios": []}
		datos["tipo"] = _elegir_tipo_melon(0.0)
		var otro := MelonRodanteEscena.instantiate() as MelonRodante
		otro.configurar(datos)
		otro.preparar_carrera(rng_melones.randf_range(Config.velocidad_melones.x, Config.velocidad_melones.y), rng_melones.randi())
		add_child(otro)
		var x := Config.bajada_inicio.x - 60.0 - (i / 2) * Config.separacion_salida + (i % 2) * 15.0
		var carril := Config.carriles_salida.x if i % 2 == 0 else Config.carriles_salida.y
		var ritmo := lerpf(Config.ritmo_rivales.x, Config.ritmo_rivales.y, float(i) / maxf(1.0, Config.rivales_salida - 1))
		otro.preparar_salida(bajada, x, carril, ritmo)
		melones.append(otro)


## Se crean por delante del jugador, después de la parrilla y solo hasta la meta.
func _poner_melones(x: float) -> void:
	var hasta := minf(x + Config.generar_adelante, Config.meta_m * Config.px_por_metro)
	while _siguiente_melon_x < hasta:
		_crear_melon_camino(_siguiente_melon_x)
		var pareja := lerpf(Config.prob_pareja_melones, minf(1.0, Config.prob_pareja_melones * 2.0), dificultad(_siguiente_melon_x))
		if rng_melones.randf() < pareja:
			_crear_melon_camino(_siguiente_melon_x + rng_melones.randf_range(
				Config.separacion_pareja_melones.x, Config.separacion_pareja_melones.y))
		_siguiente_melon_x += rng_melones.randf_range(Config.separacion_melones.x, Config.separacion_melones.y)


func _crear_melon_camino(x: float) -> void:
	if x >= Config.meta_m * Config.px_por_metro:
		return
	var tramo := tramo_en(x)
	if tramo == null:
		return
	var tipo := _elegir_tipo_melon(dificultad(x))
	var otro := MelonRodanteEscena.instantiate() as MelonRodante
	otro.configurar({"tamano": rng_melones.randi_range(1, 2),
		"piel": rng_melones.randi_range(0, Config.pieles.size() - 1),
		"patron": rng_melones.randi_range(0, Config.patrones.size() - 1),
		"cara": Config.tipos_melones[tipo]["cara"], "tipo": tipo,
		"detalle": 0, "dibujo": [], "cuerpo_propio": "", "rayas_propio": ""})
	otro.position = Vector2(x, tramo.altura(x) - otro.radio)
	otro.preparar_carrera(rng_melones.randf_range(Config.velocidad_melones.x, Config.velocidad_melones.y), rng_melones.randi())
	otro.velocidad = Vector2(otro.rapidez, 0.0)
	otro.en_suelo = true
	add_child(otro)
	melones.append(otro)


## Carácter al azar según Config.tipos_melones. Con la dificultad hay menos
## tontos y más listos.
func _elegir_tipo_melon(dif: float) -> String:
	var pesos := {}
	var total := 0.0
	for id in Config.tipos_melones:
		var peso: float = Config.tipos_melones[id]["peso"]
		match id:
			"tonto": peso *= lerpf(1.5, 0.6, dif)
			"listo": peso *= lerpf(0.4, 1.5, dif)
		pesos[id] = peso
		total += peso
	var r := rng_melones.randf() * total
	for id in pesos:
		r -= pesos[id]
		if r <= 0.0:
			return id
	return "normal"


## Fachadas de fondo (solo datos; Tramo las dibuja en su nodo Decoracion).
func _poner_casas(t: Tramo) -> void:
	if _n_tramos != 0 and rng.randf() >= Config.prob_casas:
		return
	# En el primer tramo el sorteo empieza en Config.casas_inicio_x, antes de la
	# calle, para que cada semilla conserve su ruta. Solo se ponen las que caen en ella.
	var desde := Config.casas_inicio_x if _n_tramos == 0 else t.x0
	var cx := desde + rng.randf_range(0.0, 120.0)
	while cx < t.x1 - 100.0:
		var w := rng.randf_range(110.0, 190.0)
		var h := rng.randf_range(110.0, 230.0)
		var base := maxf(t.altura(cx), t.altura(minf(cx + w, t.x1))) + 20.0
		var casa := {"rect": Rect2(cx, base - h, w, h + 40.0),
			"color": COLORES_CASAS[rng.randi_range(0, COLORES_CASAS.size() - 1)]}
		if cx >= t.x0:
			t.casas.append(casa)
		cx += w + rng.randf_range(10.0, 160.0)


func _poner_obstaculos(t: Tramo, inicio: float) -> void:
	var x := inicio + _separacion_obstaculos(inicio)
	while x < t.x1 - 150.0:
		var tipo := _elegir_obstaculo(dificultad(x))
		var ob := _crear_obstaculo(tipo, Vector2(x, t.altura(x)))
		if Config.obstaculos[tipo]["plano"]:
			ob.rotation = t.pendiente(x)
		ob.name = tipo.capitalize()
		t.get_node("Obstaculos").add_child(ob)
		x += _separacion_obstaculos(x)


## Separación hasta el siguiente obstáculo; más holgada cerca del inicio.
func _separacion_obstaculos(x: float) -> float:
	var holgura := lerpf(Config.obstaculos_holgura, 1.0, dificultad(x))
	return rng.randf_range(Config.separacion_obstaculos.x, Config.separacion_obstaculos.y) * holgura


## Al principio abundan los impulsores; los golpes ganan peso conforme avanzas.
func _elegir_obstaculo(dif: float) -> String:
	var pesos := {}
	var total := 0.0
	for id in Config.pesos_obstaculos:
		var peso: float = Config.pesos_obstaculos[id]
		match id:
			"rampa", "toldo": peso *= lerpf(1.0, 0.9, dif)
			"poste", "banqueta": peso *= lerpf(0.4, 1.4, dif)
			_: peso *= lerpf(1.0, 1.4, dif)
		pesos[id] = peso
		total += peso
	var r := rng.randf() * total
	for id in pesos:
		r -= float(pesos[id])
		if r <= 0.0:
			return id
	return "charco"


## Instancia un obstáculo (o aplauso) y conecta su área. Quien llama lo agrega
## a su contenedor después de ponerle posición.
func _crear_obstaculo(tipo: String, posicion: Vector2) -> Obstaculo:
	var ob := OBSTACULOS[tipo].instantiate() as Obstaculo
	ob.configurar(tipo)
	ob.position = posicion
	if tipo == "aplauso":
		ob.add_to_group("aplausos")    # la flor los atrae (Recorrido._atraer_aplausos)
	ob.body_entered.connect(func(cuerpo: Node2D) -> void: obstaculo_tocado.emit(cuerpo, ob))
	return ob


func _poner_publico(t: Tramo) -> void:
	var x := maxf(t.x0, 300.0) + rng.randf_range(0.0, Config.separacion_publico.x)
	while x < t.x1 - 60.0:
		var p := PersonaEscena.instantiate() as Persona
		p.color_ropa = COLORES_ROPA[rng.randi_range(0, COLORES_ROPA.size() - 1)]
		p.color_piel = Color(0.85, 0.65, 0.5).darkened(rng.randf_range(0.0, 0.4))
		p.position = Vector2(x, t.altura(x) + 2.0)
		p.name = "Vecino"
		t.get_node("Publico").add_child(p)
		t.personas.append(p)
		x += rng.randf_range(Config.separacion_publico.x, Config.separacion_publico.y)


## Grupos de monedas en arcos bajos, al alcance de saltos cortos desde la salida.
func _poner_aplausos(t: Tramo, inicio: float) -> void:
	var x := inicio + rng.randf_range(0.0, 380.0)
	while x < t.x1 - 220.0:
		var alto := rng.randf_range(Config.altura_aplausos.x, Config.altura_aplausos.y)
		for i in 3:
			var ax := x + i * 60.0
			var ap := _crear_obstaculo("aplauso", Vector2(ax, t.altura(ax) - alto - sin(i / 2.0 * PI) * 25.0))
			ap.name = "Aplauso"
			t.get_node("Coleccionables").add_child(ap)
		x += rng.randf_range(Config.separacion_aplausos.x, Config.separacion_aplausos.y)


## Los poderes alternan en el orden de Config.orden_poderes. La separación sigue
## entre tramos: cambiar de tramo no hace aparecer otro poder.
func _poner_poderes(t: Tramo) -> void:
	while _siguiente_poder_x < t.x1:
		var x := _siguiente_poder_x
		var tipo: String = Config.orden_poderes[_poderes_generados % Config.orden_poderes.size()]
		var poder := _crear_poder(tipo, Vector2(x, t.altura(x) - rng.randf_range(Config.altura_poderes.x, Config.altura_poderes.y)))
		t.get_node("Coleccionables").add_child(poder)
		_poderes_generados += 1
		_siguiente_poder_x += rng.randf_range(Config.separacion_poderes.x, Config.separacion_poderes.y)


func _crear_poder(tipo: String, posicion: Vector2) -> Poder:
	var poder := PoderEscena.instantiate() as Poder
	poder.tipo = tipo
	poder.name = tipo.capitalize()
	poder.position = posicion
	poder.recogido.connect(poder_recogido.emit)
	return poder


## Ruta ascendente hasta las nubes. Cada tercera ayuda es una corriente de niebla.
func _poner_papalotes(t: Tramo) -> void:
	while _siguiente_papalote_x < t.x1:
		var papalote := PapaloteEscena.instantiate() as Papalote
		if _papalotes_generados > 0:
			_altura_papalote = minf(Config.altura_papalotes.y, _altura_papalote + rng_aire.randf_range(280.0, 400.0))
		papalote.corriente = _papalotes_generados % 3 == 2
		papalote.position = Vector2(_siguiente_papalote_x, t.altura(_siguiente_papalote_x) - _altura_papalote)
		t.get_node("Aire").add_child(papalote)
		t.papalotes.append(papalote)
		if _papalotes_generados % 4 == 0:   # un café para seguir saltando en el aire
			var posicion_cafe := papalote.position + Vector2(170, -120)
			posicion_cafe.x = minf(posicion_cafe.x, t.x1 - 40.0)
			t.get_node("Aire").add_child(_crear_poder("cafe", posicion_cafe))
		_papalotes_generados += 1
		_siguiente_papalote_x += rng_aire.randf_range(Config.separacion_papalotes.x, Config.separacion_papalotes.y)


## Grupos cortos y separados, con filas, arcos y diagonales en cada franja.
## Cada cuatro grupos, un poder ocupa el centro de la fila de puntos.
func _poner_premios_aire(t: Tramo) -> void:
	for franja in Config.franjas_premios_aire.size():
		var limites: Vector2 = Config.franjas_premios_aire[franja]
		while _siguientes_premios[franja] < t.x1:
			var x := _siguientes_premios[franja]
			var cantidad := rng_premios.randi_range(2, 3)
			var ancho := (cantidad - 1) * 85.0
			x = maxf(x, t.x0 + ancho / 2.0 + 20.0)
			if x + ancho / 2.0 > t.x1 - 20.0:
				break
			var centro := Vector2(x, t.altura(x) - rng_premios.randf_range(limites.x, limites.y))
			var patron := rng_premios.randi_range(0, 3)
			if patron == _patrones_premios[franja]:
				patron = (patron + rng_premios.randi_range(1, 3)) % 4
			var con_poder := (_grupos_premios[franja] + franja) % 4 == 1
			for i in cantidad:
				var u := float(i) / (cantidad - 1)
				var dy := 0.0
				match patron:
					1: dy = -sin(u * PI) * 90.0
					2: dy = (0.5 - u) * 180.0
					3: dy = (u - 0.5) * 180.0
				var posicion := centro + Vector2((u - 0.5) * ancho, dy)
				if con_poder and i == cantidad / 2:
					var tipo: String = Config.orden_poderes[(franja + int(_grupos_premios[franja] / 4.0)) % Config.orden_poderes.size()]
					t.get_node("Aire").add_child(_crear_poder(tipo, posicion))
				else:
					t.get_node("Aire").add_child(_crear_obstaculo("aplauso", posicion))
			_patrones_premios[franja] = patron
			_grupos_premios[franja] += 1
			_siguientes_premios[franja] = x + rng_premios.randf_range(Config.separacion_premios_aire.x, Config.separacion_premios_aire.y)


## Pájaros que vuelan contra el melón, a veces en pareja. Solo hasta la meta.
func _poner_pajaros(t: Tramo) -> void:
	var meta := Config.meta_m * Config.px_por_metro
	while _siguiente_pajaro_x < t.x1 and _siguiente_pajaro_x < meta:
		var x := _siguiente_pajaro_x
		var dif := dificultad(x)
		var cantidad := 2 if rng_pajaros.randf() < Config.prob_bandada * dif else 1
		var alto_max := lerpf(Config.altura_pajaros.y, Config.altura_papalotes.y, dif)
		var alto := rng_pajaros.randf_range(Config.altura_pajaros.x, alto_max)
		for i in cantidad:
			if x + i * 110.0 >= meta:
				break
			var pajaro := PajaroEscena.instantiate() as Pajaro
			pajaro.name = "Pajaro"
			pajaro.position = Vector2(x + i * 110.0, t.altura(x) - alto - i * 50.0)
			pajaro.fase = rng_pajaros.randf() * TAU
			pajaro.tocado.connect(pajaro_tocado.emit)
			t.get_node("Aire").add_child(pajaro)
		_siguiente_pajaro_x += rng_pajaros.randf_range(Config.separacion_pajaros.x, Config.separacion_pajaros.y) * lerpf(1.8, 1.0, dif)


## Distancias, lugares de la ruta y puerta de meta. No consumen azar del camino.
func _poner_marcadores(t: Tramo) -> void:
	var cada := Config.marcador_cada_m * Config.px_por_metro
	var mx := ceilf(maxf(t.x0, 1.0) / cada) * cada
	while mx < t.x1:
		var m := int(round(mx / Config.px_por_metro))
		if not Config.lugares.has(m) and m < Config.meta_m:
			t.marcadores.append({"pos": Vector2(mx, t.altura(mx)), "texto": "%d m" % m})
		mx += cada
	for postal in Config.postales:
		var x := maxf(float(postal["metros"]) * Config.px_por_metro, Config.calle_inicio_x)
		if x >= t.x0 and x < t.x1:
			t.agregar_postal({"pos": Vector2(x, t.altura(x)), "tipo": postal["id"]})
			t.marcadores.append({"pos": Vector2(x, t.altura(x)), "id": postal["id"],
				"texto": postal.get("nombre_corto", postal["nombre"]), "metros": postal["metros"]})
