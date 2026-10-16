class_name PostalResultados
extends Control
## Columna izquierda de la pantalla de Resultados: la foto del lugar más lejano que se
## alcanzó en esta carrera, o una ilustración del taller si no se llegó a ninguno con foto.
##
## Vive en el nodo Margen/Columnas/Postal de pantallas/resultados/resultados.tscn.
## No necesita que nadie la llame: en _ready() lee Juego.ultimo["distancia"], busca en
## Config.postales el último lugar alcanzado que tenga foto en ArteXalapa.fotografias y,
## si lo hay, crea estos hijos (las pruebas de capturas los buscan por nombre):
##   MargenFoto        MarginContainer a pantalla completa
##     Foto            FotoLugar (interfaz/foto_lugar.gd), que a su vez crea "Imagen"
## El fondo y el marco se dibujan en _draw().

const ESCENARIO := preload("res://recursos/taller_xallitic.svg")   # ilustración sin foto
const FONDO := Color("c7ded3")
const MARCO := Color("203d38")
const MARGEN_FOTO := 16

var arte: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
## true si se encontró un lugar con foto y se creó MargenFoto/Foto.
var con_foto := false


func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Config.postales va ordenado por metros: el último que cumple es el más lejano.
	var id := ""
	var metros := float(Juego.ultimo.get("distancia", 0.0))
	for lugar in Config.postales:
		if metros >= float(lugar["metros"]) and arte.fotografias.has(lugar["id"]):
			id = lugar["id"]
	if not id.is_empty():
		var margen := MarginContainer.new()
		margen.name = "MargenFoto"
		add_child(margen)
		margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for lado in ["left", "top", "right", "bottom"]:
			margen.add_theme_constant_override("margin_" + lado, MARGEN_FOTO)
		var foto := FotoLugar.new()
		foto.name = "Foto"
		foto.configurar(arte.fotografias[id])
		margen.add_child(foto)
		con_foto = true


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	if not con_foto:
		draw_texture_rect(ESCENARIO, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), MARCO, false, 2.0)
