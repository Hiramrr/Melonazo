extends CanvasLayer
## La interfaz y la pausa viven fuera de la física y del terreno.

@onready var distancia: Label = %Distancia
@onready var estado: Label = %Estado
@onready var equipo: HBoxContainer = %Equipo
@onready var lugar: Label = %Lugar
@onready var efectos: Label = %Efectos
@onready var indicacion: Label = %Indicacion
@onready var lanzamiento: VBoxContainer = %Lanzamiento
@onready var medidor: ProgressBar = %Fuerza
@onready var pausa: Control = %Pausa

var _slots: Array = []
var _iconos: Array[Control] = []
var _nombres: Array[Label] = []


func _ready() -> void:
	var arte: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
	%Volver.get_parent().add_child(arte.crear_creditos_paisaje())
	medidor.draw.connect(_dibujar_zona_perfecta)
	for i in 3:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", lugar.get_theme_stylebox("normal"))
		equipo.add_child(panel)
		var caja := VBoxContainer.new()
		caja.add_theme_constant_override("separation", 2)
		panel.add_child(caja)
		var tecla := Label.new()
		tecla.text = str(i + 1)
		tecla.add_theme_font_size_override("font_size", 13)
		caja.add_child(tecla)
		var icono := Control.new()
		icono.custom_minimum_size = Vector2(0, 28)
		icono.draw.connect(_dibujar_slot.bind(icono, i))
		caja.add_child(icono)
		_iconos.append(icono)
		var nombre := Label.new()
		nombre.add_theme_font_size_override("font_size", 12)
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nombre.clip_text = true
		caja.add_child(nombre)
		_nombres.append(nombre)


func _dibujar_zona_perfecta() -> void:
	var zona := Rect2(medidor.size.x * Config.zona_perfecta.x, 1, medidor.size.x * (Config.zona_perfecta.y - Config.zona_perfecta.x), medidor.size.y - 2)
	medidor.draw_rect(zona, Color("7eae73"))
	medidor.draw_rect(zona, Color("fff5d9"), false, 2.0)


func _dibujar_slot(icono: Control, i: int) -> void:
	if i >= _slots.size() or _slots[i] == null:
		icono.draw_line(Vector2(icono.size.x * 0.5 - 5, 14), Vector2(icono.size.x * 0.5 + 5, 14), Color("a1ad99"), 2.0)
		return
	var accesorio: Accesorio = Config.accesorios[_slots[i]]
	accesorio.dibujar_icono(icono, Rect2(Vector2.ZERO, icono.size))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausar") and not event.is_echo():
		_alternar_pausa()
		get_viewport().set_input_as_handled()


func _alternar_pausa() -> void:
	get_tree().paused = not get_tree().paused
	pausa.visible = get_tree().paused
	if pausa.visible:
		%Continuar.grab_focus()
	else:
		%BotonPausa.release_focus()


func _volver() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/Taller.tscn")


func actualizar(melon: Melon, metros: float, fase: int, angulo: float, fuerza: float, texto_fin: String, recolectados: int, poderes: int) -> void:
	distancia.text = "%d m" % int(metros)
	%Nombre.text = "%s · Récord %d m" % [Juego.nombre_melon, int(Juego.record_m)]
	estado.text = "Resistencia %d/%d   ·   Impulsos %d\nCarisma %d   ·   Aplausos %d   ·   Poderes %d" % [maxi(0, melon.resistencia), melon.resistencia_max, melon.rebotes, melon.carisma(), recolectados * Config.valor_aplauso_suelto, poderes]
	if _slots != melon.slots:
		_slots = melon.slots.duplicate()
		for i in 3:
			var id = _slots[i]
			_nombres[i].text = Config.accesorios[id].nombre.get_slice(" ", 0) if id != null else "Vacío"
			_nombres[i].get_parent().tooltip_text = Config.accesorios[id].nombre if id != null else "Sin accesorio"
			_iconos[i].queue_redraw()
	var actual := "Barrio de Xallitic"
	var siguiente := "Colección de postales completa"
	for postal in Config.postales:
		if metros >= float(postal["metros"]):
			actual = postal["nombre"]
		else:
			siguiente = "Siguiente: %s · %d m" % [postal["nombre"], int(postal["metros"]) - int(metros)]
			break
	lugar.text = "%s\n%s" % [actual, siguiente]
	efectos.text = melon.efectos_activos()
	lanzamiento.visible = fase < 2
	indicacion.visible = fase != 2
	efectos.visible = not efectos.text.is_empty()
	medidor.value = fuerza * 100.0
	if fase == 0:
		indicacion.text = "Espacio para fijar el ángulo · %d°" % int(angulo)
	elif fase == 1:
		indicacion.text = "Espacio para lanzar · Fuerza %d%%" % int(fuerza * 100)
	else:
		indicacion.text = texto_fin if fase == 3 else ""


func actualizar_vuelo(melon: Melon, fase: int, altura: float, papalotes: int, en_rango: bool) -> void:
	%Vuelo.visible = fase >= 2
	%Vuelo.text = "Altura %d m · Papalotes %d\nEspacio usa 1 impulso · E recarga" % [int(altura), papalotes]
	if fase != 2:
		return
	indicacion.visible = true
	if en_rango:
		indicacion.text = "E · Papalote: impulso y recarga"
	elif melon.rebotes <= 0:
		indicacion.text = "Acércate a un papalote y pulsa E"
	elif melon.t_bloqueo > 0.0:
		indicacion.visible = false
	elif not melon.en_suelo and melon.t_impacto >= 0.0 and melon.t_impacto <= Config.ventana_rebote:
		indicacion.text = "Espacio · Rebote con impulso"
	else:
		indicacion.text = "Espacio · Saltar" if melon.en_suelo else "Espacio · Salto aéreo"
