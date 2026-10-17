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
	Sprites.dibujar(self, "interfaz/cielo_menu", Rect2(-m, m * 2), Color(1, 1, 1, alfa))
	var zoom := _camara.zoom.x
	for n in _nubes:
		var p := Vector2(n.x, (n.y - global_position.y) * zoom)
		if absf(p.y) < m.y + 200.0:
			_nube(p, n.z)


func _nube(pos: Vector2, escala: float) -> void:
	Sprites.dibujar(self, "paisaje/nube_menu", Rect2(pos + Vector2(-80, -50) * escala, Vector2(160, 80) * escala))
