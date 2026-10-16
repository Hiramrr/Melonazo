extends Node2D
## Dibuja en coordenadas del mundo para que la estela no rote con el melón.

var puntos: Array = []
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
	if Juego.estela > 0 and objetivo.controlable and objetivo.linear_velocity.length() > 100.0 and reloj > 0.045:
		reloj = 0.0
		puntos.append({"pos": objetivo.global_position, "vida": 0.65, "giro": objetivo.rotation})
	queue_redraw()


func _draw() -> void:
	if Juego.estela <= 0:
		return
	var color: Color = Config.estelas[Juego.estela]["color"]
	for punto in puntos:
		var vida: float = punto["vida"] / 0.65
		var col := Color(color, vida * 0.7)
		var pos: Vector2 = punto["pos"]
		if Juego.estela == 1:
			draw_set_transform(pos, punto["giro"])
			draw_rect(Rect2(-4, -3, 8, 6), col)
			draw_set_transform(Vector2.ZERO)
		elif Juego.estela == 4:
			draw_circle(pos, 4 * vida + 1, col)
			draw_line(pos + Vector2(-1, -2), pos + Vector2(1, 2), Color("dfbd91"), 1, true)
		else:
			draw_circle(pos, (12 if Juego.estela == 3 else 5) * vida + 1, col)
