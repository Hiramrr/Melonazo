class_name Melon
extends RigidBody2D
## El melón: cuerpo rígido circular. Cada accesorio agrega una forma de colisión
## en su lado, así que la orientación al caer importa.
## Lee el control del jugador durante el recorrido (giro, rebote, accesorios).
## Los accesorios viven en scripts/accesorios/ y usan los efectos de abajo.
## El dibujo del melón (piel, cara, dibujo libre) está en scripts/aspecto.gd.

signal aviso(texto: String)
signal se_rompio

var tamano := 1
var slots: Array = [null, null, null]   # accesorio por tecla 1-2-3 (null = usado/perdido)
var radio := 22.0
var resistencia := 3
var resistencia_max := 3
var rebotes := 1
var controlable := false
var roto := false

var en_suelo := false
var normal_suelo := Vector2.UP
var t_aire := 0.0
var t_impacto := -1.0                   # tiempo estimado al suelo (aro indicador)

# Temporizadores de estado
var t_rebote := 0.0                     # ventana abierta tras presionar Espacio
var t_bloqueo := 0.0
var t_planeo := 0.0
var g_planeo := 1.0                     # gravity_scale durante el planeo
var t_embestida := 0.0
var t_llantas := 0.0
var a_llantas := 0.0                    # px/s² a lo largo del suelo
var llantas_armadas := false
var _dur_llantas := 0.0
var t_paraguas := 0.0
var g_paraguas := 1.0
var v_paraguas := INF                   # velocidad máxima de caída
var escudo := false
var t_invulnerable := 0.0
var t_cafe := 0.0
var t_chile := 0.0
var t_niebla := 0.0
var t_iman := 0.0

# Cambios de velocidad pedidos desde fuera; se aplican en _integrate_forces.
var _v_prev := Vector2.ZERO
var _dv := Vector2.ZERO
var _mult := 1.0
var _fijar := false
var _v_fijar := Vector2.ZERO
var _formas := {}                       # CollisionShape2D -> slot
var _activos: Array = []                # [{acc, t}] accesorios con física propia
var _consulta: PhysicsShapeQueryParameters2D


func configurar(p_tamano: int, ids: Array, p_resistencia: int, p_rebotes: int) -> void:
	tamano = p_tamano
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
	_crear_formas()
	queue_redraw()


func datos() -> Dictionary:
	return Config.tamanos[tamano]


func carisma() -> int:
	return Juego.carisma_de(slots)


func _crear_formas() -> void:
	_formas.clear()
	var circulo: CollisionShape2D = $Cuerpo
	var cs := CircleShape2D.new()
	cs.radius = radio
	circulo.shape = cs
	for i in slots.size():
		var nodo: CollisionShape2D = get_node("Accesorio%d" % (i + 1))
		nodo.disabled = slots[i] == null
		if slots[i] == null:
			continue
		var forma := ConvexPolygonShape2D.new()
		forma.set_point_cloud(Config.accesorios[slots[i]].puntos(radio, deg_to_rad(Config.angulos_slots[i])))
		nodo.shape = forma
		_formas[nodo] = i


func _quitar_slot(i: int) -> void:
	for nodo in _formas.keys():
		if _formas[nodo] == i:
			_formas.erase(nodo)
			nodo.set_deferred("disabled", true)
	slots[i] = null
	queue_redraw()


# --- Pedidos desde fuera -----------------------------------------------------

func empujar(dv: Vector2) -> void:
	_dv += dv


## Multiplica la velocidad; los melones con más inercia lo resienten menos.
func frenar(mult: float) -> void:
	if t_niebla > 0.0 or t_chile > 0.0:
		return
	_mult *= lerpf(mult, 1.0, datos()["inercia"])


func fijar_velocidad(v: Vector2) -> void:
	_fijar = true
	_v_fijar = v


func golpe() -> void:
	if t_invulnerable > 0.0 or t_niebla > 0.0 or t_chile > 0.0 or roto:
		return
	resistencia -= 1
	t_invulnerable = Config.invulnerable_tras_golpe
	aviso.emit("¡Golpe! (%d)" % resistencia)
	if resistencia <= 0:
		roto = true
		controlable = false
		queue_redraw()
		se_rompio.emit()


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


