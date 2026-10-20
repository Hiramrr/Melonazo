class_name Melon
extends RigidBody2D
## El melón del recorrido: un cuerpo rígido circular que controla el jugador.
##
## Escena: melon/melon.tscn
##   Cuerpo                  CollisionShape2D circular (el radio depende del tamaño)
##   Aspecto                 dibujo (con los PNG de los accesorios, sin colisión) que se conserva hasta cambiar equipo o romperse
##   Lienzo                  textura del aspecto, dibujada una vez a doble resolución
##   Estela                  rastro decorativo (melon/estela.gd)
##
## Qué hace este script:
##   - Lee el control del jugador: giro (A/D), salto/rebote (Espacio), accesorios (1-2-3).
##   - Ajusta la física en _integrate_forces(): aterrizajes, rodado, efectos activos.
##   - Ofrece "efectos" (planear, rodar, proteger...) que usan los accesorios y poderes.
##
## Otros nodos no cambian linear_velocity directamente: piden cambios con empujar(),
## frenar() o fijar_velocidad(), y el melón los aplica en el siguiente paso de física.
## El dibujo (piel, cara, dibujo libre, accesorios) está en melon/aspecto.gd.

signal aviso(texto: String)             ## texto flotante para el recorrido
signal se_rompio                        ## sin resistencia: termina la carrera
signal danado(cantidad: float)          ## perdió resistencia (1.0 = un golpe completo)
signal maniobra(tipo: String)          ## rebote impulsado o slam acertado

# Imágenes de los poderes sobre el melón. Se cambian en el inspector de melon.tscn
# (cualquier Texture2D: PNG, WebP o un AtlasTexture de una hoja de sprites).
## Explosión del chile jalapeño. Si es una tira horizontal, indica sus cuadros.
@export var textura_explosion: Texture2D
@export_range(1, 32) var cuadros_explosion := 1
const DURACION_EXPLOSION := 0.45

# --- Estado general ----------------------------------------------------------
var tamano := 1                         # índice en Config.tamanos
var slots: Array = [null, null, null]   # accesorio por tecla 1-2-3 (null = usado/perdido)
var radio := 22.0
var vel_crucero := 1800.0
var resistencia := 3.0                  # golpes que aguanta antes de romperse; las caídas
var resistencia_max := 3.0              # medianas quitan fracciones
var rebotes := 1                        # cargas para saltar o rebotar con impulso
var controlable := false                # true después del trampolín y antes del final
var roto := false
var slam_activo := false
var t_slam := 0.0                      # recarga independiente de los saltos
var origen_slam := Vector2.ZERO        # posición anterior para detectar impactos entre pasos

# --- Contacto con el suelo ---------------------------------------------------
var en_suelo := false
var normal_suelo := Vector2.UP
var t_aire := 0.0                       # segundos desde que dejó el suelo
var t_impacto := -1.0                   # tiempo estimado al suelo (aro indicador); -1 = no se sabe

# --- Temporizadores de efectos (segundos que les quedan) ---------------------
# Todos los que empiezan con t_ se descuentan solos en _physics_process().
var t_rebote := 0.0                     # ventana abierta tras pulsar Espacio antes de caer
var t_bloqueo := 0.0                    # evita machacar Espacio
var t_planeo := 0.0
var g_planeo := 1.0                     # gravity_scale durante el planeo
var t_embestida := 0.0                  # rompe puestos
var t_llantas := 0.0
var a_llantas := 0.0                    # px/s² a lo largo del suelo
var llantas_armadas := false            # rodar() en el aire espera a tocar suelo
var _dur_llantas := 0.0
var t_paraguas := 0.0
var g_paraguas := 1.0
var v_paraguas := INF                   # velocidad máxima de caída
var escudo := false                     # la siguiente caída fuerte no cuesta resistencia
var t_invulnerable := 0.0               # parpadeo tras un golpe
var t_cafe := 0.0                       # saltos sin gastar cargas
var t_pizza := 0.0                      # tiempo restante de abducción
var y_pizza := 0.0                      # altura inicial de la abducción
var velocidad_pizza := 0.0
var t_explosion := 0.0                  # dibujo de la explosión del chile
var t_iman := 0.0                       # atrae aplausos (lo aplica Recorrido)
const TEMPORIZADORES := ["t_rebote", "t_bloqueo", "t_planeo", "t_embestida", "t_llantas",
	"t_paraguas", "t_invulnerable", "t_cafe", "t_pizza", "t_explosion", "t_iman", "t_slam"]

