class_name Recorrido
extends Node2D
## Pantalla de la carrera: de la bajada de Xallitic hasta que
## la llegada al CUCosta, o hasta que el melón se detiene o se rompe.
## Coordina los nodos de recorrido.tscn:
##
##   Paisaje                  fondo con paralaje (mundo/paisaje/)
##   Mundo
##     BajadaXallitic         cuesta de salida que termina en un trampolín
##     LimiteDeSalida         pared invisible bajo el borde del trampolín
##     Terreno                GeneradorTerreno: crea los tramos como hijos
##     Melon                  el cuerpo físico (melon/melon.tscn)
##   Camara                   CamaraRecorrido: sigue al melón
##   Efectos                  EfectosRecorrido: flecha de puntería y avisos
##   Interfaz                 HUD (hud/hud.tscn): datos, lanzamiento y pausa
##
## Fases: FUERZA → BAJADA sin controles → RECORRIDO al salir del trampolín → FIN.
## REVIVIR pausa el recorrido hasta aceptar o rechazar la Salsa Valentina.
## Este script aplica las reglas de la carrera: lanzamiento, cuándo termina,
## efectos de obstáculos, pájaros, empujones del público, papalotes, poderes,
## la Salsa Valentina y postales. Lo que tocan los rivales lo resuelve GeneradorTerreno;
## aquí solo se muestran sus avisos (_al_avisar_rival).
## Al terminar registra el resultado en Juego y pasa a Resultados.

enum Fase { FUERZA, BAJADA, RECORRIDO, FIN, REVIVIR }

const ESCENA_RESULTADOS := "res://pantallas/resultados/resultados.tscn"
const RADIO_IMAN := 240.0              # la flor atrae aplausos a esta distancia
const VELOCIDAD_IMAN := 460.0
const MARGEN_INTERACCION := 400.0      # solo se revisan tramos a esta distancia del melón

@onready var melon: Melon = %Melon
@onready var terreno: GeneradorTerreno = %Terreno
@onready var camara: CamaraRecorrido = %Camara
@onready var efectos: EfectosRecorrido = %Efectos
@onready var hud: HUD = %Interfaz
@onready var bajada: BajadaXallitic = $Mundo/BajadaXallitic

var fase := Fase.FUERZA
var fuerza := 0.0                      # 0..1, elegida en la fase FUERZA
var _t_oscilacion := 0.0               # reloj de la barra de fuerza
var _velocidad_salida := 0.0
var _x_bajada := 0.0

# Marcador de la carrera
var mejor_x := 0.0                     # punto más lejano alcanzado (px)
var altura_m := 0.0                    # altura sobre el suelo, para el HUD
var altura_max_m := 0.0
var recolectados := 0                  # aplausos sueltos recogidos
var poderes_recogidos := 0
var valentinas_usadas := 0
var empujones := 0                     # cada empujón vale menos que el anterior
var papalotes_usados := 0
var postales_intento: Array = []       # ids de postales alcanzadas en esta carrera
var papalote_cercano: Papalote         # el que se activaría al pulsar E
var persona_cercana: Persona
var papalote_siguiente: Papalote       # orienta el vuelo aunque quede fuera de pantalla
var texto_fin := ""

var _t_sin_avance := 0.0
var _t_fin := 0.0                      # espera antes de pasar a Resultados
var _t_ayuda := 0.0
var maniobras := {"rebotes": 0, "slams": 0}
var _reto_anunciado := false


func _ready() -> void:
	hud.valentina_elegida.connect(_elegir_valentina)
	Musica.actualizar_recorrido(0.0)
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY, Config.gravedad)
	terreno.iniciar()
	terreno.preparar_corredores(bajada)
	melon.configurar(Juego.tamano, Juego.accesorios, Juego.resistencia_max(), Juego.rebotes_max(), Juego.velocidad_crucero())
	melon.maniobra.connect(_al_hacer_maniobra)
	var pendiente := bajada.pendiente(Config.bajada_inicio.x)
	var normal := Vector2(sin(pendiente), -cos(pendiente))
	_x_bajada = Config.bajada_inicio.x
	melon.position = Vector2(_x_bajada, bajada.altura(_x_bajada)) + normal * melon.radio
	mejor_x = melon.position.x
	$Paisaje.configurar(camara)
	camara.limit_left = floori(bajada.x0)
	camara.make_current()
	camara.actualizar(melon, false, 0.0)
	camara.reset_smoothing()
	hud.actualizar(self)


