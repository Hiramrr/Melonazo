@tool
class_name Persona
extends Node2D
## Alguien del público parado junto al camino. Si el melón pasa cerca y el jugador
## presiona E, le da un empujón. Cada persona ayuda una sola vez.
##
## Escena: mundo/ayudas/persona.tscn (un solo Node2D; todo se dibuja en _draw()).
## El origen está a ras de suelo, entre los pies.
##
## Quién la usa: GeneradorTerreno._poner_publico() la instancia en el contenedor Publico
## del tramo (y la anota en Tramo.personas) con colores al azar.
## Recorrido._actualizar_interacciones() asigna `en_rango` cada cuadro y
## Recorrido._empujar_con() pone `usado` y `t_empuje`; la fuerza del empujón se calcula
## allí, no aquí.

const TINTA := Color(0.1, 0.1, 0.1)
const CENTRO_GLOBO := Vector2(0, -108)   # globo con la tecla "E", sobre la cabeza
const RADIO_GLOBO := 16.0

@export var color_ropa := Color(0.8, 0.3, 0.3)
@export var color_piel := Color(0.8, 0.6, 0.45)
## El melón está lo bastante cerca para pedirle un empujón (muestra el globo "E").
var en_rango := false:
	set(valor):
		if en_rango != valor:
			en_rango = valor
			queue_redraw()
## Ya empujó en esta carrera; se queda con los brazos arriba.
var usado := false
## Segundos que le quedan a la pose de empujar (brazos al frente).
var t_empuje := 0.0


func _process(delta: float) -> void:
	if t_empuje > 0.0:
		t_empuje -= delta
		queue_redraw()


func _draw() -> void:
	# Piernas, torso y cabeza.
	var pantalon := color_ropa.darkened(0.5)
	draw_line(Vector2(-6, 0), Vector2(-5, -28), pantalon, 6.0)
	draw_line(Vector2(6, 0), Vector2(5, -28), pantalon, 6.0)
	draw_rect(Rect2(-10, -60, 20, 34), color_ropa)
	draw_circle(Vector2(0, -70), 10.0, color_piel)
	# Brazos según la pose: empujando, festejando (ya ayudó) o esperando.
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
		draw_circle(CENTRO_GLOBO, RADIO_GLOBO, Color(1, 1, 1))
		draw_arc(CENTRO_GLOBO, RADIO_GLOBO, 0, TAU, 24, TINTA, 2.0)
		draw_string(ThemeDB.fallback_font, CENTRO_GLOBO + Vector2(-16, 7), "E", HORIZONTAL_ALIGNMENT_CENTER, 32, 20, TINTA)
