class_name FotoLugar
extends VBoxContainer
## Fotografía real de un lugar de la ruta, con su nombre, dato curioso y créditos.
## No tiene escena: se crea por código.
##
## Uso:
##   var foto := FotoLugar.new()
##   foto.configurar(arte.fotografias[id])   # ArteXalapa (recursos/arte_xalapa.tres)
##   contenedor.add_child(foto)
## La usa exclusivamente la postal de Resultados (pantallas/resultados/postal_resultados.gd).
##
## Hijos que crea configurar(), en orden:
##   Imagen     TextureRect con la foto (las pruebas de capturas lo buscan por nombre)
##   (Label)    nombre del lugar (si con_titulo)
##   DatoCurioso texto del lugar, si está asignado
##   (Label)    autor de la foto
##   (HBox)     enlaces a la foto original, sus derechos y la fuente del dato


## Crea los hijos a partir de una entrada de ArteXalapa.fotografias:
## {textura, nombre, dato_curioso, fuente_dato, autor, fuente, licencia, url_licencia}.
## alto = alto mínimo de la foto.
## con_titulo = false omite el nombre (cuando la tarjeta que la contiene ya lo muestra).
## Llamar una sola vez.
func configurar(datos: Dictionary, alto := 200.0, con_titulo := true) -> void:
	theme_type_variation = &"ColumnaNormal"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var imagen := TextureRect.new()
	imagen.name = "Imagen"
	imagen.texture = datos["textura"]
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.custom_minimum_size.y = alto
	imagen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(imagen)
	if con_titulo:
		var titulo := Label.new()
		titulo.text = datos["nombre"]
		titulo.theme_type_variation = &"TituloFoto"
		titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(titulo)
	if not str(datos.get("dato_curioso", "")).is_empty():
		var dato := Label.new()
		dato.name = "DatoCurioso"
		dato.text = "Dato curioso\n" + str(datos["dato_curioso"])
		dato.theme_type_variation = &"TextoPostal"
		dato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(dato)
	var credito := Label.new()
	credito.text = "Foto: %s\nVersión reducida. Encuadre de pantalla." % datos["autor"]
	credito.theme_type_variation = &"Credito"
	credito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(credito)
	var enlaces := HBoxContainer.new()
	enlaces.theme_type_variation = &"FilaEnlaces"
	add_child(enlaces)
	var destinos := [["Foto original", datos["fuente"]], [datos["licencia"], datos["url_licencia"]]]
	if not str(datos.get("fuente_dato", "")).is_empty():
		destinos.append(["Sobre el lugar", datos["fuente_dato"]])
	for entrada in destinos:
		if str(entrada[1]).is_empty():
			continue
		var enlace := LinkButton.new()
		enlace.text = entrada[0]
		enlace.uri = entrada[1]
		enlace.tooltip_text = entrada[1]
		enlace.theme_type_variation = &"EnlaceCredito"
		enlace.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		enlaces.add_child(enlace)
