class_name HUD
extends CanvasLayer
## Interfaz del recorrido (nodo "Interfaz" de recorrido.tscn) y menú de pausa.
##
## Escena: pantallas/recorrido/hud/hud.tscn. Es un CanvasLayer, así queda fijo
## en pantalla y no se mueve con la cámara. Tiene process_mode ALWAYS para
## seguir respondiendo con el juego en pausa.
##
##   Datos         nombre y récord, distancia grande, barra de resistencia,
##                 rayos de impulso y fichas de aplausos, carisma, poderes
##                 y Salsas Valentina que quedan
##   Lugar         postal actual, barra hasta la siguiente y cuánto falta
##   Equipo        tres SlotAccesorio (teclas 1, 2 y 3) y el botón de pausa
##   Vuelo         fichas de altura y papalotes usados
##   Efectos       una ficha por efecto activo del melón, con sus segundos
##   Lanzamiento   barra de fuerza con la zona perfecta marcada
##   Aviso         tecla dibujada (%Tecla) y qué hace ahora (%Indicacion)
##   Ayuda         teclas del juego; solo en los primeros metros tras el trampolín
##   Pausa         menú de pausa con controles y créditos del fondo
##
## Recorrido llama a actualizar(self) cada cuadro. El HUD cuenta el tiempo de
## la elección de Valentina mientras la carrera está en pausa.

signal valentina_elegida(usar: bool)

const ESCENA_TALLER := "res://pantallas/taller/taller.tscn"
const ARTE: ArteXalapa = preload("res://recursos/arte_xalapa.tres")
const CONTROLES := [["A  D", "Mover y girar"], ["Espacio", "Saltar y rebotar"], ["E", "Papalote o empujón"],
	["S / Abajo", "Slam sobre otro melón"], ["1  2  3", "Usar accesorios"], ["Esc", "Pausa"]]

@onready var distancia: Label = %Distancia
@onready var resistencia: ProgressBar = %Resistencia
@onready var impulsos: Pips = %Impulsos
@onready var ficha_aplausos: Ficha = %Aplausos
@onready var ficha_carisma: Ficha = %Carisma
@onready var ficha_poderes: Ficha = %Poderes
@onready var ficha_valentinas: Ficha = %Valentinas
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
@onready var revivir: Control = %Revivir
@onready var slots: Array[SlotAccesorio] = [%Slot1, %Slot2, %Slot3]

var _slots_mostrados: Array = []       # copia de melon.slots para redibujar solo si cambia
var _relleno_fuerza: StyleBoxTexture
var _relleno_resistencia: StyleBoxTexture
var _resistencia_previa := -1.0        # se queda atrás tras un daño para marcar lo perdido
var _ultimos := {}                     # valor mostrado por contador, para animar al cambiar
var _postal_mostrada := ""
var _t_valentina := 0.0


func _ready() -> void:
	%Volver.get_parent().add_child(ARTE.crear_creditos_paisaje())
	medidor.draw.connect(_dibujar_zona_perfecta)
	_relleno_fuerza = (medidor.get_theme_stylebox("fill") as StyleBoxTexture).duplicate()
	medidor.add_theme_stylebox_override("fill", _relleno_fuerza)
	resistencia.draw.connect(_dibujar_resistencia)
	_relleno_resistencia = (resistencia.get_theme_stylebox("fill") as StyleBoxTexture).duplicate()
	resistencia.add_theme_stylebox_override("fill", _relleno_resistencia)
	for parte in [["A", "D"], ["Mover"], ["Espacio"], ["Saltar"], ["S"], ["Slam"], ["E"], ["Papalote"], ["1", "2", "3"], ["Accesorios"]]:
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
		l.theme_type_variation = &"AyudaHUD"
		l.text = parte[0] + "   "
		ayuda.add_child(l)
		return
	for t in parte:
		ayuda.add_child(Iconos.tecla(t, &"TeclaAyuda"))


