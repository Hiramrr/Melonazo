extends Control
## Taller de ¡Rueda, Melón! La estructura estable vive en Taller.tscn.
## Este script solo genera las listas dinámicas (tamaños, pieles, accesorios,
## mejoras, pasaporte), refresca textos y dibuja la vista previa del melón.

const ESCALA_VISTA := 4.0
const SUAVE := Color("5d6f65")
const VERDE := Color("2b5745")
const ARTE := preload("res://recursos/arte_xalapa.tres")
const ESCENARIO := preload("res://recursos/taller_xallitic.svg")

@onready var vista: Control = %Vista
@onready var lbl_nombre_vista: Label = %NombreVista
@onready var lbl_carisma: Label = %Carisma
@onready var linea_nombre: LineEdit = %LineaNombre
@onready var fila_tamanos: HBoxContainer = %FilaTamanos
@onready var lbl_desc_tamano: Label = %DescTamano
@onready var caja_listas: VBoxContainer = %CajaListas
@onready var lbl_feedback_acc: Label = %FeedbackAcc
@onready var lista_acc: VBoxContainer = %ListaAcc
@onready var lista_mejoras: VBoxContainer = %ListaMejoras
@onready var lista_pasaporte: VBoxContainer = %ListaPasaporte
@onready var lbl_balance: Label = %Balance
@onready var lbl_record: Label = %Record
@onready var lbl_error: Label = %ErrorGuardo
@onready var btn_puente: Button = %BtnPuente
@onready var pestanas: TabContainer = %Pestanas
@onready var panel_dibujo: Control = %Dibujo

var botones_tamano: Array = []
var listas := {}                       # prop de Juego -> OptionButton
var filas_acc := {}                    # id -> {boton, desbloquear, info}
var filas_mejora := {}                 # id -> {texto, boton}

var _aviso_acc := ""
var _centro_vista := Vector2.ZERO        # dónde se dibujó el melón en la vista
var _radio_vista := 1.0                  # radio del melón en píxeles de la vista
var _colores: Array = []                 # [ColorPickerButton cuerpo, rayas]


func _ready() -> void:
	linea_nombre.text = _nombre_melon()
	_generar_tamanos()
	_generar_listas()
	_generar_accesorios()
	_generar_mejoras()
	_generar_pasaporte()
	vista.gui_input.connect(_entrada_vista)
	vista.mouse_exited.connect(panel_dibujo.salir_vista)
	panel_dibujo.cambio.connect(vista.queue_redraw)
	pestanas.tab_changed.connect(func(_i: int) -> void: vista.queue_redraw())
	_refrescar()
	btn_puente.grab_focus()


func _label(texto: String, tam := 16, suave := false) -> Label:
	var l := Label.new()
	l.text = texto
	if tam != 16:
		l.add_theme_font_size_override("font_size", tam)
	if suave:
		l.add_theme_color_override("font_color", SUAVE)
	return l


func _boton(texto: String, tam := 16) -> Button:
	var b := Button.new()
	b.text = texto
	if tam != 16:
		b.add_theme_font_size_override("font_size", tam)
	return b


