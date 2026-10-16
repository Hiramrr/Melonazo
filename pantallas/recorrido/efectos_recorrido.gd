class_name EfectosRecorrido
extends Node2D
## Capa de efectos del recorrido (nodo "Efectos" de recorrido.tscn, z 20).
##
## Dibuja en coordenadas del mundo, por encima del terreno:
##   - la flecha de puntería antes del lanzamiento (Recorrido la configura)
##   - los avisos flotantes ("¡Rampa!", "+5"...) que aparecen con un salto,
##     suben y se desvanecen; usan la letra gruesa del tema con contorno

const DURACION_AVISO := 1.4            # segundos en pantalla
const SUBIDA_AVISO := 40.0             # px/s hacia arriba
const RADIO_FLECHA := 130.0
const TAM_AVISO := 30
const POP_AVISO := 0.18                # segundos del salto inicial
const TEMA: Theme = preload("res://interfaz/tema_xalapa.tres")
const TINTA := Color("203d38")
const CREMA := Color("fff9ec")
const COLORES_AVISO: Array[Color] = [Color("fff9ec"), Color("ffc83d"), Color("fff9ec"), Color("8fe08a")]

# Flecha de puntería
var mostrar_flecha := false
var origen_flecha := Vector2.ZERO
var direccion_flecha := Vector2.RIGHT  # dirección de la cuesta, sin elegir ángulo
var objetivo_aereo: Papalote

var _avisos: Array = []                # [{texto, pos, t, color}]
var _cuenta := 0
var _fuente: Font = TEMA.get_font("font", "Titulo")


## Muestra un texto flotante en pos (coordenadas del mundo).
func avisar(texto: String, pos: Vector2) -> void:
	_cuenta += 1
	_avisos.append({"texto": texto, "pos": pos, "t": DURACION_AVISO, "color": COLORES_AVISO[_cuenta % COLORES_AVISO.size()]})


func _process(delta: float) -> void:
	for a in _avisos:
		a["t"] -= delta
		a["pos"] += Vector2(0, -SUBIDA_AVISO) * delta
	_avisos = _avisos.filter(func(a: Dictionary) -> bool: return a["t"] > 0.0)
	queue_redraw()


func _draw() -> void:
	if mostrar_flecha:
		_dibujar_flecha()
	for a in _avisos:
		var alfa := clampf(a["t"] / 0.5, 0.0, 1.0)
		var vivo: float = DURACION_AVISO - a["t"]
		# Salto: de 0.5 a 1.1 y de vuelta a 1 durante POP_AVISO.
		var u := clampf(vivo / POP_AVISO, 0.0, 1.0)
		var escala := lerpf(0.5, 1.0, u) + 0.35 * sin(u * PI)
		draw_set_transform(a["pos"], 0.0, Vector2.ONE * escala)
		var pos := Vector2(-250, 0)
		var col: Color = a["color"]
		draw_string_outline(_fuente, pos + Vector2(0, 4), a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 500, TAM_AVISO, 12, Color(TINTA, alfa))
		draw_string_outline(_fuente, pos, a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 500, TAM_AVISO, 10, Color(TINTA, alfa))
		draw_string(_fuente, pos, a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 500, TAM_AVISO, Color(col, alfa))
	draw_set_transform(Vector2.ZERO)
	_dibujar_objetivo_aereo()


func _dibujar_objetivo_aereo() -> void:
	if not is_instance_valid(objetivo_aereo) or objetivo_aereo.usado:
		return
	var pantalla := get_viewport_rect().size
	var transformacion := get_global_transform_with_canvas()
	var destino := transformacion * to_local(objetivo_aereo.global_position)
	var limites := Rect2(Vector2(70, 210), pantalla - Vector2(140, 380))
	if limites.has_point(destino):
		return
	var marcador := destino.clamp(limites.position, limites.end)
	var direccion := (destino - marcador).normalized()
	var punta := marcador + direccion * 22.0
	var base := marcador - direccion * 5.0
	draw_set_transform_matrix(transformacion.affine_inverse())
	draw_line(base, punta, TINTA, 9.0, true)
	draw_line(base, punta, CREMA, 4.0, true)
	var cabeza := PackedVector2Array([punta + direccion * 7, punta - direccion * 5 + direccion.orthogonal() * 8, punta - direccion * 5 - direccion.orthogonal() * 8])
	draw_colored_polygon(cabeza, CREMA)
	var distancia := int(objetivo_aereo.global_position.distance_to(origen_flecha) / Config.px_por_metro)
	var texto := "%s · %d m" % [objetivo_aereo.nombre(), distancia]
	var ancho := _fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var pos := Vector2(clampf(marcador.x - ancho / 2, 20, pantalla.x - ancho - 20), marcador.y + 45)
	draw_string_outline(_fuente, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, TINTA)
	draw_string(_fuente, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, CREMA)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Flecha fija que señala la dirección de salida por la cuesta.
func _dibujar_flecha() -> void:
	var o := origen_flecha
	var dir := direccion_flecha
	var col := Color("ffc83d")
	var punta := o + dir * RADIO_FLECHA
	var cabeza := PackedVector2Array([punta + dir * 26.0, punta + dir.orthogonal() * 16.0, punta - dir.orthogonal() * 16.0])
	draw_line(o, punta, TINTA, 14.0, true)
	draw_colored_polygon(cabeza, TINTA)
	draw_polyline(cabeza + PackedVector2Array([cabeza[0]]), TINTA, 8.0, true)
	draw_line(o, punta, col, 7.0, true)
	draw_colored_polygon(cabeza, col)
