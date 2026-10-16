class_name BajadaXallitic
extends Tramo
## Bajada de salida, sin obstáculos ni ayudas antes de cruzar Xallitic.

const PersonaEscena := preload("res://mundo/ayudas/persona.tscn")
var barrera: Line2D


func _ready() -> void:
	var inicio := Config.bajada_inicio
	var fin := Config.bajada_fin
	var desde := inicio.x - maxf(1280.0, get_viewport_rect().size.x)
	var n := int(ceil((fin.x - desde) / Config.paso_puntos))
	for i in n + 1:
		var x := lerpf(desde, fin.x, float(i) / n)
		var u := minf(inverse_lerp(inicio.x, fin.x, x), 1.0)
		puntos.append(Vector2(x, lerpf(inicio.y, fin.y, 1.0 - (1.0 - u) * (1.0 - u))))
	empedrado = true
	color_suelo = Color("aaa18e")
	construir()
	var cantidad := int((fin.x - desde) / 190.0)
	for i in cantidad:
		var x := desde + i * 190.0
		var alto := 150.0 + 70.0 * _azar(x)
		casas.append({"rect": Rect2(x, altura(x) - alto, 125, alto + 40),
			"color": GeneradorTerreno.COLORES_CASAS[i % GeneradorTerreno.COLORES_CASAS.size()]})
	for i in int((fin.x - desde - 80.0) / 68.0):
		var x := desde + 40.0 + i * 68.0
		for fila in 2:
			var persona := PersonaEscena.instantiate() as Persona
			persona.position = Vector2(x + fila * 24.0, altura(x + fila * 24.0) + (-12.0 if fila == 0 else 132.0))
			persona.color_ropa = GeneradorTerreno.COLORES_ROPA[(i + fila * 2) % GeneradorTerreno.COLORES_ROPA.size()]
			persona.color_piel = Color("d4a17d").darkened(0.12 * (i % 4))
			persona.usado = i % 4 == 0
			get_node("Decoracion" if fila == 0 else "Publico").add_child(persona)
	get_node("Publico").z_index = 2
	marcadores.append({"pos": Vector2(inicio.x - 80, altura(inicio.x - 80)), "texto": "Salida"})
	barrera = Line2D.new()
	barrera.name = "BarreraSalida"
	var salida := Vector2(inicio.x + 60.0, altura(inicio.x + 60.0))
	barrera.points = PackedVector2Array([salida + Vector2(0, -12), salida + Vector2(24, 110)])
	barrera.default_color = Color("ddd1af")
	barrera.width = 7.0
	barrera.z_index = 3
	add_child(barrera)


func abrir_salida() -> void:
	barrera.hide()


func _draw() -> void:
	super._draw()
	if puntos.size() < 2:
		return
	# El costado de la calle es un muro de contención, no un bloque de tierra liso.
	var muro := puntos.duplicate()
	for i in muro.size():
		muro[i].y += 114.0
	muro.append(Vector2(x1, _fondo))
	muro.append(Vector2(x0, _fondo))
	draw_colored_polygon(muro, Color("85877b"))
	var y := floorf((puntos[0].y + 114.0) / 36.0) * 36.0
	var fila_muro := 0
	while y < _fondo:
		var x := x0 + 4.0 - (fila_muro % 2) * 39.0
		while x < x1 - 4.0:
			var a := maxf(x, x0 + 4.0)
			var b := minf(x + 72.0, x1 - 4.0)
			var arriba := maxf(y, maxf(altura(a), altura(b)) + 116.0)
			if b > a and arriba < y + 30.0:
				var tono := Color("9e9c8f").lightened(_azar(x + y) * 0.1)
				draw_rect(Rect2(a, arriba, b - a, y + 30.0 - arriba), tono)
			x += 78.0
		y += 36.0
		fila_muro += 1
	# Calle ancha entre dos filas de público, como en la carrera de melones.
	var calle := puntos.duplicate()
	for i in range(puntos.size() - 1, -1, -1):
		calle.append(puntos[i] + Vector2(0, 106))
	draw_colored_polygon(calle, Color("aaa69a"))
	for fila in 5:
		var x := x0 + 10.0 + (fila % 2) * 11.0
		while x < x1 - 12.0:
			var p := Vector2(x, altura(x) + 7.0 + fila * 20.0)
			draw_set_transform(p, pendiente(x))
			draw_rect(Rect2(-8, -4, 17, 10), Color("c2bfb2"))
			draw_rect(Rect2(-8, -4, 17, 10), Color("88867d"), false, 1.0)
			draw_set_transform(Vector2.ZERO)
			x += 23.0
	var banqueta := puntos.duplicate()
	for i in banqueta.size():
		banqueta[i].y += 110.0
	draw_polyline(banqueta, Color("cfb559"), 8.0, true)
	draw_polyline(puntos, Color("cfb559"), 6.0, true)