# --- Cambios de velocidad pedidos desde fuera (se aplican en _integrate_forces) ---
var _v_prev := Vector2.ZERO             # velocidad del paso anterior (para medir impactos)
var _dv := Vector2.ZERO                 # suma de empujar()
var _mult := 1.0                        # producto de frenar()
var _fijar := false                     # fijar_velocidad() pendiente
var _v_fijar := Vector2.ZERO
var _activos: Array = []                # [{acc, t}] accesorios con física propia
var _consulta: PhysicsShapeQueryParameters2D


func _ready() -> void:
	$Lienzo.world_2d = World2D.new()
	$Aspecto.texture = $Lienzo.get_texture()


## Prepara el melón para una carrera. ids = accesorios equipados por tecla.


func configurar(p_tamano: int, ids: Array, p_resistencia: float, p_rebotes: int, p_crucero := 0.0) -> void:
	tamano = p_tamano
	vel_crucero = p_crucero if p_crucero > 0.0 else Config.vel_crucero
	var d := datos()
	radio = d["radio"]
	mass = d["masa"]
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = d["amortiguacion"]
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp = 0.3
	var mat := PhysicsMaterial.new()
	mat.bounce = d["rebote"]
	mat.friction = d["friccion"]
	physics_material_override = mat
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 4
	can_sleep = false
	collision_layer = 2
	collision_mask = 1
	resistencia_max = p_resistencia
	resistencia = p_resistencia
	rebotes = p_rebotes
	slots = [null, null, null]
	_activos.clear()
	for i in mini(ids.size(), Config.max_accesorios):
		if Config.accesorios.has(ids[i]):
			slots[i] = ids[i]
	_crear_forma()
	_actualizar_aspecto()


## Valores del tamaño actual en Config.tamanos.
func datos() -> Dictionary:
	return Config.tamanos[tamano]


func carisma() -> int:
	return Juego.carisma_de(slots)


## Ajusta la forma de colisión al radio. Los accesorios no tienen colisión.
func _crear_forma() -> void:
	var cs := CircleShape2D.new()
	cs.radius = radio
	($Cuerpo as CollisionShape2D).shape = cs


func _quitar_slot(i: int) -> void:
	slots[i] = null
	_actualizar_aspecto()


# --- Pedidos desde fuera -----------------------------------------------------

## Suma un cambio de velocidad en el siguiente paso de física.
func empujar(dv: Vector2) -> void:
	_dv += dv


## Multiplica la velocidad; los melones con más inercia lo resienten menos.
## Un frenón interrumpe la abducción para conservar la penalización.
func frenar(mult: float) -> void:
	_mult *= lerpf(mult, 1.0, datos()["inercia"])
	if mult < 1.0:
		t_pizza = 0.0


## Reemplaza la velocidad en el siguiente paso de física.
func fijar_velocidad(v: Vector2) -> void:
	_fijar = true
	_v_fijar = v


## Resta un golpe completo de resistencia, salvo si algo lo protege.
func golpe() -> void:
	danar(1.0)


## Resta resistencia, salvo si algo lo protege. Solo un golpe completo da
## invulnerabilidad y aviso; los raspones solo bajan la barra.
func danar(cantidad: float) -> void:
	if t_invulnerable > 0.0 or roto or cantidad <= 0.0:
		return
	resistencia = maxf(0.0, resistencia - cantidad)
	danado.emit(cantidad)
	if cantidad >= 1.0:
		t_invulnerable = Config.invulnerable_tras_golpe
		aviso.emit("¡Golpe!")
	if resistencia <= 0.0:
		roto = true
		controlable = false
		_actualizar_aspecto()
		Sonidos.muerte(self)
		se_rompio.emit()


## Usa (y consume) el accesorio de la tecla i + 1.
func usar(i: int) -> void:
	if i < 0 or i >= slots.size() or not controlable or roto:
		return
	var id = slots[i]
	if id == null:
		return
	var acc: Accesorio = Config.accesorios[id]
	_quitar_slot(i)
	acc.usar(self)
	aviso.emit(acc.texto_aviso())


# --- Efectos que pueden usar los accesorios ----------------------------------

