extends Accesorio
## Casco de luchador: embestida hacia adelante que rompe puestos.

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


func usar(m: Melon) -> void:
	m.embestir(duracion, impulso)
