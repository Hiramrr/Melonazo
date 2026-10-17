@tool
class_name Postal
extends Node2D
## Sitio de Xalapa dibujado con sprites, como fondo de un tramo. El origen es la
## base a ras de suelo; el dibujo baja un poco para que el terreno tape la unión.
##
## Escena: mundo/terreno/postal.tscn (un solo Node2D; todo se dibuja en _draw()).
## Quién la usa: GeneradorTerreno._poner_postales() pide Tramo.agregar_postal(datos), que
## instancia la escena en el contenedor Postales (z -1) del tramo y llama configurar().
## Qué lugar se dibuja lo decide `tipo`; los lugares y sus metros están en Config.postales.
## Como es @tool, `tipo` y `nombre` se pueden probar desde el inspector.
##
## Además ofrece dibujar_picado() (estática), que Tramo usa para colgar papel picado
## entre sus casas de fondo.

## Tipos válidos; los mismos del @export_enum de `tipo`.
const TIPOS: Array = ["xallitic", "catedral", "juarez", "diamante", "berros", "lagos", "usbi", "macuiltepetl"]
## Media anchura aproximada de cada dibujo; coloca el letrero en el borde izquierdo.
const MEDIO_ANCHO := {"xallitic": 290.0, "catedral": 150.0, "juarez": 230.0, "diamante": 170.0,
	"berros": 240.0, "lagos": 260.0, "usbi": 230.0, "macuiltepetl": 360.0}

## Qué lugar se dibuja.
@export_enum("xallitic", "catedral", "juarez", "diamante", "berros", "lagos", "usbi", "macuiltepetl") var tipo := "catedral":
	set(valor):
		tipo = valor
		queue_redraw()
## Texto del letrero de madera; vacío = sin letrero.
@export var nombre := "":
	set(valor):
		nombre = valor
		queue_redraw()


## Aplica datos: {pos: Vector2, tipo: String, nombre: String}; las claves que falten
## no cambian. pos va en coordenadas del padre, a ras de suelo.
func configurar(datos: Dictionary) -> void:
	if datos.has("pos"):
		position = datos["pos"]
	tipo = str(datos.get("tipo", tipo))
	nombre = str(datos.get("nombre", nombre))
	queue_redraw()


func _draw() -> void:
	Sprites.dibujar(self, "postales/" + tipo, Rect2(-440, -500, 880, 560))
	if nombre != "":
		var p := Vector2(-float(MEDIO_ANCHO.get(tipo, 150.0)) + 85.0, 0)
		Sprites.dibujar(self, "terreno/letrero", Rect2(p + Vector2(-40, -100), Vector2(80, 104)))
		draw_string(ThemeDB.fallback_font, p + Vector2(-75, -77), nombre, HORIZONTAL_ALIGNMENT_CENTER, 150, 15, Color("253e32"))

static func dibujar_picado(ci: CanvasItem, a: Vector2, b: Vector2, caida: float) -> void:
	Sprites.dibujar(ci, "terreno/picado", Rect2(a - Vector2(0, 2), Vector2(b.x - a.x, caida + 30)))
