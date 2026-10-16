@tool
class_name Postal
extends Node2D
## Sitio de Xalapa dibujado con vectores, como fondo de un tramo. El origen es la
## base a ras de suelo; el dibujo baja un poco para que el terreno tape la unión.
##
## Escena: mundo/terreno/postal.tscn (un solo Node2D; todo se dibuja en _draw()).
## Quién la usa: GeneradorTerreno._poner_postales() pide Tramo.agregar_postal(datos), que
## instancia la escena en el contenedor Postales (z -1) del tramo y llama configurar().
## Qué lugar se dibuja lo decide `tipo`; los lugares y sus metros están en Config.postales.
## Como es @tool, `tipo` y `nombre` se pueden probar desde el inspector.
##
## Además ofrece dibujar_picado() (estática), que Tramo usa para colgar papel picado
## entre sus casas de fondo.

## Tipos válidos; los mismos del @export_enum de `tipo`.
const TIPOS: Array = ["xallitic", "catedral", "juarez", "diamante", "berros", "lagos", "usbi", "macuiltepetl"]
## Media anchura aproximada de cada dibujo; coloca el letrero en el borde izquierdo.
const MEDIO_ANCHO := {"xallitic": 290.0, "catedral": 150.0, "juarez": 230.0, "diamante": 170.0,
	"berros": 240.0, "lagos": 260.0, "usbi": 230.0, "macuiltepetl": 360.0}

# --- Paleta ------------------------------------------------------------------
const PIEDRA := Color(0.66, 0.58, 0.5)
const CANTERA := Color(0.87, 0.84, 0.77)
const TEJA := Color(0.72, 0.3, 0.2)
const HOJA := Color(0.24, 0.45, 0.24)
const HOJA_OSCURA := Color(0.16, 0.32, 0.19)
const HIERRO := Color(0.16, 0.16, 0.17)
const SOMBRA := Color(0.17, 0.24, 0.19)
const MADERA := Color(0.42, 0.24, 0.14)
const AGUA := Color(0.33, 0.58, 0.68)
const PICADO: Array = [Color(0.93, 0.2, 0.55), Color(0.98, 0.6, 0.12), Color(0.2, 0.7, 0.75),
	Color(0.98, 0.85, 0.2), Color(0.45, 0.75, 0.3), Color(0.6, 0.35, 0.8)]

## Qué lugar se dibuja.
@export_enum("xallitic", "catedral", "juarez", "diamante", "berros", "lagos", "usbi", "macuiltepetl") var tipo := "catedral":
	set(valor):
		tipo = valor
		queue_redraw()
## Texto del letrero de madera; vacío = sin letrero.
@export var nombre := "":
	set(valor):
		nombre = valor
		queue_redraw()


## Aplica datos: {pos: Vector2, tipo: String, nombre: String}; las claves que falten
## no cambian. pos va en coordenadas del padre, a ras de suelo.
func configurar(datos: Dictionary) -> void:
	if datos.has("pos"):
		position = datos["pos"]
	tipo = str(datos.get("tipo", tipo))
	nombre = str(datos.get("nombre", nombre))
	queue_redraw()


func _draw() -> void:
	match tipo:
		"xallitic": _xallitic()
		"catedral": _catedral()
		"juarez": _juarez()
		"diamante": _diamante()
		"berros": _berros()
		"lagos": _lagos()
		"usbi": _usbi()
		"macuiltepetl": _macuiltepetl()
		_: push_warning("Postal: tipo desconocido '%s'" % tipo)
	if nombre != "":
		_letrero(-float(MEDIO_ANCHO.get(tipo, 150.0)) + 10.0)


# --- Sitios ------------------------------------------------------------------