## Menos gravedad durante dur segundos.
func planear(dur: float, gravedad: float) -> void:
	t_planeo = dur
	g_planeo = gravedad


## Impulso que además rompe obstáculos frágiles durante dur segundos.
func embestir(dur: float, impulso: Vector2) -> void:
	t_embestida = maxf(t_embestida, dur)
	_dv += impulso


## Menos gravedad y una velocidad de caída máxima. Termina al tocar suelo.
func caida_lenta(dur: float, gravedad: float, vel_max: float) -> void:
	t_paraguas = dur
	g_paraguas = gravedad
	v_paraguas = vel_max


## Acelera rodando dur segundos. Si está en el aire, espera a tocar suelo.
func rodar(dur: float, aceleracion: float) -> void:
	a_llantas = aceleracion
	if en_suelo:
		t_llantas = dur
	else:
		llantas_armadas = true
		_dur_llantas = dur


## La siguiente caída fuerte no cuesta resistencia.
func proteger() -> void:
	escudo = true


## Recupera resistencia sin pasar del máximo.
func reparar(puntos := 1.0) -> void:
	resistencia = minf(resistencia_max, resistencia + puntos)


## Durante dur segundos los aplausos cercanos vuelan hacia el melón.
func atraer_aplausos(dur: float) -> void:
	t_iman = maxf(t_iman, dur)


## Suma cargas de salto; puede pasar del máximo (la jarana lo usa).
func sumar_rebote(n := 1) -> void:
	rebotes += n


## true si puede saltar o rebotar: le quedan cargas o tiene el café activo.
func puede_saltar() -> bool:
	return rebotes > 0 or t_cafe > 0.0


## Salto desde el suelo o en el aire. Consume una carga, salvo con el café.
## Devuelve false si no pudo.
func saltar() -> bool:
	if not controlable or roto or slam_activo or not puede_saltar() or t_bloqueo > 0.0:
		return false
	if t_cafe > 0.0:
		t_bloqueo = Config.cafe_bloqueo
	else:
		rebotes -= 1
		t_bloqueo = Config.bloqueo_rebote
	t_rebote = 0.0
	t_pizza = 0.0
	var caida := linear_velocity.y + _dv.y
	empujar(Vector2(Config.salto_aereo_avance, minf(0.0, -Config.salto_aereo_vel - caida)))
	aviso.emit("¡Salto aéreo!" if not en_suelo else "¡Arriba!")
	return true


## Picado sin gastar saltos. Se resuelve al golpear otro melón o el suelo.
func iniciar_slam() -> bool:
	if not controlable or roto or en_suelo or slam_activo or t_slam > 0.0:
		return false
	slam_activo = true
	origen_slam = global_position
	t_rebote = 0.0
	t_planeo = 0.0
	t_pizza = 0.0
	t_paraguas = 0.0
	aviso.emit("¡Slam!")
	return true


func acertar_slam() -> void:
	if not slam_activo or not controlable or roto:
		return
	slam_activo = false
	t_slam = Config.slam_recarga
	# _mult cuenta un frenón del mismo paso; si no, el slam lo borraría al reiniciarlo.
	var vx := maxf(0.0, linear_velocity.x * _mult + _dv.x)
	fijar_velocidad(Vector2(_impulso_hasta_crucero(vx, Config.slam_impulso.x), Config.slam_impulso.y))
	_dv = Vector2.ZERO
	_mult = 1.0
	rebotes = maxi(rebotes, Config.slam_saltos_min)
	aviso.emit("¡Slam acertado! Más velocidad")
	maniobra.emit("slams")


## Suma la ganancia hasta vel_crucero; si ya iba más rápido, no gana ni pierde.
## Así encadenar slams o rebotes sostiene el ritmo, pero no lo dispara sin límite.
func _impulso_hasta_crucero(rapidez: float, ganancia: float) -> float:
	return maxf(rapidez, minf(rapidez + ganancia, vel_crucero))


## Llama a acc.fisica() en cada paso durante dur segundos.
func activar(acc: Accesorio, dur: float) -> void:
	_activos.append({"acc": acc, "t": dur})


