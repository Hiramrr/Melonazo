extends SceneTree
## Comprueba que editar el Theme alcance las escenas y los controles dinámicos.

var comprobaciones := 0


func _initialize() -> void:
	call_deferred("_verificar")


func comprobar(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		push_error(mensaje)
		quit(1)
		assert(condicion, mensaje)


func _abrir(archivo: String) -> void:
	comprobar(change_scene_to_file(archivo) == OK, "No carga " + archivo)
	for i in 4:
		await process_frame


func _verificar() -> void:
	var juego := root.get_node("Juego")
	juego.archivo_guardado = "user://prueba_temas_%d.json" % OS.get_process_id()
	var tema := ThemeDB.get_project_theme()
	comprobar(tema == load("res://interfaz/tema_xalapa.tres"), "Todas las pantallas usan el Theme del proyecto")
	# Node2D consulta el recurso directamente y necesita entradas explícitas.
	for tipo in ["AvisoFlotante", "ObjetivoAereo"]:
		comprobar(tema.has_font("font", tipo), "Falta la fuente explícita de " + tipo)
		comprobar(tema.has_font_size("font_size", tipo), "Falta el tamaño explícito de " + tipo)
		var colores := ["font_outline_color", "color_0", "color_1", "color_2", "color_3"] if tipo == "AvisoFlotante" else ["font_outline_color", "font_color"]
		for propiedad in colores:
			comprobar(tema.has_color(propiedad, tipo), "Falta el color %s de %s" % [propiedad, tipo])
		var constantes := ["outline_size", "shadow_outline_size", "shadow_offset_y"] if tipo == "AvisoFlotante" else ["outline_size"]
		for propiedad in constantes:
			comprobar(tema.has_constant(propiedad, tipo), "Falta la constante %s de %s" % [propiedad, tipo])

	await _abrir("res://pantallas/menu/menu.tscn")
	var logo: Control = current_scene.get_node("%Titulo")
	var ancho := logo.get_minimum_size().x
	var tamano_logo := tema.get_font_size("font_size", "LogoMenu")
	tema.set_font_size("font_size", "LogoMenu", tamano_logo + 8)
	await process_frame
	comprobar(logo.get_minimum_size().x > ancho, "El logo recalcula su tamaño al editar el Theme")
	tema.set_font_size("font_size", "LogoMenu", tamano_logo)

	await _abrir("res://pantallas/taller/taller.tscn")
	var taller := current_scene
	var balance = taller.get_node("%Balance")
	tema.set_font_size("font_size", "ContadorPrincipal", 25)
	await process_frame
	comprobar(balance._etiqueta.get_theme_font_size("font_size") == 25, "Ficha usa la tipografía del Theme")
	tema.set_font_size("font_size", "ContadorPrincipal", 24)
	var color := tema.get_color("font_color", "Button")
	var prueba := Color("a24e80")
	tema.set_color("font_color", "Button", prueba)
	await process_frame
	var tamanos: Array[Button] = taller.get_node("%TuMelon").botones_tamano
	comprobar(tamanos[0].get_theme_color("font_color") == prueba, "El botón normal hereda el color")
	comprobar(tamanos[juego.tamano].get_theme_color("font_color") == prueba, "La selección conserva la herencia del botón")
	tema.set_color("font_color", "Button", color)
	var dibujo = taller.get_node("%Dibujo")
	var muestra: StyleBoxFlat = tema.get_stylebox("normal", "MuestraColor")
	var fondo := muestra.bg_color
	var borde := muestra.border_color
	muestra.border_color = prueba
	var copia: StyleBoxFlat = dibujo._estilo_muestra(Color.RED, false)
	comprobar(copia != muestra and copia.border_color == prueba and copia.bg_color == Color.RED, "La paleta copia el borde del Theme y aplica solo el color del jugador")
	comprobar(muestra.bg_color == fondo, "La paleta no modifica el recurso compartido")
	muestra.border_color = borde
	var pips = load("res://interfaz/pips.gd").new()
	pips.total = 12
	root.add_child(pips)
	var ancho_pips: float = pips.custom_minimum_size.x
	tema.set_font_size("font_size", "Pips", 64)
	await process_frame
	comprobar(pips.custom_minimum_size.x > ancho_pips, "El contador de impulsos reserva espacio para la fuente del Theme")
	tema.set_font_size("font_size", "Pips", 17)
	pips.queue_free()
	for pestana in taller.get_node("%Pestanas").get_tab_count():
		taller.get_node("%Pestanas").current_tab = pestana
		await process_frame
	comprobar(taller.get_node("%Vista").texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "El arte conserva su filtro Nearest")

	await _abrir("res://pantallas/almanaque/almanaque.tscn")
	var dialogo: ConfirmationDialog = current_scene.get_node("%Confirmar")
	comprobar(dialogo.get_theme_stylebox("panel") == tema.get_stylebox("panel", "AcceptDialog"), "El diálogo hereda el panel del Theme")
	for categoria in 3:
		current_scene._cambiar_categoria(categoria)
		await process_frame
		if not current_scene._botones.is_empty():
			current_scene._elegir(0)
			comprobar(current_scene._botones[0].get_theme_font_size("font_size") == tema.get_font_size("font_size", "SeleccionPequena"), "La ficha seleccionada conserva su tamaño de Theme")

	await _abrir("res://pantallas/recorrido/recorrido.tscn")
	var hud = current_scene.hud
	comprobar(hud.impulsos.get_theme_font_size("font_size") == 20, "El texto de impulsos conserva sus 20 px")
	var plantilla: StyleBoxFlat = tema.get_stylebox("fill", "BarraFuerza")
	var relleno_original := plantilla.bg_color
	comprobar(hud._relleno_fuerza != plantilla, "La fuerza no modifica el StyleBox compartido")
	tema.set_color("perfecta", "BarraFuerza", prueba)
	current_scene.fuerza = 0.9
	hud.actualizar(current_scene)
	comprobar(hud._relleno_fuerza.bg_color == prueba, "La fuerza lee el color de zona perfecta del Theme")
	comprobar(plantilla.bg_color == relleno_original, "La fuerza conserva el relleno original del Theme")
	hud.slots[0].mostrar(null)
	comprobar(hud.slots[0].modulate == tema.get_color("vacia", "CasillaAccesorio"), "La casilla vacía usa el color del Theme")

	juego.ultimo = {"distancia": 1000, "record_nuevo": true, "total": 100}
	await _abrir("res://pantallas/resultados/resultados.tscn")
	var record: Label = current_scene.get_node("%Record")
	comprobar(record.get_theme_stylebox("normal") == tema.get_stylebox("normal", "SelloRecord"), "El récord usa el sello del Theme")
	var postal = current_scene.get_node("Margen/Columnas/Postal")
	comprobar(postal.get_theme_stylebox("marco") == tema.get_stylebox("marco", "Postal"), "La postal usa el marco del Theme")
	for estilo in ["marco", "sombra"]:
		var caja: StyleBoxTexture = tema.get_stylebox(estilo, "Postal")
		comprobar((caja.texture as AtlasTexture).filter_clip, "El atlas de la postal recorta los píxeles vecinos")
	comprobar(current_scene.get_node("Fondo").get_theme_color("arriba") == tema.get_color("arriba", "FondoResultados"), "El fondo de resultados usa su variación")
	if FileAccess.file_exists(juego.archivo_guardado):
		DirAccess.remove_absolute(juego.archivo_guardado)
	print("OK: %d comprobaciones de Themes, herencia y estados dinámicos." % comprobaciones)
	quit()
