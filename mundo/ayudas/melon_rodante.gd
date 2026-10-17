class_name MelonRodante
extends Node2D
## Rival que juega la carrera como el jugador: pasa casi todo el tiempo en el aire,
## gasta cargas en saltos aéreos, impulsa rebotes al caer (y así recarga), va por
## poderes y papalotes, y pica sobre otros rivales para aplastarlos. Va a su propio
## ritmo: no espera al jugador ni lo sigue al aire. Solo el jugador lo marca para un slam.
##
## También pierde como el jugador: tiene resistencia según su tamaño, las caídas fuertes
## sin rebote se la quitan, y si se queda rodando o detenido demasiado se rompe. Roto,
## explota un momento y terminado() avisa al generador para liberarlo.
##
## Cada uno tiene un carácter (Config.tipos_melones): los tontos van lentos, fallan más
## rebotes, tropiezan y son fáciles de aplastar; los listos van más rápido, rara vez
## fallan, buscan mejor los poderes y a veces esquivan el primer picado que los apunta.
##
## Con saltos = false (pruebas) no hay piloto: solo rueda, rebota con su material y
## nunca se rompe por sí solo.
##
## No usa el motor de física: sigue la altura del terreno con Tramo.altura() para
## avanzar de un tramo a otro sin colisiones con el jugador ni con los obstáculos.

signal se_rompio(rival: MelonRodante)               ## sin resistencia: explota y se retira
signal maniobra(rival: MelonRodante, tipo: String)  ## "rebote", "salto", "picado", "slam" (acertado), "poder", "papalote"

const EXPLOSION := preload("res://recursos/poderes/explosion.png")
const DURACION_EXPLOSION := 0.45        # explosión del chile, como en Melon

var radio := 30.0
var rapidez := 480.0                    # px/s de crucero; la pendiente la sube o la baja
var velocidad := Vector2.ZERO
var aspecto: Dictionary = {}
var tipo := "normal"                    # clave de Config.tipos_melones
var usado := false                      # ya recibió el slam del jugador
var anterior := Vector2.ZERO
var en_bajada := false
var en_suelo := false
var saltos := true                      # false = solo rueda, sin piloto (pruebas)
var en_mira := false                    # un picado lo apunta: no salta ni impulsa rebotes
var marca := Marca.NINGUNA              # aviso dibujado encima (lo decide GeneradorTerreno)
var rng := RandomNumberGenerator.new()

# --- Partida propia ----------------------------------------------------------
var roto := false
var resistencia := 3.0                  # golpes que aguanta; las caídas medianas quitan fracciones
var resistencia_max := 3.0
var cargas := 2                         # saltos aéreos guardados
var slam_activo := false                # picado en curso sobre otro rival
var escudo := false                     # papalote: la siguiente caída fuerte no cuesta resistencia

var _bajada: BajadaXallitic
var _x_bajada := 0.0
var _carril := 0.0
var _ritmo := 1.0
var _velocidad_salida := 0.0
var _giro := 0.0                        # rad/s del dibujo en el aire
var _t_salto := 0.0                     # espera para el siguiente salto aéreo
var _t_despegue := 0.0                  # espera rodando para volver a despegar
var _t_rodando := 0.0                   # s seguidos en la calle
var _t_detenido := 0.0                  # s seguidos casi sin avanzar
var _t_aplastado := 0.0
var _t_soplo := 0.0                     # dibujo del último impulso
var _t_tropiezo := 0.0                  # tonto: frenado un momento
var _t_slam := 0.0                      # recarga entre picados
var _t_invulnerable := 0.0
var _t_cafe := 0.0                      # saltos sin gastar cargas
var _t_pizza := 0.0                     # avanza sin perder altura
var _y_pizza := 0.0
var _t_explosion := 0.0                 # explosión del chile
var _t_rotura := 0.0                    # explosión al romperse
var _t_objetivos := 0.0                 # espera para volver a mirar poderes y papalotes
var _insignia := ""                     # poder que se dibuja encima mientras dura
var _t_insignia := 0.0
var _suelo_y := 0.0                     # y de su centro al tocar el suelo debajo
var _esquivo := false                   # listo: ya intentó esquivar (solo una vez)
var _objetivo: Node2D                   # poder o papalote que intenta alcanzar
var _error_objetivo := 0.0              # px de mal cálculo al buscarlo (según su puntería)
var _decididos: Dictionary = {}         # instance_id -> si decidió ir por él
var _victima: MelonRodante              # rival al que apunta su picado
var _error_picado := 0.0                # px de mal cálculo del picado (según su puntería)
var _picado_bueno := true               # false: calculó mal y cae junto a la víctima, sin tocarla

enum Marca { NINGUNA, ACERTABLE, FIJADO }
const COLOR_ACERTABLE := Color("ffc83d")
const COLOR_FIJADO := Color("ff6b4a")


func _ready() -> void:
	z_index = 3
	anterior = global_position
	$Lienzo.world_2d = World2D.new()
	$Aspecto.texture = $Lienzo.get_texture()
	_actualizar_aspecto()


