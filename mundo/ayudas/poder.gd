@tool
class_name Poder
extends Area2D
## Consumible de la ruta (chile jalapeño, café de Coatepec o pizza con yogur), con imagen propia.
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
## Melon.recibir_poder(). Los rivales no tienen física: GeneradorTerreno.actualizar_melones()
## mide la distancia y llama consumir(); entonces el jugador ya no puede recogerlo.
## Nombres y efectos de cada tipo: Config.poderes. Como es @tool, `tipo` también se
## puede cambiar desde el inspector para ver el dibujo en el editor.

## Se emite una sola vez, cuando el melón (controlable) toca el poder.
signal recogido(tipo: String)

const RADIO_INSIGNIA := 25.0
# shortcut: imágenes provisionales de Fluent Emoji, sustituir al recibir el arte propio.
const TEXTURAS := {
	"chile": preload("res://recursos/poderes/chile.png"),
	"cafe": preload("res://recursos/poderes/cafe.png"),
	"pizza": preload("res://recursos/poderes/pizza.png"),
	"valentina": preload("res://recursos/poderes/valentina.png"),   # solo en taller y almanaque
}

## Qué poder es; elige el dibujo y el nombre. Clave de Config.poderes.
@export_enum("chile", "cafe", "pizza") var tipo := "chile":
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


## Un rival se lo lleva: igual que _recoger() pero sin emitir `recogido`. Crece y se
## desvanece antes de liberarse para que se note quién lo ganó.
func consumir() -> void:
	if consumido:
		return
	consumido = true
	var efecto := create_tween().set_parallel()
	efecto.tween_property(self, "scale", Vector2.ONE * 1.6, 0.25)
	efecto.tween_property(self, "modulate:a", 0.0, 0.25)
	efecto.chain().tween_callback(queue_free)


# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	Sprites.poner(self, "ayudas/insignia")
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.35, 1.35))
	dibujar_insignia(self, tipo)


static func dibujar_insignia(ci: CanvasItem, tipo: String) -> void:
	ci.draw_texture_rect(TEXTURAS[tipo], Rect2(-RADIO_INSIGNIA, -RADIO_INSIGNIA,
		RADIO_INSIGNIA * 2.0, RADIO_INSIGNIA * 2.0), false)
