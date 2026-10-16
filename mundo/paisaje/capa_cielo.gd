@tool
class_name CapaCielo
extends Node2D
## Una capa decorativa del cielo (sin colisión): degradado de fondo, sol, nubes, aves
## o papalotes lejanos. Cada capa es un nodo hijo de Paisaje (mundo/paisaje/paisaje.tscn)
## y se puede ocultar o ajustar desde el inspector.
##
## Quién la mueve: Paisaje._process() llama actualizar() en cada hijo, cada cuadro.
## Paisaje ya sigue a la cámara, así que aquí se dibuja en coordenadas de pantalla con
## (0, 0) en el centro.
##
## Paralaje: los elementos se repiten sin fin, uno cada `separacion` px. Su x en pantalla es
##   i * separacion - (camara.x * paralaje - tiempo * velocidad)
## paralaje = qué fracción del avance de la cámara se nota (0 = fijo, como en el infinito;
## 1 = se mueve con el mundo); velocidad = deriva propia hacia la derecha (viento), en px/s.
## En vertical rige el mismo factor, sin excepciones por tipo de capa: al subir la cámara
## (vista.y menor que REF_Y) el elemento baja en pantalla (REF_Y - vista.y) * paralaje px,
## y al bajarla sube en la misma proporción. Así una capa cercana se mueve más que una
## lejana en los dos ejes y ninguna sale disparada de la pantalla al ganar altura.
## El índice i alimenta _azar(), así cada elemento se ve siempre igual al volver a pasar.

const CIELO_ARRIBA := Color("6ba8df")
const CIELO_ABAJO := Color("f7deb8")
const MARGEN := Vector2(4, 4)          # se dibuja un poco más allá del borde de la pantalla
const REF_Y := 60.0                    # igual que Paisaje.REF_Y
const ALTURA_NUBES_ALTAS := 0.85       # fracción de media pantalla por encima del centro
const ALTURA_OTRAS := 0.52             # nubes cercanas, aves y papalotes
const VARIACION_ALTURA := 95.0         # px de altura al azar entre elementos

## Qué dibuja la capa. "fondo" y "sol" no se repiten; los demás sí, según `separacion`.
@export_enum("fondo", "sol", "nubes_altas", "nubes_cercanas", "aves", "papalotes") var tipo := "nubes_altas":
	set(valor):
		tipo = valor
		queue_redraw()
## Distancia en px entre un elemento y el siguiente.
@export_range(150.0, 1600.0, 10.0) var separacion := 420.0
## Deriva propia en px/s, aunque la cámara no se mueva.
@export var velocidad := 6.0
## Fracción del movimiento de la cámara que sigue la capa (más alto = parece más cerca).
@export_range(0.0, 1.0, 0.01) var paralaje := 0.04

var mitad := Vector2(640, 360)         # media pantalla + MARGEN
var vista := Vector2.ZERO              # centro de la cámara en el mundo
var tiempo := 0.0                      # segundos acumulados, para animar
var _nivel_cielo := 0


## Recibe el estado de la cámara y vuelve a dibujar. La llama Paisaje cada cuadro.
func actualizar(tamano: Vector2, posicion_camara: Vector2, segundos: float) -> void:
	var cambio_tamano := mitad != tamano / 2.0 + MARGEN
	var nivel := clampi(int(-posicion_camara.y / 400.0), 0, 8)
	var cambio_cielo := nivel != _nivel_cielo
	_nivel_cielo = nivel
	mitad = tamano / 2.0 + MARGEN
	vista = posicion_camara
	tiempo = segundos
	if tipo != "fondo" or cambio_tamano or cambio_cielo:
		queue_redraw()


func _draw() -> void:
	match tipo:
		"fondo":
			# Degradado vertical que cubre toda la pantalla.
			var arriba := CIELO_ARRIBA.lerp(Color("4678aa"), _nivel_cielo / 8.0)
			var abajo := CIELO_ABAJO.lerp(Color("bdd8df"), _nivel_cielo / 8.0)
			draw_polygon(PackedVector2Array([Vector2(-mitad.x, -mitad.y), Vector2(mitad.x, -mitad.y), mitad, Vector2(-mitad.x, mitad.y)]),
				PackedColorArray([arriba, arriba, abajo, abajo]))
		"sol":
			# Casi fijo arriba a la derecha; se desliza hasta 80 px con la cámara y vuelve.
			var centro := Vector2(mitad.x * 0.55 - fposmod(vista.x * paralaje, 80), -mitad.y * 0.65)
			draw_circle(centro, 31, Color("f4db9f"))
			draw_arc(centro, 25, 0, TAU, 40, Color("fae8bc"), 1.5, true)
		_:
			# Elementos repetidos: solo los índices que caben en pantalla (más uno a cada lado).
			var desplazamiento := vista.x * paralaje - tiempo * velocidad
			var inicio := floori((-mitad.x + desplazamiento) / separacion) - 1
			var fin := ceili((mitad.x + desplazamiento) / separacion) + 1
			for i in range(inicio, fin + 1):
				var azar := _azar(i + paralaje * 100)
				var pos := posicion_elemento(i)
				match tipo:
					"nubes_altas", "nubes_cercanas":
						_nube(pos, azar)
					"aves":
						_bandada(pos + Vector2(0, -40), i, azar)
					"papalotes":
						if azar < 0.45:
							_papalote(pos + Vector2(0, 60), i, azar)