## Aplica un poder del camino (ver Config.poderes).
func recibir_poder(id: String) -> void:
	if not controlable or roto or not Config.poderes.has(id):
		return
	var duracion: float = Config.poderes[id]["duracion"]
	match id:
		"chile":
			var chile = load("res://melon/chile_encendido.gd").new()
			add_child(chile)
		"cafe":
			t_cafe = duracion
		"pizza":
			t_pizza = duracion
			y_pizza = global_position.y
			velocidad_pizza = linear_velocity.x
			var anterior = get_node_or_null("PizzaOvni")
			if anterior != null:
				remove_child(anterior)
				anterior.queue_free()
			var ovni = load("res://melon/pizza_ovni.gd").new()
			ovni.name = "PizzaOvni"
			add_child(ovni)
			slam_activo = false
			t_planeo = 0.0
			t_paraguas = 0.0
		"elote":
			rebotes = maxi(rebotes, Juego.rebotes_max())   # conserva las cargas extra de la jarana
			aviso.emit("¡%s! Saltos recargados" % Config.poderes[id]["nombre"])
			return
	aviso.emit("¡%s!" % Config.poderes[id]["nombre"])


func explotar_chile() -> void:
	if roto or not controlable:
		return
	var impulso: Vector2 = Config.poderes["chile"]["impulso"]
	var v := linear_velocity + _dv
	var destino := Vector2(maxf(v.x + impulso.x, Config.chile_vel_min), minf(v.y, 0.0) + impulso.y)
	empujar(destino - v)
	slam_activo = false
	t_pizza = 0.0
	t_explosion = DURACION_EXPLOSION
	t_embestida = maxf(t_embestida, 0.6)

## Salsa Valentina: vuelve a la carrera con toda la resistencia y sus cargas,
## un rato invulnerable y con impulso para seguir.
func revivir() -> void:
	roto = false
	controlable = true
	slam_activo = false
	resistencia = resistencia_max
	rebotes = maxi(rebotes, Juego.rebotes_max())
	t_invulnerable = Config.valentina_invulnerable
	var v := linear_velocity
	fijar_velocidad(Vector2(maxf(v.x, Config.valentina_impulso.x), minf(v.y, Config.valentina_impulso.y)))
	_actualizar_aspecto()
	aviso.emit("¡Salsa Valentina! Revives")


## Efectos activos para el HUD: [[nombre, segundos restantes], ...].
func efectos_lista() -> Array:
	var lista: Array = [["Café", t_cafe], ["Pizza", t_pizza], ["Aplausos al vuelo", t_iman], ["Planeo", t_planeo], ["Paraguas", t_paraguas], ["Llantitas", t_llantas]]
	for activo in _activos:
		lista.append([activo["acc"].nombre, activo["t"]])
	return lista.filter(func(efecto: Array) -> bool: return efecto[1] > 0.0)



# --- Física ------------------------------------------------------------------

## Descuenta temporizadores y lee las teclas. La física fina va en _integrate_forces().
func _physics_process(delta: float) -> void:
	for nombre in TEMPORIZADORES:
		set(nombre, maxf(0.0, get(nombre) - delta))
	for activo in _activos:
		activo["t"] -= delta
	_activos = _activos.filter(func(a: Dictionary) -> bool: return a["t"] > 0.0)
	if t_pizza > 0.0 and controlable:
		gravity_scale = 0.0
	elif t_planeo > 0.0:
		gravity_scale = g_planeo
	elif t_paraguas > 0.0:
		gravity_scale = g_paraguas
	else:
		gravity_scale = 1.0
	if controlable:
		_estimar_impacto()
		if Input.is_action_just_pressed("slam"):
			iniciar_slam()
		if not slam_activo and Input.is_action_just_pressed("rebote") and puede_saltar() and t_bloqueo <= 0.0:
			if not en_suelo and t_impacto >= 0.0 and t_impacto <= Config.tolerancia_rebote:
				t_rebote = maxf(Config.ventana_rebote, t_impacto + 0.10)
				t_bloqueo = Config.bloqueo_rebote
			else:
				saltar()
		for i in 3:
			if Input.is_action_just_pressed("acc_%d" % (i + 1)):
				usar(i)
	else:
		t_impacto = -1.0
		slam_activo = false
	modulate.a = 0.4 if t_invulnerable > 0.0 and int(t_invulnerable * 16.0) % 2 == 0 else 1.0
	queue_redraw()


