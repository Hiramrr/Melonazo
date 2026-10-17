extends Accesorio
## Llantitas: al tocar suelo acelera rodando unos segundos. Inicial.

var duracion := 2.0
var aceleracion := 350.0             # px/s² a lo largo del suelo


func _init() -> void:
	nombre = "Llantitas"
	carisma = 1
	accion = "Al tocar suelo acelera rodando ~2 s"
	inicial = true
	orden = 20
	color = Color(0.55, 0.55, 0.58)


func usar(m: Melon) -> void:
	m.rodar(duracion, aceleracion)
