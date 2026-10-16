extends Node2D
## Recorrido: lanzamiento desde el puente de Xallitic, terreno por tramos,
## obstáculos, público que empuja, cámara y HUD.

enum Fase { ANGULO, FUERZA, RECORRIDO, FIN }

const TramoEscena := preload("res://escenas/mundo/Tramo.tscn")
const OBSTACULOS := {
	"coladera": preload("res://escenas/mundo/obstaculos/Coladera.tscn"),
	"charco": preload("res://escenas/mundo/obstaculos/Charco.tscn"),
	"puesto": preload("res://escenas/mundo/obstaculos/Puesto.tscn"),
	"poste": preload("res://escenas/mundo/obstaculos/Poste.tscn"),
	"banqueta": preload("res://escenas/mundo/obstaculos/Banqueta.tscn"),
	"rampa": preload("res://escenas/mundo/obstaculos/Rampa.tscn"),
	"toldo": preload("res://escenas/mundo/obstaculos/Toldo.tscn"),
	"aplauso": preload("res://escenas/mundo/obstaculos/Aplauso.tscn"),
}
const PublicoEscena := preload("res://escenas/mundo/Publico.tscn")
const PoderEscena := preload("res://escenas/mundo/Poder.tscn")
const PapaloteEscena := preload("res://escenas/mundo/Papalote.tscn")
const COLORES_CASAS: Array = [
	Color("e3b96f"), Color("ce8879"), Color("9fbab4"), Color("e9dfbf"),
	Color("b5bf96"), Color("c7a2aa"), Color("d59c69"),
]
const COLORES_ROPA: Array = [
	Color(0.85, 0.2, 0.25), Color(0.2, 0.55, 0.3), Color(0.95, 0.95, 0.95), Color(0.25, 0.4, 0.8),
	Color(0.95, 0.7, 0.15), Color(0.6, 0.3, 0.7),
]

var fase := Fase.ANGULO
@onready var melon: Melon = %Melon
@onready var camara: Camera2D = %Camara
@onready var hud: CanvasLayer = $Interfaz
@onready var capa_dibujo: Node2D = $Efectos
var t_osc := 0.0
var angulo := 0.0
var fuerza := 0.0

var tramos: Array = []
var fin_x := 0.0
var fin_y := 0.0
var n_tramos := 0
var rng := RandomNumberGenerator.new()
var rng_aire := RandomNumberGenerator.new()

var mejor_x := 0.0
var t_sin_avance := 0.0
var t_fin := 0.0
var texto_fin := ""
var recolectados := 0
var poderes_recogidos := 0
var empujones := 0
var poderes_generados := 0
var siguiente_poder_x := 0.0
var postales_intento: Array = []
var siguiente_papalote_x := 0.0
var papalotes_generados := 0
var papalotes_usados := 0
var papalote_cercano: Papalote
var altura_m := 0.0
var avisos: Array = []              # {texto, pos, t}

func _ready() -> void:
	siguiente_poder_x = Config.primer_poder_x
	siguiente_papalote_x = Config.primer_papalote_x
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY, Config.gravedad)
	if Config.semilla_terreno >= 0:
		rng.seed = Config.semilla_terreno
	else:
		rng.randomize()
	rng_aire.seed = rng.seed + 871
	while fin_x < Config.generar_adelante:
		_crear_tramo()

	melon.configurar(Juego.tamano, Juego.accesorios, Juego.resistencia_max(), Juego.rebotes_max())
	melon.position = Vector2(0, -melon.radio - 1.0)
	$Paisaje.configurar(camara)
	camara.make_current()
	_actualizar_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("rebote") or event.is_echo():
		return
	if fase == Fase.ANGULO:
		fase = Fase.FUERZA
		t_osc = 0.0
	elif fase == Fase.FUERZA:
		_lanzar()


func _lanzar() -> void:
	var perfecto := fuerza >= Config.zona_perfecta.x and fuerza <= Config.zona_perfecta.y
	var vel := lerpf(Config.lanz_vel_min, Config.lanz_vel_max, fuerza) * Juego.mult_fuerza()
	vel *= float(melon.datos()["mult_lanzamiento"])
	if perfecto:
		vel *= Config.bonus_perfecto
		_aviso("¡Lanzamiento perfecto!", melon.global_position + Vector2(0, -60))
	melon.freeze = false
	melon.fijar_velocidad(Vector2.from_angle(-deg_to_rad(angulo)) * vel)
	melon.t_bloqueo = 0.3            # que el mismo Espacio no cuente como rebote
	melon.controlable = true
	fase = Fase.RECORRIDO


