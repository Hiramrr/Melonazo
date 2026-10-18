class_name Tarjeta
extends PanelContainer
## Tarjeta de visualización (no clicable).
##
## Orden interno (de arriba a abajo):
##   cabecera     HBox: icono + título (oculta si no hay ninguno)
##   estado       Label bajo la cabecera (oculto si vacío)
##   cuerpo       VBox para contenido personalizado (insignias, filas…)
##   descripción  Label autowrap bajo el cuerpo (oculta si vacía)
##   pie          HBox alineado a la derecha (oculto si vacío)
##
## El orden cabecera → estado → cuerpo → descripción replica el de las
## tarjetas del código anterior y es el que espera el jugador.

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

var _imagen: TextureRect
var _titulo: Label
var _estado: Label
var _descripcion: Label


func _init() -> void:
	_construir()


func _construir() -> void:
	theme_type_variation = Estilos.TARJETA
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	contenido = VBoxContainer.new()
	contenido.theme_type_variation = Estilos.COLUMNA_COMPACTA
	add_child(contenido)

	# 1. Cabecera: icono + título
	cabecera = HBoxContainer.new()
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
	cabecera.add_child(_titulo)

	# 2. Estado (debajo del título, no a su lado)
	_estado = Label.new()
	_estado.theme_type_variation = Estilos.DETALLE
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.visible = false
	contenido.add_child(_estado)

	# 3. Cuerpo (contenido personalizado)
	cuerpo = VBoxContainer.new()
	cuerpo.theme_type_variation = Estilos.COLUMNA_COMPACTA
	contenido.add_child(cuerpo)

	# 4. Descripción (debajo del cuerpo)
	_descripcion = Label.new()
	_descripcion.theme_type_variation = Estilos.DETALLE
	_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descripcion.visible = false
	contenido.add_child(_descripcion)

	# 5. Pie
	pie = HBoxContainer.new()
	pie.theme_type_variation = Estilos.FILA_ICONOS
	pie.alignment = BoxContainer.ALIGNMENT_END
	pie.visible = false
	contenido.add_child(pie)
	pie.child_entered_tree.connect(func(_n: Node) -> void: pie.visible = true)
	

func _actualizar_cabecera() -> void:
	cabecera.visible = _imagen.visible or not titulo.is_empty()