func _xallitic() -> void:
	# Puente de piedra de varios arcos, con hiedra y barranca verde debajo.
	draw_rect(Rect2(-290, -250, 580, 290), PIEDRA)
	var y := -232.0
	var fila := 0
	while y < 30.0:
		draw_line(Vector2(-290, y), Vector2(290, y), PIEDRA.darkened(0.12), 2.0)
		var x := -290.0 + (24.0 if fila % 2 == 0 else 0.0)
		while x < 290.0:
			draw_line(Vector2(x, y), Vector2(x, y + 18), PIEDRA.darkened(0.12), 2.0)
			x += 48.0
		y += 18.0
		fila += 1
	for cx in [-190.0, 0.0, 190.0]:
		_dovelas(cx, 40.0, 130.0, 200.0, PIEDRA.darkened(0.25))
		_arco(cx, 40.0, 112.0, 182.0, SOMBRA)
		_arbol(Vector2(cx - 20, 40), 26.0, HOJA_OSCURA)
		_arbol(Vector2(cx + 28, 40), 20.0, HOJA)
	# Pretil con remate y hiedra colgando.
	draw_rect(Rect2(-296, -282, 592, 32), PIEDRA.lightened(0.08))
	draw_rect(Rect2(-302, -290, 604, 10), PIEDRA.darkened(0.2))
	for i in 15:
		var hx := -280.0 + i * 40.0 + 9.0 * sin(i * 2.3)
		var largo := 30.0 + 40.0 * (0.5 + 0.5 * sin(i * 1.7))
		draw_line(Vector2(hx, -250), Vector2(hx + 4, -250 + largo), HOJA_OSCURA, 4.0)
		draw_circle(Vector2(hx + 4, -250 + largo), 6.0, HOJA)


func _catedral() -> void:
	# Fachada de cantera clara con una torre alta y la otra sin terminar.
	var cuerpo := Rect2(-120, -240, 240, 280)
	draw_rect(cuerpo, CANTERA)
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -240), Vector2(60, -240), Vector2(0, -310)]), CANTERA)
	draw_polyline(PackedVector2Array([Vector2(-66, -236), Vector2(0, -318), Vector2(66, -236)]), CANTERA.darkened(0.25), 5.0)
	_cruz(Vector2(0, -318), 22.0)
	draw_line(Vector2(-120, -150), Vector2(120, -150), CANTERA.darkened(0.2), 4.0)
	draw_circle(Vector2(0, -196), 26.0, CANTERA.darkened(0.3))
	draw_circle(Vector2(0, -196), 20.0, Color(0.35, 0.45, 0.75))
	for i in 8:
		var a := TAU * i / 8.0
		draw_line(Vector2(0, -196), Vector2(0, -196) + Vector2.from_angle(a) * 20.0, CANTERA.darkened(0.3), 2.0)
	_ojiva(0, 40, 60, 140, CANTERA.darkened(0.3))
	_ojiva(0, 40, 46, 124, MADERA)
	for vx in [-88.0, 88.0]:
		_ojiva(vx, -40, 26, 74, CANTERA.darkened(0.3))
		_ojiva(vx, -40, 18, 64, Color(0.3, 0.38, 0.6))
	# Torre alta: cuerpo, campanario, reloj y aguja.
	var tc := CANTERA.darkened(0.06)
	draw_rect(Rect2(-160, -400, 70, 440), tc)
	draw_rect(Rect2(-166, -404, 82, 10), tc.darkened(0.2))
	draw_circle(Vector2(-125, -350), 18.0, Color(0.96, 0.95, 0.9))
	draw_arc(Vector2(-125, -350), 18.0, 0, TAU, 24, tc.darkened(0.35), 3.0)
	draw_line(Vector2(-125, -350), Vector2(-125, -362), HIERRO, 2.0)
	draw_line(Vector2(-125, -350), Vector2(-116, -350), HIERRO, 2.0)
	_ojiva(-125, -250, 30, 70, SOMBRA)
	draw_rect(Rect2(-150, -470, 50, 66), tc)
	_ojiva(-125, -410, 22, 52, SOMBRA)
	draw_colored_polygon(PackedVector2Array([Vector2(-156, -470), Vector2(-94, -470), Vector2(-125, -560)]), tc.darkened(0.12))
	_cruz(Vector2(-125, -560), 20.0)
	# Torre baja, inconclusa.
	draw_rect(Rect2(90, -300, 70, 340), tc)
	draw_rect(Rect2(84, -306, 82, 10), tc.darkened(0.2))
	_ojiva(125, -220, 28, 64, SOMBRA)
	draw_rect(Rect2(-180, 20, 360, 20), CANTERA.darkened(0.15))


