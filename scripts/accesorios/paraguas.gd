extends Accesorio

var duracion := 3.0
var gravedad := 0.35
var vel_caida := 140.0               # velocidad máxima de caída


func _init() -> void:
	nombre = "Paraguas"
	carisma = 2
	accion = "Caída lenta; la siguiente caída no daña"
	grito = "¡Paraguas!"
	costo = 380
	orden = 80
	color = Color(0.6, 0.2, 0.7)
	forma = [Vector2(-0.1, -0.1), Vector2(0.1, -0.1), Vector2(0.8, 0.32), Vector2(0.5, 0.62),
		Vector2(-0.5, 0.62), Vector2(-0.8, 0.32)]


func usar(m: Melon) -> void:
	m.caida_lenta(duracion, gravedad, vel_caida)
	m.proteger()


# El dibujo no sigue la forma de colisión: mango y tela por separado.
func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	ci.draw_line(uv(r, a, 0, -0.1), uv(r, a, 0, 0.6), Color(0.25, 0.2, 0.15), ancho(r) * 1.5)
	var tela := PackedVector2Array([uv(r, a, -0.8, 0.32), uv(r, a, 0.8, 0.32),
		uv(r, a, 0.5, 0.62), uv(r, a, -0.5, 0.62)])
	ci.draw_colored_polygon(tela, color)
	tela.append(tela[0])
	ci.draw_polyline(tela, color.darkened(0.4), ancho(r))
