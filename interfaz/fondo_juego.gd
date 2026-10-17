@tool
class_name FondoJuego
extends Control
## Fondo animado de los menús: degradado, rayos de sol que giran despacio y una
## tira de papel picado que se mece arriba. Lo usan el Taller y los Resultados.
##
## Usa las hojas PNG de recursos/sprites/interfaz. Va como primer hijo de la
## pantalla, a pantalla completa y con mouse_filter IGNORE.

## Centro de los rayos, relativo al tamaño (0..1).
@export var centro_rayos := Vector2(0.3, 0.6)
## Radianes por segundo.
@export var velocidad := 0.05
@export var papel_picado := true

var _t := 0.0


func _ready() -> void:
	if theme_type_variation == &"":
		theme_type_variation = &"FondoTaller"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	Sprites.rectangulo(self, Rect2(Vector2.ZERO, size), get_theme_color("abajo"))
	Sprites.dibujar(self, "interfaz/degradado", Rect2(Vector2.ZERO, size), get_theme_color("arriba"))
	var centro := size * centro_rayos
	var tam := Vector2.ONE * size.length() * 2.4
	draw_set_transform(centro, _t * velocidad)
	Sprites.dibujar(self, "interfaz/rayos", Rect2(-tam * 0.5, tam), get_theme_color("rayos"))
	draw_set_transform(Vector2.ZERO)
	if papel_picado:
		_dibujar_papel_picado(size.x)


func _dibujar_papel_picado(w: float) -> void:
	Sprites.dibujar(self, "interfaz/picado", Rect2(0, sin(_t * 1.6) * 2.5, w, 100))
