extends Accesorio

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


func dibujar_detalle(ci: CanvasItem, r: float, a: float) -> void:
	ci.draw_circle(uv(r, a, 0, 0.18), r * 0.12, Color("543827"))
	for u in [-0.06, 0.06]:
		ci.draw_line(uv(r, a, u, 0.0), uv(r, a, u, 0.8), Color("f0d7a0"), maxf(0.6, ancho(r) * 0.4))
