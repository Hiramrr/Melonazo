extends Control
## Colección personal y fichas de consulta. Mirar una ficha no cambia Juego.

const TALLER := "res://pantallas/taller/taller.tscn"

@onready var categorias: Array[Button] = [%MisMelones, %Accesorios, %Poderes]
@onready var lista: GridContainer = %Lista
@onready var resumen: Label = %Resumen
@onready var vacio: Label = %Vacio
@onready var ilustracion: IlustracionFicha = %Ilustracion
@onready var nombre: Label = %Nombre
@onready var descripcion: Label = %Descripcion
@onready var datos: Label = %Datos
@onready var texto: ScrollContainer = %Texto
@onready var btn_guardar: Button = %Guardar
@onready var btn_usar: Button = %Usar
@onready var btn_actualizar: Button = %Actualizar
@onready var btn_eliminar: Button = %Eliminar
@onready var aviso: Label = %Aviso
@onready var confirmar: ConfirmationDialog = %Confirmar

var categoria := 0
var seleccionado := -1
var _entradas: Array = []
var _botones: Array[Button] = []
var _operacion := ""


func _ready() -> void:
	for i in categorias.size():
		categorias[i].pressed.connect(_cambiar_categoria.bind(i))
	lista.resized.connect(_ajustar_columnas)
	aviso.text = Juego.guardado_error
	confirmar.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "PanelContainer"))
	_refrescar()
	%Volver.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not confirmar.visible:
		get_viewport().set_input_as_handled()
		_volver()


func _volver() -> void:
	Animacion.cambiar_escena(TALLER)


func _cambiar_categoria(indice: int) -> void:
	categoria = indice
	seleccionado = -1
	aviso.text = Juego.guardado_error
	_refrescar()


func _refrescar() -> void:
	for i in categorias.size():
		categorias[i].theme_type_variation = &"Seleccion" if i == categoria else &""
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()
	_botones.clear()
	match categoria:
		0:
			_entradas = Juego.melones_guardados
			resumen.text = "%d de %d melones guardados. Elige una ficha para verlo o volver a usarlo." % [_entradas.size(), Juego.MAX_MELONES]
		1:
			_entradas = Config.orden_accesorios
			resumen.text = "%d de %d accesorios disponibles. Se equipan en el taller y se usan con 1, 2 y 3." % [Juego.desbloqueados.size(), _entradas.size()]
		2:
			_entradas = Config.orden_poderes
			resumen.text = "Poderes del camino. Se activan al recogerlos durante la carrera."
	btn_guardar.visible = categoria == 0
	btn_guardar.disabled = Juego.melones_guardados.size() >= Juego.MAX_MELONES
	btn_guardar.tooltip_text = "Colección llena. Puedes actualizar una ficha o eliminar una." if btn_guardar.disabled else "Guardar el melón que tienes en el taller"
	vacio.visible = _entradas.is_empty()
	for i in _entradas.size():
		_crear_ficha(i)
	_ajustar_columnas()
	_elegir(clampi(seleccionado, 0, _entradas.size() - 1) if not _entradas.is_empty() else -1)


func _ajustar_columnas() -> void:
	lista.columns = maxi(1, mini(4, int(lista.size.x / 146.0)))


func _crear_ficha(indice: int) -> void:
	var boton := ComunTaller.boton("", 16)
	boton.custom_minimum_size = Vector2(138, 164)
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.pressed.connect(_elegir.bind(indice))
	lista.add_child(boton)
	_botones.append(boton)
	var caja := VBoxContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caja.offset_left = 10
	caja.offset_right = -10
	caja.offset_top = 4
	caja.offset_bottom = -14
	var imagen := IlustracionFicha.new()
	imagen.custom_minimum_size.y = 92
	imagen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preparar_imagen(imagen, indice)
	caja.add_child(imagen)
	var titulo := ComunTaller.titulo_seccion(_nombre_entrada(indice), 16)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caja.add_child(titulo)
	var estado := "Melón personalizado"
	if categoria == 1:
		estado = "Disponible" if _entradas[indice] in Juego.desbloqueados else "Por desbloquear"
	elif categoria == 2:
		estado = "Poder del camino"
	var nota := ComunTaller.etiqueta(estado, 13, true)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(nota)
	boton.tooltip_text = "%s. %s" % [titulo.text, estado]


func _nombre_entrada(indice: int) -> String:
	match categoria:
		0: return _entradas[indice]["nombre_melon"]
		1: return Config.accesorios[_entradas[indice]].nombre
		2: return Config.poderes[_entradas[indice]]["nombre"]
	return ""


func _preparar_imagen(imagen: IlustracionFicha, indice: int) -> void:
	imagen.categoria = categoria
	imagen.melon = _entradas[indice] if categoria == 0 else {}
	imagen.id = _entradas[indice] if categoria != 0 else ""
	imagen.queue_redraw()


