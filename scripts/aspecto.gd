class_name Aspecto
extends RefCounted
## Dibujo del melón: piel, patrón, cara, detalle, dibujo libre y accesorios.
## Lo usan el melón del recorrido y la vista previa del taller.
## Para añadir una opción de aspecto, agrega su entrada en Config (pieles,
## patrones, caras o detalles) y su dibujo en el match de este archivo.

const TINTA := Color("253e32")


## Dibuja el melón centrado en el origen del CanvasItem. ids = accesorios por slot.
static func dibujar_melon(ci: CanvasItem, r: float, ids: Array, esta_roto := false, con_accesorios := true) -> void:
	var cuerpo := Juego.color_cuerpo()
	var rayas := Juego.color_rayas()
	if esta_roto:
		cuerpo = cuerpo.darkened(0.25)
	ci.draw_circle(Vector2.ZERO, r, rayas.darkened(0.15), true, -1.0, true)
	ci.draw_circle(Vector2.ZERO, r * 0.95, cuerpo.darkened(0.16), true, -1.0, true)
	ci.draw_circle(Vector2(-r * 0.055, -r * 0.065), r * 0.88, cuerpo, true, -1.0, true)
	dibujar_patron(ci, r, Config.patrones[Juego.patron]["id"], cuerpo, rayas)
	ci.draw_arc(Vector2(-r * 0.04, -r * 0.04), r * 0.76, PI * 1.12, PI * 1.56, 20, Color(cuerpo.lightened(0.45), 0.7), r * 0.075, true)
	ci.draw_polyline(PackedVector2Array([Vector2(0, -r * 0.94), Vector2(-r * 0.035, -r * 1.1), Vector2(r * 0.07, -r * 1.15)]), rayas.darkened(0.2), r * 0.07, true)
	dibujar_cara(ci, r, Config.caras[Juego.cara]["id"])
	dibujar_detalle(ci, r, Config.detalles[Juego.detalle]["id"])
	dibujar_trazos(ci, r, Juego.dibujo)
	ci.draw_arc(Vector2.ZERO, r * 0.98, 0.0, TAU, 64, rayas.darkened(0.15), maxf(0.8, r * 0.035), true)
	if esta_roto:
		var grieta := PackedVector2Array([Vector2(-r, -r * 0.1), Vector2(-r * 0.4, r * 0.2),
			Vector2(0, -r * 0.15), Vector2(r * 0.4, r * 0.25), Vector2(r, 0)])
		ci.draw_polyline(grieta, Color(0.85, 0.3, 0.25), maxf(2.0, r * 0.15))
	if con_accesorios:
		for i in ids.size():
			if ids[i] != null and Config.accesorios.has(ids[i]):
				Config.accesorios[ids[i]].dibujar(ci, r, deg_to_rad(Config.angulos_slots[i]))


## Línea recta que cruza el círculo a distancia d del centro, en la dirección ang.
static func _cuerda(ci: CanvasItem, r: float, d: float, ang: float, col: Color, w: float) -> void:
	if absf(d) >= 0.98:
		return
	var dir := Vector2.from_angle(ang)
	var media := sqrt(1.0 - d * d) * 0.97
	var centro := dir.orthogonal() * d
	ci.draw_line((centro - dir * media) * r, (centro + dir * media) * r, col, w, true)


static func dibujar_patron(ci: CanvasItem, r: float, id: String, cuerpo: Color, rayas: Color) -> void:
	var w := maxf(1.0, r * 0.08)
	match id:
		"rayas":
			for s in [-0.82, -0.5, 0.5, 0.82]:
				var pts := PackedVector2Array()
				for j in 33:
					var th := PI * j / 32.0
					pts.append(Vector2(s * r * 0.94 * sin(th), -r * 0.93 * cos(th)))
				ci.draw_polyline(pts, Color(rayas, 0.72), maxf(0.8, r * 0.055), true)
		"lunares":
			for l in [Vector3(-0.5, -0.55, 0.16), Vector3(0.1, -0.7, 0.12), Vector3(0.6, -0.4, 0.15),
					Vector3(-0.75, 0.15, 0.12), Vector3(0.72, 0.25, 0.13), Vector3(-0.4, 0.62, 0.15),
					Vector3(0.25, 0.7, 0.14), Vector3(0.0, -0.35, 0.08)]:
				ci.draw_circle(Vector2(l.x, l.y) * r, l.z * r, rayas)
		"red":
			var claro := cuerpo.lerp(rayas, 0.55)
			for d in [-0.72, -0.36, 0.0, 0.36, 0.72]:
				_cuerda(ci, r, d, PI / 4.0, claro, w * 0.6)
				_cuerda(ci, r, d, -PI / 4.0, claro, w * 0.6)
		"zigzag":
			for y in [-0.55, 0.0, 0.55]:
				var media := sqrt(1.0 - y * y) * 0.96
				var pts := PackedVector2Array()
				var pasos := 10
				for j in pasos + 1:
					var x := -media + 2.0 * media * j / pasos
					var dy := 0.1 if j % 2 == 0 else -0.1
					pts.append(Vector2(x, clampf(y + dy, -sqrt(1.0 - x * x), sqrt(1.0 - x * x))) * r)
				ci.draw_polyline(pts, rayas, w * 1.2, true)
		"franjas":
			for d in [-0.6, 0.0, 0.6]:
				_cuerda(ci, r, d, 0.0, rayas, r * 0.18)
		"liso":
			pass


