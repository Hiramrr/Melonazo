extends Accesorio

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


func dibujar_detalle(ci: CanvasItem, r: float, a: float) -> void:
	var w := ancho(r) * 1.5
	ci.draw_line(uv(r, a, -0.25, -0.1), uv(r, a, -0.15, 0.3), Color.WHITE, w)
	ci.draw_line(uv(r, a, 0.25, -0.1), uv(r, a, 0.15, 0.3), Color.WHITE, w)
	ci.draw_line(uv(r, a, 0.0, -0.1), uv(r, a, 0.0, 0.32), Color(0.9, 0.15, 0.2), w)
