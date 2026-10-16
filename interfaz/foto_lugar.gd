class_name FotoLugar
extends VBoxContainer
## Fotografía real de un lugar de Xalapa, con su nombre, atribución y enlaces a la
## fuente y a la licencia. No tiene escena: se crea por código.
##
## Uso:
##   var foto := FotoLugar.new()
##   foto.configurar(arte.fotografias[id])   # ArteXalapa (recursos/arte_xalapa.tres)
##   contenedor.add_child(foto)
## Lo usan la postal de Resultados (pantallas/resultados/postal_resultados.gd) y el
## pasaporte del Taller.
##
## Hijos que crea configurar(), en orden:
##   Imagen     TextureRect con la foto (las pruebas de capturas lo buscan por nombre)
##   (Label)    nombre del lugar
##   (Label)    autor de la foto
##   (HBox)     LinkButton "Fuente" y LinkButton con el nombre de la licencia


## Crea los hijos a partir de una entrada de ArteXalapa.fotografias:
## {textura, nombre, autor, fuente, licencia, url_licencia}. alto = alto mínimo de la foto.
## Llamar una sola vez.
func configurar(datos: Dictionary, alto := 200.0) -> void:
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var imagen := TextureRect.new()
	imagen.name = "Imagen"
	imagen.texture = datos["textura"]
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.custom_minimum_size.y = alto
	imagen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(imagen)
	var titulo := Label.new()
	titulo.text = datos["nombre"]
	titulo.add_theme_font_size_override("font_size", 20)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(titulo)
	var credito := Label.new()
	credito.text = "Foto: %s\nVersión reducida. Encuadre de pantalla." % datos["autor"]
	credito.add_theme_font_size_override("font_size", 13)
	credito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(credito)
	var enlaces := HBoxContainer.new()
	enlaces.add_theme_constant_override("separation", 16)
	add_child(enlaces)
	for entrada in [["Fuente", datos["fuente"]], [datos["licencia"], datos["url_licencia"]]]:
		var enlace := LinkButton.new()
		enlace.text = entrada[0]
		enlace.uri = entrada[1]
		enlace.tooltip_text = entrada[1]
		enlace.add_theme_font_size_override("font_size", 14)
		enlace.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		enlaces.add_child(enlace)
