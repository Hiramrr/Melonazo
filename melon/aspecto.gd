class_name Aspecto
extends RefCounted
## Dibujo compartido por el taller y el recorrido, en unidades del radio.

const TINTA := Color("253e32")
const CREMA := Color("fff3d5")
const ROSA := Color("df7180")


static func dibujar_melon(ci: CanvasItem, r: float, ids: Array, esta_roto := false, con_accesorios := true, datos: Dictionary = {}) -> void:
	var piel: Dictionary = Config.pieles[datos.get("piel", Juego.piel)]
	var cuerpo := Color.from_string(datos.get("cuerpo_propio", Juego.cuerpo_propio), piel["cuerpo"])
	var rayas := Color.from_string(datos.get("rayas_propio", Juego.rayas_propio), piel["rayas"])
	if esta_roto:
		cuerpo = cuerpo.darkened(0.25)
	var borde := rayas.lerp(TINTA, 0.45).darkened(0.12)
	ci.draw_circle(Vector2.ZERO, r, cuerpo, true, -1.0, true)
	dibujar_patron(ci, r, Config.patrones[datos.get("patron", Juego.patron)]["id"], cuerpo, rayas)
	# Una sombra curva sigue la cáscara sin crear círculos concéntricos.
	var sombra := PackedVector2Array()
	for j in 33:
		var a := -PI * 0.25 + PI * j / 32.0
		sombra.append(Vector2.from_angle(a) * 0.98)
	for j in range(31, 0, -1):
		var a := -PI * 0.25 + PI * j / 32.0
		sombra.append(Vector2.from_angle(a) * (0.98 - 0.2 * sin(PI * j / 32.0)))
	_poligono(ci, r, sombra, Color(borde, 0.18))
	ci.draw_arc(Vector2.ZERO, r * 0.975, 0, TAU, 80, borde, maxf(0.9, r * 0.045), true)
	_trazo(ci, r, _curva(Vector2(-0.73, -0.38), Vector2(-0.68, -0.58), Vector2(-0.55, -0.7), Vector2(-0.38, -0.74)), cuerpo.lightened(0.5), 0.07)
	_ovalo(ci, r, Vector2(-0.27, -0.8), Vector2(0.035, 0.022), cuerpo.lightened(0.5))
	_dibujar_tallo(ci, r, borde)
	dibujar_cara(ci, r, Config.caras[datos.get("cara", Juego.cara)]["id"])
	dibujar_detalle(ci, r, Config.detalles[datos.get("detalle", Juego.detalle)]["id"])
	dibujar_trazos(ci, r, datos.get("dibujo", Juego.dibujo))
	# El borde va encima del dibujo libre: antes el trazo tapaba el contorno y el
	# color se veía cortado en el borde del melón.
	ci.draw_arc(Vector2.ZERO, r * 0.975, 0, TAU, 80, borde, maxf(0.9, r * 0.045), true)
	if esta_roto:
		var grieta := PackedVector2Array([Vector2(-0.95, -0.12), Vector2(-0.47, 0.16), Vector2(-0.24, 0.05), Vector2(0.02, 0.27), Vector2(0.3, 0.1), Vector2(0.52, 0.3), Vector2(0.96, 0.04)])
		_trazo(ci, r, grieta, Color("823f34"), 0.09)
	if con_accesorios:
		for i in mini(ids.size(), Config.angulos_slots.size()):
			if ids[i] != null and Config.accesorios.has(ids[i]):
				Config.accesorios[ids[i]].dibujar(ci, r, deg_to_rad(Config.angulos_slots[i]))


static func _dibujar_tallo(ci: CanvasItem, r: float, borde: Color) -> void:
	_trazo(ci, r, _curva(Vector2(0, -0.96), Vector2(-0.07, -1.08), Vector2(0.07, -1.11), Vector2(0.09, -1.18)), borde, 0.065)
	var hoja := _curva(Vector2(-0.01, -1.04), Vector2(-0.25, -0.98), Vector2(-0.31, -1.19), Vector2(-0.3, -1.22))
	hoja.append_array(_curva(Vector2(-0.3, -1.22), Vector2(-0.07, -1.27), Vector2(0.04, -1.12), Vector2(-0.01, -1.04)))
	_poligono(ci, r, hoja, Color("61864b"), borde, 0.025)
	_trazo(ci, r, PackedVector2Array([Vector2(-0.02, -1.06), Vector2(-0.21, -1.17)]), Color("a6c677"), 0.018)


