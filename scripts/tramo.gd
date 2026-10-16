class_name Tramo
extends Node2D
## Un tramo de terreno: superficie, colisión, casas de fondo y marcadores de distancia.
## Los tramos se encadenan (el último punto de uno es el primero del siguiente).
##
## Contenedores hijos (escenas/mundo/Tramo.tscn; se crean si faltan):
##   Decoracion (z -2)  casas, árboles y papel picado, detrás de todo
##   Postales   (z -1)  sitios de Xalapa; ver agregar_postal()
##   Suelo              StaticBody2D con un CollisionShape2D "Segmento###" por segmento
##   Obstaculos, Publico, Coleccionables  para lo que añada Recorrido
## El terreno y los marcadores se dibujan en _draw() de este nodo (z 0).

const PostalEscena := preload("res://escenas/mundo/Postal.tscn")
const CONTENEDORES := {"Decoracion": -2, "Postales": -1, "Obstaculos": 0, "Publico": 0, "Coleccionables": 0, "Aire": 0}

var puntos := PackedVector2Array()
var empedrado := false
var color_suelo := Color(0.36, 0.52, 0.25)
var marcadores: Array = []           # {pos, texto, lugar, sub}
var casas: Array = []                # {rect, color}
var personas: Array = []
var papalotes: Array = []
var x0 := 0.0
var x1 := 0.0
var _paso := 1.0
var _fondo := 0.0


func construir() -> void:
	x0 = puntos[0].x
	x1 = puntos[puntos.size() - 1].x
	_paso = puntos[1].x - puntos[0].x
	_fondo = 0.0
	for p in puntos:
		_fondo = maxf(_fondo, p.y)
	_fondo += 1500.0
	_asegurar_nodos()
	var cuerpo := get_node("Suelo") as StaticBody2D
	cuerpo.collision_layer = 1
	cuerpo.collision_mask = 0
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	mat.bounce = 0.0
	cuerpo.physics_material_override = mat
	for c in cuerpo.get_children():
		if c.name.begins_with("Segmento"):
			cuerpo.remove_child(c)
			c.queue_free()
	# Un cuadrilátero convexo grueso por segmento: evita que el melón atraviese el suelo.
	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var abajo := maxf(a.y, b.y) + 600.0
		var forma := ConvexPolygonShape2D.new()
		forma.set_point_cloud(PackedVector2Array([a, b, Vector2(b.x, abajo), Vector2(a.x, abajo)]))
		var cs := CollisionShape2D.new()
		cs.name = "Segmento%03d" % i
		cs.shape = forma
		cuerpo.add_child(cs)


func altura(x: float) -> float:
	var f := clampf((x - x0) / _paso, 0.0, puntos.size() - 1.001)
	var i := int(f)
	return lerpf(puntos[i].y, puntos[i + 1].y, f - i)


func pendiente(x: float) -> float:
	return atan2(altura(x + 10.0) - altura(x - 10.0), 20.0)


## datos: {pos: Vector2, tipo: String, nombre: String}. pos en coordenadas del tramo,
## a ras de suelo (p. ej. Vector2(x, altura(x))).
func agregar_postal(datos: Dictionary) -> Postal:
	_asegurar_nodos()
	var p: Postal = PostalEscena.instantiate()
	p.configurar(datos)
	get_node("Postales").add_child(p)
	return p


func _asegurar_nodos() -> void:
	if get_node_or_null("Suelo") == null:
		var s := StaticBody2D.new()
		s.name = "Suelo"
		add_child(s)
	for n in CONTENEDORES:
		var c := get_node_or_null(n) as Node2D
		if c == null:
			c = Node2D.new()
			c.name = n
			add_child(c)
		c.z_index = CONTENEDORES[n]
	var deco := get_node("Decoracion") as Node2D
	if not deco.draw.is_connected(_dibujar_decoracion):
		deco.draw.connect(_dibujar_decoracion.bind(deco))


