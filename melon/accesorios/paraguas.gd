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
func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var madera := Color("8a5a36")
	var mango := PackedVector2Array([Vector2(0, 0.32)])
	for i in 9:
		var t := PI + PI * i / 8.0
		mango.append(Vector2(0.09 + cos(t) * 0.09, 0.02 + sin(t) * 0.09))
	linea(ci, r, a, mango, TINTA, 0.13)
	linea(ci, r, a, mango, madera, 0.07)
	linea(ci, r, a, PackedVector2Array([Vector2(0, 0.64), Vector2(0, 0.76)]), TINTA, 0.07)
	ci.draw_circle(uv(r, a, 0, 0.77), r * 0.045, Color("f2c14e"), true, -1.0, true)
	ci.draw_circle(uv(r, a, 0, 0.77), r * 0.045, TINTA, false, ancho(r) * 0.6, true)
	# Cuatro gajos alternados; los de la derecha más oscuros para dar volumen.
	var puntas := [-0.82, -0.41, 0.0, 0.41, 0.82]
	var colores := [color, Color("f2c14e"), color.darkened(0.12), Color("f2c14e").darkened(0.2)]
	var tela := PackedVector2Array()
	for g in 4:
		var gajo := _varilla(puntas[g], false)
		gajo.append_array(_varilla(puntas[g + 1], true))
		gajo.append_array(_feston(puntas[g + 1], puntas[g]))
		ci.draw_colored_polygon(uvs(r, a, gajo), colores[g])
		if g > 0:
			tela.append(Vector2(puntas[g], 0.3))
		tela.append_array(_feston(puntas[g], puntas[g + 1]))
	for g in [1, 2, 3]:
		linea(ci, r, a, _varilla(puntas[g], false), TINTA, ancho(r) * 0.6 / r)
	var cupula := PackedVector2Array()
	for i in 17:
		var t := PI * i / 16.0
		cupula.append(Vector2(0.82 * cos(t), 0.3 + 0.36 * sin(t)))
	cupula.append_array(tela)
	contorno(ci, r, uvs(r, a, cupula))


## Varilla curva desde la punta u del borde hasta la cima de la cúpula.
func _varilla(u: float, de_bajada: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 9:
		var t := PI / 2.0 * (8 - i if de_bajada else i) / 8.0
		pts.append(Vector2(u * cos(t), 0.3 + 0.36 * sin(t)))
	if de_bajada:
		pts.remove_at(0)  # la cima ya la puso la otra varilla
	return pts


## Borde ondulado de la tela entre dos puntas, sin repetirlas.
func _feston(desde: float, hasta: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(1, 6):
		var s := i / 6.0
		pts.append(Vector2(lerpf(desde, hasta, s), 0.3 + 0.07 * sin(s * PI)))
	return pts
