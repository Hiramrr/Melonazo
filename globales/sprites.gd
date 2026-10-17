@tool
class_name Sprites
extends RefCounted
## Hojas PNG y metadatos JSON Hash exportados por LibreSprite.

const HOJAS := {
	"transiciones": {"datos": preload("res://recursos/sprites/transiciones.json"), "textura": preload("res://recursos/sprites/transiciones.png")},
	"melon": {"datos": preload("res://recursos/sprites/melon.json"), "textura": preload("res://recursos/sprites/melon.png")},
	"accesorios": {"datos": preload("res://recursos/sprites/accesorios.json"), "textura": preload("res://recursos/sprites/accesorios.png")},
	"terreno": {"datos": preload("res://recursos/sprites/terreno.json"), "textura": preload("res://recursos/sprites/terreno.png")},
	"postales": {"datos": preload("res://recursos/sprites/postales.json"), "textura": preload("res://recursos/sprites/postales.png")},
	"obstaculos": {"datos": preload("res://recursos/sprites/obstaculos.json"), "textura": preload("res://recursos/sprites/obstaculos.png")},
	"ayudas": {"datos": preload("res://recursos/sprites/ayudas.json"), "textura": preload("res://recursos/sprites/ayudas.png")},
	"paisaje": {"datos": preload("res://recursos/sprites/paisaje.json"), "textura": preload("res://recursos/sprites/paisaje.png")},
	"interfaz": {"datos": preload("res://recursos/sprites/interfaz.json"), "textura": preload("res://recursos/sprites/interfaz.png")},
	"efectos": {"datos": preload("res://recursos/sprites/efectos.json"), "textura": preload("res://recursos/sprites/efectos.png")},
}
static var _texturas: Dictionary = {}
static var _mallas: Dictionary = {}

static func datos(id: String) -> Dictionary:
	return HOJAS[id.get_slice("/", 0)]["datos"].data["frames"][id.get_slice("/", 1)]

static func textura(id: String) -> AtlasTexture:
	if not _texturas.has(id):
		var f: Dictionary = datos(id)["frame"]
		var tex := AtlasTexture.new()
		tex.atlas = HOJAS[id.get_slice("/", 0)]["textura"]
		tex.region = Rect2(f.x, f.y, f.w, f.h)
		tex.filter_clip = true
		_texturas[id] = tex
	return _texturas[id]

static func dibujar(ci: CanvasItem, id: String, rect: Rect2, tinte := Color.WHITE) -> void:
	var d := datos(id)
	var origen: Dictionary = d["spriteSourceSize"]
	var escala := rect.size / Vector2(d.sourceSize.w, d.sourceSize.h)
	var destino := Rect2(rect.position + Vector2(origen.x, origen.y) * escala,
		Vector2(origen.w, origen.h) * escala)
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ci.draw_texture_rect(textura(id), destino, false, tinte)

static func poner(ci: CanvasItem, id: String, pos := Vector2.ZERO, tinte := Color.WHITE,
		escala := 1.0, ancla := Vector2(0.5, 0.5)) -> void:
	var d := datos(id)
	var tam := Vector2(d.sourceSize.w, d.sourceSize.h) * Pixel.ESCALA * escala
	dibujar(ci, id, Rect2(pos - tam * ancla, tam), tinte)

## Textura independiente para repetir un cuadro o usarlo en una malla de sprite.
static func suelta(id: String) -> ImageTexture:
	var clave := "suelta:" + id
	if not _texturas.has(clave):
		_texturas[clave] = ImageTexture.create_from_image(textura(id).get_image())
	return _texturas[clave]

static func mosaico(ci: CanvasItem, id: String, rect: Rect2, tinte := Color.WHITE) -> void:
	ci.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ci.draw_texture_rect_region(suelta(id), rect, Rect2(rect.position / Pixel.ESCALA, rect.size / Pixel.ESCALA), tinte)

static func disco(ci: CanvasItem, pos: Vector2, radio: float, color: Color) -> void:
	poner(ci, "efectos/disco", pos, color, radio / 32.0)

static func aro(ci: CanvasItem, pos: Vector2, radio: float, color: Color) -> void:
	poner(ci, "efectos/aro", pos, color, radio / 32.0)

## La transformación se compone con la del lienzo que ya dibuja el melón o el HUD.
static func girar(ci: CanvasItem, id: String, transformacion: Transform2D, tinte := Color.WHITE) -> void:
	if not _mallas.has(id):
		var malla := QuadMesh.new()
		malla.size = textura(id).get_size() * Pixel.ESCALA
		_mallas[id] = malla
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ci.draw_mesh(_mallas[id], suelta(id), transformacion.scaled_local(Vector2(1, -1)), tinte)

static func rectangulo(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	dibujar(ci, "efectos/papel", rect, color)

static func marco(ci: CanvasItem, rect: Rect2, color: Color, ancho := 2.0) -> void:
	for r in [Rect2(rect.position, Vector2(rect.size.x, ancho)),
		Rect2(rect.position, Vector2(ancho, rect.size.y)),
		Rect2(rect.position + Vector2(0, rect.size.y - ancho), Vector2(rect.size.x, ancho)),
		Rect2(rect.position + Vector2(rect.size.x - ancho, 0), Vector2(ancho, rect.size.y))]:
		rectangulo(ci, r, color)

static func animacion(prefijo: String, cuadros: int, segundos: float) -> String:
	var duracion := 0.0
	for i in cuadros:
		duracion += float(datos(prefijo + str(i))["duration"])
	var restante := fposmod(segundos * 1000.0, duracion)
	for i in cuadros:
		var id := prefijo + str(i)
		restante -= float(datos(id)["duration"])
		if restante < 0:
			return id
	return prefijo + "0"
