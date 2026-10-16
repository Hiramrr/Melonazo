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
	forma = [Vector2(-0.85, -0.05), Vector2(0.85, -0.05), Vector2(0.85, 0.1), Vector2(0.32, 0.42),
		Vector2(-0.32, 0.42), Vector2(-0.85, 0.1)]


func usar(m: Melon) -> void:
	m.fijar_velocidad(Vector2(m.linear_velocity.x * freno_x, minf(m.linear_velocity.y, vel_y)))


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var trenzado := color.darkened(0.3)
	var ala := rellenar(ci, r, a, suave(PackedVector2Array([Vector2(-0.93, 0.2), Vector2(-0.66, 0.0),
		Vector2(0, -0.1), Vector2(0.66, 0.0), Vector2(0.93, 0.2), Vector2(0.62, 0.13), Vector2(0, 0.11),
		Vector2(-0.62, 0.13)])), color, 0.05)
	linea(ci, r, a, PackedVector2Array([Vector2(-0.76, 0.09), Vector2(-0.4, 0.03), Vector2(0.4, 0.03),
		Vector2(0.76, 0.09)]), trenzado, 0.03)
	contorno(ci, r, ala)
	var copa := rellenar(ci, r, a, suave(PackedVector2Array([Vector2(-0.3, 0.06), Vector2(-0.29, 0.28),
		Vector2(-0.19, 0.44), Vector2(0, 0.4), Vector2(0.19, 0.45), Vector2(0.3, 0.28), Vector2(0.31, 0.06),
		Vector2(0, 0.04)])), color, 0.1)
	for v in [0.25, 0.34]:
		linea(ci, r, a, PackedVector2Array([Vector2(-0.27, v), Vector2(0, v + 0.025), Vector2(0.27, v)]), trenzado, 0.03)
	linea(ci, r, a, PackedVector2Array([Vector2(-0.22, 0.24), Vector2(-0.17, 0.37)]), color.lightened(0.45), 0.05)
	contorno(ci, r, copa)
	# Listón rojo con una franja verde, como los sombreros de feria.
	pieza(ci, r, a, PackedVector2Array([Vector2(-0.31, 0.06), Vector2(0, 0.04), Vector2(0.31, 0.06),
		Vector2(0.305, 0.17), Vector2(0, 0.15), Vector2(-0.305, 0.17)]), Color("c8463a"), 0.04)
	linea(ci, r, a, PackedVector2Array([Vector2(-0.28, 0.115), Vector2(0, 0.095), Vector2(0.28, 0.115)]), Color("3f8f5c"), 0.035)
