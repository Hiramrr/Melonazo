extends Accesorio
## Capa: planeo largo con poca gravedad. Se desbloquea en el taller.

var duracion := 2.5
var gravedad := 0.22                 # gravity_scale durante el planeo


func _init() -> void:
	nombre = "Capa"
	carisma = 3
	accion = "Planeo largo: menos gravedad 2.5 s"
	grito = "¡Planeo!"
	costo = 300
	orden = 60
	color = Color(0.85, 0.15, 0.22)
	forma = [Vector2(-0.6, -0.1), Vector2(0.6, -0.1), Vector2(0.8, 0.28), Vector2(-0.8, 0.28)]


func usar(m: Melon) -> void:
	m.planear(duracion, gravedad)


func dibujar_detalle(ci: CanvasItem, r: float, a: float) -> void:
	ci.draw_line(uv(r, a, -0.8, 0.28), uv(r, a, 0.8, 0.28), Color(1, 0.85, 0.2), ancho(r) * 1.5)
