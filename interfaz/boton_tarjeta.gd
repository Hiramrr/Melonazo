class_name BotonTarjeta
extends Button
## Tarjeta clicable. Misma estructura visual que Tarjeta, pero hereda de Button
## (se puede pulsar) y ofrece "seleccionado" para el estado de selección.
##
## Uso típico:
##   var b := BotonTarjeta.new()
##   b.titulo = accesorio.nombre
##   b.icono = ...   # opcional
##   b.pressed.connect(_pulsar.bind(id))
##   b.seleccionado = (id in Juego.accesorios)
##   lista.add_child(b)
##
## El contenido interno tiene mouse_filter = IGNORE: los clics llegan al Button.
## Si por error pusieras mouse_filter STOP, los clics se perderían en el VBox.

var contenido: VBoxContainer
var cabecera: HBoxContainer
var cuerpo: VBoxContainer
var pie: HBoxContainer

var icono: Texture2D:
	set(v):
		icono = v
		if _imagen:
			_imagen.texture = v
			_imagen.visible = v != null
			_actualizar_cabecera()

var titulo := "":
	set(v):
		titulo = v
		if _titulo:
			_titulo.text = v
			_actualizar_cabecera()

var estado := "":
	set(v):
		estado = v
		if _estado:
			_estado.text = v
			_estado.visible = not v.is_empty()
			_actualizar_cabecera()

var estado_estilo: StringName = Estilos.DETALLE:
	set(v):
		estado_estilo = v
		if _estado:
			_estado.theme_type_variation = v

var estado_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT:
	set(v):
		estado_alignment = v
		if _estado:
			_estado.horizontal_alignment = v

var descripcion := "":
	set(v):
		descripcion = v
		if _descripcion:
			_descripcion.text = v
			_descripcion.visible = not v.is_empty()

var seleccionado := false:
	set(v):
		seleccionado = v
		theme_type_variation = Estilos.SELECCION_PEQUENA if v else Estilos.BOTON_PEQUENO

var _imagen: TextureRect
var _titulo: Label
var _estado: Label
var _descripcion: Label


func _init() -> void:
	_construir()


func _construir() -> void:
	theme_type_variation = Estilos.BOTON_PEQUENO
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	contenido = VBoxContainer.new()
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.theme_type_variation = Estilos.COLUMNA_DENSA
	add_child(contenido)
	
	contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contenido.offset_left = 10
	contenido.offset_right = -10
	contenido.offset_top = 8
	contenido.offset_bottom = -14

	# 1. Cabecera: icono + título
	cabecera = HBoxContainer.new()
	cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cabecera.theme_type_variation = Estilos.FILA_ICONOS
	cabecera.visible = false
	contenido.add_child(cabecera)

	_imagen = Iconos.imagen(null, 26.0)
	_imagen.visible = false
	cabecera.add_child(_imagen)

	_titulo = Label.new()
	_titulo.theme_type_variation = Estilos.NOMBRE_TARJETA
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cabecera.add_child(_titulo)

	# 2. Estado (debajo del título, no a su lado)
	_estado = Label.new()
	_estado.theme_type_variation = Estilos.DETALLE
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.visible = false
	_estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(_estado)

	# 3. Cuerpo (contenido personalizado)
	cuerpo = VBoxContainer.new()
	cuerpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cuerpo.theme_type_variation = Estilos.COLUMNA_DENSA
	contenido.add_child(cuerpo)

	# 4. Descripción (debajo del cuerpo)
	_descripcion = Label.new()
	_descripcion.theme_type_variation = Estilos.DETALLE
	_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descripcion.visible = false
	_descripcion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(_descripcion)

	# 5. Pie (alineado al centro, como antes)
	pie = HBoxContainer.new()
	pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.theme_type_variation = Estilos.FILA_ICONOS
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.visible = false
	contenido.add_child(pie)
	pie.child_entered_tree.connect(func(_n: Node) -> void: pie.visible = true)

func _actualizar_cabecera() -> void:
	cabecera.visible = _imagen.visible or not titulo.is_empty()
