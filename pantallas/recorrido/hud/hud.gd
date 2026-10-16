class_name HUD
extends CanvasLayer
## Interfaz del recorrido (nodo "Interfaz" de recorrido.tscn) y menú de pausa.
##
## Escena: pantallas/recorrido/hud/hud.tscn. Es un CanvasLayer, así queda fijo
## en pantalla y no se mueve con la cámara. Tiene process_mode ALWAYS para
## seguir respondiendo con el juego en pausa.
##
##   Datos         nombre y récord, distancia grande, barra de resistencia,
##                 rayos de impulso y fichas de aplausos, carisma y poderes
##   Lugar         postal actual, barra hasta la siguiente y cuánto falta
##   Equipo        tres SlotAccesorio (teclas 1, 2 y 3) y el botón de pausa
##   Vuelo         fichas de altura y papalotes usados
##   Efectos       una ficha por efecto activo del melón, con sus segundos
##   Lanzamiento   barra de fuerza con la zona perfecta marcada
##   Aviso         tecla dibujada (%Tecla) y qué hace ahora (%Indicacion)
##   Ayuda         teclas del juego; solo antes de lanzar
##   Pausa         menú de pausa con controles y créditos del fondo
##
## No guarda estado de la carrera: Recorrido llama a actualizar(self) cada cuadro.

const ESCENA_TALLER := "res://pantallas/taller/taller.tscn"
const ARTE: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
const CONTROLES := [["A  D", "Mover y girar"], ["Espacio", "Saltar y rebotar"], ["E", "Papalote o empujón"],
	["1  2  3", "Usar accesorios"], ["Esc", "Pausa"]]
const AMARILLO := Color("ffc83d")
const VERDE := Color("6cc35f")
const ROJO := Color("e8553f")

@onready var distancia: Label = %Distancia
@onready var resistencia: ProgressBar = %Resistencia
@onready var impulsos: Pips = %Impulsos
@onready var ficha_aplausos: Ficha = %Aplausos
@onready var ficha_carisma: Ficha = %Carisma
@onready var ficha_poderes: Ficha = %Poderes
@onready var lugar: Control = %Lugar
@onready var efectos: HBoxContainer = %Efectos
@onready var aviso: Control = %Aviso
@onready var tecla: Label = %Tecla
@onready var indicacion: Label = %Indicacion
@onready var vuelo: Control = %Vuelo
@onready var lanzamiento: VBoxContainer = %Lanzamiento
@onready var medidor: ProgressBar = %Fuerza
@onready var ayuda: HBoxContainer = %Ayuda
@onready var pausa: Control = %Pausa
@onready var slots: Array[SlotAccesorio] = [%Slot1, %Slot2, %Slot3]

var _slots_mostrados: Array = []       # copia de melon.slots para redibujar solo si cambia
var _relleno_fuerza: StyleBoxFlat
var _relleno_resistencia: StyleBoxFlat
var _resistencia_previa := -1.0        # se queda atrás tras un daño para marcar lo perdido
var _ultimos := {}                     # valor mostrado por contador, para animar al cambiar
var _postal_mostrada := ""