# --- Pausa -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausar") and not event.is_echo():
		if revivir.visible:
			if event.is_action_pressed("ui_cancel"):
				_elegir_valentina(false)
		else:
			_alternar_pausa()
		get_viewport().set_input_as_handled()


func _alternar_pausa() -> void:
	if revivir.visible:
		return
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


# --- Salsa Valentina ---------------------------------------------------------

func preguntar_valentina() -> void:
	_t_valentina = Config.valentina_espera
	%ExistenciasValentina.text = "Salsas disponibles: %d · Usas 1 al revivir" % Juego.valentinas
	revivir.show()
	# Espacio también sirve para saltar; el foco evita gastar una salsa por accidente.
	%TerminarIntento.grab_focus()
	_process(0.0)


func _process(delta: float) -> void:
	if not revivir.visible:
		return
	_t_valentina = maxf(0.0, _t_valentina - delta)
	%CuentaValentina.text = "El intento termina en %d s" % ceili(_t_valentina)
	if _t_valentina <= 0.0:
		_elegir_valentina(false)


func _elegir_valentina(usar: bool) -> void:
	if not revivir.visible:
		return
	revivir.hide()
	valentina_elegida.emit(usar)


# --- Actualización -----------------------------------------------------------

## Refresca todo el HUD con el estado actual de la carrera.
func actualizar(r: Recorrido) -> void:
	var melon := r.melon
	var metros := maxf(0.0, r.mejor_x) / Config.px_por_metro
	distancia.text = "%d m" % int(metros)
	%Velocidad.text = "%d m/s" % int(maxf(0.0, melon.linear_velocity.x) / Config.px_por_metro)
	var reto := Juego.reto_actual()
	%Reto.visible = not reto.is_empty()
	if not reto.is_empty():
		%Reto.text = "Reto %d/%d · %s\n%d/%d · +%d aplausos" % [Juego.retos_completados + 1, Config.retos.size(), reto["texto"], Juego.progreso_reto(r.estadisticas()), reto["meta"], reto["premio"]]
	%Nombre.text = "%s · Récord %d m" % [Juego.nombre_melon, int(Juego.record_m)]
	_actualizar_resistencia(melon)
	impulsos.total = maxi(melon.rebotes, Juego.rebotes_max())
	_contador("impulsos", impulsos, melon.rebotes)
	_contador("aplausos", ficha_aplausos, r.recolectados * Config.valor_aplauso_suelto)
	_contador("carisma", ficha_carisma, melon.carisma())
	_contador("poderes", ficha_poderes, r.poderes_recogidos)
	_contador("valentinas", ficha_valentinas, Juego.valentinas)
	_actualizar_equipo(melon)
	_actualizar_lugar(metros)
	_actualizar_efectos(melon)
	lanzamiento.visible = r.fase == Recorrido.Fase.FUERZA
	ayuda.visible = r.fase == Recorrido.Fase.RECORRIDO and metros < Config.ayuda_hasta_m
	medidor.value = r.fuerza * 100.0
	var en_zona := r.fuerza >= Config.zona_perfecta.x and r.fuerza <= Config.zona_perfecta.y
	_relleno_fuerza.modulate_color = medidor.get_theme_color("perfecta") if en_zona else medidor.get_theme_color("inicio").lerp(medidor.get_theme_color("fin"), r.fuerza)
	vuelo.visible = r.fase >= Recorrido.Fase.RECORRIDO
	%Altura.texto = "%d m" % int(r.altura_m)
	%Altura.tooltip_text = "Altura máxima %d m · Bono +%d aplausos" % [int(r.altura_max_m), int(r.altura_max_m * Config.aplausos_por_metro_altura)]
	_contador("papalotes", %Papalotes, r.papalotes_usados)
	_actualizar_indicacion(r, metros)


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
	var media := resistencia.get_theme_color("media")
	_relleno_resistencia.modulate_color = resistencia.get_theme_color("baja").lerp(media, fraccion * 2.0) if fraccion < 0.5 else media.lerp(resistencia.get_theme_color("alta"), fraccion * 2.0 - 1.0)
	resistencia.queue_redraw()