static func dibujar_patron(ci: CanvasItem, r: float, id: String, cuerpo: Color, rayas: Color) -> void:
	var color := cuerpo.lerp(rayas, 0.72)
	match id:
		"rayas":
			for s in [-0.8, -0.46, 0.46, 0.8]:
				var pts := PackedVector2Array()
				for lado in [-1, 1]:
					for j in 33:
						var paso: int = j if lado == -1 else 32 - j
						var t := PI * paso / 32.0
						var x: float = s * sin(t) + 0.022 * sin(t * 4 + s) * sin(t)
						pts.append(Vector2(x + lado * 0.058 * sin(t), -0.95 * cos(t)))
				_poligono(ci, r, pts, color)
		"lunares":
			for l in [Vector3(-0.51, -0.57, 0.13), Vector3(0.1, -0.72, 0.1), Vector3(0.6, -0.42, 0.12), Vector3(-0.76, 0.05, 0.1), Vector3(0.74, 0.18, 0.1), Vector3(-0.42, 0.64, 0.13), Vector3(0.25, 0.73, 0.11)]:
				_ovalo(ci, r, Vector2(l.x, l.y), Vector2(l.z, l.z * 0.85), color)
		"red":
			var hilo := cuerpo.lightened(0.46).lerp(rayas, 0.16)
			for d in [-0.76, -0.5, -0.25, 0.0, 0.25, 0.5, 0.76]:
				_cuerda(ci, r, d, PI / 4, hilo, 0.025)
				_cuerda(ci, r, d, -PI / 4, hilo, 0.025)
		"zigzag":
			for y in [-0.57, 0.0, 0.57]:
				var pts := PackedVector2Array()
				var media := sqrt(0.9 * 0.9 - y * y)
				for j in 9:
					var x := lerpf(-media, media, j / 8.0)
					var limite := sqrt(0.94 * 0.94 - x * x)
					pts.append(Vector2(x, clampf(y + (0.075 if j % 2 == 0 else -0.075), -limite, limite)))
				_trazo(ci, r, pts, color, 0.06)
		"franjas":
			for y in [-0.59, 0.0, 0.59]:
				var pts := PackedVector2Array()
				for lado in [-1, 1]:
					for j in 13:
						var paso: int = j if lado == 1 else 12 - j
						var alto: float = y - 0.085 + 0.17 * paso / 12.0
						pts.append(Vector2(lado * sqrt(0.95 * 0.95 - alto * alto), alto))
				_poligono(ci, r, pts, color)


static func _cuerda(ci: CanvasItem, r: float, d: float, a: float, col: Color, grosor: float) -> void:
	var dir := Vector2.from_angle(a)
	var media := sqrt(0.93 * 0.93 - d * d)
	var pts := PackedVector2Array()
	for j in 17:
		var t := j / 16.0
		pts.append(dir * lerpf(-media, media, t) + dir.orthogonal() * (d + 0.012 * sin(t * TAU * 2) * sin(t * PI)))
	_trazo(ci, r, pts, col, grosor)