static func _azar(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


# --- Fondo: árboles, casas y papel picado (nodo Decoracion, z -2) -------------

func _dibujar_decoracion(ci: CanvasItem) -> void:
	var x := x0 + 60.0 + 120.0 * _azar(x0)
	while x < x1:
		var h := _azar(x)
		if not empedrado or h < 0.35:
			_arbol(ci, Vector2(x, altura(x) + 30.0), h)
		x += 130.0 + 200.0 * _azar(x + 1.0)
	for c in casas:
		_casa(ci, c["rect"], c["color"])
	for i in casas.size() - 1:
		var a: Rect2 = casas[i]["rect"]
		var b: Rect2 = casas[i + 1]["rect"]
		if b.position.x - a.end.x < 260.0:
			Postal.dibujar_picado(ci, Vector2(a.end.x - 8, a.position.y + 26), Vector2(b.position.x + 8, b.position.y + 26), 34.0)


func _arbol(ci: CanvasItem, p: Vector2, h: float) -> void:
	var tronco := Color(0.4, 0.26, 0.16)
	if h < 0.25:
		# Platanera: hojas largas en abanico.
		ci.draw_line(p, p + Vector2(0, -150), Color(0.38, 0.5, 0.22), 10.0)
		for k in 6:
			var a := -PI / 2.0 + (k - 2.5) * 0.45
			var fin := p + Vector2(0, -150) + Vector2.from_angle(a) * 80.0 + Vector2(0, 20.0 * absf(k - 2.5))
			ci.draw_line(p + Vector2(0, -150), fin, Color(0.3, 0.58, 0.25).darkened(0.06 * k), 14.0)
		return
	var r := 40.0 + 40.0 * h
	var col := Color("a38aab") if h > 0.8 else Color("496d50").lightened(0.2 * h)
	ci.draw_line(p, p + Vector2(0, -r * 1.8), tronco, r * 0.2)
	ci.draw_circle(p + Vector2(-r * 0.6, -r * 1.7), r * 0.7, col.darkened(0.15))
	ci.draw_circle(p + Vector2(r * 0.6, -r * 1.75), r * 0.7, col.darkened(0.1))
	ci.draw_circle(p + Vector2(0, -r * 2.2), r, col)
	ci.draw_circle(p + Vector2(-r * 0.3, -r * 2.5), r * 0.45, col.lightened(0.15))


## Fachada colonial xalapeña: guardapolvo, techo de teja, ventanas con marco,
## balcones de hierro con macetas en el piso alto y portón en arco abajo.
func _casa(ci: CanvasItem, r: Rect2, color: Color) -> void:
	var h := _azar(r.position.x)
	var suelo := r.end.y - 40.0
	var alto_vis := suelo - r.position.y
	var pisos := 2 if alto_vis >= 170.0 else 1
	var alto_piso := alto_vis / pisos
	var marco: Color = [Color(0.18, 0.4, 0.3), Color(0.45, 0.24, 0.14), Color(0.2, 0.3, 0.55)][int(h * 3.0)]
	ci.draw_rect(r, color)
	ci.draw_rect(Rect2(r.position.x, suelo - 34.0, r.size.x, r.end.y - suelo + 34.0), color.darkened(0.28))
	ci.draw_line(Vector2(r.position.x, suelo - 34.0), Vector2(r.end.x, suelo - 34.0), color.darkened(0.45), 2.0)
	ci.draw_rect(Rect2(r.position.x, r.position.y + 2, r.size.x, 8), Color(0.97, 0.95, 0.9))
	if pisos == 2:
		ci.draw_line(Vector2(r.position.x, suelo - alto_piso), Vector2(r.end.x, suelo - alto_piso), color.darkened(0.15), 4.0)
	# Teja: faldón con canales verticales y borde ondulado.
	var teja := Color(0.72, 0.3, 0.2).darkened(0.12 * h)
	var top := r.position.y
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r.position.x - 10, top), Vector2(r.end.x + 10, top),
		Vector2(r.end.x, top - 26), Vector2(r.position.x, top - 26)]), teja)
	var tx := r.position.x - 4.0
	while tx < r.end.x + 6.0:
		ci.draw_line(Vector2(tx + 2, top - 26), Vector2(tx, top), teja.darkened(0.25), 2.0)
		ci.draw_circle(Vector2(tx + 5, top), 5.0, teja.lightened(0.08))
		tx += 11.0
	# Vanos por columna; uno abajo se vuelve portón.
	var cols := maxi(1, int((r.size.x - 20.0) / 50.0))
	var paso := r.size.x / cols
	var porton := int(h * 7.0) % cols
	for c in cols:
		var cx := r.position.x + paso * (c + 0.5)
		for piso in pisos:
			var base := suelo - alto_piso * piso
			if piso == 0 and c == porton:
				_porton(ci, cx, base, minf(alto_piso - 30.0, 70.0), marco)
				continue
			var vr := Rect2(cx - 12, base - alto_piso + 28, 24, minf(alto_piso - 52.0, 44.0))
			if vr.size.y < 14.0:
				continue
			ci.draw_rect(vr.grow(4), marco)
			ci.draw_rect(vr, Color(0.22, 0.27, 0.34))
			ci.draw_line(vr.position + Vector2(12, 0), vr.position + Vector2(12, vr.size.y), marco, 2.0)
			if piso == pisos - 1 and pisos > 1:
				_balcon(ci, cx, vr.end.y + 4, h + c)
			elif piso == 0:
				for b in 3:
					ci.draw_line(vr.position + Vector2(6 + b * 6, 0), vr.position + Vector2(6 + b * 6, vr.size.y),
						Color(0.15, 0.15, 0.16), 2.0)


func _porton(ci: CanvasItem, cx: float, base: float, alto: float, marco: Color) -> void:
	if alto < 30.0:
		return
	var w := 34.0
	var pts := PackedVector2Array([Vector2(cx - w / 2.0, base)])
	for i in 9:
		var a := PI + PI * i / 8.0
		pts.append(Vector2(cx, base - alto + w / 2.0) + Vector2.from_angle(a) * (w / 2.0))
	pts.append(Vector2(cx + w / 2.0, base))
	ci.draw_colored_polygon(pts, marco.darkened(0.2))
	ci.draw_line(Vector2(cx, base - alto + w / 2.0), Vector2(cx, base), marco.darkened(0.5), 2.0)


