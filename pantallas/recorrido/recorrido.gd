class_name Recorrido
extends Node2D
## Pantalla de la carrera: del lanzamiento en el puente de Xallitic hasta que
## el melón se detiene o se rompe. Coordina los nodos de recorrido.tscn:
##
##   Paisaje                  fondo con paralaje (mundo/paisaje/)
##   Mundo
##     Puente                 salida, con colisión propia
##     LimiteDeSalida         pared invisible detrás del puente
##     Terreno                GeneradorTerreno: crea los tramos como hijos
##     Melon                  el cuerpo físico (melon/melon.tscn)
##   Camara                   CamaraRecorrido: sigue al melón
##   Efectos                  EfectosRecorrido: flecha de puntería y avisos
##   Interfaz                 HUD (hud/hud.tscn): datos, lanzamiento y pausa
##
## Fases: ANGULO → FUERZA (Espacio dos veces) → RECORRIDO → FIN.
## Este script aplica las reglas de la carrera: lanzamiento, cuándo termina,
## efectos de obstáculos, empujones del público, papalotes, poderes y postales.
## Al terminar registra el resultado en Juego y pasa a Resultados.

enum Fase { ANGULO, FUERZA, RECORRIDO, FIN }

const ESCENA_RESULTADOS := "res://pantallas/resultados/resultados.tscn"
const RADIO_IMAN := 240.0              # la flor atrae aplausos a esta distancia
const VELOCIDAD_IMAN := 460.0
const MARGEN_INTERACCION := 400.0      # solo se revisan tramos a esta distancia del melón

@onready var melon: Melon = %Melon
@onready var terreno: GeneradorTerreno = %Terreno
@onready var camara: CamaraRecorrido = %Camara
@onready var efectos: EfectosRecorrido = %Efectos
@onready var hud: HUD = %Interfaz

var fase := Fase.ANGULO
var angulo := 0.0                      # grados, elegido en la fase ANGULO
var fuerza := 0.0                      # 0..1, elegida en la fase FUERZA
var _t_oscilacion := 0.0               # reloj de la flecha y de la barra de fuerza

# Marcador de la carrera
var mejor_x := 0.0                     # punto más lejano alcanzado (px)
var altura_m := 0.0                    # altura sobre el suelo, para el HUD
var altura_max_m := 0.0
var recolectados := 0                  # aplausos sueltos recogidos
var poderes_recogidos := 0
var empujones := 0                     # cada empujón vale menos que el anterior
var papalotes_usados := 0
var postales_intento: Array = []       # ids de postales alcanzadas en esta carrera
var papalote_cercano: Papalote         # el que se activaría al pulsar E
var papalote_siguiente: Papalote       # orienta el vuelo aunque quede fuera de pantalla
var texto_fin := ""

var _t_sin_avance := 0.0
var _t_fin := 0.0                      # espera antes de pasar a Resultados


func _ready() -> void:
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY, Config.gravedad)
	terreno.iniciar()
	melon.configurar(Juego.tamano, Juego.accesorios, Juego.resistencia_max(), Juego.rebotes_max())
	melon.position = Vector2(0, -melon.radio - 1.0)
	$Paisaje.configurar(camara)
	camara.make_current()
	hud.actualizar(self)


# --- Lanzamiento -------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("rebote") or event.is_echo():
		return
	if fase == Fase.ANGULO:
		fase = Fase.FUERZA
		_t_oscilacion = 0.0
	elif fase == Fase.FUERZA:
		_lanzar()


## Suelta al melón con el ángulo y la fuerza elegidos.
func _lanzar() -> void:
	var perfecto := fuerza >= Config.zona_perfecta.x and fuerza <= Config.zona_perfecta.y
	var vel := lerpf(Config.lanz_vel_min, Config.lanz_vel_max, fuerza) * Juego.mult_fuerza()
	vel *= float(melon.datos()["mult_lanzamiento"])
	if perfecto:
		vel *= Config.bonus_perfecto
		efectos.avisar("¡Lanzamiento perfecto!", melon.global_position + Vector2(0, -60))
	melon.freeze = false
	melon.fijar_velocidad(Vector2.from_angle(-deg_to_rad(angulo)) * vel)
	melon.t_bloqueo = 0.3            # que el mismo Espacio no cuente como rebote
	melon.controlable = true
	fase = Fase.RECORRIDO


# --- Ciclo por cuadro --------------------------------------------------------

