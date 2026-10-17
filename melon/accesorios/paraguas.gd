extends Accesorio
## Paraguas: caída lenta y protección para la siguiente caída.

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


# El dibujo no sigue la forma de colisión: mango, gajos de tela y puntero.
