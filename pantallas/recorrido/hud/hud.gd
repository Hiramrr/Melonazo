class_name HUD
extends CanvasLayer
## Interfaz del recorrido (nodo "Interfaz" de recorrido.tscn) y menú de pausa.
##
## Escena: pantallas/recorrido/hud/hud.tscn. Es un CanvasLayer, así queda fijo
## en pantalla y no se mueve con la cámara. Tiene process_mode ALWAYS para
## seguir respondiendo con el juego en pausa.
##
##   Datos         nombre, distancia, resistencia, impulsos, carisma...
##   Equipo        tres SlotAccesorio (teclas 1, 2 y 3)
##   Vuelo         altura y papalotes usados
##   Lugar         postal actual y la siguiente
##   Lanzamiento   barra de fuerza con la zona perfecta marcada
##   Indicacion    qué tecla pulsar ahora
##   Efectos       efectos activos del melón
##   Pausa         menú de pausa con créditos del fondo
##
## No guarda estado de la carrera: Recorrido llama a actualizar(self) cada cuadro.

const ESCENA_TALLER := "res://pantallas/taller/taller.tscn"
const ARTE: ArteXalapa = preload("res://recursos/arte_xalapa.tres")

@onready var distancia: Label = %Distancia
@onready var estado: Label = %Estado
@onready var lugar: Label = %Lugar
@onready var efectos: Label = %Efectos
@onready var indicacion: Label = %Indicacion
@onready var vuelo: Label = %Vuelo
@onready var lanzamiento: VBoxContainer = %Lanzamiento
@onready var medidor: ProgressBar = %Fuerza
@onready var pausa: Control = %Pausa
@onready var slots: Array[SlotAccesorio] = [%Slot1, %Slot2, %Slot3]

var _slots_mostrados: Array = []       # copia de melon.slots para redibujar solo si cambia


func _ready() -> void:
	%Volver.get_parent().add_child(ARTE.crear_creditos_paisaje())
	medidor.draw.connect(_dibujar_zona_perfecta)


# --- Pausa -------------------------------------------------------------------

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


## Abandona la carrera sin cobrar recompensas.
func _volver() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_TALLER)


# --- Actualización -----------------------------------------------------------

## Refresca todos los textos con el estado actual de la carrera.
func actualizar(r: Recorrido) -> void:
	var melon := r.melon
	var metros := maxf(0.0, r.mejor_x) / Config.px_por_metro
	distancia.text = "%d m" % int(metros)
	%Nombre.text = "%s · Récord %d m" % [Juego.nombre_melon, int(Juego.record_m)]
	estado.text = "Resistencia %d/%d   ·   Impulsos %d\nCarisma %d   ·   Aplausos %d   ·   Poderes %d" % [
		maxi(0, melon.resistencia), melon.resistencia_max, melon.rebotes, melon.carisma(),
		r.recolectados * Config.valor_aplauso_suelto, r.poderes_recogidos]
	_actualizar_equipo(melon)
	lugar.text = _texto_lugar(metros)
	efectos.text = melon.efectos_activos()
	efectos.visible = not efectos.text.is_empty()
	lanzamiento.visible = r.fase == Recorrido.Fase.ANGULO or r.fase == Recorrido.Fase.FUERZA
	medidor.value = r.fuerza * 100.0
	vuelo.visible = r.fase >= Recorrido.Fase.RECORRIDO
	vuelo.text = "Altura %d m · Papalotes %d\nEspacio usa 1 impulso · E recarga" % [int(r.altura_m), r.papalotes_usados]
	_actualizar_indicacion(r)


func _actualizar_equipo(melon: Melon) -> void:
	if _slots_mostrados == melon.slots:
		return
	_slots_mostrados = melon.slots.duplicate()
	for i in slots.size():
		slots[i].mostrar(_slots_mostrados[i])


## "Lugar actual" y "Siguiente: X · N m" según la distancia.
func _texto_lugar(metros: float) -> String:
	var actual := "Barrio de Xallitic"
	var siguiente := "Colección de postales completa"
	for postal in Config.postales:
		if metros >= float(postal["metros"]):
			actual = postal["nombre"]
		else:
			siguiente = "Siguiente: %s · %d m" % [postal["nombre"], int(postal["metros"]) - int(metros)]
			break
	return "%s\n%s" % [actual, siguiente]


## Texto de ayuda según la fase y lo que el melón puede hacer en este momento.
func _actualizar_indicacion(r: Recorrido) -> void:
	var melon := r.melon
	indicacion.visible = true
	match r.fase:
		Recorrido.Fase.ANGULO:
			indicacion.text = "Espacio para fijar el ángulo · %d°" % int(r.angulo)
		Recorrido.Fase.FUERZA:
			indicacion.text = "Espacio para lanzar · Fuerza %d%%" % int(r.fuerza * 100)
		Recorrido.Fase.FIN:
			indicacion.text = r.texto_fin
		Recorrido.Fase.RECORRIDO:
			if is_instance_valid(r.papalote_cercano) and not r.papalote_cercano.usado:
				indicacion.text = "E · Papalote: impulso y recarga"
			elif melon.rebotes <= 0:
				indicacion.text = "Acércate a un papalote y pulsa E"
			elif melon.t_bloqueo > 0.0:
				indicacion.visible = false
			elif not melon.en_suelo and melon.t_impacto >= 0.0 and melon.t_impacto <= Config.ventana_rebote:
				indicacion.text = "Espacio · Rebote con impulso"
			else:
				indicacion.text = "Espacio · Saltar" if melon.en_suelo else "Espacio · Salto aéreo"


## Franja verde en la barra de fuerza (Config.zona_perfecta).
func _dibujar_zona_perfecta() -> void:
	var zona := Rect2(medidor.size.x * Config.zona_perfecta.x, 1,
		medidor.size.x * (Config.zona_perfecta.y - Config.zona_perfecta.x), medidor.size.y - 2)
	medidor.draw_rect(zona, Color("7eae73"))
	medidor.draw_rect(zona, Color("fff5d9"), false, 2.0)
