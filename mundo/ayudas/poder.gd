@tool
class_name Poder
extends Area2D
## Consumible de la ruta (chile jalapeño, café de Coatepec, pizza con yogur o elote de feria), con imagen propia.
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
## mide la distancia y llama recibir_rival(), sin gastar el poder del jugador.
## Nombres y efectos de cada tipo: Config.poderes. Como es @tool, `tipo` también se
## puede cambiar desde el inspector para ver el dibujo en el editor.

## Se emite una sola vez, cuando el melón (controlable) toca el poder.
signal recogido(tipo: String)

const RADIO_INSIGNIA := 25.0
# Sprites proporcionados para el juego.
const TEXTURAS := {
	"chile": preload("res://recursos/poderes/chile.png"),
	"cafe": preload("res://recursos/poderes/cafe.png"),
	"pizza": preload("res://recursos/poderes/pizza.png"),
	"elote": preload("res://recursos/poderes/elote.png"),
	"valentina": preload("res://recursos/poderes/valentina.png"),   # solo en taller y almanaque
}

## Qué poder es; elige el dibujo y el nombre. Clave de Config.poderes.
@export_enum("chile", "cafe", "pizza", "elote") var tipo := "chile":
	set(valor):
		tipo = valor
		queue_redraw()
		_actualizar_nombre.call_deferred()
## true en cuanto se cobra; evita cobrarlo dos veces antes de liberarse.
var consumido := false
var _rivales: Array[int] = []
var tiempo := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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


## Los rivales reciben el poder una sola vez sin retirarlo del mapa.
func usado_por_rival(rival: Node) -> bool:
	return rival.get_instance_id() in _rivales

func recibir_rival(rival: Node) -> bool:
	if consumido or usado_por_rival(rival):
		return false
	_rivales.append(rival.get_instance_id())
	rival.recibir_poder(tipo)
	return true


# --- Dibujo ------------------------------------------------------------------

func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


func _draw() -> void:
	var flotacion := Vector2(0, sin(tiempo * 2.8 + position.x * 0.01) * 7.0)
	draw_set_transform(flotacion)
	var colores := {"chile": Color("ff765c"), "cafe": Color("ffdba0"), "pizza": Color("ff8ae0"), "elote": Color("ffe768")}
	var color: Color = colores.get(tipo, Color.WHITE)
	for capa in range(8, 0, -1):
		color.a = 0.025 + (8 - capa) * 0.009
		draw_circle(Vector2.ZERO, 25.0 + capa * 4.0 + sin(tiempo * 3.0) * 2.0, color)
	draw_set_transform(flotacion, 0.0, Vector2(1.6, 1.6))
	dibujar_insignia(self, tipo)


static func dibujar_insignia(ci: CanvasItem, tipo: String) -> void:
	ci.draw_texture_rect(TEXTURAS[tipo], Rect2(-RADIO_INSIGNIA, -RADIO_INSIGNIA,
		RADIO_INSIGNIA * 2.0, RADIO_INSIGNIA * 2.0), false)