static func dibujar_cara(ci: CanvasItem, r: float, id: String) -> void:
	if id == "sin_cara":
		return
	for lado in [-1, 1]:
		var ojo := Vector2(lado * 0.29, -0.12)
		match id:
			"dormido":
				var parpado := _curva(ojo + Vector2(-0.12, -0.025), ojo + Vector2(-0.06, 0.055), ojo + Vector2(0.06, 0.055), ojo + Vector2(0.12, -0.025))
				_trazo(ci, r, parpado, TINTA, 0.052)
				_trazo(ci, r, PackedVector2Array([ojo + Vector2(lado * 0.09, 0.01), ojo + Vector2(lado * 0.14, 0.065)]), TINTA, 0.035)
			"lentes":
				var lente := _curva(ojo + Vector2(-0.21, -0.1), ojo + Vector2(-0.2, 0.22), ojo + Vector2(0.2, 0.22), ojo + Vector2(0.21, -0.1))
				_poligono(ci, r, lente, TINTA, TINTA, 0.045)
				_trazo(ci, r, PackedVector2Array([ojo + Vector2(-0.1, 0.025), ojo + Vector2(0.005, -0.045)]), Color("8eb5a4"), 0.038)
			"guino":
				if lado == 1:
					_trazo(ci, r, _curva(ojo + Vector2(-0.12, 0.04), ojo + Vector2(-0.05, -0.07), ojo + Vector2(0.04, -0.07), ojo + Vector2(0.12, 0.01)), TINTA, 0.055)
				else:
					_ojo(ci, r, ojo)
			"enamorado":
				_poligono(ci, r, _corazon(ojo, 0.16), Color("c64e64"))
			_:
				_ojo(ci, r, ojo, 1.17 if id == "susto" else 1.0)
		if id == "valiente":
			_trazo(ci, r, PackedVector2Array([ojo + Vector2(lado * 0.13, -0.24), ojo + Vector2(-lado * 0.09, -0.13)]), TINTA, 0.062)
		elif id == "susto":
			_trazo(ci, r, _curva(ojo + Vector2(-0.1, -0.26), ojo + Vector2(-0.04, -0.31), ojo + Vector2(0.04, -0.31), ojo + Vector2(0.1, -0.26)), TINTA, 0.035)
	match id:
		"susto":
			_ovalo(ci, r, Vector2(0, 0.34), Vector2(0.115, 0.155), TINTA)
			_ovalo(ci, r, Vector2(0.025, 0.41), Vector2(0.05, 0.035), ROSA)
		"dormido":
			_trazo(ci, r, _curva(Vector2(-0.1, 0.29), Vector2(-0.04, 0.35), Vector2(0.04, 0.35), Vector2(0.1, 0.29)), TINTA, 0.04)
		"valiente", "lentes":
			_trazo(ci, r, _curva(Vector2(-0.2, 0.24), Vector2(-0.07, 0.42), Vector2(0.12, 0.43), Vector2(0.24, 0.18)), TINTA, 0.055)
		_:
			var boca := _curva(Vector2(-0.24, 0.23), Vector2(-0.1, 0.29), Vector2(0.1, 0.29), Vector2(0.24, 0.23))
			boca.append_array(_curva(Vector2(0.24, 0.23), Vector2(0.15, 0.52), Vector2(-0.15, 0.52), Vector2(-0.24, 0.23)))
			_poligono(ci, r, boca, TINTA, TINTA, 0.025)
			if id == "lengua":
				var lengua := _curva(Vector2(0.02, 0.35), Vector2(0.06, 0.62), Vector2(0.26, 0.6), Vector2(0.25, 0.33))
				_poligono(ci, r, lengua, ROSA, TINTA, 0.025)
				_trazo(ci, r, PackedVector2Array([Vector2(0.14, 0.37), Vector2(0.14, 0.46)]), Color("ad4a5c"), 0.018)
			else:
				_ovalo(ci, r, Vector2(0.02, 0.397), Vector2(0.095, 0.035), ROSA)
	if id == "lentes":
		_trazo(ci, r, _curva(Vector2(-0.09, -0.15), Vector2(-0.04, -0.2), Vector2(0.04, -0.2), Vector2(0.09, -0.15)), TINTA, 0.055)
		for lado in [-1, 1]:
			_trazo(ci, r, PackedVector2Array([Vector2(lado * 0.49, -0.19), Vector2(lado * 0.62, -0.24)]), TINTA, 0.05)


static func _ojo(ci: CanvasItem, r: float, centro: Vector2, escala := 1.0) -> void:
	_ovalo(ci, r, centro, Vector2(0.092, 0.137) * escala, TINTA)
	_ovalo(ci, r, centro + Vector2(-0.025, -0.046), Vector2(0.032, 0.038), CREMA)


