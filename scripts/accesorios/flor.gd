extends Accesorio

var duracion_iman := 6.0


func _init() -> void:
	nombre = "Flor de jardín"
	carisma = 4
	accion = "Recupera un golpe y atrae aplausos 6 s"
	grito = "¡Flor de jardín! Atraes aplausos"
	costo = 240
	orden = 40
	color = Color("dc80a6")
	forma = [Vector2(-0.4, -0.1), Vector2(0.4, -0.1), Vector2(0.5, 0.4), Vector2(0.0, 0.7), Vector2(-0.5, 0.4)]


func usar(m: Melon) -> void:
	m.reparar()
	m.atraer_aplausos(duracion_iman)


func dibujar_detalle(ci: CanvasItem, r: float, a: float) -> void:
	var centro := uv(r, a, 0, 0.38)
	for petalo in 5:
		ci.draw_circle(centro + Vector2.from_angle(petalo * TAU / 5) * r * 0.2, r * 0.16, color.lightened(0.15))
	ci.draw_circle(centro, r * 0.13, Color("f1ce67"))
