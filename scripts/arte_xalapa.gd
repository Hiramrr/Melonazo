class_name ArteXalapa
extends Resource
## Vacía paisaje en arte_xalapa.tres para usar solamente los dibujos del juego.
@export var paisaje: Texture2D
@export var credito_paisaje: Dictionary = {}
## Las claves coinciden con los lugares del pasaporte. Vacía el diccionario para quitar las fotos.
@export var fotografias: Dictionary = {}


func dibujar(ci: CanvasItem, rect: Rect2, tinte := Color.WHITE) -> void:
	if paisaje == null:
		return
	var origen := Rect2(Vector2.ZERO, paisaje.get_size())
	var proporcion := rect.size.x / rect.size.y
	if origen.size.x / origen.size.y > proporcion:
		origen.size.x = origen.size.y * proporcion
	else:
		origen.size.y = origen.size.x / proporcion
	origen.position = (paisaje.get_size() - origen.size) / 2.0
	ci.draw_texture_rect_region(paisaje, rect, origen, tinte)


func crear_creditos_paisaje() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.name = "CreditosFondo"
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	fila.visible = paisaje != null and not credito_paisaje.is_empty()
	if not fila.visible:
		return fila
	var autor := Label.new()
	autor.text = "Foto: " + str(credito_paisaje["autor"])
	autor.add_theme_font_size_override("font_size", 13)
	fila.add_child(autor)
	for entrada in [["Fuente", credito_paisaje["fuente"]], [credito_paisaje["licencia"], credito_paisaje["url_licencia"]]]:
		var enlace := LinkButton.new()
		enlace.text = entrada[0]
		enlace.uri = entrada[1]
		enlace.tooltip_text = "Foto reducida y recortada en pantalla. " + entrada[1]
		enlace.add_theme_font_size_override("font_size", 13)
		fila.add_child(enlace)
	return fila
