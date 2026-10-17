class_name MelonesMenu
extends Node2D
## Los melones del menú principal: salen arriba de la bajada de Xallitic, ruedan
## calle abajo hasta el trampolín y explotan si se les da clic.
##
## Cada melón es un MelonMenu (melon_menu.tscn). Este nodo los crea, los mueve con
## una física sencilla sobre Tramo.altura() (gravedad, despegue en los bordes y
## rebote al caer) y dibuja en _draw() los restos de las explosiones: trozos,
## semillas, gotas de jugo, manchas en el empedrado y una onda.

signal melon_explotado

const MelonMenuEscena := preload("res://pantallas/menu/melon_menu.tscn")
const TINTA := Color("203d38")
const GRAVEDAD := 1400.0
const REBOTE := 0.25
const VELOCIDAD_MAX := 1300.0
const MAX_MELONES := 12
const RADIO := Vector2(32.0, 52.0)
const ESPERA := Vector2(0.35, 1.0)     # segundos entre melones nuevos
const CARRIL := Vector2(12.0, 92.0)    # profundidad dentro de la calle (alto 106 px)
const PRECALENTAR := 8.0               # segundos simulados al iniciar
const PULPA_ROJA := Color("ec5b57")
const PULPA_NARANJA := Color("f4a259")
const PIELES_ROJAS := ["clasico", "sandia", "noche", "bugambilia"]

## Calle por la que ruedan. La pone el Menu.
var calle: Tramo
## Más allá de esta x los melones se quitan.
var x_salida := 0.0

var _espera := 0.0
var _trozos: Array[Dictionary] = []    # {pos, vel, rot, giro, vida, forma, color, cascara, suelo}
var _gotas: Array[Dictionary] = []     # {pos, vel, r, color, suelo}
var _manchas: Array[Dictionary] = []   # {pos, r, color, vida}
var _ondas: Array[Dictionary] = []     # {pos, r, vida}


func _ready() -> void:
	z_index = 3


func precalentar() -> void:
	var paso := 1.0 / 60.0
	for i in int(PRECALENTAR / paso):
		_simular(paso)


func _process(delta: float) -> void:
	_simular(delta)
	if not (_trozos.is_empty() and _gotas.is_empty() and _manchas.is_empty() and _ondas.is_empty()):
		queue_redraw()


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _suelo(m: MelonMenu) -> float:
	return calle.altura(m.position.x) + m.carril


# --- Simulación --------------------------------------------------------------

func _simular(delta: float) -> void:
	if calle == null:
		return
	_espera -= delta
	if _espera <= 0.0 and get_child_count() < MAX_MELONES:
		_espera = randf_range(ESPERA.x, ESPERA.y)
		_nuevo_melon()
	for m: MelonMenu in get_children():
		_mover(m, delta)
		if m.position.x > x_salida:
			m.queue_free()
	_simular_restos(delta)


func _nuevo_melon() -> void:
	var m: MelonMenu = MelonMenuEscena.instantiate()
	var datos := _datos_al_azar()
	m.configurar(datos, randf_range(RADIO.x, RADIO.y))
	m.carril = randf_range(CARRIL.x, CARRIL.y)
	var x := Config.bajada_inicio.x - 250.0
	m.position = Vector2(x, calle.altura(x) + m.carril - m.radio)
	m.velocidad = Vector2(randf_range(80.0, 260.0), 0.0)
	m.rotation = randf() * TAU
	# Los de atrás se dibujan primero.
	m.z_index = int(m.carril / 10.0)
	add_child(m)


## Un aspecto al azar. A veces sale el melón del jugador o uno de su almanaque.
func _datos_al_azar() -> Dictionary:
	if randf() < 0.3:
		var propios: Array = [Juego.datos_melon()] + Juego.melones_guardados
		return propios.pick_random()
	return {"piel": randi() % Config.pieles.size(), "patron": randi() % Config.patrones.size(),
		"cara": randi() % (Config.caras.size() - 1), "detalle": randi() % Config.detalles.size(),
		"cuerpo_propio": "", "rayas_propio": "", "dibujo": []}


func _mover(m: MelonMenu, delta: float) -> void:
	m.velocidad.y += GRAVEDAD * delta
	m.velocidad = m.velocidad.limit_length(VELOCIDAD_MAX)
	m.position += m.velocidad * delta
	var piso := _suelo(m)
	if m.position.y + m.radio >= piso:
		m.position.y = piso - m.radio
		var a := calle.pendiente(m.position.x)
		var n := Vector2(sin(a), -cos(a))
		var vn := m.velocidad.dot(n)
		if vn < 0.0:
			m.velocidad -= n * vn * (1.0 + REBOTE)
		m.velocidad *= 1.0 - 0.2 * delta
		m.giro = m.velocidad.dot(Vector2(-n.y, n.x)) / m.radio
	m.rotation += m.giro * delta


func _simular_restos(delta: float) -> void:
	for p in _trozos:
		p.vida -= delta
		p.vel.y += GRAVEDAD * delta
		p.pos += p.vel * delta
		p.rot += p.giro * delta
		var piso: float = calle.altura(p.pos.x) + p.suelo
		if p.pos.y > piso:
			p.pos.y = piso
			p.vel = Vector2(p.vel.x * 0.55, -absf(p.vel.y) * 0.25)
			p.giro *= 0.5
	_trozos = _trozos.filter(func(p: Dictionary) -> bool: return p.vida > 0.0)
	for g in _gotas:
		g.vel.y += GRAVEDAD * delta
		g.pos += g.vel * delta
		var piso: float = calle.altura(g.pos.x) + g.suelo
		if g.pos.y > piso:
			_manchas.append({"pos": Vector2(g.pos.x, piso), "r": g.r * randf_range(1.6, 2.8),
				"color": g.color, "vida": 3.0})
			g.r = 0.0
	_gotas = _gotas.filter(func(g: Dictionary) -> bool: return g.r > 0.0)
	for e in _manchas:
		e.vida -= delta
	for e in _ondas:
		e.vida -= delta
	_manchas = _manchas.filter(func(e: Dictionary) -> bool: return e.vida > 0.0)
	_ondas = _ondas.filter(func(e: Dictionary) -> bool: return e.vida > 0.0)


