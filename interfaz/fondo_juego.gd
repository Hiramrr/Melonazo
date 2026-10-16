@tool
class_name FondoJuego
extends Control
## Fondo animado de los menús: degradado, rayos de sol que giran despacio y una
## tira de papel picado que se mece arriba. Lo usan el Taller y los Resultados.
##
## Todo se dibuja en _draw(); no necesita imágenes. Va como primer hijo de la
## pantalla, a pantalla completa y con mouse_filter IGNORE.

const COLORES_PAPEL: Array[Color] = [Color("e8553f"), Color("ffc83d"), Color("5fae5a"),
	Color("f27fa8"), Color("4fa3d9"), Color("fff9ec")]
const TINTA := Color("203d38")

@export var color_arriba := Color("8fd3c1")
@export var color_abajo := Color("3f8f7d")
@export var color_rayos := Color(1, 1, 1, 0.12)
## Centro de los rayos, relativo al tamaño (0..1).
@export var centro_rayos := Vector2(0.3, 0.6)
@export_range(4, 48) var rayos := 20
## Radianes por segundo.
@export var velocidad := 0.05
@export var papel_picado := true
@export var ancho_bandera := 46.0
## Cuánto se cuelga la cuerda en el centro, en píxeles.
@export var caida := 26.0

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([color_arriba, color_arriba, color_abajo, color_abajo]))
	var c := size * centro_rayos
	var largo := size.length() * 1.2
	var paso := TAU / rayos
	for i in rayos:
		var a := _t * velocidad + i * paso
		draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a) * largo,
			c + Vector2.from_angle(a + paso * 0.5) * largo]), color_rayos)
	if papel_picado:
		_dibujar_papel_picado(w)


## Cuerda colgada de lado a lado con banderitas recortadas que se mecen.
func _dibujar_papel_picado(w: float) -> void:
	var n := int(w / ancho_bandera) + 1
	var puntos := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n
		puntos.append(Vector2(u * w, 4.0 + caida * 4.0 * u * (1.0 - u)))
	for i in n:
		var a := puntos[i]
		var b := puntos[i + 1]
		var vaiven := sin(_t * 1.6 + i * 0.7) * 2.5
		var alto := ancho_bandera * 0.9
		var col := COLORES_PAPEL[i % COLORES_PAPEL.size()]
		var abajo := Vector2(vaiven, alto)
		var forma := PackedVector2Array([a + Vector2(3, 0), b - Vector2(3, 0), b - Vector2(3, 0) + abajo,
			(a + b) * 0.5 + abajo + Vector2(0, -8), a + Vector2(3, 0) + abajo])
		draw_colored_polygon(forma, col)
		draw_polyline(forma + PackedVector2Array([forma[0]]), TINTA, 2.0, true)
		# Recortes: un rombo y dos puntos, del color del fondo.
		var m := (a + b) * 0.5 + Vector2(vaiven * 0.5, alto * 0.42)
		var hueco := color_arriba
		draw_colored_polygon(PackedVector2Array([m + Vector2(0, -8), m + Vector2(7, 0), m + Vector2(0, 8), m + Vector2(-7, 0)]), hueco)
		draw_circle(m + Vector2(-11, -10), 3.0, hueco)
		draw_circle(m + Vector2(11, -10), 3.0, hueco)
	draw_polyline(puntos, TINTA, 3.0, true)
