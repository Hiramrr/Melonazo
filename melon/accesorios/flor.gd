extends Accesorio
## Flor de jardín: recupera un golpe y atrae los aplausos cercanos.

var duracion_iman := 6.0


func _init() -> void:
	nombre = "Flor de jardín"
	carisma = 4
	accion = "Recupera un golpe y atrae aplausos 6 s"
	grito = "¡Flor de jardín! Atraes aplausos"
	costo = 240
	orden = 40
	color = Color("dc80a6")
	forma = [Vector2(-0.4, -0.1), Vector2(0.4, -0.1), Vector2(0.5, 0.4), Vector2(0.0, 0.7), Vector2(-0.5, 0.4)]


func usar(m: Melon) -> void:
	m.reparar()
	m.atraer_aplausos(duracion_iman)


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var verde := Color("5f9e45")
	var tallo := PackedVector2Array([Vector2(0.03, -0.06), Vector2(0.05, 0.12), Vector2(0.01, 0.32)])
	linea(ci, r, a, tallo, TINTA, 0.13)
	linea(ci, r, a, tallo, verde.darkened(0.15), 0.07)
	for hoja in [[Vector2(0.05, 0.1), Vector2(0.42, 0.24)], [Vector2(0.03, 0.04), Vector2(-0.3, 0.17)]]:
		var pts := rellenar(ci, r, a, _hoja(hoja[0], hoja[1]), verde, 0.05)
		linea(ci, r, a, PackedVector2Array([hoja[0], hoja[0].lerp(hoja[1], 0.8)]), verde.darkened(0.3), 0.03)
		contorno(ci, r, pts)
	var centro := Vector2(0, 0.42)
	for p in 6:
		var giro := PI / 2.0 + p * TAU / 6.0
		pieza(ci, r, a, elipse(centro + Vector2.from_angle(giro) * 0.17, Vector2(0.16, 0.115), giro, 18), color, 0.05)
	ci.draw_circle(uv(r, a, centro.x, centro.y), r * 0.13, color.darkened(0.2), true, -1.0, true)
	pieza(ci, r, a, elipse(centro, Vector2(0.09, 0.09), 0.0, 16), Color("f1ce67"), 0.035)
	ci.draw_circle(uv(r, a, centro.x - 0.03, centro.y + 0.03), r * 0.025, Color("fff6df"), true, -1.0, true)


## Hoja con punta en ambos extremos, de base a punta.
func _hoja(base: Vector2, punta: Vector2) -> PackedVector2Array:
	var d := punta - base
	var n := Vector2(-d.y, d.x) * 0.3
	var pts := PackedVector2Array()
	for i in 10:
		pts.append(base + d * (i / 10.0) + n * sin(PI * i / 10.0))
	for i in 10:
		pts.append(base + d * (1.0 - i / 10.0) - n * sin(PI * (1.0 - i / 10.0)))
	return pts
