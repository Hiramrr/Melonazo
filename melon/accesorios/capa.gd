extends Accesorio
## Capa: planeo largo con poca gravedad. Se desbloquea en el taller.

var duracion := 2.5
var gravedad := 0.22                 # gravity_scale durante el planeo


func _init() -> void:
	nombre = "Capa"
	carisma = 3
	accion = "Planeo largo: menos gravedad 2.5 s"
	grito = "¡Planeo!"
	costo = 300
	orden = 60
	color = Color(0.85, 0.15, 0.22)
	forma = [Vector2(-0.6, -0.1), Vector2(0.6, -0.1), Vector2(0.8, 0.28), Vector2(-0.8, 0.28)]


func usar(m: Melon) -> void:
	m.planear(duracion, gravedad)


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var oro := Color("f2c14e")
	# Capa ondeando hacia atrás (-u), sujeta al melón por el cuello.
	var tela := suave(PackedVector2Array([Vector2(0.32, -0.02), Vector2(0.22, 0.14), Vector2(0.0, 0.27),
		Vector2(-0.35, 0.36), Vector2(-0.68, 0.37), Vector2(-0.88, 0.33), Vector2(-0.81, 0.2),
		Vector2(-0.89, 0.08), Vector2(-0.81, -0.02), Vector2(-0.87, -0.1), Vector2(-0.6, -0.07),
		Vector2(-0.35, -0.02), Vector2(-0.15, 0.0), Vector2(0.1, 0.02)]))
	var pts := rellenar(ci, r, a, tela, color, 0.07)
	for pliegue in [[Vector2(0.1, 0.12), Vector2(-0.4, 0.27), Vector2(-1.0, 0.27), Vector2(-0.4, 0.18), Vector2(-1.0, 0.13)],
			[Vector2(0.0, 0.05), Vector2(-0.45, 0.09), Vector2(-1.0, 0.04), Vector2(-0.45, 0.0), Vector2(-1.0, -0.06)]]:
		var gajo := _curva(pliegue[0], pliegue[1], pliegue[2])
		var abajo := _curva(pliegue[0], pliegue[3], pliegue[4])
		abajo.reverse()
		gajo.append_array(abajo)
		for parte in Geometry2D.intersect_polygons(gajo, tela):
			poligono(ci, uvs(r, a, parte), color.darkened(0.2))
	contorno(ci, r, pts)
	var cuello := PackedVector2Array()
	for i in 7:
		var u := lerpf(-0.18, 0.3, i / 6.0)
		cuello.append(Vector2(u, piel(u) + 0.05))
	linea(ci, r, a, cuello, TINTA, 0.13)
	linea(ci, r, a, cuello, oro, 0.07)
	pieza(ci, r, a, elipse(Vector2(0.06, 0.06), Vector2(0.075, 0.075), 0.0, 16), oro, 0.03)


## Curva cuadrática de p0 a p2 con control p1.
func _curva(p0: Vector2, p1: Vector2, p2: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		pts.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return pts