func _process(delta: float) -> void:
	match fase:
		Fase.ANGULO:
			_t_oscilacion += delta
			angulo = lerpf(Config.angulo_min, Config.angulo_max, 0.5 - 0.5 * cos(_t_oscilacion * TAU * Config.angulo_freq))
		Fase.FUERZA:
			_t_oscilacion += delta
			fuerza = 0.5 - 0.5 * cos(_t_oscilacion * TAU * Config.fuerza_freq)
		Fase.FIN:
			_t_fin -= delta
			if _t_fin <= 0.0:
				_t_fin = INF
				Juego.registrar_intento(mejor_x / Config.px_por_metro, melon.carisma(), recolectados, melon.roto, poderes_recogidos, altura_max_m)
				Animacion.cambiar_escena(ESCENA_RESULTADOS)
	var apuntando := fase == Fase.ANGULO or fase == Fase.FUERZA
	efectos.mostrar_flecha = apuntando
	efectos.origen_flecha = melon.global_position
	efectos.angulo = angulo
	efectos.angulo_fijado = fase == Fase.FUERZA
	efectos.objetivo_aereo = papalote_siguiente if fase == Fase.RECORRIDO else null
	camara.actualizar(melon, not apuntando, delta)
	hud.actualizar(self)


func _physics_process(delta: float) -> void:
	if fase != Fase.RECORRIDO:
		return
	var x := melon.global_position.x
	_revisar_avance(x, delta)
	terreno.actualizar(x)
	var tramo := terreno.tramo_en(x)
	if tramo != null:
		altura_m = maxf(0.0, tramo.altura(x) - melon.global_position.y - melon.radio) / Config.px_por_metro
		if altura_m > altura_max_m:
			for zona in Config.zonas_cielo:
				if altura_max_m < zona["metros"] and altura_m >= zona["metros"]:
					efectos.avisar(zona["nombre"], melon.global_position + Vector2(0, -100))
			altura_max_m = altura_m
	_actualizar_interacciones()
	_atraer_aplausos(delta)
	_revisar_postales()


## Termina la carrera si el melón casi no avanza durante un rato.
func _revisar_avance(x: float, delta: float) -> void:
	var avance := x - mejor_x
	mejor_x = maxf(mejor_x, x)
	if avance > Config.velocidad_min_avance * delta or not melon.en_suelo:
		_t_sin_avance = 0.0
	else:
		_t_sin_avance += delta
		if _t_sin_avance > Config.tiempo_sin_avance:
			_fin("¡Se detuvo!")


func _revisar_postales() -> void:
	for postal in Config.postales:
		if mejor_x >= float(postal["metros"]) * Config.px_por_metro and postal["id"] not in postales_intento:
			postales_intento.append(postal["id"])
			efectos.avisar("¡%s!" % postal["nombre"], melon.global_position + Vector2(0, -90))


func _fin(texto: String) -> void:
	if fase == Fase.FIN:
		return
	fase = Fase.FIN
	_t_fin = Config.espera_fin
	texto_fin = texto
	melon.controlable = false


# --- Señales -----------------------------------------------------------------

func _on_melon_aviso(texto: String) -> void:
	efectos.avisar(texto, melon.global_position + Vector2(0, -melon.radio - 30))


func _on_melon_roto() -> void:
	_fin("¡Se rompió el melón!")


## Conectada a Terreno.obstaculo_tocado. El efecto lo decide cada Obstaculo.
func _al_tocar_obstaculo(cuerpo: Node2D, ob: Obstaculo) -> void:
	if cuerpo != melon or not ob.activo or fase != Fase.RECORRIDO:
		return
	if ob.tipo == "aplauso":
		recolectados += 1
	var texto := ob.tocar(melon)
	if not texto.is_empty():
		efectos.avisar(texto, melon.global_position + Vector2(0, -50))


## Conectada a Terreno.poder_recogido.
func _al_recoger_poder(tipo: String) -> void:
	if fase != Fase.RECORRIDO:
		return
	poderes_recogidos += 1
	melon.recibir_poder(tipo)


# --- Público y papalotes (tecla E) -------------------------------------------

## Marca qué persona y qué papalote están al alcance y atiende la tecla E.
## Si ambos están cerca, E usa el papalote.
func _actualizar_interacciones() -> void:
	var pos := melon.global_position
	var cercana: Persona = null
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
					cercana = p
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
	if not melon.controlable or not Input.is_action_just_pressed("empujon"):
		return
	if papalote_cercano != null and papalote_cercano.impulsar(melon):
		papalotes_usados += 1
		efectos.avisar("¡Viento de Xalapa!" if papalote_cercano.corriente else "¡Al cielo!", melon.global_position + Vector2(0, -100))
	elif cercana != null:
		_empujar_con(cercana)


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
