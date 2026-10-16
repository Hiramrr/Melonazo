extends Accesorio
## Rebozo de paseo: planeo corto y protección para la siguiente caída. Inicial.

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


const GIRO := 0.78                   # hasta qué ángulo cubre la tela a cada lado


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var tela := _arco(1.3, -GIRO, GIRO, true)
	tela.append_array(_arco(1.03, GIRO, -GIRO))
	# Flecos en las dos puntas, antes del contorno para que este cubra su raíz.
	for lado in [-1.0, 1.0]:
		var phi: float = lado * GIRO
		var fuera := Vector2(cos(phi), -sin(phi)) * signf(phi)
		for i in 5:
			var p := _polar(lerpf(1.06, 1.27, i / 4.0), phi)
			linea(ci, r, a, PackedVector2Array([p, p + fuera * 0.13 + Vector2(0, -0.02 * i)]), color.darkened(0.3), 0.028)
	var pts := rellenar(ci, r, a, tela, color, 0.06)
	for radio in [1.11, 1.21]:
		linea(ci, r, a, _arco(radio, -GIRO, GIRO), Color("e9d9ab"), 0.032)
	# Pliegues: bloques de sombra que bajan desde el borde de afuera y se afinan.
	for phi in [-0.52, -0.14, 0.24, 0.56]:
		var pliegue := PackedVector2Array()
		for i in 5:
			var f := i / 4.0
			pliegue.append(_polar(lerpf(1.32, 1.08, f), phi - 0.03 * (1.0 - f)))
		for i in 5:
			var f := 1.0 - i / 4.0
			pliegue.append(_polar(lerpf(1.32, 1.08, f), phi + 0.02 + 0.13 * (1.0 - f)))
		for parte in Geometry2D.intersect_polygons(pliegue, tela):
			poligono(ci, uvs(r, a, parte), Color(TINTA, 0.26))
	contorno(ci, r, pts)


## Punto a distancia radio (en radios) del centro del melón y ángulo phi desde la cima.
func _polar(radio: float, phi: float) -> Vector2:
	return Vector2(radio * sin(phi), radio * cos(phi) - 1.0)


## Arco concéntrico al melón; el borde de afuera ondula un poco por los pliegues.
func _arco(radio: float, desde: float, hasta: float, ondulado := false) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 21:
		var phi := lerpf(desde, hasta, i / 20.0)
		pts.append(_polar(radio + (0.025 * sin(phi * 14.0) if ondulado else 0.0), phi))
	return pts
