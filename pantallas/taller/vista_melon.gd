class_name VistaMelon
extends Control
## Vista previa del melón en el taller, sobre el puente de Xallitic.
##
## Nodo: Taller/.../Previa/CajaPrevia/Vista (pantallas/taller/taller.tscn).
## Dibuja, en este orden: el escenario, la sombra, la estela elegida, el melón
## (con Aspecto.dibujar_melon) y, en modo dibujo, el cursor del pincel o la goma.
##
## Modo dibujo (modo_dibujo = true mientras la pestaña Dibujo está abierta):
##   - El melón se dibuja más grande, sin estela y con los accesorios puestos.
##   - Los eventos del ratón sobre la vista se pasan a pestana_dibujo.entrada_vista()
##     con la posición en unidades del radio (centro = 0, borde = 1).
## Por eso mouse_filter debe ser STOP: con IGNORE no llega ningún evento.
##
## Taller asigna pestana_dibujo y modo_dibujo, y llama queue_redraw() cuando
## cambia algo del melón. Esta vista solo lee Juego; nunca lo modifica.

const ESCENARIO := preload("res://recursos/taller_xallitic.png")
const ESCALA := 4.0                     # píxeles por unidad de radio, como máximo
const VERDE := Color("2b5745")          # estela si su entrada no trae color
const SOMBRA := Color(0.17, 0.25, 0.19, 0.15)

## Pestaña que recibe los trazos. La asigna Taller en su _ready().
var pestana_dibujo: PestanaDibujo
## true mientras la pestaña Dibujo está abierta.
var modo_dibujo := false:
	set(valor):
		modo_dibujo = valor
		queue_redraw()


func _ready() -> void:
<<<<<<< HEAD
=======
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
	resized.connect(queue_redraw)
	mouse_exited.connect(_al_salir_raton)


# --- Geometría ---------------------------------------------------------------

## Dónde va el centro del melón, en coordenadas de esta vista.
func centro_melon() -> Vector2:
	if modo_dibujo:
		# Más abajo que en reposo: el tallo y la hoja (hasta -1.27) y los
		# accesorios puestos (hasta ~1.9 radios) necesitan aire arriba.
		return size * Vector2(0.5, 0.56)
	return size * Vector2(0.5, 0.48)


## Radio del melón en píxeles de esta vista.
func radio_melon() -> float:
	if modo_dibujo:
		# Con margen para tallo, hoja, accesorios, grosor del trazo y sombra:
		# antes (0.4 del mínimo) el melón tocaba los bordes y se cortaba arriba
		# y abajo; con accesorios altos (jarana, paraguas) se cortaban también.
		return minf(size.x * 0.40, size.y * 0.27)
	var r: float = Config.tamanos[Juego.tamano]["radio"]
	return r * minf(ESCALA, minf(size.y / 105.0, size.x / 125.0))


## Convierte una posición de la vista a unidades del radio (centro = 0, borde = 1).
func a_unidades(pos: Vector2) -> Vector2:
	return (pos - centro_melon()) / radio_melon()


# --- Entrada del ratón -------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not modo_dibujo or pestana_dibujo == null or not event is InputEventMouse:
		return
	pestana_dibujo.entrada_vista(event, a_unidades((event as InputEventMouse).position))
	accept_event()


func _al_salir_raton() -> void:
	if pestana_dibujo != null:
		pestana_dibujo.salir_vista()


# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	var centro := centro_melon()
	var radio := radio_melon()
	draw_texture_rect(ESCENARIO, Rect2(Vector2.ZERO, size), false)
	# Sombra: un círculo aplastado bajo el melón.
	draw_set_transform(centro + Vector2(0, radio + 14), 0, Vector2(1, 0.16))
	Sprites.disco(self, Vector2.ZERO, radio * 1.1, SOMBRA)
	draw_set_transform(Vector2.ZERO)
	if not modo_dibujo:
		_dibujar_estela(centro)
	draw_set_transform(centro)
	Aspecto.dibujar_melon(self, radio, Juego.accesorios, false, true)
	if modo_dibujo:
		_dibujar_cursor(radio)
	draw_set_transform(Vector2.ZERO)


## Seis bolitas que se desvanecen detrás del melón, del color de la estela elegida.
func _dibujar_estela(centro: Vector2) -> void:
	var estelas: Variant = Config.estelas
	var idx := Juego.estela
	if not (estelas is Array) or idx <= 0 or idx >= (estelas as Array).size():
		return
	var col: Color = (estelas[idx] as Dictionary).get("color", VERDE)
	var base: float = Config.tamanos[Juego.tamano]["radio"] * ESCALA
	for i in 6:
		var p := centro + Vector2(-base - 18.0 - i * 20.0, 26.0 + i * 6.0)
		col.a = 0.75 - i * 0.1
		Sprites.disco(self, p, 9.0 - i * 1.2, col)


## Aro del pincel (con su color) o de la goma (rojo). Se dibuja ya centrado en el melón.
func _dibujar_cursor(radio: float) -> void:
	if pestana_dibujo == null or pestana_dibujo.cursor == null:
		return
	var c: Vector2 = pestana_dibujo.cursor * radio
	var rc := maxf(2.0, pestana_dibujo.radio_cursor() * radio)
	var tinta: Color = Color(0.85, 0.2, 0.2) if pestana_dibujo.es_goma() else pestana_dibujo.color
	Sprites.aro(self, c, rc, Color.WHITE)
	Sprites.aro(self, c, rc, tinta)
