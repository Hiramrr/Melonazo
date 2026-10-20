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
## GeneradorTerreno.actualizar_melones() llama impulsar_rival() cuando un rival pasa
## cerca. Los rivales no gastan el papalote ni provocan recargas.
## Ajustes: Config.papalote_rango, papalote_avance, papalote_elevacion.

const TINTA := Color("294b43")
const CREMA := Color("fff4d6")

@export var corriente := false

## Ya lo usó el jugador en esta carrera; se dibuja en gris.
var usado := false
var _rivales: Array[int] = []
## El melón está lo bastante cerca para usarlo (muestra el aro y "E · Impulso").
var en_rango := false:
	set(valor):
		if en_rango != valor:
			en_rango = valor
			queue_redraw()


## Impulsa al melón si está a alcance y el papalote no se ha usado. Devuelve true si
## hubo impulso. Asegura una velocidad mínima hacia adelante y hacia arriba (no suma
## si el melón ya va más rápido) y activa su escudo. Los saltos ilimitados llegan con el café.
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


## Cada rival recibe el impulso una vez, sin gastar la ayuda del jugador.
func impulsar_rival(rival: MelonRodante) -> bool:
	if usado or usado_por_rival(rival) or global_position.distance_to(rival.global_position) > Config.papalote_rango:
		return false
	_rivales.append(rival.get_instance_id())
	rival.impulsar_papalote(Vector2(Config.papalote_avance, -Config.papalote_elevacion))
	return true

func usado_por_rival(rival: Node) -> bool:
	return rival.get_instance_id() in _rivales


# --- Dibujo ------------------------------------------------------------------

const ICONO := preload("res://recursos/objetos/papalote.png")
const VIENTO := preload("res://recursos/objetos/corriente.png")

var _regiones: Dictionary = {}

func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex: Texture2D = VIENTO if corriente else ICONO
	var tam := Vector2(180, 110) if corriente else Vector2(125, 170)
	var tinte := Color(0.45, 0.45, 0.45, 0.6) if usado else Color.WHITE
	if not _regiones.has(corriente):
		_regiones[corriente] = Rect2(tex.get_image().get_used_rect())
	draw_texture_rect_region(tex, Rect2(-tam * 0.5, tam), _regiones[corriente], tinte)
	if en_rango and not usado:
		Sprites.aro(self, Vector2.ZERO, 95.0, Color("ffe488"))
		draw_string(ThemeDB.fallback_font, Vector2(-55, -105), "E · Impulso", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff4d6"))


func nombre() -> String:
	return "Corriente de niebla" if corriente else "Papalote"
