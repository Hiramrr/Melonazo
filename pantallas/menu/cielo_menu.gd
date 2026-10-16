class_name CieloMenu
extends Node2D
## Cielo alto de la entrada del menú. Va justo después de Paisaje con su mismo z,
## así queda encima de las montañas y la ciudad pero debajo de las nubes cercanas,
## las aves y los papalotes del paisaje.
##
## - Un degradado de cielo tapa el fondo mientras la cámara está alta y se desvanece
##   al acercarse al encuadre final: las montañas "salen" de la bruma.
## - Nubes ancladas al mundo entre el cielo y la calle. La cámara las atraviesa al
##   bajar, así se siente la caída.
##
## Como Paisaje, sigue a la cámara y deshace su zoom para dibujar en píxeles de pantalla.

const ARRIBA := Color("3f6fae")
const ABAJO := Color("9cc6e4")
const SOMBRA := Color("cbdbe0")
const LUZ := Color("f8f6ee")

## y del mundo donde termina la bajada de la cámara; por debajo de aquí ya no hay cielo.
var suelo_y := 0.0
## Altura (px de mundo sobre suelo_y) donde el cielo tapa por completo el fondo.
var alto_opaco := 1500.0
## Altura donde el cielo ya no tapa nada.
var alto_claro := 250.0

var _camara: Camera2D
var _nubes: Array[Vector3] = []        # x relativa a la cámara, y del mundo, escala


func _init() -> void:
	z_index = -50


func configurar(camara: Camera2D, p_suelo_y: float, altura: float) -> void:
	_camara = camara
	suelo_y = p_suelo_y
	var azar := RandomNumberGenerator.new()
	azar.seed = 11
	for i in 16:
		_nubes.append(Vector3(azar.randf_range(-900.0, 900.0), suelo_y - azar.randf_range(1200.0, altura + 300.0),
			azar.randf_range(1.6, 3.2)))


func _process(_delta: float) -> void:
	if _camara == null:
		return
	global_position = _camara.get_screen_center_position()
	scale = Vector2.ONE / _camara.zoom
	visible = global_position.y < suelo_y - alto_claro + 50.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var m := get_viewport_rect().size / 2.0 + Vector2(4, 4)
	var altura := suelo_y - global_position.y
	var alfa := smoothstep(alto_claro, alto_opaco, altura)
	var arriba := Color(ARRIBA, alfa)
	var abajo := Color(ABAJO, alfa)
	draw_polygon(PackedVector2Array([-m, Vector2(m.x, -m.y), m, Vector2(-m.x, m.y)]),
		PackedColorArray([arriba, arriba, abajo, abajo]))
	var zoom := _camara.zoom.x
	for n in _nubes:
		var p := Vector2(n.x, (n.y - global_position.y) * zoom)
		if absf(p.y) < m.y + 200.0:
			_nube(p, n.z)


## Nube de cinco bolas como las del paisaje, pero grande y cercana. Siempre opaca:
## con transparencia se notarían las bolas encimadas. Quedan arriba del encuadre final.
func _nube(pos: Vector2, escala: float) -> void:
	draw_set_transform(pos, 0, Vector2(1.0, 0.65) * escala)
	for capa in [[Vector2(0, 8), SOMBRA], [Vector2.ZERO, LUZ]]:
		for i in 5:
			var x := (i - 2) * 26.0
			var y := -sin(i * PI / 4) * 16
			var radio := 19.0 + sin(i * PI / 4) * 15
			draw_circle(Vector2(x, y) + capa[0], radio, capa[1])
	draw_rect(Rect2(-52, 0, 104, 18), LUZ)
	draw_set_transform(Vector2.ZERO)
