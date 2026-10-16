extends SceneTree
## Comprueba que las nubes se mueven en vertical con el mismo factor de
## paralaje que en horizontal, y que siguen en pantalla al subir alto.
## Ejecutar con Godot --headless --path . --script res://pruebas/paralaje.gd

var comprobaciones := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _posicion(capa: Node2D, camara: Vector2) -> Vector2:
	capa.actualizar(Vector2(1280, 720), camara, 0.0)
	return capa.posicion_elemento(10)


func _verificar() -> void:
	var paisaje = load("res://mundo/paisaje/paisaje.tscn").instantiate()
	root.add_child(paisaje)
	var altas: Node2D = paisaje.get_node("NubesAltas")
	var cercanas: Node2D = paisaje.get_node("NubesCercanas")
	comprobar(altas.paralaje > 0.0 and cercanas.paralaje > altas.paralaje, "Las nubes cercanas tienen más paralaje que las altas")
	for capa in [altas, cercanas]:
		var base := _posicion(capa, Vector2(0, 60))
		var arriba := _posicion(capa, Vector2(0, 60 - 3000))
		var abajo := _posicion(capa, Vector2(0, 60 + 1000))
		var lado := _posicion(capa, Vector2(1000, 60))
		comprobar(is_equal_approx(arriba.y - base.y, capa.paralaje * 3000.0), "Subir la cámara baja la nube con su factor de paralaje: " + capa.name)
		comprobar(is_equal_approx(abajo.y - base.y, -capa.paralaje * 1000.0), "Bajar la cámara sube la nube en la misma proporción: " + capa.name)
		comprobar(is_equal_approx(base.x - lado.x, capa.paralaje * 1000.0), "El paralaje horizontal y el vertical usan el mismo factor: " + capa.name)
		comprobar(arriba.y >= -capa.mitad.y and arriba.y <= capa.mitad.y, "La nube sigue en pantalla tras subir 3000 px: " + capa.name)
	var base_altas := _posicion(altas, Vector2(0, 60))
	var base_cercanas := _posicion(cercanas, Vector2(0, 60))
	var subida_altas: float = _posicion(altas, Vector2(0, 60 - 3000)).y - base_altas.y
	var subida_cercanas: float = _posicion(cercanas, Vector2(0, 60 - 3000)).y - base_cercanas.y
	comprobar(subida_cercanas > subida_altas, "Al subir, las nubes cercanas se desplazan más que las altas")
	print("Paralaje: %d comprobaciones, %d fallos." % [comprobaciones, fallos])
	quit(1 if fallos else 0)
