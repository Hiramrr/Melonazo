extends Accesorio

var duracion := 1.5
var gravedad := 0.22                 # gravity_scale durante el planeo


func _init() -> void:
	nombre = "Rebozo de paseo"
	carisma = 3
	accion = "Planea 1.5 s y protege la siguiente caída"
	grito = "¡Al vuelo con el rebozo!"
	inicial = true
	orden = 30
	color = Color("467d88")
	forma = [Vector2(-0.7, -0.1), Vector2(0.7, -0.1), Vector2(0.9, 0.35), Vector2(-0.9, 0.35)]


func usar(m: Melon) -> void:
	m.planear(duracion, gravedad)
	m.proteger()


func dibujar_detalle(ci: CanvasItem, r: float, a: float) -> void:
	for u in [-0.6, -0.3, 0.0, 0.3, 0.6]:
		ci.draw_line(uv(r, a, u, 0.02), uv(r, a, u, 0.42), Color("e9d9ab"), ancho(r))
