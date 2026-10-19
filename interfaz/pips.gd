@tool
class_name Pips
extends Control
## Fila de íconos que se llenan: rayos de impulso o niveles de una mejora.
## Los vacíos se dibujan apagados.
##
## Si total pasa de max_visibles, se dibujan max_visibles y el resto se resume
## con "+N" al final.

@export var icono: Texture2D:
	set(valor):
		icono = valor
		queue_redraw()
@export var total := 3:
	set(valor):
		if valor != total:
			total = maxi(0, valor)
			_ajustar_tamano()
@export var llenos := 3:
	set(valor):
		if valor != llenos:
			llenos = valor
			queue_redraw()
@export var lado := 22.0:
	set(valor):
		lado = valor
		_ajustar_tamano()
@export var separacion := 3.0
@export var max_visibles := 10


func _init() -> void:
	# La escena puede asignar la variación antes que el script; no la pisamos.
	if theme_type_variation == &"":
		theme_type_variation = &"Pips"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajustar_tamano()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_ajustar_tamano()


func _ajustar_tamano() -> void:
	var n := mini(total, max_visibles)
	var extra := 34.0 if total > max_visibles else 0.0
	if extra > 0.0:
		var texto := "+%d" % (total - max_visibles)
		extra = maxf(extra, get_theme_font("font").get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x)
	custom_minimum_size = Vector2(n * lado + maxf(0, n - 1) * separacion + extra, lado)
	queue_redraw()


func _draw() -> void:
	if icono == null:
		return
	var n := mini(total, max_visibles)
	var apagado := get_theme_color("apagado")
	for i in n:
		var r := Rect2(i * (lado + separacion), (size.y - lado) * 0.5, lado, lado)
		var lleno := i < llenos
		draw_texture_rect(icono, r, false, Color.WHITE if lleno else apagado)
	if total > max_visibles and llenos > max_visibles:
		var x := n * (lado + separacion)
		var texto := "+%d" % (llenos - max_visibles)
		var base := Vector2(x, size.y * 0.5 + lado * 0.3)
		var fuente := get_theme_font("font")
		var tamano := get_theme_font_size("font_size")
		draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, get_theme_constant("outline_size"), get_theme_color("font_outline_color"))
		draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, get_theme_color("font_color"))
