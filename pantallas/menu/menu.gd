extends Node2D
## Menú principal en la bajada de Xallitic: la cámara baja desde el cielo hasta la
## calle, luego cae el título y aparece el botón de jugar.
##
## Escena: pantallas/menu/menu.tscn. Reutiliza el mundo del recorrido:
##   Paisaje                 mundo/paisaje/paisaje.tscn: cielo, volcán, cerros y ciudad
##   CieloAlto               cielo_menu.gd: tapa el fondo arriba y pone nubes que se cruzan
##   Mundo/BajadaXallitic    la misma calle empedrada con casas y público
##   Mundo/Melones           melones_menu.gd: melones que ruedan y explotan con clic
##   Camara                  la mueve este script
##   Interfaz/Centro         Titulo (titulo_melonazo.gd) y BtnJugar
##
## Cualquier clic o tecla durante la bajada la salta.

<<<<<<< HEAD
const TALLER := "res://pantallas/taller/taller.tscn"
=======
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
const DURACION_BAJADA := 3.6
const ALTURA_INICIAL := 3200.0         # px de mundo por encima del encuadre final
## Alto del mundo que cabe en pantalla en el encuadre final; el zoom sale de aquí,
## así una ventana más ancha muestra más calle y no recorta abajo.
const ALTO_VISTA := 1100.0
## Dónde queda el borde derecho de la pantalla respecto al final de la bajada
## (Config.bajada_fin). Negativo: un poco antes, porque después de la orilla del
## trampolín no hay calle ni casas.
const MARGEN_DERECHO := -30.0
## Espacio bajo el punto más hondo de la calle: el ancho de la calle y la fila de
## público de enfrente.
const MARGEN_ABAJO := 190.0

@onready var camara: Camera2D = %Camara
@onready var melones: MelonesMenu = %Melones
@onready var titulo: TituloMelonazo = %Titulo
@onready var btn_jugar: Button = %BtnJugar

var _bajada: Tween


func _ready() -> void:
	Musica.tocar(Musica.MENU)
	Animacion._al_agregar_nodo(btn_jugar)
	# Aquí el clic se reproduce al activar Jugar, incluido su atajo Enter.
	btn_jugar.button_down.disconnect(Animacion._sonar_click.bind(btn_jugar))
	$Paisaje.configurar(camara)
	%BajadaXallitic.abrir_salida()
	melones.calle = %BajadaXallitic
	# Salen volando del trampolín y se quitan ya fuera de cuadro.
	melones.x_salida = Config.bajada_fin.x + 600.0
	melones.set_process_unhandled_input(false)
	melones.precalentar()
	var destino := _encuadre()
	%CieloAlto.configurar(camara, destino.y, ALTURA_INICIAL)
	camara.position = destino - Vector2(0, ALTURA_INICIAL)
	camara.reset_smoothing()
	titulo.modulate.a = 0.0
	btn_jugar.modulate.a = 0.0
	btn_jugar.disabled = true
	# La carga de la escena tarda; el primer cuadro trae un delta enorme que se
	# comería la bajada. Se empieza un par de cuadros después.
	await get_tree().process_frame
	await get_tree().process_frame
	_bajada = create_tween()
	_bajada.tween_property(camara, "position", destino, DURACION_BAJADA) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bajada.tween_callback(_mostrar_menu)
	get_viewport().size_changed.connect(_al_cambiar_tamano)


## Ajusta el zoom al alto de la ventana y devuelve el centro de la cámara que deja
## el final de la bajada a la derecha y la parte más honda de la calle a la vista.
func _encuadre() -> Vector2:
	var vista := get_viewport_rect().size
	camara.zoom = Vector2.ONE * vista.y / ALTO_VISTA
	var mitad := vista / camara.zoom / 2.0
	var derecha := Config.bajada_fin.x + MARGEN_DERECHO
	var calle: Tramo = %BajadaXallitic
	var hondo := -INF
	var x := derecha - mitad.x * 2.0
	while x <= derecha:
		hondo = maxf(hondo, calle.altura(x))
		x += 20.0
	return Vector2(derecha - mitad.x, hondo + MARGEN_ABAJO - mitad.y)


func _al_cambiar_tamano() -> void:
	var destino := _encuadre()
	if not (_bajada and _bajada.is_running()):
		camara.position = destino


## Salta la bajada si el jugador pulsa algo mientras la cámara todavía va cayendo.
func _input(event: InputEvent) -> void:
	if not _bajada or not _bajada.is_running():
		return
	var pulso := (event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton) \
		and event.is_pressed()
	if pulso:
		_bajada.custom_step(DURACION_BAJADA)
		get_viewport().set_input_as_handled()


func _mostrar_menu() -> void:
	melones.set_process_unhandled_input(true)
	Animacion.sellar(titulo)
	var vaiven := titulo.create_tween().set_loops()
	vaiven.tween_property(titulo, "rotation_degrees", 2.0, 1.8).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(titulo, "rotation_degrees", -2.0, 1.8).set_trans(Tween.TRANS_SINE)
	btn_jugar.disabled = false
	Animacion.aparecer(btn_jugar, 0.3, 0.5).finished.connect(Animacion.latir.bind(btn_jugar))
	btn_jugar.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirmar") and not btn_jugar.disabled:
		_jugar()


## Conectado a BtnJugar.pressed en la escena.
func _jugar() -> void:
	Animacion._sonar_click(btn_jugar)
	btn_jugar.disabled = true
<<<<<<< HEAD
	Animacion.cambiar_escena(TALLER)
=======
	Animacion.cambiar_escena(Rutas.TALLER)
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
