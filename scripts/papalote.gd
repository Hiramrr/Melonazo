@tool
class_name Papalote
extends Node2D
## Ayuda de la ruta aérea. Cada papalote se puede usar una vez con E.

var usado := false
var en_rango := false:
	set(valor):
		if en_rango != valor:
			en_rango = valor
			queue_redraw()


func impulsar(melon: Melon) -> bool:
	if usado or not melon.controlable or melon.roto or global_position.distance_to(melon.global_position) > Config.papalote_rango:
		return false
	usado = true
	en_rango = false
	var v := melon.linear_velocity + melon._dv
	melon.empujar(Vector2(maxf(0.0, Config.papalote_avance - v.x), minf(0.0, -Config.papalote_elevacion - v.y)))
	if melon.rebotes < Juego.rebotes_max():
		melon.sumar_rebote()
	melon.proteger()
	queue_redraw()
	return true


func _draw() -> void:
	var tinta := Color("294b43")
	var coral := Color("d86b51") if not usado else Color("9caaa1")
	var crema := Color("fff4d6")
	var rombo := PackedVector2Array([Vector2(0, -48), Vector2(38, -4), Vector2(0, 44), Vector2(-38, -4)])
	if en_rango:
		draw_arc(Vector2.ZERO, 64, 0, TAU, 48, crema, 4, true)
		draw_arc(Vector2.ZERO, 68, 0, TAU, 48, tinta, 2, true)
	draw_colored_polygon(rombo, coral)
	draw_colored_polygon(PackedVector2Array([rombo[0], rombo[1], rombo[2]]), Color("e9c873") if not usado else Color("b5beb4"))
	draw_polyline(PackedVector2Array([rombo[0], rombo[1], rombo[2], rombo[3], rombo[0]]), tinta, 3, true)
	draw_line(rombo[0], rombo[2], tinta, 2, true)
	draw_line(rombo[1], rombo[3], tinta, 2, true)
	draw_polyline(PackedVector2Array([Vector2(0, 44), Vector2(-8, 59), Vector2(9, 74), Vector2(-3, 94)]), tinta, 2, true)
	for y in [60.0, 80.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(-13, y - 5), Vector2(13, y - 5), Vector2(0, y + 5)]), coral)
	if not usado:
		draw_polyline(PackedVector2Array([Vector2(-12, 13), Vector2(0, -6), Vector2(12, 13)]), crema, 5, true)
	var texto := "Usado" if usado else ("E · Impulso" if en_rango else "Papalote +1")
	var fuente := ThemeDB.fallback_font
	draw_string_outline(fuente, Vector2(-90, -70), texto, HORIZONTAL_ALIGNMENT_CENTER, 180, 18, 5, tinta)
	draw_string(fuente, Vector2(-90, -70), texto, HORIZONTAL_ALIGNMENT_CENTER, 180, 18, crema)
