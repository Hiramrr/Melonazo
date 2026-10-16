class_name ComunTaller
extends RefCounted
## Utilidades compartidas por el taller y sus pestañas (no es un nodo).
##
## Se usa como ComunTaller.etiqueta(...), ComunTaller.boton(...), etc.
## Crea las etiquetas y botones que las pestañas generan por código, con los
## mismos tamaños y colores en todas, y da el nombre visible del melón.

## Nombre del melón para mostrar; si el jugador lo dejó vacío, "Melón".
static func nombre_melon() -> String:
	return Juego.nombre_melon if not Juego.nombre_melon.strip_edges().is_empty() else "Melón"


## Label con tamaño de letra tam (17 = el del tema). suave = variación Suave
## del tema (texto secundario: notas y descripciones).
static func etiqueta(texto: String, tam := 17, suave := false) -> Label:
	var l := Label.new()
	l.text = texto
	if suave:
		l.theme_type_variation = &"Suave"
	if tam != 17:
		l.add_theme_font_size_override("font_size", tam)
	return l


## Título de sección en letra gruesa ("Postales", "Poderes en la ruta").
static func titulo_seccion(texto: String, tam := 20) -> Label:
	var l := etiqueta(texto, tam)
	l.theme_type_variation = &"Subtitulo"
	l.add_theme_font_size_override("font_size", tam)
	return l


## Button con tamaño de letra tam (17 = el del tema).
static func boton(texto: String, tam := 17) -> Button:
	var b := Button.new()
	b.text = texto
	if tam != 17:
		b.add_theme_font_size_override("font_size", tam)
	return b


## Fila horizontal con una etiqueta de ancho fijo a la izquierda ("Piel", "Colores"...).
static func fila_con_titulo(titulo: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var l := titulo_seccion(titulo, 17)
	l.custom_minimum_size.x = 84
	fila.add_child(l)
	return fila