## Aspecto, tamaño y carácter. La resistencia sale del tamaño y del tipo.
func configurar(datos: Dictionary) -> void:
	aspecto = datos.duplicate(true)
	tipo = aspecto.get("tipo", "normal")
	var tam: Dictionary = Config.tamanos[aspecto.get("tamano", 2)]
	radio = tam["radio"]
	resistencia_max = float(tam["resistencia"]) * _rasgo("resistencia")
	resistencia = resistencia_max
	cargas = Config.cargas_rival
	if is_node_ready():
		_actualizar_aspecto()


## Rapidez de crucero y semilla de sus decisiones.
func preparar_carrera(p_rapidez: float, semilla: int) -> void:
	rapidez = p_rapidez * _rasgo("ritmo")
	rng.seed = semilla
	_t_salto = _pausa_salto()
	_t_despegue = _pausa_despegue()


func preparar_salida(bajada: BajadaXallitic, x: float, carril: float, ritmo: float) -> void:
	_bajada = bajada
	_x_bajada = x
	_carril = carril
	_ritmo = ritmo
	en_bajada = true
	_colocar_en_bajada()
	anterior = global_position


func soltar(p_rapidez: float) -> void:
	_velocidad_salida = p_rapidez * _ritmo


func _colocar_en_bajada() -> void:
	var pendiente := _bajada.inclinacion(_x_bajada)
	var carril := _carril * (1.0 - smoothstep(Config.bajada_fin.x - Config.bajada_subida, Config.bajada_fin.x, _x_bajada))
	position = Vector2(_x_bajada, _bajada.altura(_x_bajada) + carril) + Vector2(sin(pendiente), -cos(pendiente)) * radio


## true cuando ya se rompió y terminó de explotar: el generador puede liberarlo.
func terminado() -> bool:
	return roto and _t_rotura <= 0.0


func radio_contacto() -> float:
	return radio


## jugador indica hacia dónde se aparta al esquivar un picado; NAN = sin jugador.
## Es lo único que sabe del jugador: su ritmo y sus decisiones no dependen de él.
func avanzar(terreno: GeneradorTerreno, delta: float, jugador := Vector2(NAN, NAN)) -> void:
	anterior = global_position
	queue_redraw()                      # mira, soplo, poderes y explosión se animan
	_descontar(delta)
	if roto:
		_avanzar_roto(terreno, delta)
		return
	if en_mira and not _esquivo and not usado:
		_esquivo = true
		if rng.randf() < _rasgo("esquiva"):
			_esquivar(jugador.x)
	var aplastado := _t_aplastado / Config.aplastado_melones
	scale = Vector2(1.0 + 0.25 * aplastado, 1.0 - 0.35 * aplastado)
	$Aspecto.position.y = radio / scale.y - radio     # achatado sin despegarse del suelo
	$Aspecto.modulate.a = 0.4 if _t_invulnerable > 0.0 and int(_t_invulnerable * 16.0) % 2 == 0 else 1.0
	if en_bajada:
		_avanzar_bajada(delta)
		return
	var tramo := _tramo_en(terreno, global_position.x)
	if tramo == null:
		return
	_suelo_y = tramo.altura(global_position.x) - radio
	if saltos:
		if en_suelo:
			_pilotar_suelo(terreno, delta)
		else:
			_pilotar_aire(terreno, delta)
		if roto:
			return
	if en_suelo:
		_rodar(tramo, delta)
	elif _t_pizza > 0.0:
		# Vuelve con suavidad a la altura en que la tomó, sin bajar de su ritmo.
		velocidad.y = (_y_pizza - global_position.y) * 6.0
		velocidad.x = maxf(velocidad.x, maxf(rapidez, Config.pizza_vel * 0.6))
	var g := 0.0 if _t_pizza > 0.0 and not en_suelo else Config.gravedad
	var siguiente := global_position + velocidad * delta + Vector2(0.0, 0.5 * g * delta * delta)
	var tramo_siguiente := _tramo_en(terreno, siguiente.x)
	if tramo_siguiente == null:
		return
	var suelo := tramo_siguiente.altura(siguiente.x) - radio
	if siguiente.y < suelo - 1.0:
		# Si el suelo cae más rápido que la gravedad, despega como el jugador en una cresta.
		if en_suelo:
			en_suelo = false
			_giro = velocidad.x / radio
		velocidad.y += g * delta
		global_position = siguiente
		$Aspecto.rotation += _giro * delta
		if slam_activo:
			_resolver_slam(terreno)
		return
	global_position = Vector2(siguiente.x, suelo)
	var acerto := slam_activo and _resolver_slam(terreno)   # el picado llega justo con la calle
	if not en_suelo and not acerto:
		_aterrizar(tramo_siguiente.pendiente(siguiente.x))
	$Aspecto.rotation += velocidad.length() * signf(velocidad.x) * delta / radio


