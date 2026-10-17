extends Accesorio
## Flor de jardín: recupera un golpe y atrae los aplausos cercanos.

var duracion_iman := 6.0


func _init() -> void:
	nombre = "Flor de jardín"
	carisma = 4
	accion = "Recupera un golpe y atrae aplausos 6 s"
	grito = "¡Flor de jardín! Atraes aplausos"
	costo = 240
	orden = 40
	color = Color("dc80a6")


func usar(m: Melon) -> void:
	m.reparar()
	m.atraer_aplausos(duracion_iman)