func _actualizar_equipo(melon: Melon) -> void:
	if _slots_mostrados == melon.slots:
		return
	_slots_mostrados = melon.slots.duplicate()
	for i in slots.size():
		slots[i].mostrar(_slots_mostrados[i])


## La barra siempre mide el viaje completo, incluso durante los objetivos de altura.
func _actualizar_lugar(metros: float) -> void:
	var actual := "Barrio de Xallitic"
	var siguiente := "¡Llegaste a la meta!"
	var visitados := 0
	for postal in Config.postales:
		if metros >= float(postal["metros"]):
			actual = postal.get("nombre_corto", postal["nombre"])
			visitados += 1
		else:
			var hasta := float(postal["metros"])
			siguiente = "Siguiente: %s · %d m" % [postal.get("nombre_corto", postal["nombre"]), ceili(hasta - metros)]
			break
	var etapa := 0
	for i in Config.etapas_ruta.size():
		if metros >= float(Config.etapas_ruta[i]["metros"]):
			etapa = i
	%Etapa.text = "%d/%d · %s" % [etapa + 1, Config.etapas_ruta.size(), Config.etapas_ruta[etapa]["nombre"]]
	%Destino.text = "¡Llegaste al CUCosta!" if metros >= Config.meta_m else "Meta CUCosta · faltan %d m" % ceili(maxf(0.0, Config.meta_m - metros))
	%Destino.tooltip_text = "%s\n%s\nXalapa a Puerto Vallarta · %d m de juego" % [Config.nombre_meta, Config.institucion_meta, int(Config.meta_m)]
	%LugarActual.text = actual
	%Siguiente.text = siguiente
	%Ruta.value = clampf(metros / Config.meta_m, 0.0, 1.0)
	%Ruta.tooltip_text = "%d de %d lugares · %d%% del viaje" % [visitados, Config.postales.size(), int(%Ruta.value * 100.0)]
	if actual != _postal_mostrada:
		if _postal_mostrada != "":
			Animacion.rebotar(lugar, 1.12)
		_postal_mostrada = actual


## Una ficha por efecto activo: "Café 1.2 s". Reutiliza las fichas creadas.
func _actualizar_efectos(melon: Melon) -> void:
	var lista := melon.efectos_lista()
	while efectos.get_child_count() < lista.size():
		var f := Ficha.crear(Iconos.PODER, "", true, &"ContadorEfecto")
		f.lado_icono = 20.0
		efectos.add_child(f)
		Animacion.aparecer(f, 0.0, 0.5)
	for i in efectos.get_child_count():
		var f: Ficha = efectos.get_child(i)
		f.visible = i < lista.size()
		if f.visible:
			f.texto = "%s %.1f s" % [lista[i][0], lista[i][1]]


