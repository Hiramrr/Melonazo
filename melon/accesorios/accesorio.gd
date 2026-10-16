class_name Accesorio
extends RefCounted
## Base de todos los accesorios. Cada accesorio vive en su propio archivo dentro
## de melon/accesorios/ y Config lo carga solo al iniciar el juego.
##
## Para crear uno nuevo:
##   1. Copia cualquier archivo de esta carpeta (por ejemplo sombrero.gd).
##   2. Cambia sus datos en _init(). El id es el nombre del archivo.
##   3. Escribe su efecto en usar(). Melon ofrece efectos listos: planear(),
##      embestir(), caida_lenta(), rodar(), proteger(), reparar(),
##      atraer_aplausos(), sumar_rebote(), empujar() y fijar_velocidad().
##   4. Si necesita física propia mientras dura, llama a m.activar(self, segundos)
##      y escribe fisica(). Si quieres un dibujo especial, escribe dibujar_detalle().
##
## Coordenadas del accesorio: u va a lo largo de la superficie del melón y v hacia
## afuera, ambas en unidades del radio (v < 0 queda dentro del melón).

var id := ""
var nombre := "Accesorio"
var carisma := 1
var accion := ""                  # descripción corta para el taller
var grito := ""                   # aviso al usarlo; vacío = "¡<nombre>!"
var costo := 0                    # aplausos para desbloquearlo
var inicial := false              # viene desbloqueado desde el principio
var orden := 100                  # posición en la lista del taller
var color := Color.WHITE
var forma: Array = []             # polígono convexo de colisión (u, v)


## Efecto al pulsar su tecla. El accesorio ya se quitó del melón.
func usar(_m: Melon) -> void:
	pass


## Física por paso mientras siga activo (ver Melon.activar). Devuelve la velocidad.
func fisica(_m: Melon, v: Vector2, _dt: float) -> Vector2:
	return v


## Dibujo completo. Por defecto rellena la forma y luego llama a dibujar_detalle().
func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	var pts := puntos(r, a)
	ci.draw_colored_polygon(pts, color)
	pts.append(pts[0])
	ci.draw_polyline(pts, color.darkened(0.4), ancho(r))
	dibujar_detalle(ci, r, a)


func dibujar_detalle(_ci: CanvasItem, _r: float, _a: float) -> void:
	pass


func dibujar_icono(ci: CanvasItem, rect: Rect2) -> void:
	var pts := puntos(18.0, -PI / 2.0)
	var limites := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		limites = limites.expand(p)
	var escala := minf(rect.size.x / maxf(limites.size.x, 1.0), rect.size.y / maxf(limites.size.y, 1.0)) * 0.85
	ci.draw_set_transform(rect.get_center() - limites.get_center() * escala, 0, Vector2.ONE * escala)
	dibujar(ci, 18.0, -PI / 2.0)
	ci.draw_set_transform(Vector2.ZERO)


# --- Ayudas ------------------------------------------------------------------

## Convierte (u, v) del accesorio en el ángulo a a coordenadas del melón.
static func uv(r: float, a: float, u: float, v: float) -> Vector2:
	return Vector2.from_angle(a) * (r + v * r) + Vector2.from_angle(a + PI / 2.0) * (u * r)


static func ancho(r: float) -> float:
	return maxf(1.5, r * 0.07)


func puntos(r: float, a: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in forma:
		pts.append(uv(r, a, p.x, p.y))
	return pts


func texto_aviso() -> String:
	return grito if grito != "" else "¡%s!" % nombre