static func dibujar_cara(ci: CanvasItem, r: float, id: String) -> void:
	if id == "sin_cara":
		return
	var w := maxf(1.2, r * 0.07)
	for lado in [-1, 1]:
		var ojo := Vector2(lado * r * 0.3, -r * 0.12)
		match id:
			"dormido":
				ci.draw_line(ojo - Vector2(r * 0.12, 0), ojo + Vector2(r * 0.12, 0), TINTA, w, true)
			"lentes":
				ci.draw_circle(ojo, r * 0.19, TINTA)
				ci.draw_line(ojo + Vector2(-r * 0.09, -r * 0.06), ojo + Vector2(r * 0.02, -r * 0.06), Color("a1c2be"), r * 0.04, true)
			"guino":
				if lado < 0:
					ci.draw_arc(ojo + Vector2(0, r * 0.04), r * 0.1, PI * 1.1, PI * 1.9, 8, TINTA, w, true)
				else:
					ci.draw_circle(ojo, r * 0.09, TINTA)
			"enamorado":
				ci.draw_colored_polygon(_corazon(ojo, r * 0.13), Color("cf3f5a"))
			_:
				ci.draw_circle(ojo, r * 0.095, TINTA, true, -1.0, true)
				ci.draw_circle(ojo + Vector2(-r * 0.025, -r * 0.025), r * 0.028, Color("fff6df"), true, -1.0, true)
				if id == "valiente":
					ci.draw_line(ojo + Vector2(-r * 0.14, -r * 0.2), ojo + Vector2(r * 0.14, -r * (0.2 - lado * 0.12)), TINTA, w, true)
	match id:
		"susto":
			ci.draw_circle(Vector2(0, r * 0.3), r * 0.16, TINTA)
		"lengua":
			ci.draw_arc(Vector2(0, r * 0.05), r * 0.35, 0.2 * PI, 0.8 * PI, 14, TINTA, w, true)
			ci.draw_circle(Vector2(r * 0.1, r * 0.45), r * 0.1, Color("e0708a"))
		_:
			ci.draw_arc(Vector2(0, r * 0.05), r * 0.35, 0.2 * PI, 0.8 * PI, 14, TINTA, w, true)
	if id == "lentes":
		ci.draw_line(Vector2(-r * 0.1, -r * 0.12), Vector2(r * 0.1, -r * 0.12), TINTA, r * 0.06, true)


static func dibujar_detalle(ci: CanvasItem, r: float, id: String) -> void:
	match id:
		"mejillas":
			for lado in [-1, 1]:
				ci.draw_circle(Vector2(lado * r * 0.55, r * 0.15), r * 0.12, Color(0.93, 0.42, 0.5, 0.55))
		"pecas":
			for lado in [-1, 1]:
				for p in [Vector2(0.42, 0.05), Vector2(0.52, 0.12), Vector2(0.46, 0.2), Vector2(0.58, 0.02)]:
					ci.draw_circle(Vector2(lado * p.x, p.y) * r, maxf(0.8, r * 0.035), Color("8a5a3c"))
		"bigote":
			for lado in [-1, 1]:
				var pts := PackedVector2Array()
				for j in 9:
					var t := j / 8.0
					pts.append(Vector2(lado * (0.04 + 0.34 * t), 0.2 + 0.06 * sin(t * PI) - 0.1 * t * t) * r)
				ci.draw_polyline(pts, Color("3a2a20"), maxf(2.0, r * 0.11), true)
		"curita":
			var c := Vector2(r * 0.42, -r * 0.48)
			var x := Vector2.from_angle(-0.6) * r * 0.24
			var y := x.orthogonal() * 0.35
			ci.draw_colored_polygon(PackedVector2Array([c - x - y, c + x - y, c + x + y, c - x + y]), Color("e8c39a"))
			ci.draw_colored_polygon(PackedVector2Array([c - x * 0.35 - y, c + x * 0.35 - y, c + x * 0.35 + y, c - x * 0.35 + y]), Color("d4a77a"))
		"brillo":
			ci.draw_arc(Vector2.ZERO, r * 0.78, PI * 1.15, PI * 1.45, 10, Color(1, 1, 1, 0.65), maxf(1.5, r * 0.1), true)
			ci.draw_circle(Vector2(-r * 0.2, -r * 0.8), maxf(1.0, r * 0.05), Color(1, 1, 1, 0.65))


## Trazos del dibujo libre (Juego.dibujo), en unidades del radio.
static func dibujar_trazos(ci: CanvasItem, r: float, trazos: Array) -> void:
	for trazo in trazos:
		var col: Color = trazo["color"]
		var w := maxf(1.0, float(trazo["grosor"]) * r)
		var puntos: PackedVector2Array = trazo["puntos"]
		if puntos.size() == 1:
			ci.draw_circle(puntos[0] * r, w * 0.5, col)
			continue
		var escalados := PackedVector2Array()
		for p in puntos:
			escalados.append(p * r)
		ci.draw_polyline(escalados, col, w, true)
		# Puntas redondas para que las líneas gruesas no se vean cortadas.
		ci.draw_circle(escalados[0], w * 0.5, col)
		ci.draw_circle(escalados[-1], w * 0.5, col)


static func _corazon(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for j in 20:
		var t := TAU * j / 20.0
		pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * s / 16.0)
	return pts