## Posición en pantalla del elemento i, en coordenadas con (0, 0) al centro.
## El mismo `paralaje` rige en horizontal y en vertical.
func posicion_elemento(i: int) -> Vector2:
	var azar := _azar(i + paralaje * 100)
	var desplazamiento := vista.x * paralaje - tiempo * velocidad
	var x := i * separacion - desplazamiento + (azar - 0.5) * separacion * 0.25
	var altura := -mitad.y * (ALTURA_NUBES_ALTAS if tipo == "nubes_altas" else ALTURA_OTRAS)
	altura += (azar - 0.5) * VARIACION_ALTURA + (REF_Y - vista.y) * paralaje
	return Vector2(x, altura)


## Número pseudoaleatorio estable en [0, 1).
static func _azar(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


# --- Elementos ---------------------------------------------------------------

## Nube de cinco bolas con sombra; las altas son más planas y tenues.
func _nube(pos: Vector2, azar: float) -> void:
	var alta := tipo == "nubes_altas"
	var escala := Vector2(1.6, 0.38) if alta else Vector2(1.0, 0.7)
	escala *= 0.75 + azar * 0.55
	draw_set_transform(pos, 0, escala)
	var sombra := Color("bed4dc") if alta else Color("cbdbe0")
	var luz := Color("d9e5e7") if alta else Color("f5f3e9")
	for i in 5:
		var x := (i - 2) * 25.0
		var y := -sin(i * PI / 4) * 15
		var radio := 18.0 + sin(i * PI / 4) * 14
		draw_circle(Vector2(x, y + 7), radio, sombra)
		draw_circle(Vector2(x, y), radio, luz)
	draw_rect(Rect2(-50, 0, 100, 16), luz)
	draw_set_transform(Vector2.ZERO)


## Cinco aves en V aleteando.
func _bandada(pos: Vector2, grupo: int, azar: float) -> void:
	var color := Color("526d7c")
	for i in 5:
		var aleteo := sin(tiempo * 3.8 + i * 0.8 + grupo) * 3.5
		var p := pos + Vector2(i * 20, absf(i - 2) * 9 + sin(tiempo * 0.6 + i) * 2)
		var ala := 5.0 + azar * 3
		draw_polyline(PackedVector2Array([p + Vector2(-ala, -aleteo - 2), p + Vector2(-ala * 0.4, -2), p,
			p + Vector2(ala * 0.4, -2), p + Vector2(ala, -aleteo - 2)]), color, 1.6, true)


## Papalote lejano que se mece, con cola ondulante y moños. Solo decoración; el que se
## usa en el juego es mundo/ayudas/papalote.gd.
func _papalote(pos: Vector2, grupo: int, azar: float) -> void:
	pos += Vector2(sin(tiempo * 0.7 + grupo) * 9, sin(tiempo * 0.9 + grupo) * 5)
	var escala := 0.65 + azar * 0.3
	draw_set_transform(pos, sin(tiempo * 0.7 + grupo) * 0.12, Vector2.ONE * escala)
	var color := Color("bb755c") if grupo % 2 == 0 else Color("c6a367")
	var rombo := PackedVector2Array([Vector2(0, -20), Vector2(14, -3), Vector2(0, 20), Vector2(-14, -3)])
	draw_colored_polygon(rombo, color)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -20), Vector2(14, -3), Vector2(0, 20)]), color.lightened(0.16))
	draw_polyline(PackedVector2Array([rombo[0], rombo[1], rombo[2], rombo[3], rombo[0]]), Color("8c8270"), 1.2, true)
	draw_line(Vector2(0, -20), Vector2(0, 20), Color("e5d5ac"), 1.2, true)
	draw_line(Vector2(-14, -3), Vector2(14, -3), Color("e5d5ac"), 1.2, true)
	var cola := PackedVector2Array()
	for i in 16:
		var p := Vector2(sin(i * 0.55 - tiempo * 1.6 + grupo) * i * 0.7, 20 + i * 4)
		cola.append(p)
		if i > 0 and i % 4 == 0:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -3), p + Vector2(5, -3), p + Vector2(0, 4)]), color)
	draw_polyline(cola, Color("a19a86"), 1.2, true)
	draw_set_transform(Vector2.ZERO)