func _process(delta: float) -> void:
	match fase:
		Fase.ANGULO:
			t_osc += delta
			angulo = lerpf(Config.angulo_min, Config.angulo_max, 0.5 - 0.5 * cos(t_osc * TAU * Config.angulo_freq))
		Fase.FUERZA:
			t_osc += delta
			fuerza = 0.5 - 0.5 * cos(t_osc * TAU * Config.fuerza_freq)
		Fase.FIN:
			t_fin -= delta
			if t_fin <= 0.0:
				t_fin = INF
				Juego.registrar_intento(mejor_x / Config.px_por_metro, melon.carisma(), recolectados, melon.roto, poderes_recogidos)
				get_tree().change_scene_to_file("res://escenas/Resultados.tscn")
	for a in avisos:
		a["t"] -= delta
		a["pos"] += Vector2(0, -40) * delta
	avisos = avisos.filter(func(a: Dictionary) -> bool: return a["t"] > 0.0)
	_actualizar_camara(delta)
	_actualizar_hud()
	capa_dibujo.queue_redraw()


func _physics_process(delta: float) -> void:
	if fase != Fase.RECORRIDO:
		return
	var x := melon.global_position.x
	var avance := x - mejor_x
	mejor_x = maxf(mejor_x, x)
	if avance > Config.velocidad_min_avance * delta:
		t_sin_avance = 0.0
	else:
		t_sin_avance += delta
		if t_sin_avance > Config.tiempo_sin_avance:
			_fin("¡Se detuvo!")
	while fin_x < x + Config.generar_adelante:
		_crear_tramo()
	while tramos.size() > 1 and tramos[0].x1 < x - Config.borrar_atras:
		tramos.pop_front().queue_free()
	for t in tramos:
		if x >= t.x0 and x <= t.x1:
			altura_m = maxf(0.0, t.altura(x) - melon.global_position.y - melon.radio) / Config.px_por_metro
			break
	_actualizar_publico()
	_atraer_aplausos(delta)
	for postal in Config.postales:
		if mejor_x >= float(postal["metros"]) * Config.px_por_metro and postal["id"] not in postales_intento:
			postales_intento.append(postal["id"])
			_aviso("¡%s!" % postal["nombre"], melon.global_position + Vector2(0, -90))


func _fin(texto: String) -> void:
	if fase == Fase.FIN:
		return
	fase = Fase.FIN
	t_fin = Config.espera_fin
	texto_fin = texto
	melon.controlable = false


func _on_melon_aviso(texto: String) -> void:
	_aviso(texto, melon.global_position + Vector2(0, -melon.radio - 30))


func _on_melon_roto() -> void:
	_fin("¡Se rompió el melón!")


func _aviso(texto: String, pos: Vector2) -> void:
	avisos.append({"texto": texto, "pos": pos, "t": 1.4})


# --- Público -----------------------------------------------------------------

func _actualizar_publico() -> void:
	var pos := melon.global_position
	var cercana: Persona = null
	var mejor_d := Config.publico_rango
	papalote_cercano = null
	var distancia_aire := Config.papalote_rango
	for t in tramos:
		if t.x1 < pos.x - 400.0 or t.x0 > pos.x + 400.0:
			continue
		for p in t.personas:
			var d: float = (p.global_position + Vector2(0, -40)).distance_to(pos)
			var en: bool = not p.usado and d < Config.publico_rango
			if en != p.en_rango:
				p.en_rango = en
				p.queue_redraw()
			if en and d < mejor_d:
				cercana = p
				mejor_d = d
		for p in t.papalotes:
			var d: float = p.global_position.distance_to(pos)
			p.en_rango = not p.usado and d <= Config.papalote_rango
			if p.en_rango and d <= distancia_aire:
				papalote_cercano = p
				distancia_aire = d
	if not melon.controlable or not Input.is_action_just_pressed("empujon"):
		return
	if papalote_cercano != null and papalote_cercano.impulsar(melon):
		papalotes_usados += 1
		_aviso("¡Al cielo!", melon.global_position + Vector2(0, -100))
	elif cercana != null:
		cercana.usado = true
		cercana.en_rango = false
		cercana.t_empuje = 0.5
		var empuje := Config.empuje_base * (1.0 + melon.carisma() * Config.empuje_por_carisma)
		empuje *= pow(Config.empuje_cansancio, empujones)
		empujones += 1
		melon.empujar(Config.empuje_dir.normalized() * empuje)
		_aviso("¡Empujón! x%.1f" % (empuje / Config.empuje_base), cercana.global_position + Vector2(0, -120))


# --- Obstáculos --------------------------------------------------------------

