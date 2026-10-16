@tool
class_name Papalote
extends Node2D
## Ayuda de la ruta aérea: un papalote flotando. Si el melón pasa cerca y el jugador
## presiona E, lo lanza hacia arriba y adelante y lo protege
## de la siguiente caída fuerte.
## Cada papalote se puede usar una sola vez.
##
## Escena: mundo/ayudas/papalote.tscn (un solo Node2D, z 4; todo se dibuja en _draw()).
##
## Quién lo usa: GeneradorTerreno._poner_papalotes() lo instancia en el contenedor Aire
## del tramo (y lo anota en Tramo.papalotes). Recorrido._actualizar_interacciones()
## asigna `en_rango` cada cuadro y llama impulsar() con el más cercano al presionar E.
## Ajustes: Config.papalote_rango, papalote_avance y papalote_elevacion.

const TINTA := Color("294b43")
const CREMA := Color("fff4d6")

@export var corriente := false

## Ya se usó en esta carrera; se dibuja en gris.
var usado := false
## El melón está lo bastante cerca para usarlo (muestra el aro y "E · Impulso").
var en_rango := false:
	set(valor):
		if en_rango != valor:
			en_rango = valor
			queue_redraw()


## Impulsa al melón si está a alcance y el papalote no se ha usado. Devuelve true si
## hubo impulso. Asegura una velocidad mínima hacia adelante y hacia arriba (no suma
## si el melón ya va más rápido) y activa su escudo. Los saltos se recuperan con tamales.
func impulsar(melon: Melon) -> bool:
	if usado or not melon.controlable or melon.roto or global_position.distance_to(melon.global_position) > Config.papalote_rango:
		return false
	usado = true
	en_rango = false
	# Se lee melon._dv (privado, sin getter público) para contar también los impulsos
	# pedidos en este mismo paso de física; así Espacio + E no duplican la elevación.
	var v := melon.linear_velocity + melon._dv
	melon.empujar(Vector2(maxf(0.0, Config.papalote_avance - v.x), minf(0.0, -Config.papalote_elevacion - v.y)))
	melon.proteger()
	queue_redraw()
	return true


# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	if corriente:
		_dibujar_corriente()
		return
	var coral := Color("d86b51") if not usado else Color("9caaa1")
	var rombo := PackedVector2Array([Vector2(0, -48), Vector2(38, -4), Vector2(0, 44), Vector2(-38, -4)])
	if en_rango:
		draw_arc(Vector2.ZERO, 64, 0, TAU, 48, CREMA, 4, true)
		draw_arc(Vector2.ZERO, 68, 0, TAU, 48, TINTA, 2, true)
	# Rombo con la mitad derecha más clara, contorno y varillas.
	draw_colored_polygon(rombo, coral)
	draw_colored_polygon(PackedVector2Array([rombo[0], rombo[1], rombo[2]]), Color("e9c873") if not usado else Color("b5beb4"))
	draw_polyline(PackedVector2Array([rombo[0], rombo[1], rombo[2], rombo[3], rombo[0]]), TINTA, 3, true)
	draw_line(rombo[0], rombo[2], TINTA, 2, true)
	draw_line(rombo[1], rombo[3], TINTA, 2, true)
	# Cola con dos moños.
	draw_polyline(PackedVector2Array([Vector2(0, 44), Vector2(-8, 59), Vector2(9, 74), Vector2(-3, 94)]), TINTA, 2, true)
	for y in [60.0, 80.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(-13, y - 5), Vector2(13, y - 5), Vector2(0, y + 5)]), coral)
	# Flecha hacia arriba mientras esté disponible.
	if not usado:
		draw_polyline(PackedVector2Array([Vector2(-12, 13), Vector2(0, -6), Vector2(12, 13)]), CREMA, 5, true)
	var texto := "Usado" if usado else ("E · Impulso" if en_rango else "Papalote")
	var fuente := ThemeDB.fallback_font
	draw_string_outline(fuente, Vector2(-90, -70), texto, HORIZONTAL_ALIGNMENT_CENTER, 180, 18, 5, TINTA)
	draw_string(fuente, Vector2(-90, -70), texto, HORIZONTAL_ALIGNMENT_CENTER, 180, 18, CREMA)


func nombre() -> String:
	return "Corriente de niebla" if corriente else "Papalote"


func _dibujar_corriente() -> void:
	var color := Color("9aaca7") if usado else Color("83b9b0")
	for i in 3:
		var centro := Vector2((i - 1) * 32, 20 - sin(i * PI / 2) * 16)
		draw_circle(centro, 28, TINTA)
		draw_circle(centro, 24, color)
	for i in 3:
		var x := (i - 1) * 24.0
		draw_polyline(PackedVector2Array([Vector2(x - 5, 0), Vector2(x + 5, -20), Vector2(x - 5, -40)]), CREMA, 4, true)
	if en_rango:
		draw_arc(Vector2.ZERO, 74, 0, TAU, 40, CREMA, 3, true)
	var texto := "Usada" if usado else ("E · Subir" if en_rango else nombre())
	var fuente := ThemeDB.fallback_font
	draw_string_outline(fuente, Vector2(-110, -70), texto, HORIZONTAL_ALIGNMENT_CENTER, 220, 18, 5, TINTA)
	draw_string(fuente, Vector2(-110, -70), texto, HORIZONTAL_ALIGNMENT_CENTER, 220, 18, CREMA)
