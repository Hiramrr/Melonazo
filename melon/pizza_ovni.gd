extends Node2D
## La luz acompaña al melón mientras dura el poder; el audio conserva su cola.
const TEXTURA := preload("res://recursos/poderes/pizza.png")
const AUDIO := preload("res://recursos/sonidos/ovni.wav")
var tiempo := 0.0
var salida := 0.0
var partiendo := false
var audio: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 9
	audio = AudioStreamPlayer.new()
	audio.stream = AUDIO
	audio.volume_db = -8.0
	add_child(audio)
	audio.play()

func _physics_process(delta: float) -> void:
	var melon = get_parent()
	global_rotation = 0.0
	if melon.roto or not melon.controlable:
		queue_free()
		return
	tiempo += delta
	if melon.t_pizza <= 0.0:
		partiendo = true
	if partiendo:
		salida += delta
	if salida >= 1.0 and not audio.playing:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var radio: float = get_parent().radio
	var centro := Vector2(salida * salida * 500.0, -radio - 115.0 - salida * 250.0 + sin(tiempo * 5.0) * 5.0)
	if not partiendo:
		var ancho := radio + 25.0
		var puntos := PackedVector2Array([centro + Vector2(-22, 20), centro + Vector2(22, 20), Vector2(ancho, radio + 10), Vector2(-ancho, radio + 10)])
		draw_polygon(puntos, PackedColorArray([Color(1, 0.3, 0.75, 0.55), Color(1, 0.3, 0.75, 0.55), Color(1, 0.5, 0.85, 0.06), Color(1, 0.5, 0.85, 0.06)]))
		for i in 7:
			var avance := fmod(tiempo * 0.8 + i / 7.0, 1.0)
			var punto := Vector2(sin(i * 7.0 + tiempo) * ancho * (1.0 - avance), lerpf(radio, centro.y + 20.0, avance))
			draw_circle(punto, 2.5, Color(1, 0.65, 0.9, 0.8))
	var opacidad := clampf(1.0 - salida, 0.0, 1.0)
	draw_circle(centro, 52.0, Color(1, 0.3, 0.8, 0.12 * opacidad))
	draw_texture_rect(TEXTURA, Rect2(centro - Vector2(48, 48), Vector2(96, 96)), false, Color(1, 1, 1, opacidad))
