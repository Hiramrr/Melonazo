extends Control
## Pantalla del taller: preparar el melón antes de rodar.
##
## Escena: pantallas/taller/taller.tscn. Cada parte tiene su propio script:
##   Previa/CajaPrevia/Vista     vista_melon.gd: dibuja el melón y recibe el ratón
##   Pestanas/TuMelon            pestanas/pestana_melon.gd: nombre, tamaño y aspecto
##   Pestanas/Dibujo             pestanas/pestana_dibujo.tscn: dibujo libre
##   Pestanas/Accesorios         pestanas/pestana_accesorios.gd
##   Pestanas/Mejoras            pestanas/pestana_mejoras.gd
##   Pestanas/Pasaporte          pestanas/pestana_pasaporte.gd (solo lectura)
##   Pie                         aplausos, récord, error de guardado y "¡A rodar!"
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

const RECORRIDO := "res://pantallas/recorrido/recorrido.tscn"

# --- Vista previa ------------------------------------------------------------
@onready var vista: VistaMelon = %Vista
@onready var lbl_nombre_vista: Label = %NombreVista
@onready var lbl_carisma: Label = %Carisma

# --- Pestañas ----------------------------------------------------------------
@onready var pestanas: TabContainer = %Pestanas
@onready var pestana_melon: PestanaMelon = %TuMelon
@onready var pestana_dibujo: PestanaDibujo = %Dibujo
@onready var pestana_accesorios: PestanaAccesorios = %Accesorios
@onready var pestana_mejoras: PestanaMejoras = %Mejoras

# --- Pie ---------------------------------------------------------------------
@onready var lbl_balance: Label = %Balance
@onready var lbl_record: Label = %Record
@onready var lbl_error: Label = %ErrorGuardo
@onready var btn_puente: Button = %BtnPuente


func _ready() -> void:
	# El nodo se llama TuMelon (sin acento ni espacio); el título lleva los dos.
	pestanas.set_tab_title(pestanas.get_tab_idx_from_control(pestana_melon), "Tu melón")
	pestanas.tab_changed.connect(_al_cambiar_pestana)
	vista.pestana_dibujo = pestana_dibujo
	for pestana in [pestana_melon, pestana_accesorios, pestana_mejoras]:
		pestana.cambio.connect(_refrescar)
	pestana_melon.color_cambiado.connect(vista.queue_redraw)
	pestana_melon.nombre_confirmado.connect(btn_puente.grab_focus)
	pestana_dibujo.cambio.connect(vista.queue_redraw)
	_refrescar()
	btn_puente.grab_focus()


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
	get_tree().change_scene_to_file(RECORRIDO)


func _al_cambiar_pestana(_pestana: int) -> void:
	vista.modo_dibujo = pestanas.get_current_tab_control() == pestana_dibujo


## Pone toda la pantalla al día con Juego.
func _refrescar() -> void:
	pestana_melon.refrescar()
	pestana_accesorios.refrescar()
	pestana_mejoras.refrescar()
	lbl_balance.text = "Aplausos: %d" % Juego.aplausos
	lbl_record.text = "Récord: %d m" % int(Juego.record_m)
	lbl_error.text = Juego.guardado_error
	lbl_error.tooltip_text = Juego.guardado_error
	lbl_nombre_vista.text = ComunTaller.nombre_melon()
	lbl_carisma.text = "%s   ·   Carisma %d" % [Config.tamanos[Juego.tamano]["nombre"], Juego.carisma_de(Juego.accesorios)]
	vista.queue_redraw()