## Tecla y texto de ayuda según la fase y lo que el melón puede hacer ahora.
## El aviso late cuando hay que pulsar a tiempo (rebote o papalote). Saltar a secas
## solo se recuerda en los primeros metros: después la parte baja queda despejada.
func _actualizar_indicacion(r: Recorrido, metros := 0.0) -> void:
	var melon := r.melon
	var urgente := false
	aviso.visible = true
	tecla.visible = true
	match r.fase:
		Recorrido.Fase.FUERZA:
			_indicar("Espacio", "Soltar · Potencia %d%%" % int(r.fuerza * 100))
			urgente = r.fuerza >= Config.zona_perfecta.x
		Recorrido.Fase.BAJADA:
			_indicar("", "Bajando Xallitic · Controles después del trampolín")
			tecla.visible = false
		Recorrido.Fase.FIN:
			_indicar("", r.texto_fin)
			tecla.visible = false
		Recorrido.Fase.REVIVIR:
			aviso.visible = false
		Recorrido.Fase.RECORRIDO:
			if melon.slam_activo:
				_indicar("", "¡Apunta a un melón! El suelo frena")
				tecla.visible = false
			elif _hay_melon_debajo(r) and melon.t_slam <= 0.0:
				_indicar("S", "¡Slam sobre el melón!")
				urgente = true
			elif is_instance_valid(r.papalote_cercano) and not r.papalote_cercano.usado:
				_indicar("E", "%s: impulso y escudo" % r.papalote_cercano.nombre())
				urgente = true
			elif is_instance_valid(r.persona_cercana) and not r.persona_cercana.usado:
				_indicar("E", "¡Pide un empujón!")
				urgente = true
			elif not melon.puede_saltar():
				_indicar("", "Busca papalotes, corrientes o café")
				tecla.visible = false
			elif melon.t_bloqueo > 0.0:
				aviso.visible = false
			elif not melon.en_suelo and melon.t_impacto >= 0.0 and melon.t_impacto <= Config.tolerancia_rebote:
				_indicar("Espacio", "¡Rebote con impulso!" if melon.t_impacto <= Config.ventana_rebote else "Prepara el rebote")
				urgente = true
			elif metros < Config.ayuda_hasta_m:
				_indicar("Espacio", "Saltar" if melon.en_suelo else "Salto aéreo")
			else:
				aviso.visible = false
	aviso.pivot_offset = aviso.size * 0.5
	var pulso := 1.0 + 0.06 * absf(sin(Time.get_ticks_msec() * 0.012)) if urgente else 1.0
	aviso.scale = Vector2.ONE * pulso
	indicacion.theme_type_variation = &"IndicacionUrgente" if urgente else &"IndicacionHUD"


func _hay_melon_debajo(r: Recorrido) -> bool:
	# Con holgura: solo avisa cuando la corrección del picado sobra para acertar.
	return not r.melon.en_suelo and r.terreno.objetivo_slam(r.melon, Config.slam_confianza_aviso) != null


func _indicar(p_tecla: String, texto: String) -> void:
	tecla.text = p_tecla
	indicacion.text = texto


## Lo recién perdido en claro y una marca por cada golpe completo.
func _dibujar_resistencia() -> void:
	var m := resistencia.get_theme_stylebox("background").get_margin(SIDE_LEFT)
	var ancho := resistencia.size.x - m * 2.0
	var alto := resistencia.size.y - m * 2.0
	var por_golpe := ancho / maxf(1.0, resistencia.max_value)
	if _resistencia_previa > resistencia.value:
		var desde := m + resistencia.value * por_golpe
		Sprites.rectangulo(resistencia, Rect2(desde, m, (_resistencia_previa - resistencia.value) * por_golpe, alto), resistencia.get_theme_color("perdida"))
	for i in range(1, int(ceilf(resistencia.max_value))):
		var x := m + i * por_golpe
		Sprites.rectangulo(resistencia, Rect2(x - 1, m, 2, alto), resistencia.get_theme_color("marca"))


## Franja verde en la barra de fuerza (Config.zona_perfecta) y marcas cada 10 %.
func _dibujar_zona_perfecta() -> void:
	var m := medidor.get_theme_stylebox("background").get_margin(SIDE_LEFT)
	var ancho := medidor.size.x - m * 2.0
	var zona := Rect2(m + ancho * Config.zona_perfecta.x, 3, ancho * (Config.zona_perfecta.y - Config.zona_perfecta.x), medidor.size.y - 6)
	Sprites.rectangulo(medidor, zona, medidor.get_theme_color("zona"))
	Sprites.marco(medidor, zona, medidor.get_theme_color("borde_zona"))
	for i in range(1, 10):
		var x := m + ancho * i * 0.1
		Sprites.rectangulo(medidor, Rect2(x - 1, medidor.size.y - 12, 2, 7), medidor.get_theme_color("marca"))
