extends Node2D
const TEXTURA := preload("res://recursos/poderes/chile.png")
const AUDIO := preload("res://recursos/sonidos/chile_explosion.wav")
var tiempo := 0.0
var exploto := false
var sprite: Sprite2D
var fuego: CPUParticles2D
var audio: AudioStreamPlayer2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 10
	sprite = Sprite2D.new()
	sprite.texture = TEXTURA
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (80.0 / TEXTURA.get_width())
	sprite.position = Vector2(0, -get_parent().radio - 35)
	add_child(sprite)
	# Audio y mecha comienzan juntos al recoger el chile.
	audio = AudioStreamPlayer2D.new()
	audio.stream = AUDIO
	audio.volume_db = -9.0
	audio.max_distance = 4000.0
	add_child(audio)
	audio.play()

func _physics_process(delta: float) -> void:
	var melon = get_parent()
	global_rotation = 0.0
	if melon.roto or not melon.controlable:
		queue_free()
		return
	tiempo += delta
	if not exploto:
		sprite.modulate = Color(1, 0.25, 0.15, 0.35) if int(tiempo * 12) % 2 else Color.WHITE
		if tiempo >= 1.0:
			exploto = true
			sprite.hide()
			melon.explotar_chile()
			var explosion := _particulas(70, 0.65, 360.0, 160.0, 460.0)
			explosion.one_shot = true
			explosion.explosiveness = 1.0
			explosion.restart()
			fuego = _particulas(65, 0.55, 35.0, 100.0, 260.0)
	if exploto:
		fuego.direction = -melon.linear_velocity.normalized()
		if tiempo >= 3.5:
			fuego.emitting = false
		if tiempo >= 4.1 and not audio.playing:
			queue_free()

func _particulas(cantidad: int, vida: float, apertura: float, minima: float, maxima: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.amount = cantidad
	p.lifetime = vida
	p.local_coords = false
	p.direction = Vector2.LEFT
	p.spread = apertura
	p.gravity = Vector2(0, -70)
	p.initial_velocity_min = minima
	p.initial_velocity_max = maxima
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	var colores := Gradient.new()
	colores.colors = PackedColorArray([Color("ffe16b"), Color("ff4823"), Color(0.8, 0.02, 0, 0)])
	colores.offsets = PackedFloat32Array([0, 0.2, 1])
	p.color_ramp = colores
	add_child(p)
	p.emitting = true
	return p
