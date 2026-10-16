class_name Iconos
extends RefCounted
## Íconos de la interfaz (SVG en recursos/iconos/) y atajos para crear piezas
## pequeñas con el estilo del tema. No es un nodo: se usa como Iconos.APLAUSO,
## Iconos.imagen(...) o Iconos.tecla(...).
##
## Los íconos sustituyen a los símbolos que la fuente Fredoka no trae
## (flechas, estrellas, pausa), así se ven igual en cualquier sistema.

const APLAUSO := preload("res://recursos/iconos/aplauso.png")
const TROFEO := preload("res://recursos/iconos/trofeo.png")
const CORAZON := preload("res://recursos/iconos/corazon.png")
const IMPULSO := preload("res://recursos/iconos/impulso.png")
const CARISMA := preload("res://recursos/iconos/carisma.png")
const PODER := preload("res://recursos/iconos/poder.png")
const ALTURA := preload("res://recursos/iconos/altura.png")
const PAPALOTE := preload("res://recursos/iconos/papalote.png")
const CANDADO := preload("res://recursos/iconos/candado.png")
const PAUSA := preload("res://recursos/iconos/pausa.png")
const JUGAR := preload("res://recursos/iconos/jugar.png")
const FLECHA_IZQ := preload("res://recursos/iconos/flecha_izq.png")
const FLECHA_DER := preload("res://recursos/iconos/flecha_der.png")
const LUGAR := preload("res://recursos/iconos/lugar.png")
const REGLA := preload("res://recursos/iconos/regla.png")


## TextureRect cuadrado de lado px con la textura, que no recibe el ratón.
static func imagen(textura: Texture2D, lado := 24.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = textura
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(lado, lado)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Tecla dibujada ("Espacio", "E", "1"...), con la variación Tecla del tema.
static func tecla(texto: String, tam := 15) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"Tecla"
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if tam != 15:
		l.add_theme_font_size_override("font_size", tam)
	return l