func _juarez() -> void:
	# Terraza con balaustrada, arboleda, faroles y un busto sobre pedestal.
	_arbol(Vector2(-160, -40), 70.0, HOJA_OSCURA)
	_arbol(Vector2(170, -40), 64.0, HOJA)
	_arbol(Vector2(60, -40), 46.0, Color(0.55, 0.42, 0.75))
	draw_rect(Rect2(-230, -60, 460, 100), PIEDRA.lightened(0.1))
	for i in 10:
		draw_rect(Rect2(-220 + i * 46, -40, 30, 70), PIEDRA.darkened(0.08))
	_balaustrada(-230, 230, -60, 34, CANTERA)
	for fx in [-200.0, 200.0]:
		_farol(Vector2(fx, -60), 110.0)
	draw_rect(Rect2(-34, -150, 68, 90), CANTERA)
	draw_rect(Rect2(-42, -160, 84, 12), CANTERA.darkened(0.15))
	draw_rect(Rect2(-42, -70, 84, 12), CANTERA.darkened(0.15))
	var bronce := Color(0.3, 0.27, 0.22)
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -160), Vector2(26, -160), Vector2(18, -186), Vector2(-18, -186)]), bronce)
	draw_circle(Vector2(0, -200), 15.0, bronce)
	draw_rect(Rect2(-14, -214, 28, 8), bronce.darkened(0.3))
	for i in 9:
		draw_circle(Vector2(-110 + i * 27, -62), 7.0, PICADO[i % PICADO.size()])


func _diamante() -> void:
	# Callejón angosto en subida entre fachadas de colores, faroles y papel picado.
	draw_colored_polygon(PackedVector2Array([Vector2(-40, 40), Vector2(40, 40), Vector2(18, -150), Vector2(-18, -150)]),
		Color(0.55, 0.52, 0.48))
	for i in 9:
		var t := float(i) / 9.0
		var y := lerpf(30.0, -140.0, t)
		var w := lerpf(40.0, 18.0, t)
		draw_line(Vector2(-w, y), Vector2(w, y), Color(0.4, 0.37, 0.34), 3.0)
	_fachada(Rect2(-170, -230, 130, 270), Color(0.95, 0.72, 0.35), true)
	_fachada(Rect2(40, -260, 130, 300), Color(0.55, 0.75, 0.82), false)
	_picado(Vector2(-40, -200), Vector2(40, -220), 16.0)
	_picado(Vector2(-40, -150), Vector2(40, -160), 12.0)
	for fx in [-40.0, 40.0]:
		draw_line(Vector2(fx, -120), Vector2(fx + signf(-fx) * 16, -120), HIERRO, 3.0)
		draw_rect(Rect2(fx + signf(-fx) * 16 - 6, -120, 12, 18), Color(0.98, 0.85, 0.45))
	# Rombo de hierro sobre la entrada del callejón.
	var d := Vector2(0, -262)
	draw_colored_polygon(PackedVector2Array([d + Vector2(0, -22), d + Vector2(16, 0), d + Vector2(0, 22), d + Vector2(-16, 0)]),
		Color(0.7, 0.85, 0.95))
	draw_polyline(PackedVector2Array([d + Vector2(0, -22), d + Vector2(16, 0), d + Vector2(0, 22), d + Vector2(-16, 0),
		d + Vector2(0, -22)]), HIERRO, 3.0)
	draw_line(d + Vector2(0, 22), Vector2(0, -230), HIERRO, 2.0)


func _berros() -> void:
	# Parque arbolado con fuente al centro y reja de hierro.
	_arbol(Vector2(-170, 0), 80.0, HOJA_OSCURA)
	_arbol(Vector2(-60, -10), 58.0, HOJA)
	_arbol(Vector2(150, 0), 88.0, HOJA_OSCURA)
	_arbol(Vector2(70, -10), 50.0, Color(0.32, 0.55, 0.28))
	draw_colored_polygon(_elipse(Vector2(0, -6), Vector2(90, 16)), CANTERA.darkened(0.15))
	draw_rect(Rect2(-90, -6, 180, 40), CANTERA.darkened(0.15))
	draw_colored_polygon(_elipse(Vector2(0, -8), Vector2(80, 10)), AGUA)
	draw_rect(Rect2(-8, -90, 16, 84), CANTERA)
	draw_colored_polygon(_elipse(Vector2(0, -90), Vector2(40, 9)), CANTERA.darkened(0.1))
	draw_circle(Vector2(0, -108), 10.0, CANTERA)
	var chorro := Color(0.75, 0.9, 1.0, 0.85)
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 9:
			var t := float(i) / 8.0
			pts.append(Vector2(s * (12.0 + 60.0 * t), -112.0 + 100.0 * t * t - 40.0 * t))
		draw_polyline(pts, chorro, 3.0)
	_reja(-240, 240, 30, 60)
	for fx in [-110.0, 110.0]:
		_farol(Vector2(fx, 30), 120.0)


