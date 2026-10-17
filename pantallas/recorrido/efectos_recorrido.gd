class_name EfectosRecorrido
extends Node2D
## Capa de efectos del recorrido (nodo "Efectos" de recorrido.tscn, z 20).
##
## Dibuja en coordenadas del mundo, por encima del terreno:
##   - la flecha de puntería antes del lanzamiento (Recorrido la configura)
##   - los avisos flotantes ("¡Rampa!", "+5", "¡Se rompió!" de un rival...) que aparecen con un salto,
##     suben y se desvanecen; usan la letra gruesa del tema con contorno
## Las consultas directas a Theme no heredan. AvisoFlotante y ObjetivoAereo
## deben conservar todas sus propiedades explícitas en el recurso.

const DURACION_AVISO := 1.4            # segundos en pantalla
const SUBIDA_AVISO := 40.0             # px/s hacia arriba
const RADIO_FLECHA := 130.0
const POP_AVISO := 0.18                # segundos del salto inicial

# Flecha de puntería
var mostrar_flecha := false
var origen_flecha := Vector2.ZERO
var direccion_flecha := Vector2.RIGHT  # dirección de la cuesta, sin elegir ángulo
var objetivo_aereo: Papalote

var _avisos: Array = []                # [{texto, pos, t, color}]
var _cuenta := 0


## Muestra un texto flotante en pos (coordenadas del mundo).
func avisar(texto: String, pos: Vector2) -> void:
	_cuenta += 1
	_avisos.append({"texto": texto, "pos": pos, "t": DURACION_AVISO, "color": _cuenta % 4})


func _process(delta: float) -> void:
	for a in _avisos:
		a["t"] -= delta
		a["pos"] += Vector2(0, -SUBIDA_AVISO) * delta
	_avisos = _avisos.filter(func(a: Dictionary) -> bool: return a["t"] > 0.0)
	queue_redraw()


func _draw() -> void:
	var tema := ThemeDB.get_project_theme()
	var fuente := tema.get_font("font", "AvisoFlotante")
	var tamano := tema.get_font_size("font_size", "AvisoFlotante")
	var tinta := tema.get_color("font_outline_color", "AvisoFlotante")
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
		var col := tema.get_color("color_%d" % a["color"], "AvisoFlotante")
		var sombra := Vector2(0, tema.get_constant("shadow_offset_y", "AvisoFlotante"))
		draw_string_outline(fuente, pos + sombra, a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 500, tamano, tema.get_constant("shadow_outline_size", "AvisoFlotante"), Color(tinta, alfa))
		draw_string_outline(fuente, pos, a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 500, tamano, tema.get_constant("outline_size", "AvisoFlotante"), Color(tinta, alfa))
		draw_string(fuente, pos, a["texto"], HORIZONTAL_ALIGNMENT_CENTER, 500, tamano, Color(col, alfa))
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
	draw_set_transform_matrix(transformacion.affine_inverse())
	var centro := marcador + direccion * 14
	Sprites.girar(self, "efectos/indicador", Transform2D(direccion.angle(), centro))
	var distancia := int(objetivo_aereo.global_position.distance_to(origen_flecha) / Config.px_por_metro)
	var texto := "%s · %d m" % [objetivo_aereo.nombre(), distancia]
	var tema := ThemeDB.get_project_theme()
	var fuente := tema.get_font("font", "ObjetivoAereo")
	var tamano := tema.get_font_size("font_size", "ObjetivoAereo")
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var pos := Vector2(clampf(marcador.x - ancho / 2, 20, pantalla.x - ancho - 20), marcador.y + 45)
	draw_string_outline(fuente, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, tema.get_constant("outline_size", "ObjetivoAereo"), tema.get_color("font_outline_color", "ObjetivoAereo"))
	draw_string(fuente, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, tema.get_color("font_color", "ObjetivoAereo"))
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Flecha fija que señala la dirección de salida por la cuesta.
func _dibujar_flecha() -> void:
	var giro := direccion_flecha.angle()
	var centro := origen_flecha + Vector2(78, 0).rotated(giro)
	Sprites.girar(self, "efectos/flecha", Transform2D(giro, centro))
