extends Accesorio

var freno_x := 0.25                  # multiplica la velocidad horizontal
var vel_y := 60.0                    # velocidad vertical máxima tras frenar


func _init() -> void:
	nombre = "Sombrero ancho"
	carisma = 2
	accion = "Frenado en el aire para caer preciso"
	grito = "¡Frenón!"
	inicial = true
	orden = 10
	color = Color(0.9, 0.78, 0.4)
	forma = [Vector2(-0.85, -0.05), Vector2(0.85, -0.05), Vector2(0.85, 0.1), Vector2(0.32, 0.42),
		Vector2(-0.32, 0.42), Vector2(-0.85, 0.1)]


func usar(m: Melon) -> void:
	m.fijar_velocidad(Vector2(m.linear_velocity.x * freno_x, minf(m.linear_velocity.y, vel_y)))


func dibujar_detalle(ci: CanvasItem, r: float, a: float) -> void:
	ci.draw_line(uv(r, a, -0.38, 0.14), uv(r, a, 0.38, 0.14), Color(0.75, 0.2, 0.15), ancho(r) * 2.0)
