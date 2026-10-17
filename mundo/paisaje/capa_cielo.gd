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
			Sprites.dibujar(self, "paisaje/cielo_%d" % _nivel_cielo, Rect2(-mitad, mitad * 2))
		"sol":
			var centro := Vector2(mitad.x * 0.55 - fposmod(vista.x * paralaje, 80), -mitad.y * 0.65)
			Sprites.poner(self, "paisaje/sol", centro)
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
	var escala := (0.75 + azar * 0.55) / 1.025
	Sprites.dibujar(self, "paisaje/nube_" + ("alta" if tipo == "nubes_altas" else "cercana"),
		Rect2(pos + Vector2(-150, -60) * escala, Vector2(300, 100) * escala))

func _bandada(pos: Vector2, grupo: int, _azar: float) -> void:
	var id := Sprites.animacion("paisaje/aves_", 8, tiempo + grupo * 0.13)
	Sprites.dibujar(self, id, Rect2(pos + Vector2(-12, -20), Vector2(108, 60)))

func _papalote(pos: Vector2, grupo: int, azar: float) -> void:
	pos += Vector2(sin(tiempo * 0.7 + grupo) * 9, sin(tiempo * 0.9 + grupo) * 5)
	var id := Sprites.animacion("paisaje/papalote_", 8, tiempo + grupo * 0.16)
	var escala := (0.65 + azar * 0.3) / 0.8
	Sprites.dibujar(self, id, Rect2(pos + Vector2(-30, -30) * escala, Vector2(60, 120) * escala))
