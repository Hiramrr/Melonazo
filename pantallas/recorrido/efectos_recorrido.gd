class_name EfectosRecorrido
extends Node2D
## Capa de efectos del recorrido (nodo "Efectos" de recorrido.tscn, z 20).
##
## Dibuja en coordenadas del mundo, por encima del terreno:
##   - la flecha de puntería antes del lanzamiento (Recorrido la configura)
##   - los avisos flotantes ("¡Rampa!", "+5"...) que suben y se desvanecen

const DURACION_AVISO := 1.4            # segundos en pantalla
const SUBIDA_AVISO := 40.0             # px/s hacia arriba
const RADIO_FLECHA := 130.0

# Flecha de puntería
var mostrar_flecha := false
var origen_flecha := Vector2.ZERO
var angulo := 0.0                      # grados sobre la horizontal
var angulo_fijado := false             # true en la fase de fuerza: la flecha se pone blanca

var _avisos: Array = []                # [{texto, pos, t}]


## Muestra un texto flotante en pos (coordenadas del mundo).
func avisar(texto: String, pos: Vector2) -> void:
	_avisos.append({"texto": texto, "pos": pos, "t": DURACION_AVISO})


func _process(delta: float) -> void:
	for a in _avisos:
		a["t"] -= delta
		a["pos"] += Vector2(0, -SUBIDA_AVISO) * delta
	_avisos = _avisos.filter(func(a: Dictionary) -> bool: return a["t"] > 0.0)
	queue_redraw()


func _draw() -> void:
	if mostrar_flecha:
		_dibujar_flecha()
	var fuente := ThemeDB.fallback_font
	for a in _avisos:
		var alfa := clampf(a["t"] / 0.5, 0.0, 1.0)
		var pos: Vector2 = a["pos"] - Vector2(160, 0)
		draw_string_outline(fuente, pos, a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 320, 22, 6, Color(0, 0, 0, alfa * 0.8))
		draw_string(fuente, pos, a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 320, 22, Color(1, 1, 0.85, alfa))


## Arco con el rango de ángulos posibles y la flecha en el ángulo actual.
func _dibujar_flecha() -> void:
	var o := origen_flecha
	var dir := Vector2.from_angle(-deg_to_rad(angulo))
	draw_arc(o, RADIO_FLECHA, -deg_to_rad(Config.angulo_max), -deg_to_rad(Config.angulo_min), 24,
		Color(1, 1, 1, 0.3), 2.0)
	var col := Color(1, 1, 1, 0.8) if angulo_fijado else Color(1, 0.9, 0.2)
	var punta := o + dir * RADIO_FLECHA
	draw_line(o, punta, col, 6.0)
	draw_colored_polygon(PackedVector2Array([punta + dir * 18.0,
		punta + dir.orthogonal() * 10.0, punta - dir.orthogonal() * 10.0]), col)
