@tool
class_name Ficha
extends PanelContainer
## Contador redondeado con ícono: aplausos, récord, carisma, altura...
##
## Se usa en escenas (con los valores en el inspector) o por código:
##   var f := Ficha.crear(Iconos.APLAUSO, "120")
##   f.texto = "130"
## oscura = true usa la variación Chip (fondo tinta, letra crema con contorno),
## pensada para ir sobre el juego; false usa ChipClaro, para pantallas de menú.

@export var icono: Texture2D:
	set(valor):
		icono = valor
		if _imagen:
			_imagen.texture = valor
			_imagen.visible = valor != null
@export var texto := "0":
	set(valor):
		texto = valor
		if _etiqueta:
			_etiqueta.text = valor
@export var oscura := true:
	set(valor):
		oscura = valor
		_aplicar_estilo()
@export var tam_texto := 18:
	set(valor):
		tam_texto = valor
		_aplicar_estilo()
@export var lado_icono := 26.0:
	set(valor):
		lado_icono = valor
		if _imagen:
			_imagen.custom_minimum_size = Vector2(lado_icono, lado_icono)

var _imagen: TextureRect
var _etiqueta: Label


static func crear(p_icono: Texture2D, p_texto: String, p_oscura := true, p_tam := 18) -> Ficha:
	var f := Ficha.new()
	f.icono = p_icono
	f.texto = p_texto
	f.oscura = p_oscura
	f.tam_texto = p_tam
	return f


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila, false, Node.INTERNAL_MODE_FRONT)
	_imagen = Iconos.imagen(icono, lado_icono)
	fila.add_child(_imagen)
	_etiqueta = Label.new()
	_etiqueta.name = "Texto"
	_etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_etiqueta)


func _ready() -> void:
	_imagen.texture = icono
	_imagen.visible = icono != null
	_imagen.custom_minimum_size = Vector2(lado_icono, lado_icono)
	_etiqueta.text = texto
	_aplicar_estilo()


func _aplicar_estilo() -> void:
	if _etiqueta == null:
		return
	theme_type_variation = &"Chip" if oscura else &"ChipClaro"
	_etiqueta.theme_type_variation = &"TextoHUD" if oscura else &"Subtitulo"
	_etiqueta.add_theme_font_size_override("font_size", tam_texto)
