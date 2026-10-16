@tool
class_name Persona
extends Node2D
## Alguien del público parado junto al camino. Si el melón pasa cerca y el
## jugador presiona E, lo empuja (la lógica está en Recorrido).

@export var color_ropa := Color(0.8, 0.3, 0.3)
@export var color_piel := Color(0.8, 0.6, 0.45)
var en_rango := false
var usado := false
var t_empuje := 0.0


func _process(delta: float) -> void:
	if t_empuje > 0.0:
		t_empuje -= delta
		queue_redraw()


func _draw() -> void:
	var pantalon := color_ropa.darkened(0.5)
	draw_line(Vector2(-6, 0), Vector2(-5, -28), pantalon, 6.0)
	draw_line(Vector2(6, 0), Vector2(5, -28), pantalon, 6.0)
	draw_rect(Rect2(-10, -60, 20, 34), color_ropa)
	draw_circle(Vector2(0, -70), 10.0, color_piel)
	if t_empuje > 0.0:
		draw_line(Vector2(6, -54), Vector2(30, -50), color_piel, 5.0)
		draw_line(Vector2(6, -46), Vector2(30, -42), color_piel, 5.0)
	elif usado:
		draw_line(Vector2(-8, -56), Vector2(-16, -88), color_piel, 5.0)
		draw_line(Vector2(8, -56), Vector2(16, -88), color_piel, 5.0)
	else:
		draw_line(Vector2(-10, -56), Vector2(-14, -32), color_piel, 5.0)
		draw_line(Vector2(10, -56), Vector2(14, -32), color_piel, 5.0)
	if en_rango and not usado:
		draw_circle(Vector2(0, -108), 16.0, Color(1, 1, 1))
		draw_arc(Vector2(0, -108), 16.0, 0, TAU, 24, Color(0.1, 0.1, 0.1), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-16, -101), "E", HORIZONTAL_ALIGNMENT_CENTER, 32, 20, Color(0.1, 0.1, 0.1))