func _descontar(delta: float) -> void:
	_t_aplastado = maxf(0.0, _t_aplastado - delta)
	_t_soplo = maxf(0.0, _t_soplo - delta)
	_t_tropiezo = maxf(0.0, _t_tropiezo - delta)
	_t_slam = maxf(0.0, _t_slam - delta)
	_t_invulnerable = maxf(0.0, _t_invulnerable - delta)
	_t_cafe = maxf(0.0, _t_cafe - delta)
	_t_pizza = maxf(0.0, _t_pizza - delta)
	_t_explosion = maxf(0.0, _t_explosion - delta)
	_t_rotura = maxf(0.0, _t_rotura - delta)
	_t_insignia = maxf(0.0, _t_insignia - delta)
	_t_objetivos = maxf(0.0, _t_objetivos - delta)
	_t_salto -= delta


## Al dejar el trampolín el centro sigue unos px antes de la calle: ahí el suelo es la bajada.
func _tramo_en(terreno: GeneradorTerreno, x: float) -> Tramo:
	var tramo := terreno.tramo_en(x)
	if tramo == null and _bajada != null and x >= _bajada.x0 and x <= _bajada.x1:
		return _bajada
	return tramo


func _avanzar_bajada(delta: float) -> void:
	if _velocidad_salida <= 0.0:
		return
	var progreso := clampf(inverse_lerp(Config.bajada_inicio.x, Config.bajada_fin.x, _x_bajada), 0.0, 1.0)
	var s := _velocidad_salida * lerpf(0.65, 1.0, progreso) + _bajada.embalaje(_x_bajada)
	_x_bajada = minf(_x_bajada + cos(_bajada.inclinacion(_x_bajada)) * s * delta, Config.bajada_fin.x)
	velocidad = Vector2.from_angle(_bajada.inclinacion(_x_bajada)) * s
	_colocar_en_bajada()
	$Aspecto.rotation += s * delta / radio
	if _x_bajada >= Config.bajada_fin.x:
		# Sale del trampolín en el aire y cae a la calle.
		en_bajada = false
		en_suelo = false
		velocidad = _bajada.velocidad_salida(s)
		_giro = s / radio


## En el suelo: la pendiente acelera o frena, y un empuje propio lo lleva a su ritmo.
func _rodar(tramo: Tramo, delta: float) -> void:
	var pendiente := tramo.pendiente(global_position.x)
	var adelante := Vector2(cos(pendiente), sin(pendiente))
	var s := velocidad.dot(adelante) + Config.gravedad * sin(pendiente) * delta
	var objetivo := rapidez
	if _t_aplastado > 0.0:
		objetivo *= 0.4
	if _t_tropiezo > 0.0:
		objetivo *= 0.45
	elif rng.randf() < _rasgo("tropiezos") * delta:
		_t_tropiezo = Config.tropiezo_melones
	if s < objetivo:
		s = minf(objetivo, s + Config.aceleracion_melones * delta)
	else:
		s = maxf(objetivo, s - Config.frenado_melones * delta)
	velocidad = adelante * minf(s, Config.vel_crucero)


# --- Piloto ------------------------------------------------------------------

## Rodar no es su estado normal: tras una pausa corta intenta despegar. Un tonto puede
## fallar el intento; si pasa demasiado en la calle o se detiene, se rompe como el jugador.
func _pilotar_suelo(terreno: GeneradorTerreno, delta: float) -> void:
	_t_rodando += delta
	_t_detenido = _t_detenido + delta if velocidad.length() < Config.velocidad_min_avance else 0.0
	if _t_rodando > Config.rodando_max_rival or _t_detenido > Config.tiempo_sin_avance:
		_romper()
		return
	_t_despegue -= delta
	if en_mira or _t_aplastado > 0.0:
		return
	_elegir_objetivo(terreno)
	# Hacia un papalote despega con todo; hacia lo demás, con su salto de siempre.
	var salto := Config.salto_melones.y if _objetivo is Papalote else rng.randf_range(Config.salto_melones.x, Config.salto_melones.y)
	var por_objetivo := _vale_saltar_por_objetivo(salto)
	if _t_despegue > 0.0 and not por_objetivo:
		return
	_t_despegue = _pausa_despegue()
	if not por_objetivo and rng.randf() >= _rasgo("acierto_rebote"):
		return                          # se le fue el despegue: lo intenta de nuevo
	velocidad.y = -salto
	en_suelo = false
	_giro = velocidad.x / radio