func _lagos() -> void:
	# Lago con orilla lejana arbolada, sauces, barandal de hierro y patos.
	draw_rect(Rect2(-260, -100, 520, 30), Color(0.4, 0.6, 0.32))
	for i in 7:
		_arbol(Vector2(-230 + i * 78, -90), 24.0 + 8.0 * sin(i * 1.9), HOJA if i % 2 == 0 else HOJA_OSCURA)
	draw_rect(Rect2(-260, -72, 520, 112), AGUA)
	for i in 8:
		var y := -60.0 + i * 12.0
		var x := -220.0 + 37.0 * fposmod(i * 2.7, 6.0)
		draw_line(Vector2(x, y), Vector2(x + 50, y), AGUA.lightened(0.3), 2.0)
	for sx in [-200.0, 190.0]:
		draw_line(Vector2(sx, 0), Vector2(sx + 6, -130), MADERA, 8.0)
		for k in 9:
			var a := -PI / 2.0 + (k - 4) * 0.32
			var tope := Vector2(sx + 6, -130) + Vector2.from_angle(a) * 30.0
			draw_polyline(PackedVector2Array([Vector2(sx + 6, -130), tope, tope + Vector2(cos(a) * 14.0, 70.0)]),
				Color(0.45, 0.65, 0.3), 4.0)
	for p in [Vector2(-60, -40), Vector2(-20, -30), Vector2(80, -50)]:
		draw_colored_polygon(_elipse(p, Vector2(12, 6)), Color(0.96, 0.95, 0.9))
		draw_circle(p + Vector2(10, -8), 5.0, Color(0.96, 0.95, 0.9))
		draw_line(p + Vector2(14, -8), p + Vector2(20, -7), Color(0.95, 0.6, 0.15), 3.0)
	_baranda(-260, 260, 30, 36, HIERRO)


func _usbi() -> void:
	# Edificio moderno: cuerpo de concreto con fachada de vidrio y parasoles horizontales.
	var concreto := Color(0.8, 0.78, 0.74)
	_arbol(Vector2(-230, 20), 52.0, HOJA)
	draw_rect(Rect2(-200, -200, 400, 240), concreto)
	var vidrio := Color(0.38, 0.6, 0.66)
	for fila in 4:
		for col in 9:
			var r := Rect2(-180 + col * 40, -184 + fila * 44, 34, 34)
			draw_rect(r, vidrio if (col + fila) % 4 != 0 else vidrio.lightened(0.25))
			draw_line(r.position + Vector2(4, 30), r.position + Vector2(16, 4), Color(1, 1, 1, 0.25), 2.0)
	for fila in 5:
		draw_rect(Rect2(-208, -192 + fila * 44, 416, 8), concreto.darkened(0.15))
	draw_rect(Rect2(-60, -10, 120, 50), vidrio.darkened(0.3))
	draw_rect(Rect2(-84, -18, 168, 10), concreto.darkened(0.3))
	_arbol(Vector2(230, 20), 46.0, HOJA_OSCURA)


func _macuiltepetl() -> void:
	# Cerro boscoso con sendero y mirador en la cima.
	var cerro := PackedVector2Array()
	for i in 25:
		var t := float(i) / 24.0
		cerro.append(Vector2(lerpf(-360, 360, t), 40.0 - 400.0 * pow(sin(PI * t), 1.6)))
	draw_colored_polygon(cerro, Color(0.28, 0.48, 0.28))
	for i in 46:
		var t := fposmod(i * 0.618, 1.0)
		var tope := 40.0 - 400.0 * pow(sin(PI * t), 1.6)
		var y := lerpf(tope + 24.0, 30.0, fposmod(i * 0.377, 1.0))
		draw_circle(Vector2(lerpf(-360, 360, t), y), 16.0 + 8.0 * fposmod(i * 0.71, 1.0),
			HOJA_OSCURA if i % 3 else Color(0.36, 0.58, 0.3))
	draw_polyline(PackedVector2Array([Vector2(-200, 30), Vector2(-60, -60), Vector2(-150, -140), Vector2(-20, -230),
		Vector2(-80, -300), Vector2(0, -355)]), Color(0.78, 0.66, 0.48), 4.0)
	# Mirador: torre de patas con plataforma y barandal.
	draw_line(Vector2(-20, -360), Vector2(-12, -440), Color(0.85, 0.85, 0.82), 6.0)
	draw_line(Vector2(20, -360), Vector2(12, -440), Color(0.85, 0.85, 0.82), 6.0)
	draw_line(Vector2(-18, -380), Vector2(14, -420), Color(0.7, 0.7, 0.68), 3.0)
	draw_line(Vector2(18, -380), Vector2(-14, -420), Color(0.7, 0.7, 0.68), 3.0)
	draw_rect(Rect2(-30, -446, 60, 8), Color(0.75, 0.74, 0.7))
	_baranda(-30, 30, -446, 16, HIERRO)


