extends Control
## Pantalla del taller: preparar el melón antes de rodar.
##
## Escena: pantallas/taller/taller.tscn. Cada parte tiene su propio script:
##   Fondo                       interfaz/fondo_juego.gd: rayos y papel picado animados
##   Cabecera                    logo y fichas de aplausos (%Balance) y récord (%Record)
##   Previa/.../Vista            vista_melon.gd: dibuja el melón y recibe el ratón
##   Pestanas/TuMelon            pestanas/pestana_melon.gd: nombre, tamaño y aspecto
##   Pestanas/Dibujo             pestanas/pestana_dibujo.tscn: dibujo libre
##   Pestanas/Accesorios         pestanas/pestana_accesorios.gd
##   Pestanas/Mejoras            pestanas/pestana_mejoras.gd
##   Pestanas/Pasaporte          pestanas/pestana_pasaporte.gd (solo lectura)
##   Pie                         error de guardado, teclas de ayuda, "Reiniciar
##                               progreso" (con confirmación) y "¡A rodar!"
##
## Este script solo coordina:
##   - Cuando una pestaña emite cambio (tocó Juego), _refrescar() pone al día
##     todas las pestañas, el pie y los textos bajo la vista, y redibuja la vista.
##   - Dibujo.cambio y TuMelon.color_cambiado solo redibujan la vista: llegan en
##     cada movimiento del ratón y no hace falta refrescar lo demás.
##   - Al cambiar de pestaña activa o apaga el modo dibujo de la vista.
##   - Enter o el botón "¡A rodar!" (_ir) guardan y pasan al recorrido.
## Las señales internas de cada pestaña se conectan en la escena; las que unen
## nodos distintos, aquí en _ready().

<<<<<<< HEAD
const RECORRIDO := "res://pantallas/recorrido/recorrido.tscn"
const ALMANAQUE := "res://pantallas/almanaque/almanaque.tscn"

=======
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
# --- Vista previa ------------------------------------------------------------
@onready var vista: VistaMelon = %Vista
@onready var lbl_nombre_vista: Label = %NombreVista
@onready var lbl_tamano: Label = %Tamano
@onready var ficha_carisma: Ficha = %Carisma

# --- Pestañas ----------------------------------------------------------------
@onready var pestanas: TabContainer = %Pestanas
@onready var pestana_melon: PestanaMelon = %TuMelon
@onready var pestana_dibujo: PestanaDibujo = %Dibujo
@onready var pestana_accesorios: PestanaAccesorios = %Accesorios
@onready var pestana_mejoras: PestanaMejoras = %Mejoras
@onready var pestana_pasaporte: PestanaPasaporte = %Pasaporte

# --- Cabecera y pie ---------------------------------------------------------
@onready var titulo: Label = %Titulo
@onready var ficha_balance: Ficha = %Balance
@onready var ficha_record: Ficha = %Record
@onready var lbl_error: Label = %ErrorGuardo
@onready var ayuda: HBoxContainer = %Ayuda
@onready var btn_puente: Button = %BtnPuente
@onready var btn_reiniciar: Button = %BtnReiniciar
@onready var confirmar_reinicio: ConfirmationDialog = %ConfirmarReinicio

var _aplausos_mostrados := -1
var _carisma_mostrado := -1


func _ready() -> void:
	Musica.tocar(Musica.TIENDITA)
	# El nodo se llama TuMelon (sin acento ni espacio); el título lleva los dos.
	pestanas.set_tab_title(pestanas.get_tab_idx_from_control(pestana_melon), "Tu melón")
<<<<<<< HEAD
	pestanas.set_tab_title(pestanas.get_tab_idx_from_control(pestana_mejoras), "Tiendita")
=======
	pestanas.set_tab_title(pestanas.get_tab_idx_from_control(pestana_mejoras), "Tienda")
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
	pestanas.tab_changed.connect(_al_cambiar_pestana)
	Animacion.conectar_pestanas(pestanas)
	vista.pestana_dibujo = pestana_dibujo
	for pestana in [pestana_melon, pestana_accesorios, pestana_mejoras]:
		pestana.cambio.connect(_refrescar)
	pestana_melon.color_cambiado.connect(vista.queue_redraw)
	pestana_melon.nombre_confirmado.connect(btn_puente.grab_focus)
	pestana_dibujo.cambio.connect(vista.queue_redraw)
	for parte in [["Tab", "Elegir"], ["Enter", "Rodar"]]:
		ayuda.add_child(Iconos.tecla(parte[0]))
