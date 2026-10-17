class_name Paisaje
extends Node2D
## Fondo de la ruta: Xalapa, montañas y costa, con efecto de paralaje.
##
## Escena: mundo/paisaje/paisaje.tscn (instanciada como Paisaje en recorrido.tscn).
## Los hijos son capas del cielo (mundo/paisaje/capa_cielo.gd), editables en el inspector.
## Su z_index es relativo a este nodo, que dibuja lo suyo en z 0:
##   Cielo          (z -3)  degradado de fondo
##   Sol            (z -2)
##   NubesAltas     (z -1)
##   -- _draw() de este nodo (z 0): foto panorámica, o montañas + ciudad + niebla --
##   NubesCercanas  (z  1)
##   Bandadas       (z  2)  aves
##   Papalotes      (z  3)  papalotes lejanos, solo decoración
##
## Cómo funciona: cada cuadro este nodo se coloca en el centro de la cámara y compensa
## el zoom, así todo se dibuja en coordenadas de pantalla con (0, 0) al centro. Cada capa
## o franja se desplaza con su propio factor de paralaje (0 = infinito, 1 = mundo).
##
## Quién lo usa: Recorrido._ready() llama configurar(camara).
##
## Si recursos/arte_xalapa.tres tiene foto de paisaje, se dibuja la foto en lugar de las
## montañas, y Sol/NubesAltas/NubesCercanas solo aparecen cuando la cámara sube por
## encima de la foto (ALTURA_CIELO), mientras la foto se desvanece.

const VOLCAN := Color(0.58, 0.63, 0.74)
const LEJANO := Color(0.5, 0.6, 0.68)
const MEDIO := Color(0.38, 0.54, 0.46)
const CERCANO := Color(0.3, 0.47, 0.3)
const BRUMA := Color(0.93, 0.92, 0.88)
const FACHADAS: Array = [Color(0.95, 0.75, 0.45), Color(0.9, 0.55, 0.45), Color(0.96, 0.92, 0.8),
	Color(0.65, 0.78, 0.82), Color(0.8, 0.85, 0.6), Color(0.88, 0.68, 0.75)]
const REF_Y := 60.0                   # altura de cámara a la que el horizonte queda en su sitio
const MARGEN := Vector2(4, 4)         # se dibuja un poco más allá del borde de la pantalla
const HOLGURA_FOTO := Vector2(80, 80) # la foto sobresale para poder moverse sin dejar huecos
const CAPAS_ALTAS: Array = ["Sol", "NubesAltas", "NubesCercanas"]   # tapadas por la foto
const ALTURA_CIELO := -180.0          # con foto, las CAPAS_ALTAS se ven con la cámara más arriba de esta y

var arte: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
var camara: Camera2D
var _t := 0.0                         # segundos acumulados; anima la niebla y las capas


func _init() -> void:
	z_index = -50                     # detrás de Decoracion (-2) y Postales (-1) de los tramos


## Indica qué cámara seguir. Sin cámara, se usa la cámara activa del viewport.
func configurar(c: Camera2D) -> void:
	camara = c
	if arte.paisaje != null:
		for nombre in CAPAS_ALTAS:
			get_node(nombre).hide()
	queue_redraw()


func _camara() -> Camera2D:
	if is_instance_valid(camara):
		return camara
	return get_viewport().get_camera_2d()


func _process(delta: float) -> void:
	_t += delta
	var c := _camara()
	if c == null:
		return
	# Seguir a la cámara y deshacer su zoom: así se dibuja en coordenadas de pantalla.
	global_position = c.get_screen_center_position()
	scale = Vector2.ONE / c.zoom
	for nombre in CAPAS_ALTAS:
		get_node(nombre).visible = arte.paisaje == null or global_position.y < ALTURA_CIELO or global_position.x >= Config.salida_xalapa_m * Config.px_por_metro
	# Todos los hijos son CapaCielo.
	for capa in get_children():
		if capa.visible:
			capa.actualizar(get_viewport_rect().size, global_position, _t)
	queue_redraw()


# --- Dibujo (z 0, entre NubesAltas y NubesCercanas) ---------------------------

