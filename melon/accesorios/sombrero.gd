extends Accesorio
## Sombrero ancho: frena en seco en el aire para caer donde quieres. Inicial.

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


func usar(m: Melon) -> void:
	m.fijar_velocidad(Vector2(m.linear_velocity.x * freno_x, minf(m.linear_velocity.y, vel_y)))