func _on_obstaculo(cuerpo: Node2D, ob: Obstaculo) -> void:
	if cuerpo != melon or not ob.activo or fase != Fase.RECORRIDO:
		return
	var aqui := melon.global_position + Vector2(0, -50)
	match ob.tipo:
		"aplauso":
			ob.activo = false
			recolectados += 1
			_aviso("+%d" % Config.valor_aplauso_suelto, aqui)
			ob.queue_free()
		"coladera":
			ob.activo = false
			melon.frenar(Config.coladera_freno)
			_aviso("Coladera", aqui)
		"charco":
			melon.frenar(Config.charco_freno)
			_aviso("¡Splash!", aqui)
		"puesto":
			ob.romper()
			if melon.t_embestida > 0.0:
				_aviso("¡Puesto destrozado!", aqui)
			else:
				melon.frenar(Config.puesto_freno)
				_aviso("Se llevó un puesto", aqui)
		"poste":
			ob.activo = false
			melon.golpe()
			melon.frenar(Config.poste_freno)
		"banqueta":
			ob.activo = false
			melon.golpe()
			melon.frenar(Config.banqueta_freno)
			melon.empujar(Vector2(0, -Config.banqueta_salto))
		"rampa":
			ob.activo = false
			melon.empujar(Vector2.from_angle(ob.rotation - deg_to_rad(Config.rampa_angulo)) * Config.rampa_impulso)
			_aviso("¡Rampa!", aqui)
		"toldo":
			var v := melon.linear_velocity
			if v.y > 0.0:
				ob.activo = false
				melon.fijar_velocidad(Vector2(v.x, -v.y * Config.toldo_rebote))
				_aviso("¡Toldo!", aqui)


# --- Terreno -----------------------------------------------------------------

func _crear_tramo() -> void:
	var t := TramoEscena.instantiate() as Tramo
	t.name = "Tramo%03d" % n_tramos
	var pts := PackedVector2Array()
	if n_tramos == 0:
		# Bajo el puente y calle Lucio abajo, empedrada.
		t.empedrado = true
		var n := int(round((Config.calle_fin_x - Config.calle_inicio_x) / Config.paso_puntos))
		for j in n + 1:
			var x := lerpf(Config.calle_inicio_x, Config.calle_fin_x, float(j) / n)
			var y := Config.calle_y + Config.calle_caida * smoothstep(Config.calle_bajada_x, Config.calle_fin_x, x)
			pts.append(Vector2(x, y))

	else:
		var forma := _elegir_forma()
		var escala := lerpf(Config.terreno_suave, 1.0, dificultad(fin_x))
		var dy := rng.randf_range(forma["dy"].x, forma["dy"].y)
		var amp := rng.randf_range(forma["amp"].x, forma["amp"].y) * escala
		if dy < 0.0:
			dy *= escala
		var ks: Array = forma["k"]
		var k: int = ks[rng.randi_range(0, ks.size() - 1)]
		var n := int(round(Config.largo_tramo / Config.paso_puntos))
		for j in n + 1:
			var u := float(j) / n
			var y := fin_y + dy * smoothstep(0.0, 1.0, u) - amp * pow(sin(PI * k * u), 2)
			pts.append(Vector2(fin_x + u * Config.largo_tramo, y))
		t.empedrado = rng.randf() < Config.prob_empedrado
	t.color_suelo = Color("aaa18e") if t.empedrado else Color("6d8a58")
	t.puntos = pts
	t.construir()
	$Mundo/Terreno.add_child(t)
	_poblar(t)
	fin_x = pts[pts.size() - 1].x
	fin_y = pts[pts.size() - 1].y
	tramos.append(t)
	n_tramos += 1


## 0..1 según qué tan lejos está x. Cerca del puente el camino es amable.
func dificultad(x: float) -> float:
	var m := x / Config.px_por_metro
	return clampf(inverse_lerp(Config.dificultad_metros.x, Config.dificultad_metros.y, m), 0.0, 1.0)


func _separacion_obstaculos(x: float) -> float:
	var holgura := lerpf(Config.obstaculos_holgura, 1.0, dificultad(x))
	return rng.randf_range(Config.separacion_obstaculos.x, Config.separacion_obstaculos.y) * holgura


func _elegir_forma() -> Dictionary:
	var total := 0.0
	for f in Config.formas_tramo:
		total += float(f["peso"])
	var r := rng.randf() * total
	for f in Config.formas_tramo:
		r -= float(f["peso"])
		if r <= 0.0:
			return f
	return Config.formas_tramo[0]


