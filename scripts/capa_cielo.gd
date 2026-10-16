@tool
extends Node2D
## Capas decorativas sin colisión. Cada una se puede ocultar o ajustar en su nodo.

@export_enum("fondo", "sol", "nubes_altas", "nubes_cercanas", "aves", "papalotes") var tipo := "nubes_altas":
	set(valor):
		tipo = valor
		queue_redraw()
@export_range(150.0, 1600.0, 10.0) var separacion := 420.0
@export var velocidad := 6.0
@export_range(0.0, 1.0, 0.01) var paralaje := 0.04

var mitad := Vector2(640, 360)
var vista := Vector2.ZERO
var tiempo := 0.0


func actualizar(tamano: Vector2, posicion_camara: Vector2, segundos: float) -> void:
	mitad = tamano / 2.0 + Vector2(4, 4)
	vista = posicion_camara
	tiempo = segundos
	queue_redraw()


func _draw() -> void:
	match tipo:
		"fondo":
			draw_polygon(PackedVector2Array([Vector2(-mitad.x, -mitad.y), Vector2(mitad.x, -mitad.y), mitad, Vector2(-mitad.x, mitad.y)]),
				PackedColorArray([Color("6ba8df"), Color("6ba8df"), Color("f7deb8"), Color("f7deb8")]))
		"sol":
			var centro := Vector2(mitad.x * 0.55 - fposmod(vista.x * paralaje, 80), -mitad.y * 0.65)
			draw_circle(centro, 31, Color("f4db9f"))
			draw_arc(centro, 25, 0, TAU, 40, Color("fae8bc"), 1.5, true)
		_:
			var desplazamiento := vista.x * paralaje - tiempo * velocidad
			var inicio := floori((-mitad.x + desplazamiento) / separacion) - 1
			var fin := ceili((mitad.x + desplazamiento) / separacion) + 1
			for i in range(inicio, fin + 1):
				var azar := _azar(i + paralaje * 100)
				var x := i * separacion - desplazamiento + (azar - 0.5) * separacion * 0.25
				var altura := -mitad.y * (0.85 if tipo == "nubes_altas" else 0.52)
				altura += (azar - 0.5) * 95 - clampf((vista.y - 60) * paralaje * 0.2, -35, 35)
				match tipo:
					"nubes_altas", "nubes_cercanas":
						_nube(Vector2(x, altura), azar)
					"aves":
						_bandada(Vector2(x, altura - 40), i, azar)
					"papalotes":
						_papalote(Vector2(x, altura + 60), i, azar)


static func _azar(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


func _nube(pos: Vector2, azar: float) -> void:
	var alta := tipo == "nubes_altas"
	var escala := Vector2(1.6, 0.38) if alta else Vector2(1.0, 0.7)
	escala *= 0.75 + azar * 0.55
	draw_set_transform(pos, 0, escala)
	var sombra := Color("bed4dc") if alta else Color("cbdbe0")
	var luz := Color("d9e5e7") if alta else Color("f5f3e9")
	for i in 5:
		var x := (i - 2) * 25.0
		var y := -sin(i * PI / 4) * 15
		var radio := 18.0 + sin(i * PI / 4) * 14
		draw_circle(Vector2(x, y + 7), radio, sombra)
		draw_circle(Vector2(x, y), radio, luz)
	draw_rect(Rect2(-50, 0, 100, 16), luz)
	draw_set_transform(Vector2.ZERO)


func _bandada(pos: Vector2, grupo: int, azar: float) -> void:
	var color := Color("526d7c")
	for i in 5:
		var aleteo := sin(tiempo * 3.8 + i * 0.8 + grupo) * 3.5
		var p := pos + Vector2(i * 20, absf(i - 2) * 9 + sin(tiempo * 0.6 + i) * 2)
		var ala := 5.0 + azar * 3
		draw_polyline(PackedVector2Array([p + Vector2(-ala, -aleteo - 2), p + Vector2(-ala * 0.4, -2), p,
			p + Vector2(ala * 0.4, -2), p + Vector2(ala, -aleteo - 2)]), color, 1.6, true)


func _papalote(pos: Vector2, grupo: int, azar: float) -> void:
	pos += Vector2(sin(tiempo * 0.7 + grupo) * 9, sin(tiempo * 0.9 + grupo) * 5)
	var escala := 0.65 + azar * 0.3
	draw_set_transform(pos, sin(tiempo * 0.7 + grupo) * 0.12, Vector2.ONE * escala)
	var color := Color("bb755c") if grupo % 2 == 0 else Color("c6a367")
	var rombo := PackedVector2Array([Vector2(0, -20), Vector2(14, -3), Vector2(0, 20), Vector2(-14, -3)])
	draw_colored_polygon(rombo, color)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -20), Vector2(14, -3), Vector2(0, 20)]), color.lightened(0.16))
	draw_polyline(PackedVector2Array([rombo[0], rombo[1], rombo[2], rombo[3], rombo[0]]), Color("8c8270"), 1.2, true)
	draw_line(Vector2(0, -20), Vector2(0, 20), Color("e5d5ac"), 1.2, true)
	draw_line(Vector2(-14, -3), Vector2(14, -3), Color("e5d5ac"), 1.2, true)
	var cola := PackedVector2Array()
	for i in 16:
		var p := Vector2(sin(i * 0.55 - tiempo * 1.6 + grupo) * i * 0.7, 20 + i * 4)
		cola.append(p)
		if i > 0 and i % 4 == 0:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -3), p + Vector2(5, -3), p + Vector2(0, 4)]), color)
	draw_polyline(cola, Color("a19a86"), 1.2, true)
	draw_set_transform(Vector2.ZERO)