## Proyecta la trayectoria con un círculo para saber cuándo tocará suelo.
func _estimar_impacto() -> void:
	t_impacto = -1.0
	if en_suelo:
		return
	if _consulta == null:
		_consulta = PhysicsShapeQueryParameters2D.new()
		var c := CircleShape2D.new()
		c.radius = radio
		_consulta.shape = c
		_consulta.collision_mask = 1
		_consulta.exclude = [get_rid()]
	var t := Config.vista_indicador
	_consulta.transform = Transform2D(0.0, global_position)
	_consulta.motion = linear_velocity * t + 0.5 * Vector2(0.0, Config.gravedad * gravity_scale) * t * t
	var r := get_world_2d().direct_space_state.cast_motion(_consulta)
	if r.size() == 2 and r[1] < 1.0:
		t_impacto = r[1] * t


## Corrige la velocidad del cuerpo en cada paso: aterrizajes, control en el aire,
## rodado, efectos activos y, al final, los pedidos de empujar/frenar/fijar.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var dt := state.step
	var v := state.linear_velocity
	if state.get_contact_count() > 0:
		var nrm := state.get_contact_local_normal(0)
		if nrm.y > 0.0:
			nrm = -nrm
		var aterriza := not en_suelo and t_aire > Config.aire_min_aterrizaje
		en_suelo = true
		normal_suelo = nrm
		if slam_activo and not roto:
			slam_activo = false
			t_slam = Config.slam_recarga
			t_rebote = 0.0
			v = Vector2(_v_prev.x * Config.slam_conserva, 0.0)
			state.angular_velocity = v.x / radio
			aviso.emit("Slam fallado: pierdes velocidad")
		elif aterriza and not roto:
			v = _aterrizar(state, nrm, v)
		t_aire = 0.0
	else:
		en_suelo = false
		t_aire += dt

	# Giro en el aire
	if controlable and not en_suelo:
		var eje := Input.get_axis("izquierda", "derecha")
		if eje != 0.0:
			state.angular_velocity = move_toward(state.angular_velocity, eje * Config.giro_max, Config.giro_acel * dt)
			if eje * v.x < Config.control_aereo_max:
				v.x += eje * minf(Config.control_aereo * dt, Config.control_aereo_max - eje * v.x)

	if t_paraguas > 0.0:
		v.y = minf(v.y, v_paraguas)

	if en_suelo and llantas_armadas:
		llantas_armadas = false
		t_llantas = _dur_llantas
	var tangente := Vector2(-normal_suelo.y, normal_suelo.x)
	if tangente.x < 0.0:
		tangente = -tangente
	if en_suelo and t_llantas > 0.0:
		v += tangente * a_llantas * dt
		state.angular_velocity = v.length() / radio
	elif en_suelo:
		var s := v.length()
		if s > 0.0:
			v = v / s * maxf(0.0, s - float(datos()["friccion_rodado"]) * dt)
	# Tope suave: por encima de la velocidad de crucero el aire frena más.
	var rapidez := v.length()
	if rapidez > vel_crucero:
		v -= v / rapidez * (rapidez - vel_crucero) * Config.arrastre_extra * dt

	if controlable:
		for activo in _activos:
			v = activo["acc"].fisica(self, v, dt)

	if _fijar:
		v = _v_fijar
		_fijar = false
	v = v * _mult + _dv
	if slam_activo:
		v.y = maxf(v.y, Config.slam_caida)
	if t_pizza > 0.0 and controlable:
		v = Vector2(velocidad_pizza, -360.0)
	_mult = 1.0
	_dv = Vector2.ZERO
	state.linear_velocity = v
	_v_prev = v


