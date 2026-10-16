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
	if metros >= Config.costa_m:
		_costa(m, cam, dy)
		return
	if metros >= Config.salida_xalapa_m:
		_cordillera(m, cam.x * 0.05, 20.0 - clampf(dy * 0.05, -160, 160), 120.0, LEJANO, 1.0, false)
		_cordillera(m, cam.x * 0.1, 120.0 - clampf(dy * 0.08, -200, 200), 150.0, MEDIO, 4.0, true)
		_niebla(m, cam.x * 0.08, 80.0, 0.25)
		return
	if arte.paisaje != null:
		# Foto: se mece un poco en x; al subir la cámara, baja y se desvanece.
		var desplazamiento := Vector2(sin(cam.x * 0.0002) * 55.0, -clampf(dy * 0.2, -60, 60))
		var opacidad := 1.0 - smoothstep(180.0, 800.0, -dy)
		arte.dibujar(self, Rect2(-m - HOLGURA_FOTO + desplazamiento, m * 2.0 + HOLGURA_FOTO * 2.0), Color(1, 1, 1, opacidad))
		return
	# Sin foto: franjas de lejos a cerca. El factor que multiplica cam.x es el paralaje
	# horizontal; el que multiplica dy, cuánto baja la franja al subir la cámara.
	_volcan(m, cam.x, 10.0 - clampf(dy * 0.03, -120, 120))
	_cordillera(m, cam.x * 0.05, 20.0 - clampf(dy * 0.05, -160, 160), 120.0, LEJANO, 1.0, false)
	_niebla(m, cam.x * 0.08, 10.0 - clampf(dy * 0.06, -160, 160), 0.35)
	_cordillera(m, cam.x * 0.1, 70.0 - clampf(dy * 0.08, -200, 200), 90.0, MEDIO, 4.0, true)
	_ciudad(m, cam.x * 0.18, 100.0 - clampf(dy * 0.12, -220, 220))
	_niebla(m, cam.x * 0.22, 105.0 - clampf(dy * 0.12, -220, 220), 0.25)
	_cordillera(m, cam.x * 0.3, 190.0 - clampf(dy * 0.16, -260, 260), 60.0, CERCANO, 9.0, true)


func _costa(m: Vector2, cam: Vector2, dy: float) -> void:
	var horizonte := 60.0 - clampf(dy * 0.04, -120, 120)
	_cordillera(m, cam.x * 0.04, horizonte + 20.0, 90.0, LEJANO, 1.0, false)
	draw_rect(Rect2(-m.x, horizonte + 24, m.x * 2, maxf(0.0, m.y - horizonte - 24)), Color("68a9b5"))
	for i in 5:
		var y := horizonte + 45.0 + i * 30.0
		var x := -m.x + fposmod(i * 113.0 - cam.x * 0.06, 180.0)
		while x < m.x:
			draw_line(Vector2(x, y), Vector2(x + 75, y), Color("c4e1dc"), 2.0)
			x += 180.0
	var orilla := m.y - 90.0 - clampf(dy * 0.02, -50, 60)
	draw_colored_polygon(PackedVector2Array([Vector2(-m.x, orilla), Vector2(0, orilla + 28), Vector2(m.x, orilla - 12), Vector2(m.x, m.y), Vector2(-m.x, m.y)]), Color("e4c88e"))