# --- Piezas ------------------------------------------------------------------

## Letrero de madera con `nombre`; x = borde izquierdo.
func _letrero(x: float) -> void:
	draw_line(Vector2(x + 10, 40), Vector2(x + 10, -54), MADERA, 5.0)
	draw_line(Vector2(x + 140, 40), Vector2(x + 140, -54), MADERA, 5.0)
	draw_rect(Rect2(x, -84, 150, 32), MADERA.lightened(0.15))
	draw_rect(Rect2(x, -84, 150, 32), MADERA.darkened(0.3), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(x, -62), nombre, HORIZONTAL_ALIGNMENT_CENTER, 150, 15,
		Color(1, 0.96, 0.85))


## Abertura de medio punto: rectángulo con semicírculo arriba.
func _arco(x: float, base: float, ancho: float, alto: float, col: Color) -> void:
	var r := ancho / 2.0
	var pts := PackedVector2Array([Vector2(x - r, base)])
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(Vector2(x + cos(a) * r, base - alto + r + sin(a) * r))
	pts.append(Vector2(x + r, base))
	draw_colored_polygon(pts, col)


## Arco de medio punto con las juntas de sus piedras (dovelas) marcadas.
func _dovelas(x: float, base: float, ancho: float, alto: float, col: Color) -> void:
	_arco(x, base, ancho, alto, col)
	var r := ancho / 2.0
	var centro := Vector2(x, base - alto + r)
	for i in 9:
		var a := PI + PI * i / 8.0
		draw_line(centro + Vector2.from_angle(a) * (r - 18.0), centro + Vector2.from_angle(a) * r, PIEDRA.darkened(0.4), 2.0)


## Arco apuntado (ojival) con dos arcos de radio = ancho.
func _ojiva(x: float, base: float, ancho: float, alto: float, col: Color) -> void:
	var r := ancho / 2.0
	var arranque := base - alto + 0.866 * ancho
	var pts := PackedVector2Array([Vector2(x - r, base)])
	for i in 7:
		pts.append(Vector2(x + r, arranque) + Vector2.from_angle(PI + PI / 3.0 * i / 6.0) * ancho)
	for i in range(1, 7):
		pts.append(Vector2(x - r, arranque) + Vector2.from_angle(5.0 * PI / 3.0 + PI / 3.0 * i / 6.0) * ancho)
	pts.append(Vector2(x + r, base))
	draw_colored_polygon(pts, col)


func _cruz(p: Vector2, alto: float) -> void:
	draw_line(p, p + Vector2(0, -alto), HIERRO, 3.0)
	draw_line(p + Vector2(-alto * 0.3, -alto * 0.7), p + Vector2(alto * 0.3, -alto * 0.7), HIERRO, 3.0)


func _arbol(p: Vector2, r: float, col: Color) -> void:
	draw_line(p, p + Vector2(0, -r * 1.4), MADERA, maxf(4.0, r * 0.18))
	draw_circle(p + Vector2(-r * 0.6, -r * 1.3), r * 0.72, col.darkened(0.15))
	draw_circle(p + Vector2(r * 0.6, -r * 1.35), r * 0.7, col.darkened(0.1))
	draw_circle(p + Vector2(0, -r * 1.75), r, col)
	draw_circle(p + Vector2(-r * 0.3, -r * 2.05), r * 0.45, col.lightened(0.15))


func _farol(p: Vector2, alto: float) -> void:
	draw_line(p, p + Vector2(0, -alto), HIERRO, 4.0)
	draw_rect(Rect2(p.x - 8, p.y - alto - 22, 16, 22), Color(0.98, 0.86, 0.5))
	draw_rect(Rect2(p.x - 10, p.y - alto - 26, 20, 5), HIERRO)


func _baranda(xa: float, xb: float, y: float, alto: float, col: Color) -> void:
	draw_line(Vector2(xa, y - alto), Vector2(xb, y - alto), col, 3.0)
	draw_line(Vector2(xa, y - alto * 0.5), Vector2(xb, y - alto * 0.5), col, 2.0)
	var x := xa
	while x <= xb:
		draw_line(Vector2(x, y), Vector2(x, y - alto), col, 3.0)
		x += 20.0


