extends Accesorio

var duracion := 2.0
var aceleracion := 350.0             # px/s² a lo largo del suelo


func _init() -> void:
	nombre = "Llantitas"
	carisma = 1
	accion = "Al tocar suelo acelera rodando ~2 s"
	inicial = true
	orden = 20
	color = Color(0.55, 0.55, 0.58)
	forma = [Vector2(-0.6, -0.1), Vector2(0.6, -0.1), Vector2(0.6, 0.5), Vector2(-0.6, 0.5)]


func usar(m: Melon) -> void:
	m.rodar(duracion, aceleracion)


func dibujar_detalle(ci: CanvasItem, r: float, a: float) -> void:
	for u in [-0.35, 0.35]:
		ci.draw_circle(uv(r, a, u, 0.38), r * 0.16, Color(0.12, 0.12, 0.12))
		ci.draw_circle(uv(r, a, u, 0.38), r * 0.06, Color(0.8, 0.8, 0.8))
