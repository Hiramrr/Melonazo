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
	forma = [Vector2(-0.35, -0.1), Vector2(0.35, -0.1), Vector2(0.4, 0.3), Vector2(0.13, 0.85),
		Vector2(-0.13, 0.85), Vector2(-0.4, 0.3)]


func usar(m: Melon) -> void:
	m.empujar(impulso)
	m.sumar_rebote()
