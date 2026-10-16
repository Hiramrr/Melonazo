@tool
class_name Poder
extends Area2D
## Consumible de la ruta (café, chile, niebla o tamal), con imagen propia.
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

const RADIO_INSIGNIA := 25.0
# shortcut: imágenes provisionales de Fluent Emoji, sustituir al recibir el arte propio.
const TEXTURAS := {
	"cafe": preload("res://recursos/poderes/cafe.png"),
	"chile": preload("res://recursos/poderes/chile.png"),
	"niebla": preload("res://recursos/poderes/niebla.png"),
	"tamal": preload("res://recursos/poderes/tamal.png"),
}

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
	draw_circle(Vector2.ZERO, 40.0, Color("fff4d6"))
	draw_arc(Vector2.ZERO, 40.0, 0, TAU, 48, Color("294b43"), 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.35, 1.35))
	dibujar_insignia(self, tipo)


## Dibuja la insignia del poder tipo centrada en el origen de ci (radio RADIO_INSIGNIA).
## También la usa el pasaporte del taller para mostrar cada poder.
static func dibujar_insignia(ci: CanvasItem, tipo: String) -> void:
	ci.draw_texture_rect(TEXTURAS[tipo], Rect2(-RADIO_INSIGNIA, -RADIO_INSIGNIA,
		RADIO_INSIGNIA * 2.0, RADIO_INSIGNIA * 2.0), false)