func _balcon(ci: CanvasItem, cx: float, y: float, h: float) -> void:
	var hierro := Color(0.14, 0.14, 0.15)
	ci.draw_rect(Rect2(cx - 22, y, 44, 5), hierro)
	ci.draw_line(Vector2(cx - 22, y - 18), Vector2(cx + 22, y - 18), hierro, 2.0)
	for b in 7:
		ci.draw_line(Vector2(cx - 21 + b * 7, y), Vector2(cx - 21 + b * 7, y - 18), hierro, 1.5)
	if _azar(h) < 0.6:
		# Macetas con bugambilia.
		ci.draw_rect(Rect2(cx - 18, y - 28, 10, 10), Color(0.7, 0.35, 0.2))
		ci.draw_circle(Vector2(cx - 13, y - 32), 8.0, Color(0.88, 0.22, 0.55))
		ci.draw_circle(Vector2(cx - 7, y - 36), 5.0, Color(0.3, 0.55, 0.25))


# --- Terreno y marcadores (z 0) ----------------------------------------------

func _draw() -> void:
	if puntos.size() < 2:
		return
	# Recorrido llama queue_redraw() tras poblar; el fondo de casas vive en otro nodo.
	var deco := get_node_or_null("Decoracion") as CanvasItem
	if deco != null:
		deco.queue_redraw()
	var poly := puntos.duplicate()
	poly.append(Vector2(x1, _fondo))
	poly.append(Vector2(x0, _fondo))
	draw_colored_polygon(poly, Color("95806a"))
	# Franja superior más clara: capa de calle o de pasto sobre la tierra.
	var franja := puntos.duplicate()
	for i in range(puntos.size() - 1, -1, -1):
		franja.append(puntos[i] + Vector2(0, 38))
	draw_colored_polygon(franja, color_suelo)
	var borde := Color(0.42, 0.4, 0.38) if empedrado else color_suelo.darkened(0.3)
	draw_polyline(puntos, borde, 10.0)
	if empedrado:
		var x := x0 + 9.0
		var fila := 0
		while x < x1:
			var y := altura(x)
			var tono := 0.08 * _azar(x)
			draw_circle(Vector2(x, y + 2.0), 5.5, Color(0.58, 0.55, 0.5).darkened(tono))
			draw_circle(Vector2(x + 8.5, y + 14.0), 5.0, Color(0.5, 0.47, 0.43).darkened(tono))
			if fila % 3 == 0:
				draw_circle(Vector2(x + 4, y + 26.0), 4.5, Color(0.46, 0.43, 0.4))
			x += 17.0
			fila += 1
	else:
		draw_polyline(puntos, color_suelo.lightened(0.18), 4.0)
		var x := x0 + 7.0
		while x < x1:
			var y := altura(x)
			var h := _azar(x)
			var pasto := color_suelo.lightened(0.1 + 0.15 * h)
			# Las hojas pequeñas pierden precisión si se triangulan lejos del origen.
			draw_set_transform(Vector2(x, y))
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 2), Vector2(-1, -8 - 8 * h), Vector2(1, 2)]), pasto)
			draw_colored_polygon(PackedVector2Array([Vector2(1, 2), Vector2(6, -6 - 6 * h), Vector2(5, 2)]), pasto)
			draw_set_transform(Vector2.ZERO)
			if h > 0.93:
				draw_circle(Vector2(x + 3, y - 12), 3.5, Color(0.98, 0.8, 0.25))
			x += 13.0 + 10.0 * h
	var fuente := ThemeDB.fallback_font
	for m in marcadores:
		var p: Vector2 = m["pos"]
		var lugar: bool = m["lugar"]
		var alto := 150.0 if lugar else 70.0
		draw_line(p, p + Vector2(0, -alto), Color(0.35, 0.25, 0.15), 5.0)
		var ancho := 200.0 if lugar else 70.0
		var caja := Rect2(p.x - ancho / 2.0, p.y - alto - (46.0 if lugar else 26.0), ancho, 46.0 if lugar else 26.0)
		draw_rect(caja, Color(0.15, 0.35, 0.2) if lugar else Color(0.95, 0.95, 0.9))
		var col := Color.WHITE if lugar else Color(0.15, 0.15, 0.15)
		if lugar:
			draw_string(fuente, Vector2(caja.position.x, caja.position.y + 20), m["texto"],
				HORIZONTAL_ALIGNMENT_CENTER, ancho, 16, col)
			draw_string(fuente, Vector2(caja.position.x, caja.position.y + 40), m["sub"],
				HORIZONTAL_ALIGNMENT_CENTER, ancho, 14, col)
		else:
			draw_string(fuente, Vector2(caja.position.x, caja.position.y + 19), m["texto"],
				HORIZONTAL_ALIGNMENT_CENTER, ancho, 15, col)
