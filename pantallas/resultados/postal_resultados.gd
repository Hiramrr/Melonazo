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
## Se ve como una foto instantánea pegada con cinta: marco crema con sombra, un
## trozo de cinta arriba y una ligera inclinación. Todo eso se dibuja en _draw().

const ESCENARIO := preload("res://recursos/taller_xallitic.svg")   # ilustración sin foto
const FONDO := Color("fff9ec")
const MARCO := Color("203d38")
const SOMBRA := Color(0.125, 0.239, 0.22, 0.3)
const CINTA := Color(1, 0.93, 0.6, 0.85)
const MARGEN_FOTO := 18
const INCLINACION := -2.5              # grados

var arte: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
## true si se encontró un lugar con foto y se creó MargenFoto/Foto.
var con_foto := false


func _ready() -> void:
	resized.connect(_al_cambiar_tamano)
	mouse_filter = Control.MOUSE_FILTER_PASS
	rotation_degrees = INCLINACION
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


func _al_cambiar_tamano() -> void:
	pivot_offset = size * 0.5
	queue_redraw()


func _draw() -> void:
	var marco := Rect2(Vector2.ZERO, size)
	draw_style_box(_caja(SOMBRA, 0), Rect2(marco.position + Vector2(6, 9), marco.size))
	draw_style_box(_caja(FONDO, 4), marco)
	if not con_foto:
		var dentro := marco.grow(-MARGEN_FOTO)
		draw_texture_rect(ESCENARIO, dentro, false)
		draw_rect(dentro, MARCO, false, 3.0)
	# Cinta adhesiva arriba, un poco girada.
	draw_set_transform(Vector2(size.x * 0.5, 4), deg_to_rad(4.0))
	draw_rect(Rect2(-60, -16, 120, 32), CINTA)
	draw_set_transform(Vector2.ZERO)


func _caja(color: Color, borde: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(10)
	s.set_border_width_all(borde)
	s.border_color = MARCO
	return s
