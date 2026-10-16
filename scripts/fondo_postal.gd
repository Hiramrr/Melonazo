extends Control
## Postal del lugar fotografiado más lejano que se alcanzó en esta carrera.
var arte: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
var con_foto := false
const ESCENARIO := preload("res://recursos/taller_xallitic.svg")


func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
			margen.add_theme_constant_override("margin_" + lado, 16)
		var foto := FotoLugar.new()
		foto.name = "Foto"
		foto.configurar(arte.fotografias[id])
		margen.add_child(foto)
		con_foto = true


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("c7ded3"))
	if not con_foto:
		draw_texture_rect(ESCENARIO, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), Color("203d38"), false, 2.0)
