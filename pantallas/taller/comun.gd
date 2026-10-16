class_name ComunTaller
extends RefCounted
## Utilidades compartidas por el taller y sus pestañas (no es un nodo).
##
## Se usa como ComunTaller.etiqueta(...), ComunTaller.boton(...), etc.
## Crea las etiquetas y botones que las pestañas generan por código, con los
## mismos tamaños y colores en todas, y da el nombre visible del melón.

const SUAVE := Color("5d6f65")          # texto secundario (notas, descripciones)


## Nombre del melón para mostrar; si el jugador lo dejó vacío, "Melón".
static func nombre_melon() -> String:
	return Juego.nombre_melon if not Juego.nombre_melon.strip_edges().is_empty() else "Melón"


## Label con tamaño de letra tam (16 = el del tema). suave = color secundario.
static func etiqueta(texto: String, tam := 16, suave := false) -> Label:
	var l := Label.new()
	l.text = texto
	if tam != 16:
		l.add_theme_font_size_override("font_size", tam)
	if suave:
		l.add_theme_color_override("font_color", SUAVE)
	return l


## Button con tamaño de letra tam (16 = el del tema).
static func boton(texto: String, tam := 16) -> Button:
	var b := Button.new()
	b.text = texto
	if tam != 16:
		b.add_theme_font_size_override("font_size", tam)
	return b


## Fila horizontal con una etiqueta de ancho fijo a la izquierda ("Piel", "Colores"...).
static func fila_con_titulo(titulo: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var l := etiqueta(titulo)
	l.custom_minimum_size.x = 70
	fila.add_child(l)
	return fila