func reparar(puntos := 1) -> void:
	resistencia = mini(resistencia_max, resistencia + puntos)


func atraer_aplausos(dur: float) -> void:
	t_iman = maxf(t_iman, dur)


func sumar_rebote(n := 1) -> void:
	rebotes += n


func saltar() -> bool:
	if not controlable or roto or rebotes <= 0 or t_bloqueo > 0.0:
		return false
	rebotes -= 1
	t_rebote = 0.0
	t_bloqueo = Config.bloqueo_rebote
	var caida := linear_velocity.y + _dv.y
	empujar(Vector2(Config.salto_aereo_avance, minf(0.0, -Config.salto_aereo_vel - caida)))
	aviso.emit("¡Salto aéreo!" if not en_suelo else "¡Arriba!")
	return true


## Llama a acc.fisica() en cada paso durante dur segundos.
func activar(acc: Accesorio, dur: float) -> void:
	_activos.append({"acc": acc, "t": dur})


func recibir_poder(id: String) -> void:
	if not controlable or roto or not Config.poderes.has(id):
		return
	var duracion: float = Config.poderes[id]["duracion"]
	match id:
		"cafe":
			t_cafe = duracion
			_dv += Vector2(180, -60)
		"chile":
			t_chile = duracion
			t_embestida = maxf(t_embestida, duracion)
			_dv += Vector2(260, -80)
		"niebla":
			t_niebla = duracion
		"tamal":
			reparar()
			if rebotes < Juego.rebotes_max():
				rebotes += 1
	aviso.emit("¡%s!" % Config.poderes[id]["nombre"])


func efectos_activos() -> String:
	var efectos: Array = []
	var lista: Array = [["Café", t_cafe], ["Chile", t_chile], ["Niebla", t_niebla], ["Aplausos al vuelo", t_iman], ["Planeo", t_planeo], ["Paraguas", t_paraguas], ["Llantitas", t_llantas]]
	for activo in _activos:
		lista.append([activo["acc"].nombre, activo["t"]])
	for efecto in lista:
		if efecto[1] > 0.0:
			efectos.append("%s %.1f s" % [efecto[0], efecto[1]])
	return " · ".join(efectos)


# --- Física ------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	for nombre in ["t_rebote", "t_bloqueo", "t_planeo", "t_embestida", "t_llantas", "t_paraguas", "t_invulnerable", "t_cafe", "t_chile", "t_niebla", "t_iman"]:
		set(nombre, maxf(0.0, get(nombre) - delta))
	for activo in _activos:
		activo["t"] -= delta
	_activos = _activos.filter(func(a: Dictionary) -> bool: return a["t"] > 0.0)
	if t_planeo > 0.0:
		gravity_scale = g_planeo
	elif t_paraguas > 0.0:
		gravity_scale = g_paraguas
	else:
		gravity_scale = 1.0
	if controlable:
		_estimar_impacto()
		if Input.is_action_just_pressed("rebote") and rebotes > 0 and t_bloqueo <= 0.0:
			if not en_suelo and t_impacto >= 0.0 and t_impacto <= Config.ventana_rebote:
				t_rebote = Config.ventana_rebote
				t_bloqueo = Config.bloqueo_rebote
			else:
				saltar()
		for i in 3:
			if Input.is_action_just_pressed("acc_%d" % (i + 1)):
				usar(i)
	else:
		t_impacto = -1.0
	modulate.a = 0.4 if t_invulnerable > 0.0 and int(t_invulnerable * 16.0) % 2 == 0 else 1.0
	queue_redraw()


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
		if aterriza and not roto:
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
	if t_cafe > 0.0 and controlable:
		v.x = maxf(v.x, minf(v.x + Config.cafe_aceleracion * dt, 1400.0))

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
	if rapidez > Config.vel_crucero:
		v -= v / rapidez * (rapidez - Config.vel_crucero) * Config.arrastre_extra * dt

	if controlable:
		for activo in _activos:
			v = activo["acc"].fisica(self, v, dt)

	if _fijar:
		v = _v_fijar
		_fijar = false
	v = v * _mult + _dv
	_mult = 1.0
	_dv = Vector2.ZERO
	state.linear_velocity = v
	_v_prev = v


