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
##      y escribe fisica(). Para un dibujo propio escribe dibujar() con las ayudas
##      del final: suave(), elipse(), pieza() y linea().
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

const TINTA := Color("253e32")    # contorno, el mismo de la cara del melón
const LUZ := Vector2(-0.45, 0.9)  # la luz llega desde arriba a la izquierda (u, v)


## Efecto al pulsar su tecla. El accesorio ya se quitó del melón.
func usar(_m: Melon) -> void:
	pass


## Física por paso mientras siga activo (ver Melon.activar). Devuelve la velocidad.
func fisica(_m: Melon, v: Vector2, _dt: float) -> Vector2:
	return v


## Dibujo completo. Por defecto rellena la forma y luego llama a dibujar_detalle().
func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	pieza(ci, r, a, PackedVector2Array(forma), color)
	dibujar_detalle(ci, r, a)


func dibujar_detalle(_ci: CanvasItem, _r: float, _a: float) -> void:
	pass


func dibujar_icono(ci: CanvasItem, rect: Rect2) -> void:
	var pts := puntos(1.0, -PI / 2.0)
	var limites := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		limites = limites.expand(p)
	limites = limites.grow(0.2)  # el arte sobresale un poco de la colisión
	# Se dibuja al radio que cabe en vez de escalar, así el antialias queda nítido.
	var r := minf(rect.size.x / limites.size.x, rect.size.y / limites.size.y) * 0.95
	ci.draw_set_transform(rect.get_center() - limites.get_center() * r)
	dibujar(ci, r, -PI / 2.0)
	ci.draw_set_transform(Vector2.ZERO)


# --- Ayudas ------------------------------------------------------------------

## Convierte (u, v) del accesorio en el ángulo a a coordenadas del melón.
static func uv(r: float, a: float, u: float, v: float) -> Vector2:
	return Vector2.from_angle(a) * (r + v * r) + Vector2.from_angle(a + PI / 2.0) * (u * r)


static func ancho(r: float) -> float:
	return maxf(1.0, r * 0.045)


## Superficie del melón: la v de la piel a la altura u (para que las piezas la abracen).
static func piel(u: float) -> float:
	return sqrt(maxf(0.0, 1.0 - u * u)) - 1.0


## Convierte una lista de (u, v) a coordenadas del melón.
static func uvs(r: float, a: float, lista: PackedVector2Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in lista:
		pts.append(uv(r, a, p.x, p.y))
	return pts


## Curva cerrada y suave (Catmull-Rom) que pasa por los puntos (u, v) dados.
static func suave(lista: PackedVector2Array, pasos := 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := lista.size()
	for i in n:
		var p0 := lista[(i - 1 + n) % n]
		var p1 := lista[i]
		var p2 := lista[(i + 1) % n]
		var p3 := lista[(i + 2) % n]
		for s in pasos:
			pts.append(p1.cubic_interpolate(p2, p0, p3, float(s) / pasos))
	return pts


## Elipse (u, v) con centro c y radios rad, girada giro radianes.
static func elipse(c: Vector2, rad: Vector2, giro := 0.0, pasos := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in pasos:
		var t := TAU * i / pasos
		pts.append(c + Vector2(cos(t) * rad.x, sin(t) * rad.y).rotated(giro))
	return pts


## Rellena una figura (u, v) y le pone una sombra del lado contrario a la luz.
## Devuelve los puntos ya convertidos, para cerrar con contorno() tras los detalles.
static func rellenar(ci: CanvasItem, r: float, a: float, figura: PackedVector2Array, col: Color, sombra := 0.1) -> PackedVector2Array:
	var pts := uvs(r, a, figura)
	ci.draw_colored_polygon(pts, col)
	if sombra > 0.0:
		var paso := uv(r, a, LUZ.x * sombra, LUZ.y * sombra) - uv(r, a, 0, 0)
		var movida := PackedVector2Array()
		for p in pts:
			movida.append(p + paso)
		for parte in Geometry2D.clip_polygons(pts, movida):
			poligono(ci, parte, col.darkened(0.22))
	return pts


## Polígono ya convertido con el borde suavizado (el relleno solo no tiene antialias).
static func poligono(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	ci.draw_colored_polygon(pts, col)
	var cerrado := pts.duplicate()
	cerrado.append(pts[0])
	ci.draw_polyline(cerrado, col, 1.0, true)


static func contorno(ci: CanvasItem, r: float, pts: PackedVector2Array, grosor := 1.0) -> void:
	var cerrado := pts.duplicate()
	cerrado.append(pts[0])
	ci.draw_polyline(cerrado, TINTA, ancho(r) * grosor, true)


## Figura completa: relleno, sombra y contorno de tinta.
static func pieza(ci: CanvasItem, r: float, a: float, figura: PackedVector2Array, col: Color, sombra := 0.1) -> void:
	contorno(ci, r, rellenar(ci, r, a, figura, col, sombra))


## Trazo abierto con puntos (u, v); grosor en fracciones del radio.
static func linea(ci: CanvasItem, r: float, a: float, lista: PackedVector2Array, col: Color, grosor: float) -> void:
	ci.draw_polyline(uvs(r, a, lista), col, maxf(0.8, r * grosor), true)


func puntos(r: float, a: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in forma:
		pts.append(uv(r, a, p.x, p.y))
	return pts


func texto_aviso() -> String:
	return grito if grito != "" else "¡%s!" % nombre