func _draw() -> void:
	var c := _camara()
	if c == null:
		return
	var m := get_viewport_rect().size / 2.0 + MARGEN
	var cam := c.get_screen_center_position()
	var dy := cam.y - REF_Y
	var metros := cam.x / Config.px_por_metro
	var bosque := smoothstep(Config.salida_xalapa_m - 80.0, Config.salida_xalapa_m, metros)
	var centro_m := float(Config.etapas_ruta[2]["metros"])
	var centro := smoothstep(centro_m - 80.0, centro_m, metros)
	var costa := smoothstep(Config.costa_m - 80.0, Config.costa_m, metros)
	if arte.paisaje != null and bosque < 1.0:
		# Foto: se mece un poco en x; al subir la cámara, baja y se desvanece.
		var desplazamiento := Vector2(sin(cam.x * 0.0002) * 55.0, -clampf(dy * 0.2, -60, 60))
		var opacidad := (1.0 - smoothstep(180.0, 800.0, -dy)) * (1.0 - bosque)
		arte.dibujar(self, Rect2(-m - HOLGURA_FOTO + desplazamiento, m * 2.0 + HOLGURA_FOTO * 2.0), Color(1, 1, 1, opacidad))
		if bosque == 0.0:
			return
	# Sin foto: franjas de lejos a cerca. El factor que multiplica cam.x es el paralaje
	# horizontal; el que multiplica dy, cuánto baja la franja al subir la cámara.
	if costa < 1.0:
		_volcan(m, cam.x, 10.0 - clampf(dy * 0.03, -120, 120), (1.0 - centro) * (1.0 - costa))
		_cordillera(m, cam.x * 0.05, 20.0 - clampf(dy * 0.05, -160, 160), 120.0, LEJANO, 1.0, false, 1.0 - costa)
		_niebla(m, cam.x * 0.08, 10.0 - clampf(dy * 0.06, -160, 160), 0.35 * (1.0 - centro) * (1.0 - costa))
		_cordillera(m, cam.x * 0.1, 70.0 - clampf(dy * 0.08, -200, 200), 90.0, MEDIO, 4.0, true, 1.0 - costa)
		_ciudad(m, cam.x * 0.18, 100.0 - clampf(dy * 0.12, -220, 220), (1.0 - bosque + centro) * (1.0 - costa))
		_niebla(m, cam.x * 0.22, 105.0 - clampf(dy * 0.12, -220, 220), 0.25 * (1.0 - centro) * (1.0 - costa))
		_cordillera(m, cam.x * 0.3, 190.0 - clampf(dy * 0.16, -260, 260), 60.0, CERCANO, 9.0, true, 1.0 - costa)
		_bosque(m, cam, dy, bosque * (1.0 - centro) * (1.0 - costa))
	if costa > 0.0:
		_costa(m, cam, dy, costa)


func _costa(m: Vector2, cam: Vector2, dy: float, alfa := 1.0) -> void:
	var desp := fposmod(cam.x * 0.06, 1280.0)
	for i in range(floori((-m.x + desp + 640) / 1280) - 1, ceili((m.x + desp + 640) / 1280) + 1):
		var rect := Rect2(Vector2(i * 1280 - desp - 640, -m.y - clampf(dy * 0.04, -120, 120)), Vector2(1280, m.y * 2))
		var escala := rect.size / Vector2(1280, 720)
		if posmod(i, 2) == 1:
			escala.x = -escala.x
		Sprites.girar(self, "paisaje/costa", Transform2D(0, escala, 0, rect.get_center()), Color(1, 1, 1, alfa))


func _bosque(m: Vector2, cam: Vector2, dy: float, alfa: float) -> void:
	if alfa <= 0.0:
		return
	var desp := cam.x * 0.22
	var base := 210.0 - clampf(dy * 0.14, -240, 240)
	for i in range(floori((-m.x + desp) / 160.0) - 1, ceili((m.x + desp) / 160.0) + 1):
		var alto := 140.0 + _azar(i) * 90.0
		Sprites.dibujar(self, "terreno/arbol_1", Rect2(i * 160 - desp, base - alto, alto, alto), Color(0.65, 0.8, 0.72, alfa))

static func _azar(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)

func _franja(id: String, m: Vector2, desp: float, base: float, alto: float, tinte := Color.WHITE) -> void:
	var ancho := 2048.0
	var inicio := floori((-m.x + desp) / ancho)
	var fin := ceili((m.x + desp) / ancho)
	for i in range(inicio, fin + 1):
		var rect := Rect2(i * ancho - desp, base - alto, ancho, maxf(1000.0, m.y + alto - base))
		# Alternar el reflejo une los mismos bordes de la franja sin saltos.
		var escala := rect.size / Vector2(2048, 1000)
		if posmod(i, 2) == 1:
			escala.x = -escala.x
		Sprites.girar(self, id, Transform2D(0, escala, 0, rect.get_center()), tinte)

func _cordillera(m: Vector2, desp: float, base: float, _alto: float, col: Color, s: float, _arboles: bool, alfa := 1.0) -> void:
	col.a *= alfa
	_franja("paisaje/cerros_%d" % int(s), m, desp, base, 200.0, col)

func _volcan(_m: Vector2, cam_x: float, base: float, alfa := 1.0) -> void:
	var x := fposmod(260.0 - cam_x * 0.015 + 1300.0, 2600.0) - 1300.0
	Sprites.dibujar(self, "paisaje/volcan", Rect2(x - 1560, base - 300, 2600, 1120), Color(1, 1, 1, alfa))

func _niebla(m: Vector2, desp: float, y: float, alfa: float) -> void:
	var inicio := floori((-m.x + desp - _t * 10) / 1900.0)
	var fin := ceili((m.x + desp - _t * 10) / 1900.0)
	for i in range(inicio, fin + 1):
		Sprites.dibujar(self, "paisaje/niebla", Rect2(i * 1900 - desp + _t * 10, y - 30, 1900, 100), Color(1, 1, 1, alfa))

func _ciudad(m: Vector2, desp: float, base: float, alfa := 1.0) -> void:
	_franja("paisaje/ciudad", m, desp, base, 180, Color(1, 1, 1, alfa))