## En el aire: vuelve a su ritmo, busca poderes y papalotes, pica sobre otros rivales
## y gasta saltos aéreos para no tocar la calle sin rebote.
func _pilotar_aire(terreno: GeneradorTerreno, delta: float) -> void:
	_t_rodando = 0.0
	_t_detenido = 0.0
	if slam_activo:
		_guiar_picado(delta)
		return
	if en_mira:
		return                          # sigue su arco: el picado del jugador lo prevé así
	velocidad.x = move_toward(velocidad.x, rapidez, Config.control_rival * delta)
	if _t_pizza > 0.0 or _t_aplastado > 0.0:
		return
	_elegir_objetivo(terreno)
	if _intentar_slam(terreno, delta):
		return
	var salto := rng.randf_range(Config.salto_rival.x, Config.salto_rival.y)
	if _escalar_papalote():
		# Escalar a un papalote pide el salto más fuerte, no uno al azar.
		_saltar_aire(Config.salto_rival.y)
		return
	if not _puede_saltar_aire():
		return
	var altura := _suelo_y - global_position.y
	if _vale_saltar_por_objetivo(salto):
		_saltar_aire(salto)
	elif velocidad.y > 0.0 and altura < Config.techo_salto_rival:
		# Al caer, salta antes de llegar a la calle; con café, cada vez que puede.
		var umbral := Config.techo_salto_rival if _t_cafe > 0.0 else rng.randf_range(Config.altura_salto_rival.x, Config.altura_salto_rival.y)
		if altura < umbral:
			_saltar_aire(salto)


## Un papalote alto se alcanza encadenando saltos en lo alto de cada arco, sin
## pausa entre ellos, mientras le queden cargas (o dure el café).
func _escalar_papalote() -> bool:
	if not is_instance_valid(_objetivo) or not _objetivo is Papalote or velocidad.y < -80.0 or (cargas <= 0 and _t_cafe <= 0.0):
		return false
	if _t_cafe > 0.0 and _t_salto > 0.0:
		return false
	var hacia := _objetivo.global_position - global_position
	var falta := -hacia.y - Config.papalote_rango * 0.5
	var llegada := hacia.x / maxf(velocidad.x, 120.0)
	if falta <= 0.0 or hacia.x <= 0.0 or llegada > 2.5:
		return false
	# Si un salto basta, lo guarda para que la cima del arco quede junto al papalote.
	var un_salto := Config.salto_rival.y * Config.salto_rival.y / (2.0 * Config.gravedad)
	return falta > un_salto or llegada < Config.salto_rival.y / Config.gravedad


func _puede_saltar_aire() -> bool:
	return _t_salto <= 0.0 and (cargas > 0 or _t_cafe > 0.0)


func _saltar_aire(salto: float) -> void:
	if _t_cafe > 0.0:
		_t_salto = Config.cafe_bloqueo
	else:
		cargas -= 1
		_t_salto = _pausa_salto()
	velocidad.y = minf(velocidad.y, -salto)
	velocidad.x += Config.salto_aereo_avance * 0.5
	_giro = velocidad.x / radio
	_t_soplo = 0.3
	maniobra.emit(self, "salto")


## Mira los poderes y papalotes que tiene delante y decide una vez por cada uno si
## va por él. Los tontos casi nunca lo intentan y calculan peor.
func _elegir_objetivo(terreno: GeneradorTerreno) -> void:
	if _objetivo_vigente(_objetivo):
		return
	_objetivo = null
	if _t_objetivos > 0.0 or not terreno.has_method("objetivos_rival"):
		return
	_t_objetivos = 0.25
	if _decididos.size() > 32:
		_decididos.clear()
	var punteria: float = _rasgo("punteria")
	var un_salto := Config.salto_rival.y * Config.salto_rival.y / (2.0 * Config.gravedad)
	var alcance := _suelo_y - Config.techo_salto_rival - un_salto
	# Un papalote se alcanza encadenando saltos (ver _escalar_papalote), no con uno solo.
	var alcance_papalote := _suelo_y - Config.techo_salto_rival - Config.cargas_max_rival * un_salto
	for candidato in terreno.call("objetivos_rival", self):
		if not _objetivo_vigente(candidato):
			continue
		var id: int = candidato.get_instance_id()
		if not _decididos.has(id):
			# Lo que queda fuera de su alcance ni lo intenta.
			var limite := alcance_papalote if candidato is Papalote else alcance
			_decididos[id] = candidato.global_position.y > limite and rng.randf() < punteria
		if not _decididos[id]:
			continue
		if _objetivo == null:
			_objetivo = candidato
		elif candidato is Papalote != _objetivo is Papalote:
			# El papalote manda sobre un poder: es más escaso y pasa una sola vez.
			if candidato is Papalote:
				_objetivo = candidato
		elif candidato.global_position.x < _objetivo.global_position.x:
			_objetivo = candidato
	if _objetivo != null:
		_error_objetivo = rng.randf_range(-1.0, 1.0) * (1.0 - punteria) * 160.0


## Sigue delante y sin usar (los poderes se consumen; los papalotes se gastan un rato).
func _objetivo_vigente(nodo: Variant) -> bool:
	return is_instance_valid(nodo) and nodo.global_position.x > global_position.x - radio \
		and not nodo.get("consumido") and not nodo.get("usado")


