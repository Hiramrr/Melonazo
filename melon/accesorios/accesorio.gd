class_name Accesorio
extends RefCounted
## Datos, efecto y colisión del accesorio. Su arte está en recursos/sprites/accesorios.
## Para añadir uno, copia un archivo de esta carpeta, define usar() y exporta su sprite.

var id := ""
var nombre := "Accesorio"
var carisma := 1
var accion := ""                  # descripción corta para el taller
var grito := ""                   # aviso al usarlo; vacío = "¡<nombre>!"
var costo := 0                    # aplausos para desbloquearlo
var inicial := false              # viene desbloqueado desde el principio
var orden := 100                  # posición en la lista del taller
var color := Color.WHITE
var _recorte_icono := Rect2i()
var forma: Array = []             # polígono convexo de colisión (u, v)

const TINTA := Color("253e32")    # contorno, el mismo de la cara del melón


## Efecto al pulsar su tecla. El accesorio ya se quitó del melón.
func usar(_m: Melon) -> void:
	pass


## Física por paso mientras siga activo (ver Melon.activar). Devuelve la velocidad.
func fisica(_m: Melon, v: Vector2, _dt: float) -> Vector2:
	return v


func dibujar(ci: CanvasItem, r: float, a: float) -> void:
	Sprites.girar(ci, "accesorios/" + id, Transform2D(a + PI / 2.0, Vector2.ONE * r / 32.0, 0.0, Vector2.ZERO))


func dibujar_icono(ci: CanvasItem, rect: Rect2) -> void:
	var tex := Sprites.textura("accesorios/" + id)
	if not _recorte_icono.has_area():
		_recorte_icono = tex.get_image().get_used_rect()
	var recorte := _recorte_icono
	var tam := Vector2(recorte.size)
	if tam == Vector2.ZERO:
		return
	var escala := minf(rect.size.x / tam.x, rect.size.y / tam.y) * 0.95
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ci.draw_texture_rect_region(tex, Rect2(rect.get_center() - tam * escala * 0.5, tam * escala), recorte)

static func uv(r: float, a: float, u: float, v: float) -> Vector2:
	return Vector2.from_angle(a) * (r + v * r) + Vector2.from_angle(a + PI / 2.0) * (u * r)

static func piel(u: float) -> float:
	return sqrt(maxf(0.0, 1.0 - u * u)) - 1.0

func puntos(r: float, a: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in forma:
		pts.append(uv(r, a, p.x, p.y))
	return pts

func texto_aviso() -> String:
	return grito if grito != "" else "¡%s!" % nombre
