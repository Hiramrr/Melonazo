class_name MelonRodante
extends Node2D
## Melón que avanza por el suelo. Solo recibe golpes durante un slam desde arriba.

var radio := 30.0
var velocidad := 240.0
var aspecto: Dictionary = {}
var usado := false
var anterior := Vector2.ZERO
var en_bajada := false
var _bajada: BajadaXallitic
var _x_bajada := 0.0
var _carril := 0.0
var _ritmo := 1.0
var _velocidad_salida := 0.0
var _velocidad_rodado := 0.0
var _cayendo := false
var _velocidad_y := 0.0


func _ready() -> void:
	z_index = 3
	anterior = global_position
	$Lienzo.world_2d = World2D.new()
	$Aspecto.texture = $Lienzo.get_texture()
	_actualizar_aspecto()


func configurar(datos: Dictionary) -> void:
	aspecto = datos.duplicate(true)
	radio = Config.tamanos[aspecto.get("tamano", 2)]["radio"]
	if is_node_ready():
		_actualizar_aspecto()


func preparar_salida(bajada: BajadaXallitic, x: float, carril: float, ritmo: float) -> void:
	_bajada = bajada
	_x_bajada = x
	_carril = carril
	_ritmo = ritmo
	en_bajada = true
	_colocar_en_bajada()
	anterior = global_position


func soltar(rapidez: float) -> void:
	_velocidad_salida = rapidez * _ritmo
	_velocidad_rodado = velocidad


func _colocar_en_bajada() -> void:
	var pendiente := _bajada.pendiente(_x_bajada) if _x_bajada < Config.bajada_fin.x else 0.0
	var suelo := _bajada.altura(_x_bajada) if _x_bajada < Config.bajada_fin.x else Config.bajada_fin.y
	var carril := _carril * (1.0 - smoothstep(Config.bajada_fin.x - 220.0, Config.puente_fin_x, _x_bajada))
	position = Vector2(_x_bajada, suelo + carril) + Vector2(sin(pendiente), -cos(pendiente)) * radio


func avanzar(terreno: GeneradorTerreno, delta: float) -> void:
	anterior = global_position
	if en_bajada:
		if _velocidad_salida <= 0.0:
			return
		var progreso := clampf(inverse_lerp(Config.bajada_inicio.x, Config.puente_fin_x, _x_bajada), 0.0, 1.0)
		var rapidez := _velocidad_salida * lerpf(0.65, 1.0, progreso)
		var pendiente := _bajada.pendiente(_x_bajada) if _x_bajada < Config.bajada_fin.x else 0.0
		velocidad = rapidez * cos(pendiente)
		_x_bajada += velocidad * delta
		_colocar_en_bajada()
		$Aspecto.rotation += rapidez * delta / radio
		if _x_bajada - radio > Config.puente_fin_x:
			en_bajada = false
			_cayendo = true
		return
	if _velocidad_rodado > 0.0:
		velocidad = move_toward(velocidad, _velocidad_rodado, Config.frenado_melones * delta)
	var x := global_position.x + velocidad * delta
	var tramo := terreno.tramo_en(x)
	if tramo == null:
		return
	var suelo := tramo.altura(x) - radio
	if _cayendo:
		_velocidad_y += Config.gravedad * delta
		global_position = Vector2(x, minf(suelo, global_position.y + _velocidad_y * delta))
		_cayendo = global_position.y < suelo
	else:
		global_position = Vector2(x, suelo)
	$Aspecto.rotation += velocidad * delta / radio


func margen_slam(melon: Melon) -> float:
	return clampf(absf(melon.linear_velocity.x - velocidad) * Config.slam_tolerancia, Config.slam_margen.x, Config.slam_margen.y)


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
	melon.acertar_slam()
	return true


func _actualizar_aspecto() -> void:
	$Lienzo.render_target_update_mode = SubViewport.UPDATE_ONCE
	$Lienzo/Dibujo.queue_redraw()


func _dibujar_aspecto() -> void:
	Aspecto.dibujar_melon($Lienzo/Dibujo, radio, aspecto.get("accesorios", []), false, true, aspecto)
