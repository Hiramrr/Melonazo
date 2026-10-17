extends AudioStreamPlayer
## Una sola voz por escena: las monedas seguidas prolongan el sonido sin reiniciarlo.
const AUDIO := preload("res://recursos/sonidos/monedas.wav")
const VOLUMEN := -12.0
const FUNDIDO := 0.06
var restante := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	stream = AUDIO
	add_to_group("audio_monedas")
	finished.connect(func() -> void:
		if restante > 0.0:
			play())

func sonar(duracion := 0.3) -> void:
	if get_tree().paused or duracion <= 0.0:
		return
	restante = maxf(restante, duracion)
	volume_db = VOLUMEN
	if not playing:
		play()

func _process(delta: float) -> void:
	if restante <= 0.0:
		return
	restante = maxf(0.0, restante - delta)
	volume_linear = db_to_linear(VOLUMEN) * minf(1.0, restante / FUNDIDO)
	if restante <= 0.0:
		stop()