# --- Lanzamiento -------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("rebote") or event.is_echo():
		return
	if fase == Fase.FUERZA:
		_lanzar()


## Empuja al melón cuesta abajo con la fuerza elegida.
func _lanzar() -> void:
	if fase != Fase.FUERZA:
		return
	var perfecto := fuerza >= Config.zona_perfecta.x and fuerza <= Config.zona_perfecta.y
	var vel := lerpf(Config.lanz_vel_min, Config.lanz_vel_max, fuerza) * Juego.mult_fuerza()
	vel *= float(melon.datos()["mult_lanzamiento"])
	if perfecto:
		vel *= Config.bonus_perfecto
		efectos.avisar("¡Lanzamiento perfecto!", melon.global_position + Vector2(0, -60))
	bajada.abrir_salida()
	_velocidad_salida = vel
	for rival in terreno.melones:
		rival.soltar(vel)
	melon.en_suelo = true
	melon.controlable = false
	fase = Fase.BAJADA


# --- Ciclo por cuadro --------------------------------------------------------

func _process(delta: float) -> void:
	match fase:
		Fase.FUERZA:
			_t_oscilacion += delta
			fuerza = 0.5 - 0.5 * cos(_t_oscilacion * TAU * Config.fuerza_freq)
		Fase.FIN:
			_t_fin -= delta
			if _t_fin <= 0.0:
				_t_fin = INF
				Juego.registrar_intento(maxf(0.0, mejor_x) / Config.px_por_metro, melon.carisma(), recolectados, melon.roto, poderes_recogidos, altura_max_m, valentinas_usadas, estadisticas())
				Animacion.cambiar_escena(ESCENA_RESULTADOS)
	var apuntando := fase == Fase.FUERZA
	efectos.mostrar_flecha = apuntando
	efectos.origen_flecha = melon.global_position
	efectos.direccion_flecha = Vector2.from_angle(bajada.pendiente(Config.bajada_inicio.x))
	efectos.objetivo_aereo = papalote_siguiente if fase == Fase.RECORRIDO else null
	camara.actualizar(melon, not apuntando, delta)
	hud.actualizar(self)


func _physics_process(delta: float) -> void:
	if fase != Fase.BAJADA and fase != Fase.RECORRIDO:
		return
	if fase == Fase.BAJADA:
		_avanzar_bajada(delta)
	terreno.actualizar_melones(melon, delta)
	var x := melon.global_position.x
	_revisar_avance(x, delta)
	if fase == Fase.BAJADA and _x_bajada >= Config.bajada_fin.x:
		fase = Fase.RECORRIDO
		melon.freeze = false
		melon.en_suelo = false
		melon.t_aire = 0.0
		melon.fijar_velocidad(bajada.velocidad_salida(_velocidad_salida))
		melon.angular_velocity = _velocidad_salida / melon.radio
		melon.controlable = true
	if fase != Fase.RECORRIDO:
		return
	terreno.actualizar(x)
	var tramo := terreno.tramo_en(x)
	if tramo != null:
		altura_m = maxf(0.0, tramo.altura(x) - melon.global_position.y - melon.radio) / Config.px_por_metro
		if altura_m > altura_max_m:
			for zona in Config.zonas_cielo:
				if altura_max_m < zona["metros"] and altura_m >= zona["metros"]:
					efectos.avisar(zona["nombre"], melon.global_position + Vector2(0, -100))
			altura_max_m = altura_m
	_actualizar_interacciones(delta)
	_atraer_aplausos(delta)
	_revisar_postales()
	var reto := Juego.reto_actual()
	if not _reto_anunciado and not reto.is_empty() and Juego.progreso_reto(estadisticas()) >= int(reto["meta"]):
		_reto_anunciado = true
		efectos.avisar("¡Reto cumplido! +%d aplausos al terminar" % reto["premio"], melon.global_position + Vector2(0, -140))


func estadisticas() -> Dictionary:
	return {"distancia": maxf(0.0, mejor_x) / Config.px_por_metro, "altura": altura_max_m,
		"monedas": recolectados, "papalotes": papalotes_usados,
		"rebotes": maniobras["rebotes"], "slams": maniobras["slams"],
		"llegada": int(mejor_x >= Config.meta_m * Config.px_por_metro and not melon.roto)}


