extends SceneTree
## Comprueba el avance de dificultad y su efecto real en la ruta extendida.

func _initialize() -> void:
	call_deferred("_verificar")

func _verificar() -> void:
	var config := root.get_node("Config")
	var terreno = load("res://mundo/terreno/generador_terreno.gd").new()
	root.add_child(terreno)
	assert(config.meta_m == 5200.0, "El viaje tiene el doble de longitud")
	assert(config.dificultad_metros.y == config.meta_m, "El reto sigue aumentando hasta la meta")
	assert(terreno.dificultad(0.0) == 0.0 and terreno.dificultad(config.meta_m * config.px_por_metro) == 1.0)
	var anterior := -1.0
	for m in range(0, int(config.meta_m) + 1, 100):
		var dif: float = terreno.dificultad(m * config.px_por_metro)
		assert(dif >= anterior, "La dificultad no retrocede al cambiar de tramo o de etapa")
		anterior = dif
	assert(terreno.dificultad(800.0 * config.px_por_metro) < 0.1, "A los 800 m todavía estamos al inicio, no en dificultad máxima")
	var separaciones: Array[float] = []
	var golpes: Array[int] = []
	var listos: Array[int] = []
	for fraccion in [0.0, 0.5, 1.0]:
		var x: float = config.meta_m * config.px_por_metro * fraccion
		var dif: float = terreno.dificultad(x)
		terreno.rng.seed = 42
		terreno.rng_melones.seed = 42
		var distancia := 0.0
		var peligros := 0
		var rivales_listos := 0
		for i in 3000:
			distancia += terreno._separacion_obstaculos(x)
			if terreno._elegir_obstaculo(dif) in ["poste", "banqueta"]:
				peligros += 1
			if terreno._elegir_tipo_melon(dif) == "listo":
				rivales_listos += 1
		separaciones.append(distancia / 3000.0)
		golpes.append(peligros)
		listos.append(rivales_listos)
	assert(separaciones[0] > separaciones[1] and separaciones[1] > separaciones[2], "Los obstáculos se acercan durante todo el viaje")
	assert(golpes[0] < golpes[1] and golpes[1] < golpes[2], "Los obstáculos dañinos aumentan durante todo el viaje")
	assert(listos[0] < listos[1] and listos[1] < listos[2], "Hay más rivales que esquivan conforme avanza el viaje")
	terreno.free()
	print("OK: ruta de 5200 m, dificultad creciente, separación media %.0f/%.0f/%.0f px, obstáculos dañinos %s y rivales listos %s en 3000 sorteos por etapa." % [separaciones[0], separaciones[1], separaciones[2], golpes, listos])
	quit()
