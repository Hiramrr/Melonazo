extends SceneTree
## Penalizaciones e impulsos con física real. No escribe el progreso del jugador.

var comprobaciones := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos += 1
		push_error(mensaje)


func crear_melon(tamano: int, x: float):
	var melon = load("res://melon/melon.tscn").instantiate()
	root.add_child(melon)
	melon.configurar(tamano, [], 50.0, 2)
	melon.position = Vector2(x, -10000.0)
	melon.controlable = true
	melon.freeze = false
	melon.linear_velocity = Vector2(1000.0, 0.0)
	return melon


func _verificar() -> void:
	var config := root.get_node("Config")
	for tamano in 3:
		for tipo in ["pajaro", "charco", "coladera"]:
			var control = crear_melon(tamano, 0.0)
			var penalizado = crear_melon(tamano, 500.0)
			control.recibir_poder("pizza")
			penalizado.recibir_poder("pizza")
			for cuadro in 12:
				await physics_frame
			var obstaculo = load("res://mundo/obstaculos/%s.tscn" % tipo).instantiate()
			obstaculo.position = Vector2(-20000.0, 0.0)
			root.add_child(obstaculo)
			obstaculo.tocar(penalizado)
			comprobar(penalizado.t_pizza == 0.0, "%s tira de la pizza al tamaño %d" % [tipo, tamano])
			for cuadro in 60:
				await physics_frame
				if cuadro in [5, 59]:
					comprobar(penalizado.linear_velocity.x < control.linear_velocity.x * 0.9, "%s conserva su penalización tras %.2f s, tamaño %d" % [tipo, (cuadro + 1) / 120.0, tamano])
			comprobar(control.t_pizza > 0.0 and control.linear_velocity.x >= config.pizza_vel * 0.95, "La pizza sin golpes conserva su impulso")
			control.queue_free()
			penalizado.queue_free()
			obstaculo.queue_free()
			await process_frame
	var control = crear_melon(1, 0.0)
	var penalizado = crear_melon(1, 500.0)
	for melon in [control, penalizado]:
		melon.linear_velocity = Vector2(1700.0, 0.0)
		melon.iniciar_slam()
	penalizado.frenar(config.pajaro_freno)
	control.acertar_slam()
	penalizado.acertar_slam()
	for cuadro in 6:
		await physics_frame
	comprobar(penalizado.linear_velocity.x < control.linear_velocity.x - 100.0, "Acertar un slam conserva el frenón del mismo paso")
	for golpe in 24:
		control.t_slam = 0.0
		control.iniciar_slam()
		control.acertar_slam()
		await physics_frame
	comprobar(control.linear_velocity.x <= config.vel_crucero + 1.0, "Encadenar slams no acumula velocidad sin límite")
	control.t_slam = 0.0
	control.linear_velocity = Vector2(config.vel_crucero + 200.0, 0.0)
	control.iniciar_slam()
	control.acertar_slam()
	comprobar(control._v_fijar.x >= config.vel_crucero + 200.0, "Un slam conserva un impulso previo que ya supera el crucero")
	control.queue_free()
	penalizado.queue_free()
	await process_frame
	print("Penalizaciones: %d comprobaciones, %d fallos." % [comprobaciones, fallos])
	quit(1 if fallos else 0)
