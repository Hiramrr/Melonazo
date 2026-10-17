@tool
class_name TituloMelonazo
extends Control
## Logo "MELONAZO" del menú principal. Las letras ondulan como una ola y la
## letra `indice_melon` es un melón que gira. Darle clic al melón lo hace saltar.
##
## Usa la letra gruesa de la variación Titulo del tema, con contorno y sombra.

## El melón del logo siempre se ve igual, sin importar el que tenga el jugador.
const MELON_LOGO := {"piel": 0, "patron": 0, "cara": 0, "detalle": 1, "cuerpo_propio": "",
	"rayas_propio": "", "dibujo": []}

@export var texto := "MELONAZO":
	set(valor):
		texto = valor
		update_minimum_size()
		queue_redraw()
## Qué letra se dibuja como melón (0 = la primera). La última O por defecto.
@export var indice_melon := 7:
	set(valor):
		indice_melon = valor
		update_minimum_size()
		queue_redraw()
var tamano: int:
	get: return get_theme_font_size("font_size")
var separacion: int:
	get: return get_theme_constant("separacion")
var contorno: int:
	get: return get_theme_constant("outline_size")

var _t := 0.0
var _giro := 0.0
var _vel_giro := 1.2                   # radianes por segundo
var _salto := 0.0
var _vel_salto := 0.0


func _init() -> void:
	theme_type_variation = &"LogoMenu"


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		update_minimum_size()
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _process(delta: float) -> void:
	_t += delta
	_vel_giro = move_toward(_vel_giro, 1.2, delta * 6.0)
	_giro += _vel_giro * delta
	# Un resorte devuelve el salto a 0.
	_vel_salto += (-_salto * 120.0 - _vel_salto * 9.0) * delta
	_salto += _vel_salto * delta
	queue_redraw()


func _fuente() -> Font:
	return get_theme_font("font")


func _ancho_letra(i: int) -> float:
	if i == indice_melon:
		return _radio() * 2.0 + separacion * 2.0
	return _fuente().get_string_size(texto[i], HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x + separacion


func _radio() -> float:
	return tamano * 0.36


func _get_minimum_size() -> Vector2:
	var ancho := 0.0
	for i in texto.length():
		ancho += _ancho_letra(i)
	return Vector2(ancho + contorno * 2, tamano * 1.15)


func _centro_melon() -> Vector2:
	var x := contorno + 0.0
	for i in indice_melon:
		x += _ancho_letra(i)
	return Vector2(x + _ancho_letra(indice_melon) * 0.5, _linea_base() - _radio() * 0.98 + _ola(indice_melon) - _salto)


func _linea_base() -> float:
	return size.y * 0.5 + tamano * 0.36


func _ola(i: int) -> float:
	return sin(_t * 3.0 - i * 0.6) * 6.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.distance_to(_centro_melon()) <= _radio() * 1.2:
			_vel_giro = 18.0
			_vel_salto = 700.0
			accept_event()


func _draw() -> void:
	var fuente := _fuente()
	var tinta := get_theme_color("font_outline_color")
	var crema := get_theme_color("font_color")
	var sombra := Vector2(0, get_theme_constant("shadow_offset_y"))
	var x := contorno + 0.0
	for i in texto.length():
		var ancho := _ancho_letra(i)
		if i != indice_melon:
			var p := Vector2(x, _linea_base() + _ola(i))
			var letra := texto[i]
			# Sombra, contorno y relleno.
			draw_string_outline(fuente, p + sombra, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, contorno, tinta)
			draw_string(fuente, p + sombra, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, tinta)
			draw_string_outline(fuente, p, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, contorno, tinta)
			draw_string(fuente, p, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, crema)
		x += ancho
	var c := _centro_melon()
	var r := _radio()
	Sprites.disco(self, c + sombra, r + contorno * 0.5, tinta)
	Sprites.disco(self, c, r + contorno * 0.5, tinta)
	draw_set_transform(c, _giro)
	if Engine.is_editor_hint():
		Sprites.disco(self, Vector2.ZERO, r, Color("a6cc62"))
	else:
		Aspecto.dibujar_melon(self, r, [], false, false, MELON_LOGO)
	draw_set_transform(Vector2.ZERO)
