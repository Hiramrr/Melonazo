extends SceneTree
## Elección de Valentina, pausa y consumo. Usa un guardado separado.
## Sin --headless también guarda capturas a 1280 × 720 y 960 × 540.

var juego: Node
var config: Node
var comprobaciones := 0


func _initialize() -> void:
	AudioServer.set_bus_mute(0, true)
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		push_error(mensaje)
		quit(1)
		assert(condicion, mensaje)
	comprobaciones += 1


func _abrir(salsas: int):
	juego.valentinas = salsas
	juego.guardar()
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_physics_process(false)
	r.fase = r.Fase.RECORRIDO
	r.melon.position = Vector2(1200, -200)
	r.melon.freeze = false
	r.melon.controlable = true
	# Avanzamos el contador a mano salvo en la prueba del vencimiento automático.
	r.hud.set_process(false)
	return r


func _verificar() -> void:
	juego = root.get_node("Juego")
	config = root.get_node("Config")
	juego.archivo_guardado = "user://prueba_valentina_%d.json" % OS.get_process_id()
	juego.niveles = {"fuerza": 0, "resistencia": 0, "rebotes": 0}
	juego.accesorios = []
	juego.intentos = 0
	var r = await _abrir(2)
	var guardado := FileAccess.get_file_as_string(juego.archivo_guardado)
	r.melon.danar(r.melon.resistencia_max)
	comprobar(paused and r.fase == r.Fase.REVIVIR and r.hud.revivir.visible, "Romper el melón ofrece revivir y pausa la carrera")
	comprobar(juego.valentinas == 2 and r.valentinas_usadas == 0 and FileAccess.get_file_as_string(juego.archivo_guardado) == guardado, "Ofrecer la salsa no la consume ni modifica el guardado")
	comprobar(r.hud.get_node("%CuentaValentina").text == "El intento termina en 5 s", "La cuenta empieza en cinco segundos")
	var posicion: Vector2 = r.melon.position
	var rival: Vector2 = r.terreno.melones[0].position
	Input.action_press("rebote")
	for i in 6:
		await process_frame
	Input.action_release("rebote")
	comprobar(r.melon.position == posicion and r.terreno.melones[0].position == rival and not r.melon.controlable, "El jugador y los rivales quedan en pausa durante la elección")
	comprobar(root.get_node("Musica").stream_paused, "La elección pausa también la música")
	r.hud._process(1.1)
	r._on_melon_roto()
	comprobar(r.hud.get_node("%CuentaValentina").text == "El intento termina en 4 s", "Repetir la señal no reinicia la cuenta")
	r.hud._alternar_pausa()
	comprobar(paused and not r.hud.pausa.visible, "El menú de pausa no interrumpe la elección")
	var tecla_pausa := InputEventKey.new()
	tecla_pausa.keycode = KEY_P
	tecla_pausa.physical_keycode = KEY_P
	tecla_pausa.pressed = true
	root.push_input(tecla_pausa, true)
	await process_frame
	comprobar(paused and r.hud.revivir.visible and not r.hud.pausa.visible, "P conserva la elección sin rechazarla ni abrir la pausa")
	tecla_pausa.pressed = false
	root.push_input(tecla_pausa, true)
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("user://revision_grafica")
		for resolucion in [Vector2i(1280, 720), Vector2i(960, 540)]:
			root.size = resolucion
			for i in 8:
				await process_frame
			var limites := root.get_visible_rect()
			for id in ["%PanelValentina", "%CuentaValentina", "%UsarValentina", "%TerminarIntento"]:
				comprobar(limites.encloses(r.hud.get_node(id).get_global_rect()), "Elección dentro de pantalla: " + id)
			RenderingServer.force_draw()
			await process_frame
			var ruta := "user://revision_grafica/%dx%d-valentina.png" % [resolucion.x, resolucion.y]
			comprobar(root.get_texture().get_image().save_png(ruta) == OK, "Se guarda la captura de Valentina")
	r.hud.get_node("%UsarValentina").pressed.emit()
	comprobar(not paused and r.fase == r.Fase.RECORRIDO and not r.hud.revivir.visible, "Aceptar cierra el aviso y reanuda la carrera")
	comprobar(juego.valentinas == 1 and r.valentinas_usadas == 1 and r.hud.ficha_valentinas.texto == "1", "Aceptar descuenta exactamente una salsa y actualiza el HUD")
	comprobar(not r.melon.roto and r.melon.controlable and r.melon.resistencia == r.melon.resistencia_max and r.melon.rebotes >= juego.rebotes_max() and r.melon.t_invulnerable > 0.0, "Revivir devuelve resistencia, saltos, protección y controles")
	r.hud.get_node("%UsarValentina").pressed.emit()
	comprobar(juego.valentinas == 1 and r.valentinas_usadas == 1, "Un segundo clic no consume otra salsa")
	juego.cargar()
	comprobar(juego.valentinas == 1, "El consumo confirmado queda guardado")
	for i in 6:
		await physics_frame
	await process_frame
	comprobar(r.melon.position != posicion and r.melon.linear_velocity.x > 0.0, "El melón vuelve a moverse con impulso tras aceptar")

	r = await _abrir(1)
	r.melon.en_suelo = true
	r.mejor_x = r.melon.position.x
	r._revisar_avance(r.mejor_x, config.tiempo_sin_avance + 0.1)
	comprobar(paused and r.fase == r.Fase.REVIVIR and not r.melon.roto, "Detenerse también ofrece revivir")
	r.hud.get_node("%TerminarIntento").pressed.emit()
	comprobar(not paused and r.fase == r.Fase.FIN and r.texto_fin == "¡Se detuvo!" and juego.valentinas == 1, "Rechazar termina sin gastar la salsa y conserva la causa")
	r._t_fin = 0.0
	r._process(0.01)
	await process_frame
	await process_frame
	comprobar(current_scene.name == "Resultados" and juego.ultimo["valentinas"] == 0 and juego.intentos == 1, "Rechazar muestra resultados y registra una sola vez")

	r = await _abrir(1)
	r.melon.danar(r.melon.resistencia_max)
	r.hud.set_process(true)
	await create_timer(config.valentina_espera + 0.1).timeout
	comprobar(not paused and r.fase == r.Fase.FIN and not r.hud.revivir.visible and juego.valentinas == 1, "La cuenta avanza con el árbol pausado y termina sin consumir la salsa")
	comprobar(r.texto_fin == "¡Se rompió el melón!" and r.melon.roto, "El vencimiento conserva el melón roto y la causa del fin")

	r = await _abrir(1)
	r.melon.danar(r.melon.resistencia_max)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await process_frame
	comprobar(not paused and r.fase == r.Fase.FIN and juego.valentinas == 1, "Esc rechaza la salsa sin abrir la pausa")

	r = await _abrir(0)
	r.melon.danar(r.melon.resistencia_max)
	comprobar(not paused and r.fase == r.Fase.FIN and not r.hud.revivir.visible, "Sin salsas el intento termina sin mostrar la elección")
	DirAccess.remove_absolute(juego.archivo_guardado)
	root.get_node("Musica").stop()
	await create_timer(0.05).timeout
	print("OK: %d comprobaciones de Valentina, elección, pausa, consumo y vencimiento." % comprobaciones)
	quit()
