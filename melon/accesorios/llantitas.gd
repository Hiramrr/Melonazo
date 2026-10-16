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
	forma = [Vector2(-0.6, -0.1), Vector2(0.6, -0.1), Vector2(0.6, 0.5), Vector2(-0.6, 0.5)]


func usar(m: Melon) -> void:
	m.rodar(duracion, aceleracion)


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	for u in [-0.22, 0.22]:
		linea(ci, r, a, PackedVector2Array([Vector2(u, piel(u) - 0.04), Vector2(u, 0.08)]), TINTA, 0.12)
		linea(ci, r, a, PackedVector2Array([Vector2(u, piel(u) - 0.04), Vector2(u, 0.08)]), Color("8d929b"), 0.06)
	pieza(ci, r, a, suave(PackedVector2Array([Vector2(-0.58, 0.1), Vector2(-0.5, 0.17), Vector2(0, 0.17),
		Vector2(0.5, 0.17), Vector2(0.58, 0.1), Vector2(0.5, 0.04), Vector2(0, 0.04), Vector2(-0.5, 0.04)]), 4),
		Color("d9573b"), 0.05)
	for u in [-0.34, 0.34]:
		var c := Vector2(u, 0.29)
		pieza(ci, r, a, elipse(c, Vector2(0.22, 0.22)), Color("34343c"), 0.06)
		var brillo := PackedVector2Array()
		for i in 6:
			var t := PI * (0.55 + 0.06 * i)
			brillo.append(c + Vector2(cos(t), sin(t)) * 0.17)
		linea(ci, r, a, brillo, Color("74747f"), 0.04)
		rellenar(ci, r, a, elipse(c, Vector2(0.12, 0.12), 0.0, 16), Color("d7dbe0"), 0.04)
		for rayo in 3:
			var d := Vector2.from_angle(PI / 2.0 + rayo * TAU / 3.0) * 0.11
			linea(ci, r, a, PackedVector2Array([c, c + d]), Color("8d929b"), 0.035)
		ci.draw_circle(uv(r, a, c.x, c.y), r * 0.12, TINTA, false, ancho(r) * 0.6, true)
		ci.draw_circle(uv(r, a, c.x, c.y), r * 0.045, Color("5b5f68"), true, -1.0, true)