func _al_hacer_maniobra(tipo: String) -> void:
	maniobras[tipo] += 1


## Durante la bajada el rodado sigue la calle y conserva la potencia elegida.
func _avanzar_bajada(delta: float) -> void:
	var progreso := clampf(inverse_lerp(Config.bajada_inicio.x, Config.bajada_fin.x, _x_bajada), 0.0, 1.0)
	var rapidez := _velocidad_salida * lerpf(0.65, 1.0, progreso) + bajada.embalaje(_x_bajada)
	var pendiente := bajada.inclinacion(_x_bajada)
	_x_bajada = minf(_x_bajada + rapidez * cos(pendiente) * delta, Config.bajada_fin.x)
	pendiente = bajada.inclinacion(_x_bajada)
	melon.position = Vector2(_x_bajada, bajada.altura(_x_bajada)) + Vector2(sin(pendiente), -cos(pendiente)) * melon.radio
	melon.rotation += rapidez * delta / melon.radio


## Termina la carrera si el melón casi no avanza durante un rato.
func _revisar_avance(x: float, delta: float) -> void:
	var avance := x - mejor_x
	mejor_x = minf(maxf(mejor_x, x), Config.meta_m * Config.px_por_metro)
	Musica.actualizar_recorrido(mejor_x / Config.px_por_metro)
	if not melon.roto and x >= Config.meta_m * Config.px_por_metro:
		_revisar_postales()
		melon.freeze = true
		_fin("¡Llegaste al CUCosta!")
		return
	if avance > Config.velocidad_min_avance * delta or not melon.en_suelo:
		_t_sin_avance = 0.0
	else:
		_t_sin_avance += delta
		if _t_sin_avance > Config.tiempo_sin_avance:
			_t_sin_avance = 0.0
			_ofrecer_valentina("¡Se detuvo!")


func _revisar_postales() -> void:
	for postal in Config.postales:
		if mejor_x >= float(postal["metros"]) * Config.px_por_metro and postal["id"] not in postales_intento:
			postales_intento.append(postal["id"])
			if postal["id"] != "xallitic":   # la salida no necesita aviso
				efectos.avisar("¡%s!" % postal["nombre"], melon.global_position + Vector2(0, -90))


func _fin(texto: String) -> void:
	if fase == Fase.FIN:
		return
	fase = Fase.FIN
	_t_fin = Config.espera_fin
	texto_fin = texto
	melon.controlable = false
	var llegada := not melon.roto and mejor_x >= Config.meta_m * Config.px_por_metro
	Musica.tocar(Musica.MENU if llegada else Musica.DERROTA)


# --- Señales -----------------------------------------------------------------

func _on_melon_aviso(texto: String) -> void:
	efectos.avisar(texto, melon.global_position + Vector2(0, -melon.radio - 30))


func _on_melon_roto() -> void:
	_ofrecer_valentina("¡Se rompió el melón!")


## Pausa la carrera para elegir; la salsa se gasta solo al aceptar.
func _ofrecer_valentina(texto: String) -> void:
	if fase == Fase.FIN or fase == Fase.REVIVIR:
		return
	if fase != Fase.RECORRIDO or Juego.valentinas <= 0:
		_fin(texto)
		return
	fase = Fase.REVIVIR
	texto_fin = texto
	melon.controlable = false
	hud.actualizar(self)
	hud.preguntar_valentina()
	get_tree().paused = true


func _elegir_valentina(usar: bool) -> void:
	if fase != Fase.REVIVIR:
		return
	get_tree().paused = false
	if usar and Juego.usar_valentina():
		valentinas_usadas += 1
		_t_sin_avance = 0.0
		fase = Fase.RECORRIDO
		melon.revivir()
	else:
		_fin(texto_fin)
	hud.actualizar(self)


## Conectada a Terreno.obstaculo_tocado. El efecto lo decide cada Obstaculo.
func _al_tocar_obstaculo(cuerpo: Node2D, ob: Obstaculo) -> void:
	if cuerpo != melon or not ob.activo or fase != Fase.RECORRIDO:
		return
	if ob.tipo == "aplauso":
		recolectados += 1
	var texto := ob.tocar(melon)
	if not texto.is_empty():
		efectos.avisar(texto, melon.global_position + Vector2(0, -50))


