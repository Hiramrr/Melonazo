@tool
class_name Poder
extends Area2D
## Consumible de la ruta (café, chile, niebla o tamal), con silueta propia.
##
## Escena: mundo/ayudas/poder.tscn (Area2D en la capa 4; detecta la capa 2, la del melón)
##   AreaDeRecogida   CollisionShape2D circular, un poco más grande que el dibujo
##   Nombre           Label con el nombre del poder, encima del dibujo
## En la escena, body_entered está conectada a _recoger().
##
## Quién lo usa: GeneradorTerreno._poner_poderes() (mundo/terreno/generador_terreno.gd)
## instancia uno cada tantos metros en el contenedor Coleccionables del tramo, le asigna
## `tipo` y reenvía `recogido` como su señal poder_recogido, que atiende
## Recorrido._al_recoger_poder(). Este nodo solo avisa y desaparece; el efecto lo aplica
## Melon.recibir_poder().
## Nombres y efectos de cada tipo: Config.poderes. Como es @tool, `tipo` también se
## puede cambiar desde el inspector para ver el dibujo en el editor.

## Se emite una sola vez, cuando el melón (controlable) toca el poder.
signal recogido(tipo: String)

const TINTA := Color("294b43")
const CREMA := Color("fff4d6")
const RADIO_INSIGNIA := 25.0          # círculo crema de fondo del dibujo

## Qué poder es; elige el dibujo y el nombre. Clave de Config.poderes.
@export_enum("cafe", "chile", "niebla", "tamal") var tipo := "cafe":
	set(valor):
		tipo = valor
		queue_redraw()
		_actualizar_nombre.call_deferred()
## true en cuanto se cobra; evita cobrarlo dos veces antes de liberarse.
var consumido := false


func _ready() -> void:
	_actualizar_nombre()
	queue_redraw()


func _actualizar_nombre() -> void:
	if not is_inside_tree():
		return
	# En el editor no corre el autoload Config; se usa un nombre provisional.
	$Nombre.text = ("Café" if tipo == "cafe" else tipo.capitalize()) if Engine.is_editor_hint() else Config.poderes[tipo]["nombre"]


# --- Recogida ----------------------------------------------------------------

## Conectada a body_entered. Solo cuenta el melón mientras el jugador lo controla.
func _recoger(cuerpo: Node2D) -> void:
	if consumido or not cuerpo is Melon or not cuerpo.controlable:
		return
	consumido = true
	recogido.emit(tipo)
	queue_free()


# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIO_INSIGNIA, CREMA)
	draw_arc(Vector2.ZERO, RADIO_INSIGNIA, 0, TAU, 40, TINTA, 2.0, true)
	match tipo:
		"cafe":
			# Taza con asa y dos hilos de vapor.
			draw_rect(Rect2(-12, -8, 21, 20), Color("a56d43"))
			draw_arc(Vector2(11, 1), 7, -PI / 2, PI / 2, 16, Color("a56d43"), 4, true)
			for x in [-6.0, 2.0]:
				draw_polyline(PackedVector2Array([Vector2(x, -12), Vector2(x - 2, -16), Vector2(x + 1, -21)]), TINTA, 1.5, true)
		"chile":
			# Chile rojo con rabito verde.
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -8), Vector2(3, -13), Vector2(13, -5), Vector2(11, 5), Vector2(0, 13), Vector2(-17, 15), Vector2(-4, 3)]), Color("cf5142"))
			draw_polyline(PackedVector2Array([Vector2(4, -10), Vector2(6, -18), Vector2(15, -18)]), Color("51804b"), 4, true)
		"niebla":
			# Tres franjas de neblina.
			for i in 3:
				var y := -10.0 + i * 10
				draw_line(Vector2(-16 + i * 3, y), Vector2(16 - i * 2, y), Color("649795"), 5, true)
		"tamal":
			# Hoja de maíz amarrada.
			draw_colored_polygon(PackedVector2Array([Vector2(-15, -10), Vector2(8, -17), Vector2(15, 10), Vector2(-8, 17)]), Color("72974b"))
			draw_line(Vector2(-12, -2), Vector2(11, -8), CREMA, 2, true)
			draw_line(Vector2(-9, 7), Vector2(14, 1), CREMA, 2, true)
			draw_line(Vector2(-4, -14), Vector2(5, 14), Color("496d36"), 2, true)
