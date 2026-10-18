class_name IlustracionFicha
extends Control
## El mismo dibujo para las miniaturas y la ficha abierta.

var categoria := 0
var melon: Dictionary = {}
var id := ""


func _ready() -> void:
<<<<<<< HEAD
=======
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST 
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	match categoria:
		0:
			if melon.is_empty():
				return
			var radio := minf(size.x, size.y) * 0.28
			var centro := size * Vector2(0.5, 0.55)
			var estela: Dictionary = Config.estelas[melon["estela"]]
			if melon["estela"] > 0:
				for i in 4:
					Sprites.disco(self, centro + Vector2(-radio * (1.2 + i * 0.24), radio * 0.4), radio * (0.12 - i * 0.02), estela["color"])
			draw_set_transform(centro)
			Aspecto.dibujar_melon(self, radio, melon["accesorios"], false, true, melon)
			draw_set_transform(Vector2.ZERO)
		1:
			Config.accesorios[id].dibujar_icono(self, Rect2(Vector2.ONE * 12, size - Vector2.ONE * 24))
		2:
			var escala := minf(size.x, size.y) * 0.72 / (Poder.RADIO_INSIGNIA * 2.0 + 4.0)
			draw_set_transform(size * 0.5, 0, Vector2.ONE * escala)
			Poder.dibujar_insignia(self, id)
			draw_set_transform(Vector2.ZERO)