## true si un salto de esa fuerza ahora lo deja a la altura de su objetivo al llegar a él.
func _vale_saltar_por_objetivo(salto: float) -> bool:
	if not is_instance_valid(_objetivo) or not _puede_saltar_por_objetivo():
		return false
	var hacia := _objetivo.global_position - global_position
	if hacia.x <= 0.0:
		return false
	var t := hacia.x / maxf(velocidad.x, 120.0)
	if t > 1.4:
		return false
	var meta := hacia.y + _error_objetivo
	# El papalote impulsa desde lejos; el poder hay que tocarlo.
	var holgura := Config.papalote_rango * 0.5 if _objetivo is Papalote else Poder.RADIO_INSIGNIA + radio * 0.5
	var g := Config.gravedad
	var sin_saltar := velocidad.y * t + 0.5 * g * t * t
	if absf(sin_saltar - meta) < holgura:
		return false                    # así como va ya pasa cerca
	var saltando := minf(velocidad.y, -salto) * t + 0.5 * g * t * t
	return saltando < meta + holgura and saltando > meta - holgura - 80.0


func _puede_saltar_por_objetivo() -> bool:
	return en_suelo or _puede_saltar_aire()


## Con otro rival a tiro debajo, a veces pica sobre él. El impacto lo resuelve
## recibir_slam_rival(); si llega a la calle sin acertar, se raspa.
func _intentar_slam(terreno: GeneradorTerreno, delta: float) -> bool:
	if _t_slam > 0.0 or velocidad.y < -250.0:
		return false
	if rng.randf() >= Config.prob_slam_rival * _rasgo("agresividad") * delta:
		return false
	# Decide antes si calcula bien. Si no, pica cuando todavía no está encima, cae a un lado
	# y no aplasta a nadie aunque lo roce.
	var bien := rng.randf() < lerpf(Config.acierto_slam_rival.x, Config.acierto_slam_rival.y, _rasgo("punteria"))
	for otro in terreno.melones:
		if otro == self or not is_instance_valid(otro) or otro.roto or otro.en_bajada:
			continue
		var debajo := otro.global_position - global_position
		var radios := radio + otro.radio
		if debajo.y <= radios or debajo.y >= Config.slam_alcance:
			continue
		var t := debajo.y / Config.slam_caida
		var desvio := absf(debajo.x + (otro.velocidad.x - velocidad.x) * t)
		var a_tiro := desvio < radios + Config.slam_margen.y if bien else desvio > radios + 30.0 and desvio < radios + 140.0
		if not a_tiro:
			continue
		slam_activo = true
		_victima = otro
		_picado_bueno = bien
		_error_picado = 0.0 if bien else signf(-debajo.x) * (radios + 60.0)
		_t_pizza = 0.0
		maniobra.emit(self, "picado")
		return true
	return false


## Cae deprisa y corrige un poco hacia su víctima, con el mismo límite que el jugador.
func _guiar_picado(delta: float) -> void:
	velocidad.y = maxf(velocidad.y, Config.slam_caida)
	if not is_instance_valid(_victima) or _victima.roto:
		return
	var t := maxf((_victima.global_position.y - global_position.y) / Config.slam_caida, delta)
	var desvio := _victima.global_position.x + _error_picado + (_victima.velocidad.x - velocidad.x) * t - global_position.x
	var limite: float = Config.slam_guiado * _rasgo("punteria") * delta
	velocidad.x = maxf(velocidad.x + clampf(desvio / t, -limite, limite), rapidez * 0.4)


## El generador también resuelve los picados; probarlo aquí cubre el paso en que cae.
## Si acierta dos veces en el mismo paso, la segunda ya no cuenta (slam_activo = false).
func _resolver_slam(terreno: GeneradorTerreno) -> bool:
	for otro in terreno.melones:
		if otro != self and is_instance_valid(otro) and otro.recibir_slam_rival(self):
			return true
	return false


## Conserva la velocidad a lo largo del suelo. Con piloto casi siempre impulsa el
## rebote (gana una carga); si lo falla rebota con su material, y una caída fuerte
## le cuesta resistencia como al jugador.
func _aterrizar(pendiente: float) -> void:
	var nrm := Vector2(sin(pendiente), -cos(pendiente))
	if slam_activo:
		slam_activo = false
		_t_slam = Config.slam_recarga_rival
		velocidad = Vector2(maxf(velocidad.x * Config.slam_conserva_rival, rapidez * 0.5), 0.0)
		en_suelo = true
		_t_despegue = _pausa_despegue()
		danar(Config.dano_slam_fallado_rival)
		return
	var impacto := maxf(0.0, -velocidad.dot(nrm))
	var tangente := velocidad + nrm * impacto
	_giro = velocidad.x / radio
	if saltos and not en_mira and _t_aplastado <= 0.0 and impacto > Config.impacto_rebote_rival:
		if rng.randf() < _rasgo("acierto_rebote"):
			var salida := maxf(impacto * Config.rebote_mult_normal, Config.rebote_min)
			velocidad = tangente + nrm * salida
			cargas = mini(cargas + 1, Config.cargas_max_rival)
			_t_soplo = 0.3
			maniobra.emit(self, "rebote")
			return
	var tam: Dictionary = Config.tamanos[aspecto.get("tamano", 2)]
	var umbral: float = tam["umbral_caida"] * Config.umbral_caida_rival
	var dureza := smoothstep(umbral * Config.raspon_desde, umbral, impacto)
	var salida: float = impacto * tam["rebote"]
	var conserva := lerpf(Config.lado_redondo_conserva, 0.7, dureza) if saltos else Config.lado_redondo_conserva
	if salida < Config.salida_min_melones:
		en_suelo = true
		_t_despegue = _pausa_despegue()
		velocidad = tangente * conserva
	else:
		velocidad = tangente * conserva + nrm * salida
	_giro = velocidad.x / radio
	if not saltos:
		return
	if impacto > umbral:
		if escudo:
			escudo = false
		else:
			danar(1.0)
	elif impacto > umbral * Config.raspon_desde:
		danar(Config.raspon_max * inverse_lerp(umbral * Config.raspon_desde, umbral, impacto))


