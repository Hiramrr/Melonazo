class_name Tramo
extends Node2D
## Un tramo de terreno: superficie con colisión, casas de fondo y letreros de distancia.
##
## Los tramos los crea y llena GeneradorTerreno (mundo/terreno/generador_terreno.gd).
## Se encadenan: el último punto de uno es el primero del siguiente.
##
## Escena: mundo/terreno/tramo.tscn
##   Decoracion (z -2)   casas, árboles y papel picado; se dibuja en _dibujar_decoracion()
##   Postales   (z -1)   lugares de Xalapa (postal.tscn); ver agregar_postal()
##   Suelo               StaticBody2D; construir() le agrega un "Segmento###" por tramo de línea
##   Obstaculos          obstaculos/*.tscn
##   Publico             personas que empujan (ayudas/persona.tscn)
##   Coleccionables      aplausos sueltos y poderes
##   Aire                papalotes, rutas de aplausos y poderes en altura
## El suelo y los letreros se dibujan en _draw() de este nodo (z 0).

const PostalEscena := preload("res://mundo/terreno/postal.tscn")

var puntos := PackedVector2Array()   # superficie, de izquierda a derecha, con paso fijo en x
var empedrado := false               # calle de piedra o pasto
var color_suelo := Color(0.36, 0.52, 0.25)
var marcadores: Array = []           # {pos, texto}: letreros de distancia
var casas: Array = []                # {rect, color}: fachadas de fondo
var personas: Array = []             # Persona del contenedor Publico
var papalotes: Array = []            # Papalote del contenedor Aire
var x0 := 0.0                        # primer x del tramo
var x1 := 0.0                        # último x del tramo
var _paso := 1.0
var _fondo := 0.0                    # y hasta donde se rellena la tierra


## Calcula los límites y crea la colisión a partir de puntos. Llamar una vez.
func construir() -> void:
	x0 = puntos[0].x
	x1 = puntos[puntos.size() - 1].x
	_paso = puntos[1].x - puntos[0].x
	_fondo = 0.0
	for p in puntos:
		_fondo = maxf(_fondo, p.y)
	_fondo += 1500.0
	var cuerpo := get_node("Suelo") as StaticBody2D
	cuerpo.collision_layer = 1
	cuerpo.collision_mask = 0
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	mat.bounce = 0.0
	cuerpo.physics_material_override = mat
	for c in cuerpo.get_children():
		if c.name.begins_with("Segmento"):
			cuerpo.remove_child(c)
			c.queue_free()
	# Un cuadrilátero convexo grueso por segmento: evita que el melón atraviese el suelo.
	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var abajo := maxf(a.y, b.y) + 600.0
		var forma := ConvexPolygonShape2D.new()
		forma.set_point_cloud(PackedVector2Array([a, b, Vector2(b.x, abajo), Vector2(a.x, abajo)]))
		var cs := CollisionShape2D.new()
		cs.name = "Segmento%03d" % i
		cs.shape = forma
		cuerpo.add_child(cs)


## y del suelo en x (interpolado entre puntos). Fuera del tramo usa el borde.
func altura(x: float) -> float:
	var f := clampf((x - x0) / _paso, 0.0, puntos.size() - 1.001)
	var i := int(f)
	return lerpf(puntos[i].y, puntos[i + 1].y, f - i)


## Ángulo del suelo en x, en radianes.
func pendiente(x: float) -> float:
	return atan2(altura(x + 10.0) - altura(x - 10.0), 20.0)


## datos: {pos: Vector2, tipo: String, nombre: String}. pos en coordenadas del tramo,
## a ras de suelo (p. ej. Vector2(x, altura(x))).
func agregar_postal(datos: Dictionary) -> Postal:
	var p: Postal = PostalEscena.instantiate()
	p.configurar(datos)
	get_node("Postales").add_child(p)
	return p


