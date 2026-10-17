class_name Aspecto
extends RefCounted
## Capas de sprites compartidas por el taller, el almanaque y el recorrido.

const TINTA := Color("253e32")
static var _dibujos: Dictionary = {}

static func dibujar_melon(ci: CanvasItem, r: float, ids: Array, esta_roto := false, con_accesorios := true, datos: Dictionary = {}) -> void:
	var piel: Dictionary = Config.pieles[datos.get("piel", Juego.piel)]
	var cuerpo := Color.from_string(datos.get("cuerpo_propio", Juego.cuerpo_propio), piel["cuerpo"])
	var rayas := Color.from_string(datos.get("rayas_propio", Juego.rayas_propio), piel["rayas"])
	if esta_roto:
		cuerpo = cuerpo.darkened(0.25)
	var borde := rayas.lerp(TINTA, 0.45).darkened(0.12)
	_capa(ci, r, "cuerpo", cuerpo)
	dibujar_patron(ci, r, Config.patrones[datos.get("patron", Juego.patron)]["id"], cuerpo, rayas)
	_capa(ci, r, "sombra", Color(borde, 0.18))
	_capa(ci, r, "luz", cuerpo.lightened(0.5))
	_capa(ci, r, "tallo")
	dibujar_cara(ci, r, Config.caras[datos.get("cara", Juego.cara)]["id"])
	dibujar_detalle(ci, r, Config.detalles[datos.get("detalle", Juego.detalle)]["id"])
	dibujar_trazos(ci, r, datos.get("dibujo", Juego.dibujo))
	_capa(ci, r, "borde", borde)
	if esta_roto:
		_capa(ci, r, "grieta")
	if con_accesorios:
		for i in mini(ids.size(), Config.angulos_slots.size()):
			if ids[i] != null and Config.accesorios.has(ids[i]):
				Config.accesorios[ids[i]].dibujar(ci, r, deg_to_rad(Config.angulos_slots[i]))

static func _capa(ci: CanvasItem, r: float, id: String, color := Color.WHITE) -> void:
	Sprites.poner(ci, "melon/" + id, Vector2.ZERO, color, r / 32.0)

static func dibujar_patron(ci: CanvasItem, r: float, id: String, cuerpo: Color, rayas: Color) -> void:
	var color := cuerpo.lightened(0.46).lerp(rayas, 0.16) if id == "red" else cuerpo.lerp(rayas, 0.72)
	_capa(ci, r, "patron_" + id, color)

static func dibujar_cara(ci: CanvasItem, r: float, id: String) -> void:
	_capa(ci, r, "cara_" + id)

static func dibujar_detalle(ci: CanvasItem, r: float, id: String) -> void:
	_capa(ci, r, "detalle_" + id)

## Los trazos guardados conservan sus puntos; se pintan en un mapa de bits al cambiar.
static func dibujar_trazos(ci: CanvasItem, r: float, trazos: Array) -> void:
	if trazos.is_empty():
		return
	var clave := hash([r, trazos])
	var lado := ceili(r * 2.0 + Config.grosor_dibujo.y * r + 4.0)
	if not _dibujos.has(clave):
		var imagen := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
		var centro := Vector2.ONE * lado * 0.5
		for trazo in trazos:
			var puntos: PackedVector2Array = trazo["puntos"]
			var ancho := maxf(1.0, float(trazo["grosor"]) * r) * 0.5
			# Una máscara por trazo evita acumular opacidad en cruces y retrocesos.
			var mascara := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
			for i in puntos.size():
				var a := puntos[maxi(0, i - 1)] * r + centro
				var b := puntos[i] * r + centro
				var desde := (a.min(b) - Vector2.ONE * (ancho + 1)).floor().max(Vector2.ZERO)
				var hasta := (a.max(b) + Vector2.ONE * (ancho + 1)).ceil().min(Vector2.ONE * lado)
				for y in range(int(desde.y), int(hasta.y)):
					for x in range(int(desde.x), int(hasta.x)):
						var p := Vector2(x + 0.5, y + 0.5)
						var d := p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
						var col: Color = trazo["color"]
						col.a *= clampf(ancho + 0.5 - d, 0.0, 1.0)
						if col.a > mascara.get_pixel(x, y).a:
							mascara.set_pixel(x, y, col)
			imagen.blend_rect(mascara, Rect2i(0, 0, lado, lado), Vector2i.ZERO)
		if _dibujos.size() >= 64:
			_dibujos.clear()
		_dibujos[clave] = ImageTexture.create_from_image(imagen)
	ci.draw_texture_rect(_dibujos[clave], Rect2(Vector2.ONE * -lado * 0.5, Vector2.ONE * lado), false)
