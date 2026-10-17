class_name ComunTaller
extends RefCounted
## Construye controles con variaciones de interfaz/tema_xalapa.tres.


static func nombre_melon() -> String:
	return Juego.nombre_melon if not Juego.nombre_melon.strip_edges().is_empty() else "Melón"


static func etiqueta(texto: String, estilo: StringName = &"") -> Label:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = estilo
	return l


static func titulo_seccion(texto: String, estilo: StringName = &"Subtitulo") -> Label:
	return etiqueta(texto, estilo)


static func boton(texto: String, estilo: StringName = &"") -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = estilo
	return b


static func fila_con_titulo(titulo: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.theme_type_variation = &"FilaSeccion"
	var l := titulo_seccion(titulo, &"SubtituloChico")
	l.custom_minimum_size.x = 84
	fila.add_child(l)
	return fila
