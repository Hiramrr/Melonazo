@tool
class_name Obstaculo
extends Area2D
## Elemento del terreno detectado por área: frena, daña, impulsa o se recolecta.
## El efecto lo aplica Recorrido; aquí solo viven la forma y el dibujo.
## El origen está en el suelo; el área crece hacia arriba.

@export_enum("coladera", "charco", "puesto", "poste", "banqueta", "rampa", "toldo", "aplauso") var tipo := "coladera":
	set(valor):
		tipo = valor
		queue_redraw()
@export var medida := Vector2(56, 10):
	set(valor):
		medida = valor
		queue_redraw()
@export var altura_toldo := 115.0
@export var radio_aplauso := 14.0
var activo := true
var roto := false


func configurar(p_tipo: String) -> void:
	tipo = p_tipo
	queue_redraw()


func _puntos_rampa() -> PackedVector2Array:
	var w := medida.x / 2.0
	return PackedVector2Array([Vector2(-w, 6), Vector2(w, 6), Vector2(w, -medida.y)])


func romper() -> void:
	activo = false
	roto = true
	queue_redraw()


func _draw() -> void:
	var w := medida.x / 2.0
	var h := medida.y
	match tipo:
		"aplauso":
			draw_circle(Vector2.ZERO, radio_aplauso, Color(1, 0.82, 0.2))
			draw_arc(Vector2.ZERO, radio_aplauso, 0, TAU, 20, Color(0.75, 0.5, 0.1), 2.0)
			draw_circle(Vector2(-4, 0), 4.0, Color(1, 0.95, 0.7))
			draw_circle(Vector2(4, 0), 4.0, Color(1, 0.95, 0.7))
		"coladera":
			draw_rect(Rect2(-w, -h, w * 2, h), Color(0.15, 0.15, 0.17))
			var x := -w + 6.0
			while x < w:
				draw_line(Vector2(x, -h), Vector2(x, 0), Color(0.45, 0.45, 0.48), 2.0)
				x += 8.0
		"charco":
			draw_rect(Rect2(-w, -h, w * 2, h + 2), Color(0.3, 0.5, 0.85, 0.85))
			draw_line(Vector2(-w * 0.5, -h - 1), Vector2(w * 0.2, -h - 1), Color(0.8, 0.9, 1.0), 2.0)
		"puesto":
			if roto:
				draw_rect(Rect2(-w, -18, w * 2, 18), Color(0.55, 0.35, 0.2))
				draw_rect(Rect2(-w * 0.6, -26, 22, 10), Color(0.95, 0.5, 0.1))
				draw_circle(Vector2(w * 0.5, -6), 7.0, Color(0.9, 0.2, 0.25))
				return
			draw_rect(Rect2(-w, -h * 0.55, w * 2, h * 0.55), Color(0.6, 0.4, 0.22))
			draw_line(Vector2(-w + 4, -h * 0.55), Vector2(-w + 4, -h), Color(0.4, 0.28, 0.15), 4.0)
			draw_line(Vector2(w - 4, -h * 0.55), Vector2(w - 4, -h), Color(0.4, 0.28, 0.15), 4.0)
			for i in 5:
				var col := Color(0.95, 0.85, 0.85) if i % 2 == 0 else Color(0.9, 0.25, 0.3)
				draw_rect(Rect2(-w + i * w * 0.4, -h - 6, w * 0.4, 14), col)
			for i in 4:
				draw_circle(Vector2(-w + 18 + i * 25, -h * 0.55 - 7), 8.0, Color(0.95, 0.55 + i * 0.1, 0.15))
		"poste":
			draw_rect(Rect2(-w, -h, w * 2, h), Color(0.35, 0.37, 0.4))
			draw_rect(Rect2(-w, -h, 26, 8), Color(0.35, 0.37, 0.4))
			draw_circle(Vector2(22, -h + 8), 7.0, Color(1, 0.9, 0.5))
		"banqueta":
			draw_rect(Rect2(-w, -h, w * 2, h), Color(0.7, 0.68, 0.62))
			draw_rect(Rect2(-w, -h, w * 2, 6), Color(0.85, 0.75, 0.2))
		"rampa":
			var pts := _puntos_rampa()
			draw_colored_polygon(pts, Color(0.5, 0.47, 0.43))
			for i in 6:
				var t := (i + 0.5) / 6.0
				draw_circle(Vector2(-w + t * w * 2, -h * t + 1), 6.0, Color(0.62, 0.58, 0.52))
		"toldo":
			var y := -altura_toldo
			draw_line(Vector2(-w + 8, 0), Vector2(-w + 8, y), Color(0.4, 0.28, 0.15), 4.0)
			draw_line(Vector2(w - 8, 0), Vector2(w - 8, y), Color(0.4, 0.28, 0.15), 4.0)
			for i in 6:
				var col := Color(0.2, 0.6, 0.35) if i % 2 == 0 else Color(0.95, 0.95, 0.9)
				draw_rect(Rect2(-w + i * w / 3.0, y - h / 2.0, w / 3.0, h), col)
