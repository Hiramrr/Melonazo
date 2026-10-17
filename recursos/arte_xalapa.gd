class_name ArteXalapa
extends Resource
## Recurso con el arte fotográfico opcional del juego y sus créditos.
## La instancia única es recursos/arte_xalapa.tres; se edita en el inspector.
##
## Quién lo usa (todos con preload del .tres):
##   Paisaje            dibujar() pinta la foto panorámica como fondo del recorrido
##   HUD                crear_creditos_paisaje() agrega la atribución de esa foto
##   PostalResultados   fotografias, mostradas con FotoLugar solo al terminar
##   Postal             lugares_mapa, imágenes provisionales del recorrido
##
## Vacía `paisaje` en el .tres para usar solamente los dibujos del juego.

## Foto panorámica de fondo (puede ser un AtlasTexture recortado). null = sin foto.
@export var paisaje: Texture2D
## Atribución de `paisaje`: {nombre, autor, licencia, fuente, url_licencia}.
@export var credito_paisaje: Dictionary = {}
## id de lugar -> {textura, nombre, dato_curioso, fuente_dato, autor, fuente, licencia, url_licencia}.
## Las claves coinciden con los id de Config.postales.
## Vacía el diccionario para quitar las fotos.
@export var fotografias: Dictionary = {}
## id de lugar -> Texture2D. Sustituye cada foto por su sprite sin cambiar los resultados.
@export var lugares_mapa: Dictionary = {}


## Dibuja `paisaje` en rect sobre ci, recortado al centro para llenar rect sin
## deformarse (como "cover" en CSS). No hace nada si no hay foto.
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


## Crea la fila "Foto: autor · Fuente · Licencia" del paisaje. Siempre devuelve el
## nodo (llamado "CreditosFondo"); queda oculto y vacío si no hay foto o crédito.
func crear_creditos_paisaje() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.name = "CreditosFondo"
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.theme_type_variation = &"FilaNormal"
	fila.visible = paisaje != null and not credito_paisaje.is_empty()
	if not fila.visible:
		return fila
	var autor := Label.new()
	autor.text = "Foto: " + str(credito_paisaje["autor"])
	autor.theme_type_variation = &"AutorPaisaje"
	fila.add_child(autor)
	for entrada in [["Fuente", credito_paisaje["fuente"]], [credito_paisaje["licencia"], credito_paisaje["url_licencia"]]]:
		var enlace := LinkButton.new()
		enlace.text = entrada[0]
		enlace.uri = entrada[1]
		enlace.tooltip_text = "Foto reducida y recortada en pantalla. " + entrada[1]
		enlace.theme_type_variation = &"EnlaceCredito"
		fila.add_child(enlace)
	return fila