<<<<<<< HEAD
		var l := ComunTaller.etiqueta(parte[1], &"AyudaHUD")
=======
		var l := ComunTaller.etiqueta(parte[1], Estilos.AYUDA_HUD)
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
		ayuda.add_child(l)
	_refrescar()
	btn_puente.grab_focus()
	_animar_entrada()


## Logo que se mece, botón que late y paneles que entran con rebote.
func _animar_entrada() -> void:
	titulo.pivot_offset = titulo.size * 0.5
	titulo.rotation_degrees = -2.0
	var vaiven := titulo.create_tween().set_loops()
	vaiven.tween_property(titulo, "rotation_degrees", 2.0, 1.6).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(titulo, "rotation_degrees", -2.0, 1.6).set_trans(Tween.TRANS_SINE)
	Animacion.aparecer(titulo, 0.0, 0.4)
	Animacion.aparecer(%Previa, 0.08, 0.85)
	Animacion.aparecer(pestanas, 0.14, 0.9)
	Animacion.aparecer(btn_puente, 0.25, 0.5).finished.connect(Animacion.latir.bind(btn_puente))


## Enter fuera de un campo de texto o botón = "¡A rodar!".
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirmar"):
		var foco := get_viewport().gui_get_focus_owner()
		if foco is LineEdit or foco is BaseButton:
			return
		_ir()


## Guarda el melón y pasa al recorrido. Conectado a BtnPuente.pressed en la escena.
func _ir() -> void:
	Juego.nombre_melon = ComunTaller.nombre_melon()
	Juego.guardar()
<<<<<<< HEAD
	Animacion.cambiar_escena(RECORRIDO)
=======
	Animacion.cambiar_escena(Rutas.RECORRIDO)
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)


func _abrir_almanaque() -> void:
	pestana_dibujo.salir_vista()
	Juego.guardar()
<<<<<<< HEAD
	Animacion.cambiar_escena(ALMANAQUE)
=======
	Animacion.cambiar_escena(Rutas.ALMANAQUE)
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)


func _guardar_melon() -> void:
	pestana_dibujo.salir_vista()
	var indice := Juego.guardar_melon()
	_refrescar()
	if not Juego.guardado_error.is_empty():
		return
	lbl_error.text = "Melón guardado. Ábrelo en el almanaque." if indice >= 0 else "Colección llena. Actualiza o elimina una ficha en el almanaque."
	lbl_error.tooltip_text = lbl_error.text


## Muestra la confirmación antes de borrar. Conectado a BtnReiniciar.pressed.
func _pedir_reinicio() -> void:
	confirmar_reinicio.popup_centered()


## Borra el progreso y pone toda la pantalla al día. Conectado a
## ConfirmarReinicio.confirmed en la escena.
func _reiniciar_progreso() -> void:
	Juego.reiniciar_progreso()
	pestana_dibujo.refrescar()
	pestana_pasaporte.refrescar()
	_refrescar()
	btn_puente.grab_focus()


func _al_cambiar_pestana(_pestana: int) -> void:
	vista.modo_dibujo = pestanas.get_current_tab_control() == pestana_dibujo


## Pone toda la pantalla al día con Juego.
func _refrescar() -> void:
	pestana_melon.refrescar()
	pestana_accesorios.refrescar()
	pestana_mejoras.refrescar()
<<<<<<< HEAD
=======
	pestana_dibujo.refrescar()
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
	ficha_balance.texto = str(Juego.aplausos)
	ficha_record.texto = "%d m" % int(Juego.record_m)
	if _aplausos_mostrados >= 0 and _aplausos_mostrados != Juego.aplausos:
		Animacion.rebotar(ficha_balance, 1.2)
	_aplausos_mostrados = Juego.aplausos
	lbl_error.text = Juego.guardado_error
	lbl_error.tooltip_text = Juego.guardado_error
	lbl_nombre_vista.text = ComunTaller.nombre_melon()
	lbl_tamano.text = Config.tamanos[Juego.tamano]["nombre"]
	var carisma := Juego.carisma_de(Juego.accesorios)
	ficha_carisma.texto = "Carisma %d" % carisma
	if _carisma_mostrado >= 0 and _carisma_mostrado != carisma:
		Animacion.rebotar(ficha_carisma, 1.2)
	_carisma_mostrado = carisma
	vista.queue_redraw()