## Conectada a Terreno.pajaro_tocado.
func _al_tocar_pajaro(pajaro: Pajaro) -> void:
	if fase != Fase.RECORRIDO:
		return
	var texto := pajaro.tocar(melon)
	if not texto.is_empty():
		efectos.avisar(texto, melon.global_position + Vector2(0, -50))


## Conectada a Terreno.rival_aviso: lo que hace un rival (romperse, slam, poderes).
## El generador ya filtra por distancia y repetición; aquí solo se muestran los que
## quedan dentro de la vista de la cámara.
func _al_avisar_rival(texto: String, posicion: Vector2) -> void:
	if fase != Fase.RECORRIDO:
		return
	var vista := get_viewport_rect().size / camara.zoom
	if Rect2(camara.get_screen_center_position() - vista / 2.0, vista).has_point(posicion):
		efectos.avisar(texto, posicion)


## Conectada a Terreno.poder_recogido.
func _al_recoger_poder(tipo: String) -> void:
	if fase != Fase.RECORRIDO:
		return
	poderes_recogidos += 1
	melon.recibir_poder(tipo)


# --- Público y papalotes (tecla E) -------------------------------------------

## Marca qué persona y qué papalote están al alcance y atiende la tecla E.
## Si ambos están cerca, E usa el papalote.
func _actualizar_interacciones(delta: float) -> void:
	var pos := melon.global_position
	persona_cercana = null
	var mejor_d := Config.publico_rango
	papalote_cercano = null
	papalote_siguiente = null
	var distancia_aire := Config.papalote_rango
	for t in terreno.tramos:
		if t.x1 >= pos.x - MARGEN_INTERACCION and t.x0 <= pos.x + MARGEN_INTERACCION:
			for p in t.personas:
				var d: float = (p.global_position + Vector2(0, -40)).distance_to(pos)
				p.en_rango = not p.usado and d < Config.publico_rango
				if p.en_rango and d < mejor_d:
					persona_cercana = p
					mejor_d = d
		for p in t.papalotes:
			if not p.usado and p.global_position.x >= pos.x - Config.papalote_rango:
				if papalote_siguiente == null or p.global_position.x < papalote_siguiente.global_position.x:
					papalote_siguiente = p
			var d: float = p.global_position.distance_to(pos)
			p.en_rango = not p.usado and d <= Config.papalote_rango
			if p.en_rango and d <= distancia_aire:
				papalote_cercano = p
				distancia_aire = d
	if not melon.controlable or melon.roto or melon.slam_activo:
		_t_ayuda = 0.0
		return
	_t_ayuda = Config.margen_ayuda if Input.is_action_just_pressed("empujon") else maxf(0.0, _t_ayuda - delta)
	if _t_ayuda <= 0.0:
		return
	if papalote_cercano != null and papalote_cercano.impulsar(melon):
		_t_ayuda = 0.0
		papalotes_usados += 1
		efectos.avisar("¡Viento de Xalapa!" if papalote_cercano.corriente else "¡Al cielo!", melon.global_position + Vector2(0, -100))
	elif persona_cercana != null:
		_t_ayuda = 0.0
		_empujar_con(persona_cercana)


## La persona empuja al melón. Más carisma = más fuerza; cada empujón cansa.
func _empujar_con(persona: Persona) -> void:
	persona.usado = true
	persona.en_rango = false
	persona.t_empuje = 0.5
	var empuje := Config.empuje_base * (1.0 + melon.carisma() * Config.empuje_por_carisma)
	empuje *= pow(Config.empuje_cansancio, empujones)
	empujones += 1
	melon.empujar(Config.empuje_dir.normalized() * empuje)
	efectos.avisar("¡Empujón! x%.1f" % (empuje / Config.empuje_base), persona.global_position + Vector2(0, -120))


## Con la flor activa, los aplausos cercanos vuelan hacia el melón.
func _atraer_aplausos(delta: float) -> void:
	if melon.t_iman <= 0.0:
		return
	for ap in get_tree().get_nodes_in_group("aplausos"):
		if ap.global_position.distance_to(melon.global_position) < RADIO_IMAN:
			ap.global_position = ap.global_position.move_toward(melon.global_position, VELOCIDAD_IMAN * delta)