func _ready() -> void:
	%Volver.get_parent().add_child(ARTE.crear_creditos_paisaje())
	medidor.draw.connect(_dibujar_zona_perfecta)
	_relleno_fuerza = (medidor.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
	medidor.add_theme_stylebox_override("fill", _relleno_fuerza)
	resistencia.draw.connect(_dibujar_resistencia)
	_relleno_resistencia = (resistencia.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
	resistencia.add_theme_stylebox_override("fill", _relleno_resistencia)
	for parte in [["A", "D"], ["Mover"], ["Espacio"], ["Saltar"], ["E"], ["Papalote"], ["1", "2", "3"], ["Accesorios"]]:
		_agregar_ayuda(parte)
	for control in CONTROLES:
		%Controles.add_child(Iconos.tecla(control[0]))
		var l := Label.new()
		l.text = control[1]
		%Controles.add_child(l)


## Teclas sueltas (["A", "D"]) o una palabra de explicación (["Mover"]).
func _agregar_ayuda(parte: Array) -> void:
	if parte.size() == 1 and parte[0].length() > 3 and parte[0] != "Espacio":
		var l := Label.new()
		l.theme_type_variation = &"TextoHUD"
		l.add_theme_font_size_override("font_size", 15)
		l.text = parte[0] + "   "
		ayuda.add_child(l)
		return
	for t in parte:
		ayuda.add_child(Iconos.tecla(t, 14))


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
		Animacion.aparecer(%Columna, 0.0, 0.7)
	else:
		%BotonPausa.release_focus()


## Abandona la carrera sin cobrar recompensas.
func _volver() -> void:
	get_tree().paused = false
	Animacion.cambiar_escena(ESCENA_TALLER)


# --- Actualización -----------------------------------------------------------

## Refresca todo el HUD con el estado actual de la carrera.
func actualizar(r: Recorrido) -> void:
	var melon := r.melon
	var metros := maxf(0.0, r.mejor_x) / Config.px_por_metro
	distancia.text = "%d m" % int(metros)
	%Nombre.text = "%s · Récord %d m" % [Juego.nombre_melon, int(Juego.record_m)]
	_actualizar_resistencia(melon)
	impulsos.total = maxi(melon.rebotes, Juego.rebotes_max())
	_contador("impulsos", impulsos, melon.rebotes)
	_contador("aplausos", ficha_aplausos, r.recolectados * Config.valor_aplauso_suelto)
	_contador("carisma", ficha_carisma, melon.carisma())
	_contador("poderes", ficha_poderes, r.poderes_recogidos)
	_actualizar_equipo(melon)
	_actualizar_lugar(metros, r.altura_m, r.altura_max_m)
	_actualizar_efectos(melon)
	lanzamiento.visible = r.fase == Recorrido.Fase.FUERZA
	ayuda.visible = r.fase == Recorrido.Fase.ANGULO or r.fase == Recorrido.Fase.FUERZA
	medidor.value = r.fuerza * 100.0
	var en_zona := r.fuerza >= Config.zona_perfecta.x and r.fuerza <= Config.zona_perfecta.y
	_relleno_fuerza.bg_color = VERDE if en_zona else AMARILLO.lerp(Color("e8553f"), r.fuerza)
	vuelo.visible = r.fase >= Recorrido.Fase.RECORRIDO
	%Altura.texto = "%d m" % int(r.altura_m)
	_contador("papalotes", %Papalotes, r.papalotes_usados)
	_actualizar_indicacion(r)


## Pone el valor en un contador (Ficha o Pips) y le da un salto si cambió.
func _contador(clave: String, nodo: Control, valor: int) -> void:
	if nodo is Ficha:
		(nodo as Ficha).texto = str(valor)
	else:
		(nodo as Pips).llenos = valor
	if _ultimos.has(clave) and _ultimos[clave] != valor:
		Animacion.rebotar(nodo, 1.25 if valor > _ultimos[clave] else 1.12)
	_ultimos[clave] = valor


## Barra verde que pasa a amarillo y rojo al bajar. Lo recién perdido se queda
## un momento en claro y se va vaciando.
func _actualizar_resistencia(melon: Melon) -> void:
	var valor := maxf(0.0, melon.resistencia)
	resistencia.max_value = melon.resistencia_max
	if _resistencia_previa < 0.0 or valor > _resistencia_previa:
		_resistencia_previa = valor
	elif valor < resistencia.value:
		Animacion.rebotar(resistencia, 1.12 if resistencia.value - valor >= 1.0 else 1.05)
	resistencia.value = valor
	_resistencia_previa = move_toward(_resistencia_previa, valor, get_process_delta_time() * 1.5)
	var fraccion := valor / maxf(0.01, melon.resistencia_max)
	_relleno_resistencia.bg_color = ROJO.lerp(AMARILLO, fraccion * 2.0) if fraccion < 0.5 else AMARILLO.lerp(VERDE, fraccion * 2.0 - 1.0)
	resistencia.queue_redraw()


func _actualizar_equipo(melon: Melon) -> void:
	if _slots_mostrados == melon.slots:
		return
	_slots_mostrados = melon.slots.duplicate()
	for i in slots.size():
		slots[i].mostrar(_slots_mostrados[i])


## Postal actual, barra de avance hasta la siguiente y metros que faltan.
func _actualizar_lugar(metros: float, altura: float, altura_max: float) -> void:
	var actual := "Barrio de Xallitic"
	var desde := 0.0
	var siguiente := "¡Colección de postales completa!"
	var avance := 1.0
	for postal in Config.postales:
		if metros >= float(postal["metros"]):
			actual = postal["nombre"]
			desde = float(postal["metros"])
		else:
			var hasta := float(postal["metros"])
			siguiente = "Siguiente: %s · %d m" % [postal["nombre"], int(hasta) - int(metros)]
			avance = (metros - desde) / maxf(1.0, hasta - desde)
			break
	if altura >= Config.zonas_cielo[0]["metros"]:
		siguiente = "Altura máxima: %d m · Bono +%d" % [int(altura_max), int(altura_max * Config.aplausos_por_metro_altura)]
		avance = 1.0
		for zona in Config.zonas_cielo:
			if altura >= zona["metros"]:
				actual = zona["nombre"]
				desde = zona["metros"]
			else:
				siguiente = "Sube a %d m · %s" % [int(zona["metros"]), zona["nombre"]]
				avance = (altura - desde) / (zona["metros"] - desde)
				break
	%LugarActual.text = actual
	%Siguiente.text = siguiente
	%Ruta.value = avance
	if actual != _postal_mostrada:
		if _postal_mostrada != "":
			Animacion.rebotar(lugar, 1.12)
		_postal_mostrada = actual


## Una ficha por efecto activo: "Café 1.2 s". Reutiliza las fichas creadas.
func _actualizar_efectos(melon: Melon) -> void:
	var lista := melon.efectos_lista()
	while efectos.get_child_count() < lista.size():
		var f := Ficha.crear(Iconos.PODER, "", true, 16)
		f.lado_icono = 20.0
		efectos.add_child(f)
		Animacion.aparecer(f, 0.0, 0.5)
	for i in efectos.get_child_count():
		var f: Ficha = efectos.get_child(i)
		f.visible = i < lista.size()
		if f.visible:
			f.texto = "%s %.1f s" % [lista[i][0], lista[i][1]]


## Tecla y texto de ayuda según la fase y lo que el melón puede hacer ahora.
## El aviso late cuando hay que pulsar a tiempo (rebote o papalote).
func _actualizar_indicacion(r: Recorrido) -> void:
	var melon := r.melon
	var urgente := false
	aviso.visible = true
	tecla.visible = true
	match r.fase:
		Recorrido.Fase.ANGULO:
			_indicar("Espacio", "Fijar el ángulo · %d°" % int(r.angulo))
		Recorrido.Fase.FUERZA:
			_indicar("Espacio", "¡Lanzar! · Fuerza %d%%" % int(r.fuerza * 100))
			urgente = r.fuerza >= Config.zona_perfecta.x
		Recorrido.Fase.FIN:
			_indicar("", r.texto_fin)
			tecla.visible = false
		Recorrido.Fase.RECORRIDO:
			if is_instance_valid(r.papalote_cercano) and not r.papalote_cercano.usado:
				_indicar("E", "%s: impulso y escudo" % r.papalote_cercano.nombre())
				urgente = true
			elif melon.rebotes <= 0:
				_indicar("E", "Busca papalotes o corrientes")
			elif melon.t_bloqueo > 0.0:
				aviso.visible = false
			elif not melon.en_suelo and melon.t_impacto >= 0.0 and melon.t_impacto <= Config.ventana_rebote:
				_indicar("Espacio", "¡Rebote con impulso!")
				urgente = true
			else:
				_indicar("Espacio", "Saltar" if melon.en_suelo else "Salto aéreo")
	aviso.pivot_offset = aviso.size * 0.5
	var pulso := 1.0 + 0.06 * absf(sin(Time.get_ticks_msec() * 0.012)) if urgente else 1.0
	aviso.scale = Vector2.ONE * pulso
	indicacion.add_theme_color_override("font_color", AMARILLO if urgente else Color("fff9ec"))


func _indicar(p_tecla: String, texto: String) -> void:
	tecla.text = p_tecla
	indicacion.text = texto


## Lo recién perdido en claro y una marca por cada golpe completo.
func _dibujar_resistencia() -> void:
	var m := 4.0
	var ancho := resistencia.size.x - m * 2.0
	var alto := resistencia.size.y - m * 2.0
	var por_golpe := ancho / maxf(1.0, resistencia.max_value)
	if _resistencia_previa > resistencia.value:
		var desde := m + resistencia.value * por_golpe
		resistencia.draw_rect(Rect2(desde, m, (_resistencia_previa - resistencia.value) * por_golpe, alto), Color(1, 0.976, 0.925, 0.7))
	for i in range(1, int(ceilf(resistencia.max_value))):
		var x := m + i * por_golpe
		resistencia.draw_line(Vector2(x, m), Vector2(x, m + alto), Color(0.09, 0.18, 0.165, 0.6), 2.0)


## Franja verde en la barra de fuerza (Config.zona_perfecta) y marcas cada 10 %.
func _dibujar_zona_perfecta() -> void:
	var m := 5.0
	var ancho := medidor.size.x - m * 2.0
	var zona := Rect2(m + ancho * Config.zona_perfecta.x, 3, ancho * (Config.zona_perfecta.y - Config.zona_perfecta.x), medidor.size.y - 6)
	medidor.draw_rect(zona, Color(0.42, 0.76, 0.37, 0.35))
	medidor.draw_rect(zona, Color("fff9ec"), false, 2.0)
	for i in range(1, 10):
		var x := m + ancho * i * 0.1
		medidor.draw_line(Vector2(x, medidor.size.y - 12), Vector2(x, medidor.size.y - 5), Color(1, 1, 1, 0.5), 2.0)