func _elegir(indice: int) -> void:
	seleccionado = indice
	texto.scroll_vertical = 0
	for i in _botones.size():
		_botones[i].theme_type_variation = &"Seleccion" if i == indice else &""
	for boton in [btn_usar, btn_actualizar, btn_eliminar]:
		boton.visible = categoria == 0 and indice >= 0
	if indice < 0:
		nombre.text = "Tu primer melón"
		descripcion.text = "Personaliza un melón en el taller y guárdalo aquí. Podrás hacer otros sin perder este."
		datos.text = "Cada ficha conserva su dibujo, colores, tamaño, estela y accesorios."
		ilustracion.categoria = 0
		ilustracion.melon = Juego.datos_melon()
		ilustracion.queue_redraw()
		return
	nombre.text = _nombre_entrada(indice)
	_preparar_imagen(ilustracion, indice)
	match categoria:
		0:
			var melon: Dictionary = _entradas[indice]
			var tamano: Dictionary = Config.tamanos[melon["tamano"]]
			descripcion.text = tamano["desc"]
			var equipo := PackedStringArray()
			for id in melon["accesorios"]:
				equipo.append(Config.accesorios[id].nombre)
			datos.text = "\n".join([
				"Tamaño: %s" % tamano["nombre"],
				"Piel: %s" % Config.pieles[melon["piel"]]["nombre"],
				"Patrón: %s" % Config.patrones[melon["patron"]]["nombre"],
				"Cara: %s" % Config.caras[melon["cara"]]["nombre"],
				"Detalle: %s" % Config.detalles[melon["detalle"]]["nombre"],
				"Estela: %s" % Config.estelas[melon["estela"]]["nombre"],
				"Dibujo: %d trazos" % melon["dibujo"].size(),
				"Equipo: %s" % (", ".join(equipo) if not equipo.is_empty() else "Sin accesorios"),
				"Carisma: %d" % Juego.carisma_de(melon["accesorios"]),
			])
		1:
			var accesorio: Accesorio = Config.accesorios[_entradas[indice]]
			descripcion.text = accesorio.accion
			datos.text = "Carisma: %d\nPrecio: %d aplausos\n%s\n\nAl usarlo, pierdes su carisma durante esa carrera. Vuelve en el siguiente intento." % [accesorio.carisma, accesorio.costo, "Disponible para equipar en el taller." if accesorio.id in Juego.desbloqueados else "Desbloquéalo en la pestaña Accesorios del taller."]
		2:
			var poder: Dictionary = Config.poderes[_entradas[indice]]
			descripcion.text = poder["descripcion"]
			var duracion := "Duración: %s s" % str(poder["duracion"]) if poder["duracion"] > 0 else "Efecto instantáneo"
			datos.text = "%s\n\nSe activa al tocarlo. Busca los poderes por encima del camino y aprovecha los saltos para alcanzarlos." % duracion


func _guardar() -> void:
	var indice := Juego.guardar_melon()
	if indice < 0:
		aviso.text = "Ya tienes %d melones. Actualiza una ficha o elimina una para guardar otro." % Juego.MAX_MELONES
		return
	seleccionado = indice
	_refrescar()
	aviso.text = Juego.guardado_error if not Juego.guardado_error.is_empty() else "Melón guardado en tu colección."
	_botones[indice].grab_focus()


func _usar() -> void:
	if Juego.usar_melon(seleccionado):
		_volver()


func _pedir_confirmacion(operacion: String) -> void:
	if seleccionado < 0:
		return
	_operacion = operacion
	confirmar.title = "¿Eliminar este melón?" if operacion == "eliminar" else "¿Actualizar esta ficha?"
	if operacion == "eliminar":
		confirmar.dialog_text = "Eliminarás a %s de la colección. El melón del taller seguirá igual." % nombre.text
	else:
		confirmar.dialog_text = "Reemplazarás a %s con el melón actual del taller, %s." % [nombre.text, ComunTaller.nombre_melon()]
	confirmar.ok_button_text = "Eliminar" if operacion == "eliminar" else "Actualizar"
	confirmar.popup_centered()


func _confirmar() -> void:
	if _operacion == "eliminar":
		Juego.eliminar_melon(seleccionado)
		aviso.text = "Melón eliminado de la colección."
	else:
		Juego.guardar_melon(seleccionado)
		aviso.text = "Ficha actualizada con el melón del taller."
	_refrescar()
	if not Juego.guardado_error.is_empty():
		aviso.text = Juego.guardado_error
	if seleccionado >= 0:
		_botones[seleccionado].grab_focus()
	else:
		btn_guardar.grab_focus()
