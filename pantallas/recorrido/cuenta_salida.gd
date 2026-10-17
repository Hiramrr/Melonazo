extends CanvasLayer
## Presentación de salida: tres segundos de espera y un segundo de «¡Fuera!».
signal salida

const SEGUNDO_SALIDA := 3.0
const AUDIO := preload("res://recursos/sonidos/countdown.wav")
var tiempo := 0.0
var _salio := false
var audio: AudioStreamPlayer
var _raiz: Control
var _texto: Label
var _detalle: Label
var _paso := -1


func _ready() -> void:
	layer = 2
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	for abajo in [false, true]:
		var banda := ColorRect.new()
		banda.color = Color(0.04, 0.09, 0.07, 0.85)
		banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_raiz.add_child(banda)
		banda.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if abajo else Control.PRESET_TOP_WIDE)
		banda.offset_top = -38.0 if abajo else 0.0
		banda.offset_bottom = 0.0 if abajo else 38.0
	_texto = Label.new()
	_raiz.add_child(_texto)
	_texto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.add_theme_font_size_override("font_size", 64)
	_texto.add_theme_color_override("font_color", Color("ffda66"))
	_texto.add_theme_color_override("font_outline_color", Color("173e35"))
	_texto.add_theme_constant_override("outline_size", 12)
	_detalle = Label.new()
	_raiz.add_child(_detalle)
	_detalle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_detalle.offset_top = -34
	_detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detalle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detalle.add_theme_font_size_override("font_size", 20)
	_detalle.add_theme_color_override("font_color", Color("fff2cc"))
	_detalle.text = "Potencia fijada · Prepárate para rodar"
	audio = AudioStreamPlayer.new()
	audio.stream = AUDIO
	audio.volume_db = -4.0
	add_child(audio)
	audio.play()
	_actualizar_texto()


func _notification(que: int) -> void:
	if not is_instance_valid(_raiz):
		return
	if que == NOTIFICATION_PAUSED:
		_raiz.hide()
	elif que == NOTIFICATION_UNPAUSED:
		_raiz.show()


func avanzar(delta: float) -> void:
	tiempo += delta
	_actualizar_texto()
	if not _salio and tiempo >= SEGUNDO_SALIDA:
		_salio = true
		salida.emit()
	# La última palabra del audio continúa mientras todos arrancan.
	_raiz.modulate.a = 1.0 - clampf((tiempo - 3.45) / 0.55, 0.0, 1.0)
	if tiempo >= 4.0 and not audio.playing:
		queue_free()


func _actualizar_texto() -> void:
	var paso := mini(int(tiempo), 3)
	if paso == _paso:
		return
	_paso = paso
	_texto.text = ["EN SUS MARCAS", "LISTOS", "LISTOS", "¡FUERA!"][paso]
	_texto.pivot_offset = _texto.size * 0.5
	_texto.scale = Vector2.ONE * 1.12
	create_tween().tween_property(_texto, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD)
