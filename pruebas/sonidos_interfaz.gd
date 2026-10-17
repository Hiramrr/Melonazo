extends SceneTree

var fallos := 0

func _initialize() -> void:
	call_deferred("_verificar")

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func _verificar() -> void:
	var animacion = root.get_node("Animacion")
	var pantalla := Control.new()
	root.add_child(pantalla)
	var boton := Button.new()
	boton.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.add_child(boton)
	boton.mouse_entered.emit()
	comprobar(animacion._audio_hover.playing, "Hover conectado automáticamente")
	boton.button_down.emit()
	comprobar(animacion._audio_click.playing and not animacion._audio_hover.playing, "Clic tiene prioridad sobre hover")
	pantalla.queue_free()
	await process_frame
	comprobar(animacion._audio_click.playing, "El clic sobrevive al botón y su pantalla")
	await create_timer(0.2).timeout
	boton = Button.new()
	boton.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boton)
	boton.disabled = true
	animacion._audio_hover.stop()
	animacion._audio_click.stop()
	boton.mouse_entered.emit()
	boton.button_down.emit()
	comprobar(not animacion._audio_hover.playing and not animacion._audio_click.playing, "Botón deshabilitado silencioso")
	boton.disabled = false
	boton.hide()
	boton.mouse_entered.emit()
	comprobar(not animacion._audio_hover.playing, "Botón oculto silencioso")
	boton.show()
	boton.process_mode = Node.PROCESS_MODE_ALWAYS
	paused = true
	boton.button_down.emit()
	await process_frame
	comprobar(animacion._audio_click.playing and not animacion._audio_click.stream_paused, "Botones del menú de pausa tienen audio")
	paused = false
	boton.queue_free()
	await create_timer(0.2).timeout
	comprobar(get_nodes_in_group("audio_interfaz").size() == 2, "Los sonidos no acumulan reproductores")
	change_scene_to_file("res://pantallas/menu/menu.tscn")
	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	var menu = current_scene
	if menu._bajada:
		menu._bajada.kill()
	menu._mostrar_menu()
	animacion._ultimo_click = -1000
	animacion._ultimo_hover = -1000
	menu.btn_jugar.mouse_entered.emit()
	comprobar(animacion._audio_hover.playing, "El botón real del menú principal tiene hover")
	menu.btn_jugar.pressed.emit()
	comprobar(animacion._ultimo_click >= 0, "Jugar dispara sonido antes de cargar la siguiente escena")
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	var barra: TabBar = current_scene.pestanas.get_tab_bar()
	comprobar(barra.tab_count == 5, "El taller tiene sus cinco apartados")
	for i in barra.tab_count:
		barra.tab_hovered.emit(i)
		comprobar(animacion._audio_hover.playing, "Hover en apartado %d" % i)
		barra.tab_clicked.emit(i)
		comprobar(animacion._audio_click.playing, "Clic en apartado %d" % i)
		var reproduccion = animacion._audio_click.get_stream_playback()
		barra.tab_selected.emit(i)
		comprobar(animacion._audio_click.get_stream_playback() == reproduccion, "Selección y clic no duplican el sonido")
		reproduccion = null
		await create_timer(0.2).timeout
	barra.set_tab_disabled(1, true)
	barra.tab_hovered.emit(1)
	barra.tab_clicked.emit(1)
	comprobar(not animacion._audio_hover.playing and not animacion._audio_click.playing, "Pestaña deshabilitada silenciosa")
	current_scene.queue_free()
	await process_frame
	await process_frame
	root.get_node("Musica").stop()
	await create_timer(0.1).timeout
	print("OK: sonidos de interfaz, botones dinámicos, deshabilitados, cambio de pantalla y pausa." if fallos == 0 else "FALLO: sonidos de interfaz")
	quit(0 if fallos == 0 else 1)
