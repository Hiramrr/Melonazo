class_name Selector
extends HBoxContainer
## Elegir una opción de una lista con flechas, como en el vestidor de un juego:
##   [◀]  Verde de mercado  2/8  [▶]
## Da la vuelta al llegar al final. También cambia con izquierda y derecha
## cuando una de sus flechas tiene el foco.
##
## Uso:
##   var s := Selector.new()
##   s.opciones = PackedStringArray(["Uno", "Dos"])
##   s.cambiado.connect(func(i): ...)
##   s.elegir(1)     # sin emitir cambiado

signal cambiado(indice: int)

var opciones := PackedStringArray():
	set(valor):
		opciones = valor
		_mostrar()
var indice := 0

var _anterior: Button
var _siguiente: Button
var _nombre: Label
var _cuenta: Label


func _init() -> void:
	theme_type_variation = &"FilaIconos"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_anterior = _flecha(Iconos.FLECHA_IZQ, -1)
	add_child(_anterior)
	var centro := PanelContainer.new()
	centro.theme_type_variation = &"Tarjeta"
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var fila := HBoxContainer.new()
	centro.add_child(fila)
	_nombre = Label.new()
	_nombre.theme_type_variation = &"SubtituloChico"
	_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre.clip_text = true
	_nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fila.add_child(_nombre)
	_cuenta = Label.new()
	_cuenta.theme_type_variation = &"Detalle"
	fila.add_child(_cuenta)
	_siguiente = _flecha(Iconos.FLECHA_DER, 1)
	add_child(_siguiente)


## Muestra la opción i sin emitir cambiado.
func elegir(i: int) -> void:
	indice = clampi(i, 0, maxi(0, opciones.size() - 1))
	_mostrar()


func _flecha(textura: Texture2D, paso: int) -> Button:
	var b := Button.new()
	b.icon = textura
	b.expand_icon = true
	b.custom_minimum_size = Vector2(44, 40)
	b.theme_type_variation = &"FlechaSelector"
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(_mover.bind(paso))
	b.gui_input.connect(_teclas)
	return b


func _teclas(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_mover(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_mover(1)
		get_viewport().set_input_as_handled()


func _mover(paso: int) -> void:
	if opciones.is_empty():
		return
	indice = posmod(indice + paso, opciones.size())
	_mostrar()
	Animacion.rebotar(_nombre)
	cambiado.emit(indice)


func _mostrar() -> void:
	if opciones.is_empty():
		_nombre.text = "—"
		_cuenta.text = ""
		return
	_nombre.text = opciones[indice]
	_cuenta.text = "%d/%d" % [indice + 1, opciones.size()]