# --- Clic --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not is_processing_unhandled_input():
		return
	if event is InputEventMouseMotion:
		var encima := _melon_en(get_global_mouse_position()) != null
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if encima else Input.CURSOR_ARROW)
	elif event is InputEventMouseButton:
		var boton := event as InputEventMouseButton
		if boton.pressed and boton.button_index == MOUSE_BUTTON_LEFT:
			var m := _melon_en(get_global_mouse_position())
			if m != null:
				explotar(m)
				get_viewport().set_input_as_handled()


## El melón bajo el punto (el más cercano a la cámara si hay varios), o null.
func _melon_en(punto: Vector2) -> MelonMenu:
	var elegido: MelonMenu = null
	for m: MelonMenu in get_children():
		if m.is_queued_for_deletion() or punto.distance_to(m.position) > m.radio + 10.0:
			continue
		if elegido == null or m.carril > elegido.carril:
			elegido = m
	return elegido


func explotar(m: MelonMenu) -> void:
	var piel: String = Config.pieles[m.datos.get("piel", 0)]["id"]
	var pulpa := PULPA_ROJA if piel in PIELES_ROJAS else PULPA_NARANJA
	var cascara := m.color_cascara()
	var semilla := TINTA if pulpa == PULPA_ROJA else Color("fff3d5")
	var fuerza := m.radio / RADIO.y
	for k in 14:
		var a := randf() * TAU
		var forma := PackedVector2Array()
		var lado := m.radio * randf_range(0.35, 0.6)
		for v in 3:
			forma.append(Vector2.from_angle(v * TAU / 3.0 + randf_range(-0.4, 0.4)) * lado * randf_range(0.7, 1.2))
		_trozos.append({"pos": m.position + Vector2.from_angle(a) * m.radio * 0.4,
			"vel": Vector2.from_angle(a) * randf_range(250.0, 600.0) * fuerza + Vector2(m.velocidad.x * 0.5, -300.0),
			"rot": randf() * TAU, "giro": randf_range(-14.0, 14.0), "vida": randf_range(1.2, 2.0),
			"forma": forma, "color": pulpa, "cascara": cascara, "suelo": m.carril + randf_range(-10, 10)})
	for k in 16:
		var a := randf() * TAU
		_trozos.append({"pos": m.position, "vel": Vector2.from_angle(a) * randf_range(200.0, 500.0) * fuerza + Vector2(0, -220.0),
			"rot": randf() * TAU, "giro": randf_range(-20.0, 20.0), "vida": randf_range(1.0, 1.7),
			"forma": PackedVector2Array(), "color": semilla, "cascara": semilla, "suelo": m.carril + randf_range(-12, 12)})
	for k in 20:
		var a := randf() * TAU
		_gotas.append({"pos": m.position, "vel": Vector2.from_angle(a) * randf_range(150.0, 700.0) * fuerza + Vector2(0, -260.0),
			"r": randf_range(3.0, 7.0), "color": pulpa.lightened(randf_range(0.0, 0.25)), "suelo": m.carril + randf_range(-15, 15)})
	_ondas.append({"pos": m.position, "r": m.radio, "vida": 0.3})
	_asustar_publico(m.position)
	m.queue_free()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	melon_explotado.emit()
	queue_redraw()


## La gente cercana levanta los brazos del susto.
func _asustar_publico(punto: Vector2) -> void:
	for contenedor in ["Decoracion", "Publico"]:
		for p in calle.get_node(contenedor).get_children():
			if p is Persona and p.global_position.distance_to(punto) < 260.0:
				p.t_empuje = 0.6
				p.queue_redraw()


# --- Dibujo de los restos ----------------------------------------------------

func _draw() -> void:
	for e in _manchas:
		Sprites.girar(self, "efectos/disco", Transform2D(0, Vector2(e.r / 32.0, e.r / 32.0 * 0.35), 0, e.pos), Color(e.color, clampf(e.vida, 0.0, 1.0) * 0.8))
	for o in _ondas:
		var u: float = 1.0 - o.vida / 0.3
		Sprites.aro(self, o.pos, o.r * (1 + u * 1.6), Color(1, 0.98, 0.9, 1 - u))
	for p in _trozos:
		var alfa := clampf(p.vida / 0.4, 0, 1)
		if p.forma.is_empty():
			Sprites.girar(self, "efectos/disco", Transform2D(p.rot, Vector2(3.5 / 32, 2.1 / 32), 0, p.pos), Color(p.color, alfa))
		else:
			var tam := Rect2(p.forma[0], Vector2.ZERO)
			for punto in p.forma: tam = tam.expand(punto)
			var escala := maxf(tam.size.x, tam.size.y) / 32.0
			Sprites.girar(self, "efectos/trozo", Transform2D(p.rot, Vector2.ONE * escala, 0, p.pos), Color(p.color, alfa))
	for g in _gotas:
		Sprites.disco(self, g.pos, g.r, g.color)
