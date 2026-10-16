extends ScrollContainer
## Pestaña "Dibujo" del taller. El taller le pasa los eventos del ratón sobre la
## vista previa ya convertidos a unidades del radio (centro = 0, borde = 1).
## Los trazos se guardan en Juego.dibujo; Aspecto los dibuja en el melón.

signal cambio

const PASO_MIN := 0.025                # distancia mínima entre puntos de un trazo
const GOMA_EXTRA := 0.06

@onready var pincel: Button = %Pincel
@onready var goma: Button = %Goma
@onready var fila_colores: HFlowContainer = %FilaColores
@onready var otro_color: ColorPickerButton = %OtroColor
@onready var grosor: HSlider = %Grosor
@onready var btn_deshacer: Button = %Deshacer
@onready var btn_borrar: Button = %Borrar
@onready var lbl_conteo: Label = %Conteo

var color := Color("253e32")
var cursor = null                      # Vector2 en unidades del radio, o null
var _trazando := false
var _borrando := false
var _muestras: Array = []              # [Button, Color]


func _ready() -> void:
	grosor.min_value = Config.grosor_dibujo.x
	grosor.max_value = Config.grosor_dibujo.y
	for c in Config.colores_dibujo:
		var b := Button.new()
		b.custom_minimum_size = Vector2(34, 34)
		b.tooltip_text = "#" + (c as Color).to_html(false)
		b.pressed.connect(_elegir_color.bind(c))
		fila_colores.add_child(b)
		_muestras.append([b, c])
	if not Config.colores_dibujo.is_empty():
		color = Config.colores_dibujo[0]
	otro_color.color = color
	goma.toggled.connect(func(_activo: bool) -> void: _refrescar())
	_refrescar()


func _estilo_muestra(c: Color, elegido: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(17)
	s.set_border_width_all(4 if elegido else 1)
	s.border_color = Color("253e32") if elegido else c.darkened(0.35)
	return s


func _elegir_color(c: Color) -> void:
	color = c
	otro_color.color = c
	pincel.button_pressed = true
	_refrescar()


func _cambiar_grosor(_valor: float) -> void:
	cambio.emit()


func es_goma() -> bool:
	return goma.button_pressed


## Radio del cursor (unidades del radio) para la vista previa.
func radio_cursor() -> float:
	return grosor.value * 0.5 + (GOMA_EXTRA if es_goma() else 0.0)


## Recibe un evento del ratón sobre la vista. p = posición en unidades del radio.
func entrada_vista(event: InputEvent, p: Vector2) -> void:
	cursor = p if p.length() <= 1.25 else null
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_borrando = es_goma() or mb.button_index == MOUSE_BUTTON_RIGHT
				_trazando = not _borrando and _empezar_trazo(p)
				if _borrando:
					_borrar_en(p)
			else:
				if _trazando or _borrando:
					Juego.guardar()
				_trazando = false
				_borrando = false
	elif event is InputEventMouseMotion:
		if _trazando:
			_seguir_trazo(p)
		elif _borrando:
			_borrar_en(p)
	_refrescar()


func salir_vista() -> void:
	cursor = null
	if _trazando or _borrando:
		Juego.guardar()
	_trazando = false
	_borrando = false
	cambio.emit()


func _limite(p: Vector2) -> Vector2:
	return p.limit_length(maxf(0.0, 1.0 - grosor.value * 0.5))


func _puntos_totales() -> int:
	var total := 0
	for trazo in Juego.dibujo:
		total += (trazo["puntos"] as PackedVector2Array).size()
	return total


func _empezar_trazo(p: Vector2) -> bool:
	if p.length() > 1.1 or Juego.dibujo.size() >= Config.max_trazos or _puntos_totales() >= Config.max_puntos_dibujo:
		return false
	Juego.dibujo.append({"color": color, "grosor": grosor.value, "puntos": PackedVector2Array([_limite(p)])})
	return true


func _seguir_trazo(p: Vector2) -> void:
	var trazo: Dictionary = Juego.dibujo[-1]
	var puntos: PackedVector2Array = trazo["puntos"]
	var q := _limite(p)
	if puntos[-1].distance_to(q) < PASO_MIN or _puntos_totales() >= Config.max_puntos_dibujo:
		return
	puntos.append(q)
	trazo["puntos"] = puntos


func _borrar_en(p: Vector2) -> void:
	var alcance := radio_cursor()
	Juego.dibujo = Juego.dibujo.filter(func(trazo: Dictionary) -> bool:
		for q in trazo["puntos"]:
			if q.distance_to(p) <= alcance + float(trazo["grosor"]) * 0.5:
				return false
		return true)


func deshacer() -> void:
	if Juego.dibujo.is_empty():
		return
	Juego.dibujo.pop_back()
	Juego.guardar()
	_refrescar()


func borrar_todo() -> void:
	Juego.dibujo.clear()
	Juego.guardar()
	_refrescar()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.keycode == KEY_Z and (k.ctrl_pressed or k.meta_pressed):
		deshacer()
		get_viewport().set_input_as_handled()


func _refrescar() -> void:
	for m in _muestras:
		var b: Button = m[0]
		var elegido: bool = m[1] == color and not es_goma()
		for estado in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(estado, _estilo_muestra(m[1], elegido))
	var n := Juego.dibujo.size()
	btn_deshacer.disabled = n == 0
	btn_borrar.disabled = n == 0
	if n == 0:
		lbl_conteo.text = "Sin trazos todavía."
	else:
		lbl_conteo.text = "%d %s · %d %% del espacio para dibujar." % [n, "trazo" if n == 1 else "trazos",
			int(100.0 * _puntos_totales() / Config.max_puntos_dibujo)]
	cambio.emit()
