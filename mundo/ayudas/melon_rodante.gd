class_name MelonRodante
extends Node2D
## Rival que corre como el jugador: acelera en las bajadas, despega en las crestas,
## rebota al caer y salta de vez en cuando. Si el jugador vuela alto y cerca, lo sigue
## con impulsos en el aire, un poco por debajo. Solo recibe golpes de un slam desde arriba.
##
## Cada uno tiene un carácter (Config.tipos_melones): los tontos van lentos, saltan sin
## ton ni son, tropiezan y son fáciles de aplastar; los listos van más rápido y a
## veces esquivan el primer picado que los apunta.
##
## No usa el motor de física: sigue la altura del terreno con Tramo.altura() para
## avanzar de un tramo a otro sin colisiones con el jugador ni con los obstáculos.

var radio := 30.0
var rapidez := 480.0                    # px/s de crucero; la pendiente la sube o la baja
var velocidad := Vector2.ZERO
var aspecto: Dictionary = {}
var tipo := "normal"                    # clave de Config.tipos_melones
var usado := false
var anterior := Vector2.ZERO
var en_bajada := false
var en_suelo := false
var saltos := true                      # false = solo rueda (pruebas)
var en_mira := false                    # un picado lo apunta: no salta ni impulsa rebotes
var marca := Marca.NINGUNA              # aviso dibujado encima (lo decide GeneradorTerreno)
var rng := RandomNumberGenerator.new()
var _bajada: BajadaXallitic
var _x_bajada := 0.0
var _carril := 0.0
var _ritmo := 1.0
var _velocidad_salida := 0.0
var _giro := 0.0                        # rad/s del dibujo en el aire
var _t_salto := 0.0
var _t_aplastado := 0.0
var _suelo_y := 0.0                     # y de su centro al tocar el suelo debajo
var _bajo_jugador := 250.0              # px por debajo del jugador cuando lo sigue al aire
var _t_aleteo := 0.0                    # espera entre impulsos en el aire
var _t_soplo := 0.0                     # dibujo del último impulso
var _t_tropiezo := 0.0                  # tonto: frenado un momento
var _esquivo := false                   # listo: ya intentó esquivar (solo una vez)

enum Marca { NINGUNA, ACERTABLE, FIJADO }
const COLOR_ACERTABLE := Color("ffc83d")
const COLOR_FIJADO := Color("ff6b4a")


func _ready() -> void:
	z_index = 3
	anterior = global_position
	$Lienzo.world_2d = World2D.new()
	$Aspecto.texture = $Lienzo.get_texture()
	_actualizar_aspecto()


func configurar(datos: Dictionary) -> void:
	aspecto = datos.duplicate(true)
	tipo = aspecto.get("tipo", "normal")
	radio = Config.tamanos[aspecto.get("tamano", 2)]["radio"]
	if is_node_ready():
		_actualizar_aspecto()


## Rapidez de crucero y semilla de sus saltos.
func preparar_carrera(p_rapidez: float, semilla: int) -> void:
	rapidez = p_rapidez * _rasgo("ritmo")
	rng.seed = semilla
	_t_salto = _pausa_salto()
	_bajo_jugador = rng.randf_range(Config.bajo_jugador_melones.x, Config.bajo_jugador_melones.y)


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