func _elegir_obstaculo() -> String:
	var total := 0.0
	for p in Config.pesos_obstaculos.values():
		total += float(p)
	var r := rng.randf() * total
	for id in Config.pesos_obstaculos:
		r -= float(Config.pesos_obstaculos[id])
		if r <= 0.0:
			return id
	return "charco"


func _poblar(t: Tramo) -> void:
	var inicio := Config.inicio_obstaculos_x if n_tramos == 0 else t.x0 + 150.0

	# Casas de fondo
	if n_tramos == 0 or rng.randf() < Config.prob_casas:
		var cx := t.x0 + rng.randf_range(0.0, 120.0)
		while cx < t.x1 - 100.0:
			var w := rng.randf_range(110.0, 190.0)
			var h := rng.randf_range(110.0, 230.0)
			var base := maxf(t.altura(cx), t.altura(minf(cx + w, t.x1))) + 20.0
			t.casas.append({"rect": Rect2(cx, base - h, w, h + 40.0),
				"color": COLORES_CASAS[rng.randi_range(0, COLORES_CASAS.size() - 1)]})
			cx += w + rng.randf_range(10.0, 160.0)

	# Obstáculos e impulsores
	var x := inicio + _separacion_obstaculos(inicio)
	while x < t.x1 - 150.0:
		var tipo := _elegir_obstaculo()
		var ob := OBSTACULOS[tipo].instantiate() as Obstaculo
		ob.configurar(tipo)
		ob.position = Vector2(x, t.altura(x))
		if Config.obstaculos[tipo]["plano"]:
			ob.rotation = t.pendiente(x)
		ob.name = tipo.capitalize()
		t.get_node("Obstaculos").add_child(ob)
		ob.body_entered.connect(_on_obstaculo.bind(ob))
		x += _separacion_obstaculos(x)

	# Público
	x = maxf(t.x0, 300.0) + rng.randf_range(0.0, Config.separacion_publico.x)
	while x < t.x1 - 60.0:
		var p := PublicoEscena.instantiate() as Persona
		p.color_ropa = COLORES_ROPA[rng.randi_range(0, COLORES_ROPA.size() - 1)]
		p.color_piel = Color(0.85, 0.65, 0.5).darkened(rng.randf_range(0.0, 0.4))
		p.position = Vector2(x, t.altura(x) + 2.0)
		p.name = "Vecino"
		t.get_node("Publico").add_child(p)
		t.personas.append(p)
		x += rng.randf_range(Config.separacion_publico.x, Config.separacion_publico.y)

	# Aplausos sueltos en el aire, en arco
	x = inicio + rng.randf_range(0.0, Config.separacion_aplausos.x)
	while x < t.x1 - 200.0:
		var alto := rng.randf_range(Config.altura_aplausos.x, Config.altura_aplausos.y)
		for i in 4:
			var ax := x + i * 45.0
			var ap := OBSTACULOS["aplauso"].instantiate() as Obstaculo
			ap.configurar("aplauso")
			ap.position = Vector2(ax, t.altura(ax) - alto - sin(i / 3.0 * PI) * 40.0)
			ap.name = "Aplauso"
			ap.add_to_group("aplausos")
			t.get_node("Coleccionables").add_child(ap)
			ap.body_entered.connect(_on_obstaculo.bind(ap))
		x += rng.randf_range(Config.separacion_aplausos.x, Config.separacion_aplausos.y)

	# La separación continúa entre tramos; no aparece otro poder al cambiar de tramo.
	while siguiente_poder_x < t.x1:
		x = siguiente_poder_x
		var poder := PoderEscena.instantiate() as PoderXalapeno
		poder.tipo = Config.orden_poderes[poderes_generados % Config.orden_poderes.size()]
		poder.name = poder.tipo.capitalize()
		poder.position = Vector2(x, t.altura(x) - rng.randf_range(Config.altura_poderes.x, Config.altura_poderes.y))
		t.get_node("Coleccionables").add_child(poder)
		poder.recogido.connect(_recibir_poder)
		poderes_generados += 1
		siguiente_poder_x += rng.randf_range(Config.separacion_poderes.x, Config.separacion_poderes.y)

	# Usa su propio azar para conservar la ruta del suelo al poblar el cielo.
	while siguiente_papalote_x < t.x1:
		var papalote := PapaloteEscena.instantiate() as Papalote
		var alto: float = Config.alturas_papalotes[papalotes_generados % Config.alturas_papalotes.size()]
		papalote.position = Vector2(siguiente_papalote_x, t.altura(siguiente_papalote_x) - alto)
		t.get_node("Aire").add_child(papalote)
		t.papalotes.append(papalote)
		for i in 4:
			var ap := OBSTACULOS["aplauso"].instantiate() as Obstaculo
			ap.configurar("aplauso")
			ap.position = papalote.position + Vector2(-210 + i * 50, 135 - i * 35)
			ap.add_to_group("aplausos")
			t.get_node("Aire").add_child(ap)
			ap.body_entered.connect(_on_obstaculo.bind(ap))
		papalotes_generados += 1
		siguiente_papalote_x += rng_aire.randf_range(Config.separacion_papalotes.x, Config.separacion_papalotes.y)

	for postal in Config.postales:
		var px: float = float(postal["metros"]) * Config.px_por_metro
		if px >= t.x0 and px < t.x1:
			t.agregar_postal({"pos": Vector2(px, t.altura(px)), "nombre": "" if postal["id"] == "xallitic" else postal["nombre"], "tipo": postal["tipo"]})

	# Marcadores de distancia
	var cada := Config.marcador_cada_m * Config.px_por_metro
	var mx := ceilf(maxf(t.x0, 1.0) / cada) * cada
	while mx < t.x1:
		var m := int(round(mx / Config.px_por_metro))
		var lugar: bool = Config.lugares.has(m)
		if lugar:
			mx += cada
			continue
		t.marcadores.append({"pos": Vector2(mx, t.altura(mx)), "lugar": lugar,
			"texto": Config.lugares[m] if lugar else "%d m" % m, "sub": "%d m" % m})
		mx += cada
	t.queue_redraw()
	t.get_node("Decoracion").queue_redraw()


