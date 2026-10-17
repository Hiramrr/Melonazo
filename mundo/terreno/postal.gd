@tool
class_name Postal
extends Node2D
## Imagen junto al letrero de un punto de interés, detrás del suelo y sin colisión.
## ArteXalapa.lugares_mapa asigna una foto provisional o un sprite a cada id.

const ARTE := preload("res://recursos/arte_xalapa.tres")
const TAMANO_MAX := Vector2(520, 280)

@export var tipo := "xallitic":
	set(valor):
		tipo = valor
		queue_redraw()


## pos en coordenadas del tramo, a ras de suelo; tipo es el id de Config.postales.
func configurar(datos: Dictionary) -> void:
	position = datos["pos"]
	tipo = str(datos["tipo"])


func _draw() -> void:
	var textura: Texture2D = ARTE.lugares_mapa.get(tipo)
	if textura == null:
		return
	var tamano := textura.get_size()
	tamano *= minf(TAMANO_MAX.x / tamano.x, TAMANO_MAX.y / tamano.y)
	draw_texture_rect(textura, Rect2(Vector2(480.0 - tamano.x / 2.0, -tamano.y), tamano), false)

static func dibujar_picado(ci: CanvasItem, a: Vector2, b: Vector2, caida: float) -> void:
	Sprites.dibujar(ci, "terreno/picado", Rect2(a - Vector2(0, 2), Vector2(b.x - a.x, caida + 30)))