func _generar_tamanos() -> void:
	for i in Config.tamanos.size():
		var b := _boton(Config.tamanos[i]["nombre"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_elegir_tamano.bind(i))
		fila_tamanos.add_child(b)
		botones_tamano.append(b)


func _generar_listas() -> void:
	_agregar_lista("Piel", "piel", Config.pieles)
	_agregar_colores()
	_agregar_lista("Patrón", "patron", Config.patrones)
	_agregar_lista("Cara", "cara", Config.caras)
	_agregar_lista("Detalle", "detalle", Config.detalles)
	_agregar_lista("Estela", "estela", Config.estelas)


## Dos selectores para cambiar los colores de la piel elegida.
func _agregar_colores() -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	caja_listas.add_child(fila)
	var etiqueta := _label("Colores", 16)
	etiqueta.custom_minimum_size.x = 70
	fila.add_child(etiqueta)
	for prop in ["cuerpo_propio", "rayas_propio"]:
		var picker := ColorPickerButton.new()
		picker.edit_alpha = false
		picker.custom_minimum_size = Vector2(64, 32)
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.tooltip_text = "Color del cuerpo" if prop == "cuerpo_propio" else "Color de las rayas y el borde"
		picker.color_changed.connect(_elegir_color.bind(prop))
		picker.popup_closed.connect(_guardar)
		fila.add_child(picker)
		_colores.append(picker)
	var volver := _boton("Original", 14)
	volver.tooltip_text = "Usar los colores de la piel"
	volver.pressed.connect(_colores_de_piel)
	fila.add_child(volver)


func _agregar_lista(titulo: String, prop: String, datos: Variant) -> void:
	if not (datos is Array) or (datos as Array).is_empty():
		return
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	caja_listas.add_child(fila)
	var etiqueta := _label(titulo, 16)
	etiqueta.custom_minimum_size.x = 70
	fila.add_child(etiqueta)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", 16)
	for d in (datos as Array):
		opt.add_item(str((d as Dictionary).get("nombre", "?")))
	opt.select(clampi(_jentero(prop), 0, (datos as Array).size() - 1))
	opt.item_selected.connect(_elegir_lista.bind(prop))
	fila.add_child(opt)
	listas[prop] = opt


func _generar_accesorios() -> void:
	for id in Config.orden_accesorios:
		var fila_equipo := HBoxContainer.new()
		fila_equipo.add_theme_constant_override("separation", 12)
		lista_acc.add_child(fila_equipo)
		var icono := Control.new()
		icono.custom_minimum_size = Vector2(44, 44)
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var accesorio: Accesorio = Config.accesorios[id]
		icono.draw.connect(accesorio.dibujar_icono.bind(icono, Rect2(0, 0, 44, 44)))
		fila_equipo.add_child(icono)
		var cont := VBoxContainer.new()
		cont.add_theme_constant_override("separation", 2)
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_equipo.add_child(cont)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		cont.add_child(fila)
		var b := _boton("")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.pressed.connect(_alternar_accesorio.bind(id))
		fila.add_child(b)
		var d := _boton("")
		d.pressed.connect(_desbloquear.bind(id))
		fila.add_child(d)
		var info := _label("", 14, true)
		cont.add_child(info)
		filas_acc[id] = {"boton": b, "desbloquear": d, "info": info}


func _generar_mejoras() -> void:
	for id in Config.orden_mejoras:
		var cont := VBoxContainer.new()
		cont.add_theme_constant_override("separation", 4)
		lista_mejoras.add_child(cont)
		var texto := _label("", 16)
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cont.add_child(texto)
		var b := _boton("")
		b.pressed.connect(_comprar.bind(id))
		cont.add_child(b)
		filas_mejora[id] = {"texto": texto, "boton": b}


func _generar_pasaporte() -> void:
	var visitados: Array = Juego.visitados
	lista_pasaporte.add_child(_label("Pasaporte de Xalapa", 20))
	lista_pasaporte.add_child(_label("Cada lugar nuevo suma %d aplausos. Ruta y distancias de fantasía." % Config.bonus_postal, 15, true))
	lista_pasaporte.add_child(_label("Intentos: %d. Sitios visitados: %d." % [Juego.intentos, visitados.size()]))
	var postales: Variant = Config.postales
	var hay_postales := postales is Array and not (postales as Array).is_empty()
	if hay_postales:
		lista_pasaporte.add_child(_label("Postales", 20))
		var record_m := int(Juego.record_m)
		for p in (postales as Array):
			var pd := p as Dictionary
			var pid := str(pd.get("id", ""))
			var linea := ""
			if pid != "" and pid in visitados:
				linea = "Visitado: %s. %s" % [pd.get("nombre", "?"), pd.get("nota", "")]
			else:
				var falta := maxi(0, int(pd.get("metros", 0)) - record_m)
				linea = "A %d m: %s. Te faltan %d m." % [int(pd.get("metros", 0)), pd.get("nombre", "?"), falta]
			var l := _label(linea)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lista_pasaporte.add_child(l)
			if ARTE.fotografias.has(pid):
				var foto := FotoLugar.new()
				foto.configurar(ARTE.fotografias[pid])
				lista_pasaporte.add_child(foto)
	var poderes: Variant = Config.poderes
	var hay_poderes := poderes is Dictionary and not (poderes as Dictionary).is_empty()
	if hay_poderes:
		lista_pasaporte.add_child(_label("Poderes en la ruta", 20))
		lista_pasaporte.add_child(_label("Se activan al recogerlos. Cada uno tiene su propio efecto.", 15, true))
		for id in (poderes as Dictionary).keys():
			var pw := (poderes as Dictionary)[id] as Dictionary
			var d := float(pw.get("duracion", 0.0))
			var txt_d := str(int(d)) if d == float(int(d)) else str(d)
			var tiempo := " · %s s" % txt_d if d > 0 else " · instantáneo"
			var l := _label("%s%s. %s" % [pw.get("nombre", "?"), tiempo, pw.get("descripcion", "")])
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lista_pasaporte.add_child(l)
	if not hay_postales and not hay_poderes:
		lista_pasaporte.add_child(_label("Rueda lejos y el pasaporte se llena solo.", 16, true))


func _jentero(prop: String) -> int:
	return int(Juego.get(prop))


func _nombre_melon() -> String:
	return Juego.nombre_melon if not Juego.nombre_melon.strip_edges().is_empty() else "Melón"


func _guardar() -> void:
	Juego.guardar()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirmar"):
		var foco := get_viewport().gui_get_focus_owner()
		if foco is LineEdit or foco is BaseButton:
			return
		_ir()


func _ir() -> void:
	Juego.nombre_melon = _nombre_melon()
	_guardar()
	get_tree().change_scene_to_file("res://escenas/Recorrido.tscn")


func _elegir_tamano(i: int) -> void:
	Juego.tamano = i
	_guardar()
	_refrescar()


func _cambiar_nombre(nuevo: String) -> void:
	var limpio := nuevo.strip_edges().left(24)
	Juego.nombre_melon = limpio
	_guardar()
	_refrescar()


func _nombre_listo(_texto: String) -> void:
	_guardar()
	btn_puente.grab_focus()


func _elegir_lista(idx: int, prop: String) -> void:
	Juego.set(prop, idx)
	if prop == "piel":
		Juego.cuerpo_propio = ""
		Juego.rayas_propio = ""
	_guardar()
	_refrescar()


func _elegir_color(c: Color, prop: String) -> void:
	Juego.set(prop, c.to_html(false))
	vista.queue_redraw()


func _colores_de_piel() -> void:
	Juego.cuerpo_propio = ""
	Juego.rayas_propio = ""
	_guardar()
	_refrescar()


func _dibujando() -> bool:
	return pestanas.get_current_tab_control() == panel_dibujo


func _entrada_vista(event: InputEvent) -> void:
	if not _dibujando() or not event is InputEventMouse:
		return
	var p: Vector2 = ((event as InputEventMouse).position - _centro_vista) / _radio_vista
	panel_dibujo.entrada_vista(event, p)
	vista.accept_event()


func _alternar_accesorio(id: String) -> void:
	if id in Juego.accesorios:
		Juego.accesorios.erase(id)
	elif id in Juego.desbloqueados:
		if Juego.accesorios.size() < Config.max_accesorios:
			Juego.accesorios.append(id)
		else:
			_aviso_acc = "Ya llevas %d accesorios. Quita uno para ponerte otro." % Config.max_accesorios
	_guardar()
	_refrescar()


func _desbloquear(id: String) -> void:
	Juego.desbloquear(id)
	_refrescar()


func _comprar(id: String) -> void:
	Juego.comprar_mejora(id)
	_refrescar()


func _refrescar() -> void:
	for i in botones_tamano.size():
		var b: Button = botones_tamano[i]
		b.text = Config.tamanos[i]["nombre"]
		b.theme_type_variation = &"Seleccion" if i == Juego.tamano else &"Button"
	lbl_desc_tamano.text = Config.tamanos[Juego.tamano]["desc"]
	if not linea_nombre.has_focus():
		linea_nombre.text = _nombre_melon()
	for prop in listas.keys():
		var opt: OptionButton = listas[prop]
		opt.set_block_signals(true)
		opt.select(clampi(_jentero(prop), 0, opt.item_count - 1))
		opt.set_block_signals(false)
	if _colores.size() == 2:
		_colores[0].color = Juego.color_cuerpo()
		_colores[1].color = Juego.color_rayas()

	var base := "Equipados %d de %d. Teclas 1, 2, 3 para usarlos en el aire." % [Juego.accesorios.size(), Config.max_accesorios]
	lbl_feedback_acc.text = base if _aviso_acc == "" else base + " " + _aviso_acc
	_aviso_acc = ""
	for id in Config.orden_accesorios:
		var a: Accesorio = Config.accesorios[id]
		var b: Button = filas_acc[id]["boton"]
		var d: Button = filas_acc[id]["desbloquear"]
		var libre: bool = id in Juego.desbloqueados
		var pos := Juego.accesorios.find(id)
		var marca := "[%d]" % (pos + 1) if pos >= 0 else "[  ]"
		b.text = "%s %s · carisma %d" % [marca, a.nombre, a.carisma]
		b.disabled = not libre or (pos < 0 and Juego.accesorios.size() >= Config.max_accesorios)
		b.theme_type_variation = &"Seleccion" if pos >= 0 else &"Button"
		filas_acc[id]["info"].text = a.accion
		d.visible = not libre
		d.text = "Desbloquear · %d" % a.costo
		d.disabled = Juego.aplausos < a.costo

	for id in Config.orden_mejoras:
		var m: Dictionary = Config.mejoras[id]
		var nivel: int = Juego.niveles[id]
		var efecto := ""
		match id:
			"fuerza":
				efecto = "salida x%.2f" % Juego.mult_fuerza()
			"resistencia":
				efecto = "%d golpes con este tamaño" % Juego.resistencia_max()
			"rebotes":
				efecto = "%d por intento" % Juego.rebotes_max()
		var txt := "%s, nivel %d de %d" % [m["nombre"], nivel, m["max"]]
		if efecto != "":
			txt += " · %s" % efecto
		filas_mejora[id]["texto"].text = txt
		var b: Button = filas_mejora[id]["boton"]
		if Juego.mejora_al_max(id):
			b.text = "Al máximo"
			b.disabled = true
		else:
			b.text = "Comprar · %d aplausos" % Juego.costo_mejora(id)
			b.disabled = Juego.aplausos < Juego.costo_mejora(id)

	lbl_balance.text = "Aplausos: %d" % Juego.aplausos
	lbl_record.text = "Récord: %d m" % int(Juego.record_m)
	lbl_error.text = Juego.guardado_error
	lbl_error.tooltip_text = Juego.guardado_error
	lbl_nombre_vista.text = _nombre_melon()
	lbl_carisma.text = "%s   ·   Carisma %d" % [Config.tamanos[Juego.tamano]["nombre"], Juego.carisma_de(Juego.accesorios)]
	vista.queue_redraw()


func _dibujar_vista() -> void:
	var r: float = Config.tamanos[Juego.tamano]["radio"]
	vista.draw_texture_rect(ESCENARIO, Rect2(Vector2.ZERO, vista.size), false)
	var centro := vista.size * Vector2(0.5, 0.48)
	var escala := minf(ESCALA_VISTA, minf(vista.size.y / 105.0, vista.size.x / 125.0))
	var dibujando := _dibujando()
	if dibujando:
		# Más grande para dibujar con calma, sin importar el tamaño elegido.
		escala = minf(vista.size.x, vista.size.y) * 0.4 / r
	vista.draw_set_transform(centro + Vector2(0, r * escala + 14), 0, Vector2(1, 0.16))
	vista.draw_circle(Vector2.ZERO, r * escala * 1.1, Color(0.17, 0.25, 0.19, 0.15), true, -1.0, true)
	vista.draw_set_transform(Vector2.ZERO)
	if not dibujando:
		_dibujar_estela(centro, r)
	vista.draw_set_transform(centro)
	_centro_vista = centro
	_radio_vista = r * escala
	Melon.dibujar(vista, r * escala, Juego.accesorios, false, not dibujando)
	if dibujando and panel_dibujo.cursor != null:
		var c: Vector2 = panel_dibujo.cursor * _radio_vista
		var rc: float = maxf(2.0, panel_dibujo.radio_cursor() * _radio_vista)
		var tinta: Color = Color(0.85, 0.2, 0.2) if panel_dibujo.es_goma() else panel_dibujo.color
		vista.draw_arc(c, rc, 0, TAU, 32, Color.WHITE, 3.0, true)
		vista.draw_arc(c, rc, 0, TAU, 32, tinta, 1.5, true)
	vista.draw_set_transform(Vector2.ZERO)


func _dibujar_estela(centro: Vector2, r: float) -> void:
	var estelas: Variant = Config.estelas
	var idx := _jentero("estela")
	if not (estelas is Array) or idx <= 0 or idx >= (estelas as Array).size():
		return
	var col: Color = (estelas[idx] as Dictionary).get("color", VERDE)
	var base := r * ESCALA_VISTA
	for i in 6:
		var p := centro + Vector2(-base - 18.0 - i * 20.0, 26.0 + i * 6.0)
		col.a = 0.75 - i * 0.1
		vista.draw_circle(p, 9.0 - i * 1.2, col)
