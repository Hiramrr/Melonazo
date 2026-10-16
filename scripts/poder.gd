@tool
class_name PoderXalapeno
extends Area2D
## Un consumible con silueta propia. Se configura también desde el inspector.

signal recogido(tipo: String)
@export_enum("cafe", "chile", "niebla", "tamal") var tipo := "cafe":
	set(valor):
		tipo = valor
		queue_redraw()
		_actualizar_nombre.call_deferred()
var consumido := false


func _ready() -> void:
	_actualizar_nombre()
	queue_redraw()


func _actualizar_nombre() -> void:
	if not is_inside_tree():
		return
	$Nombre.text = ("Café" if tipo == "cafe" else tipo.capitalize()) if Engine.is_editor_hint() else Config.poderes[tipo]["nombre"]


func _recoger(cuerpo: Node2D) -> void:
	if consumido or not cuerpo is Melon or not cuerpo.controlable:
		return
	consumido = true
	recogido.emit(tipo)
	queue_free()


func _draw() -> void:
	var tinta := Color("294b43")
	var crema := Color("fff4d6")
	draw_circle(Vector2.ZERO, 25.0, crema)
	draw_arc(Vector2.ZERO, 25.0, 0, TAU, 40, tinta, 2.0, true)
	match tipo:
		"cafe":
			draw_rect(Rect2(-12, -8, 21, 20), Color("a56d43"))
			draw_arc(Vector2(11, 1), 7, -PI / 2, PI / 2, 16, Color("a56d43"), 4, true)
			for x in [-6.0, 2.0]:
				draw_polyline(PackedVector2Array([Vector2(x, -12), Vector2(x - 2, -16), Vector2(x + 1, -21)]), tinta, 1.5, true)
		"chile":
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -8), Vector2(3, -13), Vector2(13, -5), Vector2(11, 5), Vector2(0, 13), Vector2(-17, 15), Vector2(-4, 3)]), Color("cf5142"))
			draw_polyline(PackedVector2Array([Vector2(4, -10), Vector2(6, -18), Vector2(15, -18)]), Color("51804b"), 4, true)
		"niebla":
			for i in 3:
				var y := -10.0 + i * 10
				draw_line(Vector2(-16 + i * 3, y), Vector2(16 - i * 2, y), Color("649795"), 5, true)
		"tamal":
			draw_colored_polygon(PackedVector2Array([Vector2(-15, -10), Vector2(8, -17), Vector2(15, 10), Vector2(-8, 17)]), Color("72974b"))
			draw_line(Vector2(-12, -2), Vector2(11, -8), crema, 2, true)
			draw_line(Vector2(-9, 7), Vector2(14, 1), crema, 2, true)
			draw_line(Vector2(-4, -14), Vector2(5, 14), Color("496d36"), 2, true)