## Valor de su carácter en Config.tipos_melones.
func _rasgo(clave: String) -> Variant:
	return Config.tipos_melones[tipo][clave]


func _pausa_salto() -> float:
	return rng.randf_range(Config.pausa_saltos_melones.x, Config.pausa_saltos_melones.y) * _rasgo("pausa_saltos")


func _pausa_despegue() -> float:
	return rng.randf_range(Config.despegue_rival.x, Config.despegue_rival.y)


## Listo: un empujón hacia el lado contrario al jugador y un saltito. El guiado del
## picado alcanza a corregir parte del desvío, así que esquivar no es seguro.
func _esquivar(x_jugador: float) -> void:
	var lado := 1.0 if is_nan(x_jugador) or x_jugador <= global_position.x else -1.0
	velocidad.x += lado * Config.esquiva_melones.x
	if en_suelo:
		velocidad.y = -Config.esquiva_melones.y
		en_suelo = false
		_giro = velocidad.x / radio
	_t_soplo = 0.3


# --- Pedidos desde fuera -----------------------------------------------------

## Aplica un poder del camino (ver Config.poderes), como Melon.recibir_poder().
func recibir_poder(id: String) -> void:
	if roto or not Config.poderes.has(id):
		return
	var duracion: float = Config.poderes[id]["duracion"]
	match id:
		"chile":
			var impulso: Vector2 = Config.poderes[id]["impulso"]
			velocidad = Vector2(maxf(velocidad.x + impulso.x, Config.chile_vel_min), minf(velocidad.y, 0.0) + impulso.y)
			en_suelo = false
			slam_activo = false
			_t_pizza = 0.0
			_t_explosion = DURACION_EXPLOSION
		"cafe":
			_t_cafe = duracion
		"pizza":
			_t_pizza = duracion
			_y_pizza = minf(global_position.y, _suelo_y - 60.0)
			slam_activo = false
			if en_suelo:
				en_suelo = false
				velocidad.y = minf(velocidad.y, -300.0)
	_insignia = id
	_t_insignia = maxf(duracion, 0.8)
	_objetivo = null
	maniobra.emit(self, "poder")


## Papalote: sale con al menos esa velocidad (adelante y arriba) y protegido contra
## la siguiente caída fuerte.
func impulsar_papalote(dv_minimo: Vector2) -> void:
	if roto:
		return
	velocidad = Vector2(maxf(velocidad.x, dv_minimo.x), minf(velocidad.y, dv_minimo.y))
	en_suelo = false
	slam_activo = false
	_t_pizza = 0.0
	escudo = true
	_giro = velocidad.x / radio
	_objetivo = null
	maniobra.emit(self, "papalote")


## Multiplica la velocidad; los grandes lo resienten menos. Un frenón tira la pizza.
func frenar(mult: float) -> void:
	var inercia: float = Config.tamanos[aspecto.get("tamano", 2)]["inercia"]
	velocidad *= lerpf(mult, 1.0, inercia)
	if mult < 1.0:
		_t_pizza = 0.0


## Resta resistencia (1.0 = un golpe completo, que además da invulnerabilidad un momento).
func danar(cantidad: float) -> void:
	if roto or cantidad <= 0.0 or _t_invulnerable > 0.0:
		return
	resistencia = maxf(0.0, resistencia - cantidad)
	if cantidad >= 1.0:
		_t_invulnerable = Config.invulnerable_tras_golpe
	if resistencia <= 0.0:
		_romper()


## Se rompe: explota, deja de jugar y de ser objetivo. terminado() avisa al acabar.
func _romper() -> void:
	if roto:
		return
	roto = true
	resistencia = 0.0
	slam_activo = false
	_t_pizza = 0.0
	_t_insignia = 0.0
	_t_rotura = Config.explosion_rival
	marcar(Marca.NINGUNA)
	_actualizar_aspecto()
	Sonidos.muerte(self)
	se_rompio.emit(self)


## Roto: los trozos caen y resbalan por la calle mientras dura la explosión.
func _avanzar_roto(terreno: GeneradorTerreno, delta: float) -> void:
	$Aspecto.modulate.a = _t_rotura / Config.explosion_rival
	var tramo := _tramo_en(terreno, global_position.x)
	if tramo == null:
		return
	velocidad.x = move_toward(velocidad.x, 0.0, 600.0 * delta)
	velocidad.y += Config.gravedad * delta
	global_position += velocidad * delta
	var suelo := tramo.altura(global_position.x) - radio
	if global_position.y >= suelo:
		global_position.y = suelo
		velocidad.y = 0.0