# --- Cámara y HUD ------------------------------------------------------------

func _actualizar_camara(delta: float) -> void:
	var z := 1.0
	if fase == Fase.ANGULO or fase == Fase.FUERZA:
		camara.position = Vector2(250, 60)
	else:
		var anticipacion := clampf(melon.linear_velocity.y * 0.1, -70.0, 60.0)
		camara.position = melon.global_position + Vector2(260, -40 + anticipacion)
		z = clampf(1.0 - melon.linear_velocity.length() / 3000.0, 0.55, 1.0)
	camara.zoom = camara.zoom.lerp(Vector2(z, z), clampf(delta * 1.5, 0.0, 1.0))


func _actualizar_hud() -> void:
	hud.actualizar(melon, maxf(0.0, mejor_x) / Config.px_por_metro, fase, angulo, fuerza, texto_fin, recolectados, poderes_recogidos)
	hud.actualizar_vuelo(melon, fase, altura_m, papalotes_usados, is_instance_valid(papalote_cercano) and not papalote_cercano.usado)


func _recibir_poder(id: String) -> void:
	if fase != Fase.RECORRIDO:
		return
	poderes_recogidos += 1
	melon.recibir_poder(id)


func _atraer_aplausos(delta: float) -> void:
	if melon.t_iman <= 0.0:
		return
	for ap in get_tree().get_nodes_in_group("aplausos"):
		if ap.global_position.distance_to(melon.global_position) < 240.0:
			ap.global_position = ap.global_position.move_toward(melon.global_position, 460.0 * delta)


func _dibujar_capa() -> void:
	if fase == Fase.ANGULO or fase == Fase.FUERZA:
		var o := melon.global_position
		var dir := Vector2.from_angle(-deg_to_rad(angulo))
		capa_dibujo.draw_arc(o, 130.0, -deg_to_rad(Config.angulo_max), -deg_to_rad(Config.angulo_min), 24,
			Color(1, 1, 1, 0.3), 2.0)
		var col := Color(1, 0.9, 0.2) if fase == Fase.ANGULO else Color(1, 1, 1, 0.8)
		var punta := o + dir * 130.0
		capa_dibujo.draw_line(o, punta, col, 6.0)
		capa_dibujo.draw_colored_polygon(PackedVector2Array([punta + dir * 18.0,
			punta + dir.orthogonal() * 10.0, punta - dir.orthogonal() * 10.0]), col)
	var fuente := ThemeDB.fallback_font
	for a in avisos:
		var alfa := clampf(a["t"] / 0.5, 0.0, 1.0)
		capa_dibujo.draw_string_outline(fuente, a["pos"] - Vector2(160, 0), a["texto"], HORIZONTAL_ALIGNMENT_CENTER,
			320, 22, 6, Color(0, 0, 0, alfa * 0.8))
		capa_dibujo.draw_string(fuente, a["pos"] - Vector2(160, 0), a["texto"], HORIZONTAL_ALIGNMENT_CENTER,
			320, 22, Color(1, 1, 0.85, alfa))