## Número pseudoaleatorio estable en [0, 1).
static func _azar(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


## Suma de senos en [0, 1] aprox.; s (semilla) distingue una cordillera de otra.
func _ruido(u: float, s: float) -> float:
	return 0.5 + 0.25 * sin(u * 0.004 + s) + 0.15 * sin(u * 0.011 + s * 2.1) + 0.1 * sin(u * 0.027 + s * 3.7)


## Línea de cerros continua; u = x de pantalla + desplazamiento, así no se repite.
func _cordillera(m: Vector2, desp: float, base: float, alto: float, col: Color, s: float, arboles: bool) -> void:
	var pts := PackedVector2Array()
	var x := -m.x
	while x <= m.x + 20.0:
		pts.append(Vector2(x, base - alto * _ruido(x + desp, s)))
		x += 20.0
	pts.append(Vector2(m.x + 20.0, m.y))
	pts.append(Vector2(-m.x, m.y))
	draw_colored_polygon(pts, col)
	if not arboles:
		return
	# Copas sobre la cresta, ancladas al mundo para que no "naden".
	var paso := 16.0 if s > 5.0 else 11.0
	var u := ceilf((-m.x + desp) / paso) * paso
	while u - desp < m.x + 10.0:
		var sx := u - desp
		var h := _azar(u + s)
		if h < 0.7:
			var r := paso * (0.5 + 0.4 * h)
			draw_circle(Vector2(sx, base - alto * _ruido(u, s) + r * 0.4), r, col.darkened(0.12 + 0.1 * h))
		u += paso


func _volcan(m: Vector2, cam_x: float, base: float) -> void:
	# Un cono nevado lejano y un macizo de cima plana; reaparecen cada 2600 px de pantalla.
	var x := fposmod(260.0 - cam_x * 0.015 + 1300.0, 2600.0) - 1300.0
	var cima := Vector2(x, base - 270.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 480, base + 40), Vector2(x - 60, cima.y + 30), cima,
		Vector2(x + 50, cima.y + 26), Vector2(x + 500, base + 40)]), VOLCAN)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 60, cima.y + 30), cima, Vector2(x + 50, cima.y + 26),
		Vector2(x + 105, cima.y + 72), Vector2(x + 60, cima.y + 60), Vector2(x + 30, cima.y + 82),
		Vector2(x - 10, cima.y + 58), Vector2(x - 50, cima.y + 84), Vector2(x - 115, cima.y + 74)]), Color(0.97, 0.97, 0.98))
	var x2 := x - 900.0 if x > 0.0 else x + 900.0
	draw_colored_polygon(PackedVector2Array([Vector2(x2 - 380, base + 40), Vector2(x2 - 70, base - 150),
		Vector2(x2 + 10, base - 158), Vector2(x2 + 20, base - 172), Vector2(x2 + 34, base - 160),
		Vector2(x2 + 90, base - 150), Vector2(x2 + 360, base + 40)]), VOLCAN.darkened(0.05))


func _niebla(m: Vector2, desp: float, y: float, alfa: float) -> void:
	# Jirones de niebla bajos, característicos de la ciudad; se mueven despacio.
	var periodo := 1900.0
	for i in 4:
		var x := fposmod(i * 520.0 - desp + _t * 10.0 + periodo / 2.0, periodo) - periodo / 2.0
		var c := Vector2(x, y + 24.0 * _azar(i + 9.0))
		var r := Vector2(240.0 + 120.0 * _azar(i + 2.0), 22.0)
		var pts := PackedVector2Array()
		for k in 20:
			var a := TAU * k / 20.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_colored_polygon(pts, Color(BRUMA, alfa))


func _ciudad(m: Vector2, desp: float, base: float) -> void:
	# Manzanas lejanas, teñidas por la bruma; de vez en cuando una torre o cúpula.
	var ancho := 46.0
	var k := floori((-m.x + desp) / ancho) - 1
	while k * ancho - desp < m.x + ancho:
		var sx := k * ancho - desp
		var h := _azar(k * 1.37)
		var y := base - 18.0 - 46.0 * _azar(k * 2.11 + 0.3) - 6.0 * sin(k * 0.21) * 4.0
		var col: Color = FACHADAS[int(h * FACHADAS.size())]
		col = col.lerp(BRUMA, 0.45).darkened(0.08)
		draw_rect(Rect2(sx, y, ancho + 1.0, m.y - y + 4.0), col)
		draw_rect(Rect2(sx - 2, y - 5, ancho + 5.0, 6), Color(0.72, 0.38, 0.28).lerp(BRUMA, 0.4))
		for v in 3:
			draw_rect(Rect2(sx + 7 + v * 13, y + 12, 6, 9), col.darkened(0.25))
		if h > 0.93:
			var tx := sx + ancho / 2.0
			draw_rect(Rect2(tx - 9, y - 60, 18, 60), Color(0.9, 0.88, 0.82).lerp(BRUMA, 0.3))
			draw_circle(Vector2(tx, y - 60), 9.0, Color(0.82, 0.78, 0.68).lerp(BRUMA, 0.3))
			draw_line(Vector2(tx, y - 69), Vector2(tx, y - 82), Color(0.35, 0.35, 0.38), 2.0)
			draw_line(Vector2(tx - 4, y - 77), Vector2(tx + 4, y - 77), Color(0.35, 0.35, 0.38), 2.0)
		k += 1