func _aterrizar(state: PhysicsDirectBodyState2D, nrm: Vector2, v: Vector2) -> Vector2:
	var vp := _v_prev
	var impacto := maxf(0.0, -vp.dot(nrm))
	var tang := vp - nrm * vp.dot(nrm)
	t_paraguas = 0.0

	if t_rebote > 0.0 and rebotes > 0:
		rebotes -= 1
		t_rebote = 0.0
		aviso.emit("¡Rebote impulsado!")
		var salida := maxf(impacto * Config.rebote_mult_normal, Config.rebote_min)
		if nrm.y > -0.5:
			# Contra una pared (costado de rampa, escalón): salta por encima, nunca hacia atrás.
			return Vector2(absf(vp.x) * Config.rebote_pared_conserva, -salida)
		var rebote := tang * Config.rebote_mult_tang + nrm * salida
		if vp.x > 0.0:
			rebote.x = maxf(rebote.x, vp.x * Config.rebote_pared_conserva)
		return rebote

	var nueva := v
	var slot := _slot_en_contacto(state)
	if slot >= 0:
		nueva = v * Config.lado_acc_freno
		state.angular_velocity += randf_range(-1.0, 1.0) * Config.lado_acc_giro
		if impacto > Config.umbral_perder_acc:
			aviso.emit("¡Se cayó: %s!" % Config.accesorios[slots[slot]].nombre)
			_quitar_slot(slot)
		else:
			aviso.emit("De lado...")
	else:
		var mat_rebote: float = datos()["rebote"]
		nueva = tang * Config.lado_redondo_conserva + nrm * impacto * mat_rebote
		if nrm.y < -0.5:
			var adelante := Vector2(-nrm.y, nrm.x)
			if adelante.x < 0.0:
				adelante = -adelante
			nueva += adelante * impacto * Config.caida_a_rodado
		state.angular_velocity = tang.length() / radio * signf(tang.x)

	if impacto > float(datos()["umbral_caida"]) and t_niebla <= 0.0 and t_chile <= 0.0:
		if escudo:
			escudo = false
			aviso.emit("El escudo amortiguó la caída")
		else:
			golpe()
	return nueva


func _slot_en_contacto(state: PhysicsDirectBodyState2D) -> int:
	for c in state.get_contact_count():
		var dueno := shape_find_owner(state.get_contact_local_shape(c))
		var nodo := shape_owner_get_owner(dueno)
		if _formas.has(nodo):
			return _formas[nodo]
	return -1


# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	Aspecto.dibujar_melon(self, radio, slots, roto)
	if not controlable:
		return
	if t_embestida > 0.0:
		draw_arc(Vector2.ZERO, radio + 4, 0.0, TAU, 32, Color(1, 0.55, 0.1, 0.8), 4.0)
	if escudo:
		draw_arc(Vector2.ZERO, radio + 10, 0.0, TAU, 32, Color(0.7, 0.4, 1.0, 0.5), 2.0)
	if t_niebla > 0.0:
		draw_arc(Vector2.ZERO, radio + 14, 0, TAU, 40, Color("b5eee7"), 4, true)
	if t_cafe > 0.0:
		draw_line(Vector2(-radio - 8, -6), Vector2(-radio - 24, -6), Color("d6a471"), 3, true)
		draw_line(Vector2(-radio - 8, 6), Vector2(-radio - 20, 6), Color("d6a471"), 3, true)
	# Aro del rebote impulsado: se cierra conforme se acerca el suelo; verde = ¡ahora!
	if rebotes > 0 and not en_suelo:
		if t_rebote > 0.0:
			draw_arc(Vector2.ZERO, radio + 8, 0.0, TAU, 40, Color(1, 1, 1, 0.95), 4.0)
		elif t_impacto >= 0.0:
			var rr := radio + 6.0 + 60.0 * t_impacto / Config.vista_indicador
			var col := Color(0.3, 1.0, 0.4, 0.95) if t_impacto <= Config.ventana_rebote else Color(1, 0.85, 0.2, 0.8)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, col, 3.0)


## Dibuja un melón con el aspecto guardado en cualquier CanvasItem (también la vista previa del taller).
static func dibujar(ci: CanvasItem, r: float, ids: Array, esta_roto := false, con_accesorios := true) -> void:
	Aspecto.dibujar_melon(ci, r, ids, esta_roto, con_accesorios)