## Decide la velocidad al tocar suelo tras estar en el aire:
## rebote impulsado o caída sobre el lado redondo.
func _aterrizar(state: PhysicsDirectBodyState2D, nrm: Vector2, v: Vector2) -> Vector2:
	var vp := _v_prev
	var impacto := maxf(0.0, -vp.dot(nrm))
	var tang := vp - nrm * vp.dot(nrm)
	t_paraguas = 0.0

	if t_rebote > 0.0 and puede_saltar():
		if t_cafe <= 0.0:
			rebotes -= 1
		t_rebote = 0.0
		aviso.emit("¡Rebote impulsado!")
		maniobra.emit("rebotes")
		var salida := maxf(impacto * Config.rebote_mult_normal, Config.rebote_min)
		if nrm.y > -0.5:
			# Contra una pared (costado de rampa, escalón): salta por encima, nunca hacia atrás.
			return Vector2(absf(vp.x) * Config.rebote_pared_conserva, -salida)
		var avance := tang.length()
		var rebote := tang.normalized() * _impulso_hasta_crucero(avance, avance * (Config.rebote_mult_tang - 1.0)) + nrm * salida
		if vp.x > 0.0:
			rebote.x = maxf(rebote.x, vp.x * Config.rebote_pared_conserva)
		return rebote

	var mat_rebote: float = datos()["rebote"]
	var umbral: float = datos()["umbral_caida"]
	# Los raspones frenan un poco; una caída fuerte sin rebote, mucho.
	var dureza := smoothstep(umbral * Config.raspon_desde, umbral, impacto)
	var conserva := lerpf(Config.lado_redondo_conserva, Config.caida_conserva, dureza)
	var nueva := tang * conserva + nrm * impacto * mat_rebote
	state.angular_velocity = tang.length() * conserva / radio * signf(tang.x)
	if impacto > umbral:
		if escudo:
			escudo = false
			aviso.emit("El escudo amortiguó la caída")
		else:
			golpe()
	elif impacto > umbral * Config.raspon_desde:
		danar(Config.raspon_max * inverse_lerp(umbral * Config.raspon_desde, umbral, impacto))
	return nueva


# --- Dibujo ------------------------------------------------------------------

func _actualizar_aspecto() -> void:
	$Lienzo.render_target_update_mode = SubViewport.UPDATE_ONCE
	$Lienzo/Dibujo.queue_redraw()


func _dibujar_aspecto() -> void:
	Aspecto.dibujar_melon($Lienzo/Dibujo, radio, slots, roto)


func _draw() -> void:
	if not controlable:
		return
	if slam_activo:
		var giro := -global_rotation
		var escala := radio / 32.0
		var centro := Vector2(0, -12 * escala).rotated(giro)
		Sprites.girar(self, "efectos/slam", Transform2D(giro, Vector2.ONE * escala, 0, centro), Color("ffc83d"))
	if t_embestida > 0.0:
		Sprites.aro(self, Vector2.ZERO, radio + 4, Color(1, 0.55, 0.1, 0.8))
	if escudo:
		Sprites.aro(self, Vector2.ZERO, radio + 10, Color(0.7, 0.4, 1, 0.5))
	if t_cafe > 0.0:
		Sprites.dibujar(self, "efectos/cafe_velocidad", Rect2(-radio - 26, -10, 24, 20), Color("d6a471"))
	if t_explosion > 0.0:
		draw_set_transform(Vector2.ZERO, -global_rotation)
		if t_explosion > 0.0 and textura_explosion != null:
			_dibujar_explosion(1.0 - t_explosion / DURACION_EXPLOSION)
		draw_set_transform(Vector2.ZERO)
	if puede_saltar() and not en_suelo and not slam_activo:
		if t_rebote > 0.0:
			Sprites.aro(self, Vector2.ZERO, radio + 8, Color(1, 1, 1, 0.95))
		elif t_impacto >= 0.0:
			var rr := radio + 6.0 + 60.0 * t_impacto / Config.vista_indicador
			var col := Color(0.3, 1, 0.4, 0.95) if t_impacto <= Config.ventana_rebote else Color(1, 0.85, 0.2, 0.8)
			Sprites.aro(self, Vector2.ZERO, rr, col)


## Con una sola imagen crece y se desvanece; con una tira avanza sus cuadros.
func _dibujar_explosion(avance: float) -> void:
	var centro := Vector2(-radio * 0.6, radio * 0.3)
	var lado := radio * (5.0 if cuadros_explosion > 1 else lerpf(1.6, 5.0, avance))
	var destino := Rect2(centro - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
	if cuadros_explosion <= 1:
		draw_texture_rect(textura_explosion, destino, false, Color(1, 1, 1, 1.0 - avance))
		return
	var ancho := textura_explosion.get_width() / float(cuadros_explosion)
	var cuadro := mini(int(avance * cuadros_explosion), cuadros_explosion - 1)
	draw_texture_rect_region(textura_explosion, destino, Rect2(cuadro * ancho, 0, ancho, textura_explosion.get_height()))