# --- Slam --------------------------------------------------------------------

func margen_slam(melon: Melon) -> float:
	var margen := absf(melon.linear_velocity.x - velocidad.x) * Config.slam_tolerancia
	return clampf(margen, Config.slam_margen.x, Config.slam_margen.y) * _rasgo("margen_slam")


## Anticipa un picado sobre este melón: x = segundos hasta alcanzarlo,
## y = distancia horizontal que faltaría entonces (positiva si queda a la derecha).
## Devuelve x < 0 si no está debajo, queda fuera de alcance o ya se rompió.
func prevision_slam(melon: Melon) -> Vector2:
	var diferencia := global_position - melon.global_position
	var radios := radio + melon.radio
	if usado or roto or diferencia.y <= radios * 0.25 or diferencia.y >= Config.slam_alcance:
		return Vector2(-1.0, INF)
	var caida := maxf(Config.slam_caida, melon.linear_velocity.y)
	var hueco := maxf(0.0, diferencia.y - radios * 0.5)
	var cierre := caida - velocidad.y
	var tiempo := hueco / maxf(cierre, Config.slam_caida * 0.5)
	if not en_suelo and _t_pizza <= 0.0:
		# En el aire sigue su arco; si toca suelo antes, el picado lo alcanza ahí.
		var g := Config.gravedad
		var discriminante := cierre * cierre - 2.0 * g * hueco
		tiempo = INF if discriminante < 0.0 else (cierre - sqrt(discriminante)) / g
		var bajar := maxf(0.0, _suelo_y - global_position.y)
		var aterriza := (-velocidad.y + sqrt(velocidad.y * velocidad.y + 2.0 * g * bajar)) / g
		if aterriza < tiempo:
			tiempo = maxf(aterriza, (_suelo_y - radios * 0.5 - melon.global_position.y) / caida)
		if is_inf(tiempo):
			return Vector2(-1.0, INF)
	return Vector2(tiempo, diferencia.x + (velocidad.x - melon.linear_velocity.x) * tiempo)


## Desvío horizontal que el picado alcanza a corregir antes del choque. Es poco
## al picar de cerca y más al picar desde lo alto, pero nunca cubre un mal cálculo.
## confianza < 1 deja holgura, para avisar solo de caídas seguras.
func alcance_slam(melon: Melon, tiempo: float, confianza := 1.0) -> float:
	return radio + melon.radio + (margen_slam(melon) + 0.5 * Config.slam_guiado * tiempo * tiempo) * confianza


## Barrido relativo entre ambos melones para no saltarse impactos a gran velocidad.
func recibir_slam(melon: Melon) -> bool:
	if usado or roto or not melon.slam_activo or not melon.controlable or melon.roto:
		return false
	if not _golpe_desde_arriba(melon.origen_slam - anterior, melon.global_position - global_position,
			radio + melon.radio, margen_slam(melon)):
		return false
	usado = true
	Sonidos.muerte(self)
	melon.acertar_slam()
	_aplastar()
	return true


## Picado de otro rival. El de abajo queda aplastado y pierde resistencia (puede
## romperse); sigue sirviendo de objetivo al jugador. El atacante sale impulsado.
func recibir_slam_rival(atacante: MelonRodante) -> bool:
	if atacante == self or roto or en_bajada or not atacante.slam_activo or atacante.roto or not atacante._picado_bueno:
		return false
	var margen: float = Config.slam_margen.x * _rasgo("margen_slam")
	if not _golpe_desde_arriba(atacante.anterior - anterior, atacante.global_position - global_position,
			radio + atacante.radio, margen):
		return false
	Sonidos.muerte(self)
	atacante.acertar_slam_rival()
	_t_aplastado = Config.aplastado_melones
	velocidad = Vector2(velocidad.x * 0.5, maxf(velocidad.y, 0.0) + 300.0)
	slam_activo = false
	_t_pizza = 0.0
	danar(Config.dano_slam_rival)
	return true


## Como Melon.acertar_slam(): sale hacia arriba con más avance y recupera una carga.
func acertar_slam_rival() -> void:
	if not slam_activo or roto:
		return
	slam_activo = false
	_victima = null
	_t_slam = Config.slam_recarga_rival
	velocidad = Vector2(maxf(velocidad.x, minf(velocidad.x + Config.slam_impulso.x, Config.vel_crucero)), Config.slam_impulso.y)
	en_suelo = false
	cargas = mini(cargas + 1, Config.cargas_max_rival)
	_t_soplo = 0.3
	maniobra.emit(self, "slam")


