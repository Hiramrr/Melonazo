extends Accesorio
## Rebozo de paseo: planeo corto y protección para la siguiente caída. Inicial.

var duracion := 1.5
var gravedad := 0.22                 # gravity_scale durante el planeo


func _init() -> void:
	nombre = "Rebozo de paseo"
	carisma = 3
	accion = "Planea 1.5 s y protege la siguiente caída"
	grito = "¡Al vuelo con el rebozo!"
	inicial = true
	orden = 30
	color = Color("467d88")


func usar(m: Melon) -> void:
	m.planear(duracion, gravedad)
	m.proteger()


const GIRO := 0.78                   # hasta qué ángulo cubre la tela a cada lado