func _balaustrada(xa: float, xb: float, y: float, alto: float, col: Color) -> void:
	draw_rect(Rect2(xa, y - alto - 6, xb - xa, 8), col)
	var x := xa + 8.0
	while x < xb - 6.0:
		draw_colored_polygon(_elipse(Vector2(x, y - alto * 0.5), Vector2(5, alto * 0.45)), col.darkened(0.08))
		x += 16.0


func _reja(xa: float, xb: float, y: float, alto: float) -> void:
	draw_line(Vector2(xa, y - alto + 8), Vector2(xb, y - alto + 8), HIERRO, 3.0)
	var x := xa
	while x <= xb:
		draw_line(Vector2(x, y), Vector2(x, y - alto), HIERRO, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, y - alto), Vector2(x + 4, y - alto), Vector2(x, y - alto - 9)]), HIERRO)
		x += 14.0


## Fachada colonial: muro, guardapolvo, techo de teja y ventanas (con balcón si se pide).
func _fachada(r: Rect2, col: Color, balcon: bool) -> void:
	draw_rect(r, col)
	draw_rect(Rect2(r.position.x, r.end.y - 60, r.size.x, 60), col.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(r.position.x - 8, r.position.y), Vector2(r.end.x + 8, r.position.y),
		Vector2(r.end.x, r.position.y - 18), Vector2(r.position.x, r.position.y - 18)]), TEJA)
	var x := r.position.x + 6.0
	while x < r.end.x:
		draw_line(Vector2(x, r.position.y - 18), Vector2(x - 2, r.position.y), TEJA.darkened(0.25), 2.0)
		x += 10.0
	if r.size.x < 60.0:
		return
	for vx in [r.position.x + r.size.x * 0.3, r.position.x + r.size.x * 0.7]:
		draw_rect(Rect2(vx - 13, r.position.y + 30, 26, 40), Color(0.2, 0.42, 0.32))
		draw_rect(Rect2(vx - 9, r.position.y + 34, 18, 32), Color(0.25, 0.3, 0.38))
		if balcon:
			draw_rect(Rect2(vx - 18, r.position.y + 70, 36, 5), HIERRO)
			for b in 5:
				draw_line(Vector2(vx - 16 + b * 8, r.position.y + 70), Vector2(vx - 16 + b * 8, r.position.y + 56), HIERRO, 2.0)
			draw_line(Vector2(vx - 18, r.position.y + 56), Vector2(vx + 18, r.position.y + 56), HIERRO, 2.0)
			draw_circle(Vector2(vx - 10, r.position.y + 52), 6.0, PICADO[0])
		draw_rect(Rect2(vx - 13, r.position.y + 110, 26, 40), Color(0.2, 0.42, 0.32))
		draw_rect(Rect2(vx - 9, r.position.y + 114, 18, 32), Color(0.25, 0.3, 0.38))


## Guirnalda de papel picado colgando entre dos puntos.
func _picado(a: Vector2, b: Vector2, comba: float) -> void:
	dibujar_picado(self, a, b, comba)


## Igual que _picado(), pero sobre cualquier CanvasItem; la usa Tramo para su decoración.
## comba = cuánto cuelga el centro, en px. Los colores dependen de a.x, así que la
## misma guirnalda siempre se ve igual.
static func dibujar_picado(ci: CanvasItem, a: Vector2, b: Vector2, comba: float) -> void:
	var n := maxi(2, int(a.distance_to(b) / 22.0))
	var prev := a
	for i in range(1, n + 1):
		var t := float(i) / n
		var p := a.lerp(b, t) + Vector2(0, comba * 4.0 * t * (1.0 - t))
		ci.draw_line(prev, p, Color(0.3, 0.3, 0.3), 1.5)
		if i < n:
			var col: Color = PICADO[(i + int(absf(a.x) / 7.0)) % PICADO.size()]
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 0), p + Vector2(7, 0), p + Vector2(7, 16),
				p + Vector2(3.5, 20), p + Vector2(0, 16), p + Vector2(-3.5, 20), p + Vector2(-7, 16)]), col)
			ci.draw_rect(Rect2(p + Vector2(-3, 5), Vector2(6, 5)), col.lightened(0.45))
		prev = p


## Polígono de 20 lados que aproxima una elipse de centro c y radios r.
static func _elipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts
