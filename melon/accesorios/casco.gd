extends Accesorio
## Casco de luchador: embestida hacia adelante que rompe puestos.

var duracion := 0.9                  # s en que rompe obstáculos frágiles
var impulso := Vector2(750, -120)


func _init() -> void:
	nombre = "Casco de luchador"
	carisma = 4
	accion = "Embestida: impulso, rompe puestos"
	grito = "¡Embestida!"
	costo = 500
	orden = 70
	color = Color(0.2, 0.35, 0.85)
	forma = [Vector2(-0.7, -0.15), Vector2(0.7, -0.15), Vector2(0.45, 0.32), Vector2(-0.45, 0.32)]


func usar(m: Melon) -> void:
	m.embestir(duracion, impulso)


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var domo := _franja(-0.72, 0.72, 24)
	for i in range(1, 12):  # la base abraza la piel del melón
		var u := -0.72 + 1.44 * i / 12.0
		domo.append(Vector2(u, piel(u) + 0.05))
	var pts := rellenar(ci, r, a, domo, color, 0.12)
	var blanco := Color("f4efe1")
	for f in [[-0.27, -0.16, blanco], [-0.07, 0.07, Color("d8433b")], [0.16, 0.27, blanco.darkened(0.18)]]:
		for parte in Geometry2D.intersect_polygons(_franja(f[0], f[1], 8), domo):
			poligono(ci, uvs(r, a, parte), f[2])
	var borde := PackedVector2Array()
	for i in 13:
		var u := -0.72 + 1.44 * i / 12.0
		borde.append(Vector2(u, piel(u) + 0.05))
	for i in 13:
		var u := 0.72 - 1.44 * i / 12.0
		borde.append(Vector2(u, piel(u) + 0.15))
	for parte in Geometry2D.intersect_polygons(borde, domo):
		poligono(ci, uvs(r, a, parte), color.darkened(0.45))
	var brillo := PackedVector2Array()
	for i in 6:
		var t := PI * (0.6 + 0.04 * i)
		brillo.append(Vector2(0.56 * cos(t), -0.26 + 0.5 * sin(t)))
	linea(ci, r, a, brillo, Color(1, 1, 1, 0.6), 0.07)
	contorno(ci, r, pts)


## Gajo de la cúpula entre dos meridianos u0 y u1, que se juntan en la cima.
func _franja(u0: float, u1: float, pasos: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in pasos + 1:
		var t := PI / 2.0 * i / pasos
		pts.append(Vector2(u0 * cos(t), -0.26 + 0.62 * sin(t)))
	for i in range(1, pasos + 1):
		var t := PI / 2.0 * (pasos - i) / pasos
		pts.append(Vector2(u1 * cos(t), -0.26 + 0.62 * sin(t)))
	return pts
