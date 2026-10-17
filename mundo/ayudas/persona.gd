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
	var pose := 2 if t_empuje > 0.0 else (1 if usado else 0)
	var rect := Rect2(-24, -96, 64, 100)
	Sprites.dibujar(self, "ayudas/persona_ropa_%d" % pose, rect, color_ropa)
	Sprites.dibujar(self, "ayudas/persona_piel_%d" % pose, rect, color_piel)
	if en_rango and not usado:
		Sprites.poner(self, "ayudas/tecla", CENTRO_GLOBO)
		draw_string(ThemeDB.fallback_font, CENTRO_GLOBO + Vector2(-16, 7), "E", HORIZONTAL_ALIGNMENT_CENTER, 32, 20, TINTA)
