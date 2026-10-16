extends Accesorio
## Jarana de fandango: impulso hacia adelante y un rebote extra.

var impulso := Vector2(520, -240)


func _init() -> void:
	nombre = "Jarana de fandango"
	carisma = 5
	accion = "Impulso del son y un rebote extra"
	grito = "¡Que siga el son! +1 rebote"
	costo = 420
	orden = 50
	color = Color("bc8049")
	forma = [Vector2(-0.35, -0.1), Vector2(0.35, -0.1), Vector2(0.4, 0.3), Vector2(0.13, 0.85),
		Vector2(-0.13, 0.85), Vector2(-0.4, 0.3)]


func usar(m: Melon) -> void:
	m.empujar(impulso)
	m.sumar_rebote()


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var oscura := Color("6b4128")
	var crema := Color("f0d7a0")
	var mitad := [Vector2(0.25, -0.1), Vector2(0.36, 0.06), Vector2(0.29, 0.2), Vector2(0.21, 0.28),
		Vector2(0.26, 0.38), Vector2(0.21, 0.5)]
	var cuerpo := PackedVector2Array([Vector2(0, -0.13)])
	cuerpo.append_array(PackedVector2Array(mitad))
	cuerpo.append(Vector2(0, 0.55))
	for i in range(mitad.size() - 1, -1, -1):
		cuerpo.append(Vector2(-mitad[i].x, mitad[i].y))
	var pts := rellenar(ci, r, a, suave(cuerpo), color, 0.1)
	ci.draw_circle(uv(r, a, 0, 0.37), r * 0.1, crema, true, -1.0, true)
	ci.draw_circle(uv(r, a, 0, 0.37), r * 0.07, Color("3b261a"), true, -1.0, true)
	linea(ci, r, a, PackedVector2Array([Vector2(-0.13, 0.05), Vector2(0.13, 0.05)]), oscura, 0.06)
	contorno(ci, r, pts)
	pieza(ci, r, a, PackedVector2Array([Vector2(-0.055, 0.5), Vector2(0.055, 0.5), Vector2(0.05, 0.75),
		Vector2(-0.05, 0.75)]), oscura, 0.03)
	for v in [0.79, 0.85]:
		linea(ci, r, a, PackedVector2Array([Vector2(-0.15, v), Vector2(0.15, v)]), TINTA, 0.05)
	pieza(ci, r, a, suave(PackedVector2Array([Vector2(-0.09, 0.72), Vector2(0.09, 0.72), Vector2(0.11, 0.84),
		Vector2(0, 0.9), Vector2(-0.11, 0.84)]), 4), oscura, 0.03)
	for u in [-0.035, 0.0, 0.035]:
		linea(ci, r, a, PackedVector2Array([Vector2(u, 0.05), Vector2(u * 0.8, 0.76)]), crema, 0.018)
