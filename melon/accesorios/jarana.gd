extends Accesorio
## Jarana de fandango: impulso hacia adelante y un rebote extra.

var impulso := Vector2(520, -240)


func _init() -> void:
	nombre = "Jarana de fandango"
	carisma = 5
	accion = "Impulso del son y un rebote extra"
	grito = "¡Que siga el son! +1 rebote"
	costo = 420
	orden = 50
	color = Color("bc8049")


func usar(m: Melon) -> void:
	m.empujar(impulso)
	m.sumar_rebote()
