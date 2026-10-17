class_name PostalResultados
extends Control
## Postal fotográfica del lugar más lejano alcanzado en este intento.
## Si falta su imagen, oculta la postal. Nunca sustituye un lugar por otro ni por dibujos.

const INCLINACION := -2.5              # grados

var arte: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
## true si se encontró un lugar con foto y se creó MargenFoto/Foto.
var con_foto := false
var lugar_id := ""
var lugar_nombre := "Xalapa"


func _ready() -> void:
	theme_type_variation = &"Postal"
	resized.connect(_al_cambiar_tamano)
	mouse_filter = Control.MOUSE_FILTER_PASS
	rotation_degrees = INCLINACION
	# Config.postales va ordenado por metros: el último que cumple es el más lejano.
	var metros := float(Juego.ultimo.get("distancia", 0.0))
	for lugar in Config.postales:
		if metros < float(lugar["metros"]):
			break
		lugar_id = lugar["id"]
		lugar_nombre = lugar["nombre"]
	var datos: Dictionary = arte.fotografias.get(lugar_id, {}).duplicate()
	if not datos.get("textura") is Texture2D:
		hide()
		return
	datos["nombre"] = lugar_nombre
	var margen := MarginContainer.new()
	margen.name = "MargenFoto"
	add_child(margen)
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.theme_type_variation = &"MargenPostal"
	var foto := FotoLugar.new()
	foto.name = "Foto"
	foto.configurar(datos)
	margen.add_child(foto)
	con_foto = true


func _al_cambiar_tamano() -> void:
	pivot_offset = size * 0.5
	queue_redraw()


func _draw() -> void:
	var marco := Rect2(Vector2.ZERO, size)
	draw_style_box(get_theme_stylebox("sombra"), Rect2(marco.position + Vector2(6, 9), marco.size))
	draw_style_box(get_theme_stylebox("marco"), marco)
	# Cinta adhesiva arriba, un poco girada.
	draw_set_transform(Vector2(size.x * 0.5, 4), deg_to_rad(4.0))
	Sprites.rectangulo(self, Rect2(-60, -16, 120, 32), get_theme_color("cinta"))
	draw_set_transform(Vector2.ZERO)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()