static func dibujar_detalle(ci: CanvasItem, r: float, id: String) -> void:
	match id:
		"mejillas":
			for lado in [-1, 1]:
				_ovalo(ci, r, Vector2(lado * 0.52, 0.18), Vector2(0.135, 0.075), Color(ROSA, 0.64))
				for x in [-0.035, 0.035]:
					_trazo(ci, r, PackedVector2Array([Vector2(lado * 0.52 + x, 0.15), Vector2(lado * 0.52 + x - 0.012, 0.19)]), Color("be606a"), 0.016)
		"pecas":
			for lado in [-1, 1]:
				for p in [Vector2(0.43, 0.13), Vector2(0.53, 0.2), Vector2(0.61, 0.1)]:
					_ovalo(ci, r, Vector2(lado * p.x, p.y), Vector2(0.025, 0.028), Color("92603f"))
		"bigote":
			for lado in [-1, 1]:
				var bigote := _curva(Vector2(0, 0.19), Vector2(lado * 0.13, 0.02), Vector2(lado * 0.22, 0.27), Vector2(lado * 0.4, 0.14))
				bigote.append_array(_curva(Vector2(lado * 0.4, 0.14), Vector2(lado * 0.29, 0.43), Vector2(lado * 0.07, 0.28), Vector2(0, 0.19)))
				_poligono(ci, r, bigote, Color("49372a"))
		"curita":
			var c := Vector2(0.43, -0.48)
			var x := Vector2.from_angle(-0.6) * 0.23
			var y := x.orthogonal() * 0.38
			_poligono(ci, r, PackedVector2Array([c - x - y, c + x - y, c + x + y, c - x + y]), Color("e8c39a"), Color("ae8057"), 0.018)
			_poligono(ci, r, PackedVector2Array([c - x * 0.32 - y, c + x * 0.32 - y, c + x * 0.32 + y, c - x * 0.32 + y]), Color("f4dbb4"))
			for lado in [-1, 1]:
				for fila in [-1, 1]:
					_ovalo(ci, r, c + x * lado * 0.65 + y * fila * 0.4, Vector2.ONE * 0.014, Color("ae8057"))
		"brillo":
			var c := Vector2(-0.49, -0.51)
			var estrella := PackedVector2Array([c + Vector2(0, -0.13), c + Vector2(0.035, -0.035), c + Vector2(0.12, 0), c + Vector2(0.035, 0.035), c + Vector2(0, 0.13), c + Vector2(-0.035, 0.035), c + Vector2(-0.12, 0), c + Vector2(-0.035, -0.035)])
			_poligono(ci, r, estrella, CREMA)
			_ovalo(ci, r, Vector2(-0.26, -0.65), Vector2.ONE * 0.032, CREMA)


static func dibujar_trazos(ci: CanvasItem, r: float, trazos: Array) -> void:
	for trazo in trazos:
		var col: Color = trazo["color"]
		var w := maxf(1.0, float(trazo["grosor"]) * r)
		var puntos: PackedVector2Array = trazo["puntos"]
		# Segmentos independientes y uniones redondas evitan deformaciones al retroceder.
		var segmentos := PackedVector2Array()
		for i in range(1, puntos.size()):
			segmentos.append(puntos[i - 1] * r)
			segmentos.append(puntos[i] * r)
		if not segmentos.is_empty():
			ci.draw_multiline(segmentos, col, w, true)
		for p in puntos:
			ci.draw_circle(p * r, w * 0.5, col, true, -1.0, true)


static func _curva(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for j in 17:
		pts.append(p0.bezier_interpolate(p1, p2, p3, j / 16.0))
	return pts


static func _poligono(ci: CanvasItem, r: float, pts: PackedVector2Array, color: Color, borde := Color.TRANSPARENT, grosor := 0.0) -> void:
	var escalados := PackedVector2Array()
	for p in pts:
		escalados.append(p * r)
	ci.draw_colored_polygon(escalados, color)
	escalados.append(escalados[0])
	ci.draw_polyline(escalados, borde if grosor > 0 else color, maxf(0.5, r * grosor), true)


static func _trazo(ci: CanvasItem, r: float, pts: PackedVector2Array, color: Color, grosor: float) -> void:
	var escalados := PackedVector2Array()
	for p in pts:
		escalados.append(p * r)
	var w := maxf(0.5, r * grosor)
	ci.draw_polyline(escalados, color, w, true)
	ci.draw_circle(escalados[0], w * 0.5, color, true, -1.0, true)
	ci.draw_circle(escalados[-1], w * 0.5, color, true, -1.0, true)


static func _ovalo(ci: CanvasItem, r: float, c: Vector2, ejes: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for j in 32:
		pts.append(c + Vector2.from_angle(TAU * j / 32.0) * ejes)
	_poligono(ci, r, pts, color)


static func _corazon(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for j in 40:
		var t := TAU * j / 40.0
		pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * s / 16.0)
	return pts