## jugador ajusta el ritmo para no alejarse demasiado y la altura a la que vuela;
## NAN = sin ajuste. vel_jugador marca su ritmo cuando lo sigue por el aire.
func avanzar(terreno: GeneradorTerreno, delta: float, jugador := Vector2(NAN, NAN), vel_jugador := Vector2.ZERO) -> void:
	anterior = global_position
	if marca != Marca.NINGUNA or _t_soplo > 0.0:
		queue_redraw()                  # anima la mira y borra el soplo al terminar
	_t_aplastado = maxf(0.0, _t_aplastado - delta)
	_t_aleteo = maxf(0.0, _t_aleteo - delta)
	_t_soplo = maxf(0.0, _t_soplo - delta)
	_t_tropiezo = maxf(0.0, _t_tropiezo - delta)
	if en_mira and not _esquivo and not usado:
		_esquivo = true
		if rng.randf() < _rasgo("esquiva"):
			_esquivar(jugador.x)
	var aplastado := _t_aplastado / Config.aplastado_melones
	scale = Vector2(1.0 + 0.25 * aplastado, 1.0 - 0.35 * aplastado)
	$Aspecto.position.y = radio / scale.y - radio     # achatado sin despegarse del suelo
	if en_bajada:
		_avanzar_bajada(delta)
		return
	var tramo := _tramo_en(terreno, global_position.x)
	if tramo == null:
		return
	_suelo_y = tramo.altura(global_position.x) - radio
	var vuelo_y := _altura_vuelo(jugador, vel_jugador)
	if en_suelo:
		_rodar(tramo, delta, jugador.x, vuelo_y)
	else:
		_volar(delta, jugador.x, vel_jugador, vuelo_y)
	var siguiente := global_position + velocidad * delta + Vector2(0.0, 0.5 * Config.gravedad * delta * delta)
	var tramo_siguiente := _tramo_en(terreno, siguiente.x)
	if tramo_siguiente == null:
		return
	var suelo := tramo_siguiente.altura(siguiente.x) - radio
	if siguiente.y < suelo - 1.0:
		# Si el suelo cae más rápido que la gravedad, despega como el jugador en una cresta.
		if en_suelo:
			en_suelo = false
			_giro = velocidad.x / radio
		velocidad.y += Config.gravedad * delta
		global_position = siguiente
		$Aspecto.rotation += _giro * delta
		return
	global_position = Vector2(siguiente.x, suelo)
	if not en_suelo:
		_aterrizar(tramo_siguiente.pendiente(siguiente.x))
	$Aspecto.rotation += velocidad.length() * signf(velocidad.x) * delta / radio


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


## Más rápido si se quedó atrás del jugador, más lento si le saca ventaja.
func _ajuste_ritmo(x_jugador: float) -> float:
	if is_nan(x_jugador):
		return 1.0
	var atras := (x_jugador - global_position.x) / Config.alcance_ritmo_melones
	return clampf(1.0 + atras, Config.ritmo_melones.x, Config.ritmo_melones.y)


## y a la que sigue al jugador por el aire, o NAN si el jugador va bajo, lejos o en
## picado, o si este melón ya recibió un slam. Así nunca sube al encuentro de un slam.
func _altura_vuelo(jugador: Vector2, vel_jugador: Vector2) -> float:
	if usado or not _rasgo("sigue_aire") or is_nan(jugador.x) or absf(jugador.x - global_position.x) > Config.alcance_vuelo_melones:
		return NAN
	if vel_jugador.y >= Config.slam_caida * 0.9:
		return NAN
	if _suelo_y - jugador.y < Config.vuelo_melones_desde:
		return NAN
	return jugador.y + _bajo_jugador


## En el aire: si sigue al jugador, ajusta su avance al de él y se impulsa al
## caer por debajo de su altura de vuelo. Si no, solo cae.
func _volar(delta: float, x_jugador: float, vel_jugador: Vector2, vuelo_y: float) -> void:
	if is_nan(vuelo_y):
		return
	var objetivo := maxf(rapidez, vel_jugador.x) * _ajuste_ritmo(x_jugador)
	velocidad.x = move_toward(velocidad.x, objetivo, Config.control_vuelo_melones * delta)
	if velocidad.y > 0.0 and global_position.y > vuelo_y and _t_aleteo <= 0.0 and not en_mira:
		_impulsar_hacia(vuelo_y)


## Impulso hacia arriba para llegar a la altura y, con un tope como el del papalote.
func _impulsar_hacia(y: float) -> void:
	var subir := maxf(0.0, global_position.y - y) + Config.margen_vuelo_melones
	velocidad.y = -minf(sqrt(2.0 * Config.gravedad * subir), Config.impulso_vuelo_melones)
	_t_aleteo = rng.randf_range(Config.aleteo_melones.x, Config.aleteo_melones.y)
	_t_soplo = 0.3
	en_suelo = false
	_giro = velocidad.x / radio


## En el suelo: la pendiente acelera o frena, y un empuje propio lo lleva a su ritmo.
func _rodar(tramo: Tramo, delta: float, x_jugador: float, vuelo_y: float) -> void:
	var pendiente := tramo.pendiente(global_position.x)
	var adelante := Vector2(cos(pendiente), sin(pendiente))
	var s := velocidad.dot(adelante) + Config.gravedad * sin(pendiente) * delta
	var objetivo := rapidez * _ajuste_ritmo(x_jugador)
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
	if not is_nan(vuelo_y) and _t_aleteo <= 0.0 and not en_mira and _t_aplastado <= 0.0:
		_impulsar_hacia(vuelo_y)
		return
	_t_salto -= delta
	if saltos and not en_mira and _t_salto <= 0.0 and _t_aplastado <= 0.0:
		_t_salto = _pausa_salto()
		velocidad.y = -rng.randf_range(Config.salto_melones.x, Config.salto_melones.y)
		en_suelo = false
		_giro = velocidad.x / radio