## desde/hasta: posición del que pica relativa a este melón antes y después del paso.
## El margen solo ensancha el golpe: conserva la altura real y exige caer desde arriba.
func _golpe_desde_arriba(desde: Vector2, hasta: Vector2, suma_radios: float, margen: float) -> bool:
	var escala_x := suma_radios / (suma_radios + margen)
	desde.x *= escala_x
	hasta.x *= escala_x
	var movimiento := hasta - desde
	if movimiento.y <= 0.0 or desde.y >= -radio * 0.25:
		return false
	var contacto := desde
	if desde.length_squared() > suma_radios * suma_radios:
		var a := movimiento.length_squared()
		var b := 2.0 * desde.dot(movimiento)
		var c := desde.length_squared() - suma_radios * suma_radios
		var discriminante := b * b - 4.0 * a * c
		if discriminante < 0.0:
			return false
		var t := (-b - sqrt(discriminante)) / (2.0 * a)
		if t < 0.0 or t > 1.0:
			return false
		contacto = desde + movimiento * t
	return contacto.y < -radio * 0.25


## Queda achatado y frenado un momento; después cae y sigue corriendo, ya sin servir de apoyo.
func _aplastar() -> void:
	_t_aplastado = Config.aplastado_melones
	velocidad = Vector2(velocidad.x * 0.5, maxf(velocidad.y, 0.0) + 300.0)
	slam_activo = false
	_t_pizza = 0.0
	modulate = Color(0.78, 0.78, 0.78)
	marcar(Marca.NINGUNA)


func marcar(nueva: Marca) -> void:
	if nueva != marca:
		marca = nueva
		queue_redraw()


# --- Dibujo ------------------------------------------------------------------

## Debajo, el soplo del último impulso y la pizza; alrededor, picado, escudo y café;
## encima, el poder activo y la mira (amarilla si un slam ahora acierta, coral si
## el picado ya va hacia él). Roto, solo la explosión.
func _draw() -> void:
	if roto:
		_dibujar_explosion(1.0 - _t_rotura / Config.explosion_rival, 1.3)
		return
	if _t_soplo > 0.0:
		var a := _t_soplo / 0.3
		for lado in [-1.0, 1.0]:
			Sprites.dibujar(self, "efectos/soplo", Rect2(lado * radio * 0.5 - 14, radio + 6 + 14 * (1 - a), 28, 18), Color(1, 1, 1, 0.8 * a))
	if slam_activo:
		var escala := radio / 32.0
		Sprites.girar(self, "efectos/slam", Transform2D(0.0, Vector2.ONE * escala, 0, Vector2(0, -12 * escala)), Color("ffc83d"))
	if escudo:
		Sprites.aro(self, Vector2.ZERO, radio + 10, Color(0.7, 0.4, 1, 0.5))
	if _t_cafe > 0.0:
		Sprites.dibujar(self, "efectos/cafe_velocidad", Rect2(-radio - 26, -10, 24, 20), Color("d6a471"))
	if _t_pizza > 0.0:
		Sprites.disco(self, Vector2(0, radio + 4), radio * 0.9, Color(Config.poderes["pizza"]["color"], 0.8))
	if _t_explosion > 0.0:
		_dibujar_explosion(1.0 - _t_explosion / DURACION_EXPLOSION, 1.0)
	if _t_insignia > 0.0 and marca == Marca.NINGUNA:
		var escala := 0.5
		draw_set_transform(Vector2(0, -radio - Poder.RADIO_INSIGNIA * escala - 6), 0.0, Vector2.ONE * escala)
		Poder.dibujar_insignia(self, _insignia)
		draw_set_transform(Vector2.ZERO)
	if marca == Marca.NINGUNA:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var color := COLOR_ACERTABLE if marca == Marca.ACERTABLE else COLOR_FIJADO
	var r := radio + 12.0 + (3.0 * sin(t * 10.0) if marca == Marca.ACERTABLE else 0.0)
	Sprites.aro(self, Vector2.ZERO, r, color)
	for i in 4:
		var a := i * PI * 0.5 + t * 1.5
		Sprites.girar(self, "efectos/linea", Transform2D(a, Vector2(14.0 / 32, 1), 0, Vector2.from_angle(a) * r), color)
	var punta := Vector2(0, -r - 6 - 4 * absf(sin(t * 6)))
	Sprites.dibujar(self, "efectos/triangulo", Rect2(punta + Vector2(-12, -14), Vector2(24, 16)), color)


## Como Melon._dibujar_explosion() con una sola imagen: crece y se desvanece.
func _dibujar_explosion(avance: float, tamano: float) -> void:
	var lado := radio * lerpf(1.6, 5.0, avance) * tamano
	draw_texture_rect(EXPLOSION, Rect2(-Vector2.ONE * lado * 0.5, Vector2.ONE * lado), false, Color(1, 1, 1, 1.0 - avance))


func _actualizar_aspecto() -> void:
	$Lienzo.render_target_update_mode = SubViewport.UPDATE_ONCE
	$Lienzo/Dibujo.queue_redraw()


func _dibujar_aspecto() -> void:
	Aspecto.dibujar_melon($Lienzo/Dibujo, radio, aspecto.get("accesorios", []), roto, true, aspecto)
