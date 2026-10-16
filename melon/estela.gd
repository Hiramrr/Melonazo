extends Node2D
## Rastro decorativo que deja el melón al moverse (nodo "Estela" de melon.tscn).
##
## Es top_level: dibuja en coordenadas del mundo para que el rastro se quede
## donde pasó el melón y no gire con él. El estilo sale de Config.estelas[Juego.estela].

const VIDA := 0.65                     # segundos que dura cada marca
const CADA := 0.045                    # segundos entre marcas
const VELOCIDAD_MIN := 100.0           # px/s; más lento no deja rastro

var puntos: Array = []                 # [{pos, vida, giro}]
var reloj := 0.0
var objetivo: Melon


func _ready() -> void:
	objetivo = get_parent() as Melon
	top_level = true
	global_transform = Transform2D.IDENTITY


func _process(delta: float) -> void:
	for punto in puntos:
		punto["vida"] -= delta
	puntos = puntos.filter(func(p: Dictionary) -> bool: return p["vida"] > 0.0)
	reloj += delta
	if Juego.estela > 0 and objetivo.controlable and objetivo.linear_velocity.length() > VELOCIDAD_MIN and reloj > CADA:
		reloj = 0.0
		puntos.append({"pos": objetivo.global_position, "vida": VIDA, "giro": objetivo.rotation})
	queue_redraw()


func _draw() -> void:
	if Juego.estela <= 0:
		return
	var estilo: Dictionary = Config.estelas[Juego.estela]
	var color: Color = estilo["color"]
	for punto in puntos:
		var vida: float = punto["vida"] / VIDA
		var col := Color(color, vida * 0.7)
		var pos: Vector2 = punto["pos"]
		match estilo["id"]:
			"papel":
				draw_set_transform(pos, punto["giro"])
				draw_rect(Rect2(-4, -3, 8, 6), col)
				draw_set_transform(Vector2.ZERO)
			"cafe":
				draw_circle(pos, 4 * vida + 1, col)
				draw_line(pos + Vector2(-1, -2), pos + Vector2(1, 2), Color("dfbd91"), 1, true)
			"niebla":
				draw_circle(pos, 12 * vida + 1, col)
			_:
				draw_circle(pos, 5 * vida + 1, col)