## Conserva la velocidad a lo largo del suelo y rebota según su tamaño. A veces
## impulsa el rebote, como el jugador cuando acierta el aro verde.
func _aterrizar(pendiente: float) -> void:
	var nrm := Vector2(sin(pendiente), -cos(pendiente))
	var impacto := maxf(0.0, -velocidad.dot(nrm))
	var tangente := velocidad + nrm * impacto
	var rebote: float = Config.tamanos[aspecto.get("tamano", 2)]["rebote"]
	if saltos and not en_mira and _t_aplastado <= 0.0 and impacto > Config.rebote_min * 0.6 and rng.randf() < Config.prob_rebote_melones:
		rebote = Config.rebote_mult_normal
	var salida := impacto * rebote
	if salida < Config.salida_min_melones:
		en_suelo = true
		velocidad = tangente * Config.lado_redondo_conserva
	else:
		velocidad = tangente * Config.lado_redondo_conserva + nrm * salida
	_giro = velocidad.x / radio


## Valor de su carácter en Config.tipos_melones.
func _rasgo(clave: String) -> Variant:
	return Config.tipos_melones[tipo][clave]


func _pausa_salto() -> float:
	return rng.randf_range(Config.pausa_saltos_melones.x, Config.pausa_saltos_melones.y) * _rasgo("pausa_saltos")


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


func margen_slam(melon: Melon) -> float:
	var margen := absf(melon.linear_velocity.x - velocidad.x) * Config.slam_tolerancia
	return clampf(margen, Config.slam_margen.x, Config.slam_margen.y) * _rasgo("margen_slam")


## Anticipa un picado sobre este melón: x = segundos hasta alcanzarlo,
## y = distancia horizontal que faltaría entonces (positiva si queda a la derecha).
## Devuelve x < 0 si no está debajo o queda fuera de alcance.
func prevision_slam(melon: Melon) -> Vector2:
	var diferencia := global_position - melon.global_position
	var radios := radio + melon.radio
	if usado or diferencia.y <= radios * 0.25 or diferencia.y >= Config.slam_alcance:
		return Vector2(-1.0, INF)
	var caida := maxf(Config.slam_caida, melon.linear_velocity.y)
	var hueco := maxf(0.0, diferencia.y - radios * 0.5)
	var cierre := caida - velocidad.y
	var tiempo := hueco / maxf(cierre, Config.slam_caida * 0.5)
	if not en_suelo:
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
	if usado or not melon.slam_activo or not melon.controlable or melon.roto:
		return false
	var desde := melon.origen_slam - anterior
	var hasta := melon.global_position - global_position
	var suma_radios := radio + melon.radio
	# El margen solo ensancha el golpe: conserva la altura real y exige caer desde arriba.
	var escala_x := suma_radios / (suma_radios + margen_slam(melon))
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
	if contacto.y >= -radio * 0.25:
		return false
	usado = true
	Sonidos.muerte(self)
	melon.acertar_slam()
	_aplastar()
	return true


## Queda achatado y frenado un momento; después cae y sigue corriendo, ya sin servir de apoyo.
func _aplastar() -> void:
	_t_aplastado = Config.aplastado_melones
	velocidad = Vector2(velocidad.x * 0.5, maxf(velocidad.y, 0.0) + 300.0)
	modulate = Color(0.78, 0.78, 0.78)
	marcar(Marca.NINGUNA)


func marcar(nueva: Marca) -> void:
	if nueva != marca:
		marca = nueva
		queue_redraw()


## Mira encima del melón: amarilla si un slam ahora acierta, coral si el picado ya va hacia él.
## Debajo, el soplo del último impulso en el aire.
func _draw() -> void:
	if _t_soplo > 0.0:
		var a := _t_soplo / 0.3
		for lado in [-1.0, 1.0]:
			Sprites.dibujar(self, "efectos/soplo", Rect2(lado * radio * 0.5 - 14, radio + 6 + 14 * (1 - a), 28, 18), Color(1, 1, 1, 0.8 * a))
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


func _actualizar_aspecto() -> void:
	$Lienzo.render_target_update_mode = SubViewport.UPDATE_ONCE
	$Lienzo/Dibujo.queue_redraw()


func _dibujar_aspecto() -> void:
	Aspecto.dibujar_melon($Lienzo/Dibujo, radio, aspecto.get("accesorios", []), false, true, aspecto)