## Número pseudoaleatorio estable en [0, 1) para decorar siempre igual.
static func _azar(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


# --- Fondo: árboles, casas y papel picado (nodo Decoracion, z -2) -------------

## Conectada a la señal draw del nodo Decoracion en tramo.tscn.
func _dibujar_decoracion() -> void:
	var ci := get_node("Decoracion") as CanvasItem
	var x := x0 + 60.0 + 120.0 * _azar(x0)
	while x < x1:
		var h := _azar(x)
		if not empedrado or h < 0.35:
			_arbol(ci, Vector2(x, altura(x) + 30.0), h)
		x += 130.0 + 200.0 * _azar(x + 1.0)
	for c in casas:
		_casa(ci, c["rect"], c["color"])
	for i in casas.size() - 1:
		var a: Rect2 = casas[i]["rect"]
		var b: Rect2 = casas[i + 1]["rect"]
		if b.position.x - a.end.x < 260.0:
			Postal.dibujar_picado(ci, Vector2(a.end.x - 8, a.position.y + 26), Vector2(b.position.x + 8, b.position.y + 26), 34.0)


func _arbol(ci: CanvasItem, p: Vector2, h: float) -> void:
	var i := 0 if h < 0.25 else (3 if h > 0.8 else (1 if h < 0.55 else 2))
	Sprites.dibujar(ci, "terreno/arbol_%d" % i, Rect2(p + Vector2(-130, -270), Vector2(260, 280)))

func _casa(ci: CanvasItem, r: Rect2, color: Color) -> void:
	var piso := 1 if r.size.y - 40 >= 170 else 0
	var alto := 240.0 if piso else 140.0
	var escala := r.size / Vector2(160, alto)
	var indice := 0
	var distancia := INF
	for i in GeneradorTerreno.COLORES_CASAS.size():
		var c: Color = GeneradorTerreno.COLORES_CASAS[i]
		var d := Vector3(color.r, color.g, color.b).distance_squared_to(Vector3(c.r, c.g, c.b))
		if d < distancia:
			distancia = d
			indice = i
	Sprites.dibujar(ci, "terreno/casa_%d_%d" % [piso, indice],
		Rect2(r.position - Vector2(12, 28) * escala, Vector2(184, alto + 28) * escala))

func _draw() -> void:
	if puntos.size() < 2:
		return
	_dibujar_suelo("terreno/calle" if empedrado else "terreno/pasto", false)
	for m in marcadores:
		var p: Vector2 = m["pos"]
		Sprites.dibujar(self, "terreno/letrero", Rect2(p + Vector2(-40, -100), Vector2(80, 104)))
		draw_string(ThemeDB.fallback_font, p + Vector2(-35, -77), m["texto"], HORIZONTAL_ALIGNMENT_CENTER, 70, 15, Color(0.15, 0.15, 0.15))

## Columnas de textura siguen la misma altura que usa la colisión del terreno.
func _dibujar_suelo(id: String, bajada: bool) -> void:
	var tex := Sprites.textura(id)
	var tam := tex.get_size() * Pixel.ESCALA
	var x := x0
	while x < x1:
		var ancho := minf(Pixel.ESCALA, x1 - x)
		var y := altura(x + ancho * 0.5)
		var inicio := y + (114.0 if bajada else 38.0)
		Sprites.mosaico(self, "terreno/muro" if bajada else "terreno/tierra", Rect2(x, inicio, ancho, _fondo - inicio))
		var color := Color.WHITE if empedrado or bajada else color_suelo
		var alto_superficie := tam.y if bajada else 54.0
		var destino := Rect2(x, y - (0.0 if bajada else 16.0), ancho, alto_superficie)
		var region := Rect2(fposmod(x, tam.x) / Pixel.ESCALA, 0, ancho / Pixel.ESCALA, alto_superficie / Pixel.ESCALA)
		draw_texture_rect_region(tex, destino, region, color)
		x += ancho
