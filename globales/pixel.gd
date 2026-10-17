class_name Pixel
extends RefCounted
## Ayudas para dibujar el mundo con sprites de pixel art (recursos/sprites/).
##
## Regla del proyecto: el mundo no usa SVG ni dibujo vectorial (polígonos,
## círculos o líneas en _draw()). El arte sale de hojas PNG convertidas de los dibujos originales, que se
## pueden abrir y editar en LibreSprite. Ver recursos/sprites/README.md.
##
## Cada píxel del arte mide ESCALA píxeles del mundo. Los nodos raíz del mundo
## (Mundo y Paisaje de cada pantalla) usan texture_filter = Nearest, así los
## píxeles se ven nítidos al escalar. Los Control que muestran arte del mundo
## (vista del taller, almanaque, HUD) también deben usar Nearest.

const ESCALA := 2.0


## Redondea al múltiplo de ESCALA: alinea con la cuadrícula del arte.
static func ajustar(v: float) -> float:
	return floorf(v / ESCALA) * ESCALA


static func ajustar_v(v: Vector2) -> Vector2:
	return Vector2(ajustar(v.x), ajustar(v.y))


## Dibuja tex a ESCALA con su ancla en pos. ancla (0..1) es el punto del sprite
## que cae en pos: (0.5, 1) = centro de la base, (0.5, 0.5) = centro.
static func dibujar(ci: CanvasItem, tex: Texture2D, pos: Vector2, ancla := Vector2(0.5, 1.0),
		tinte := Color.WHITE, voltear := false, escala := ESCALA) -> void:
	var tam := tex.get_size() * escala
	var r := Rect2(pos - tam * ancla, tam)
	if voltear:
		r.position.x += r.size.x
		r.size.x = -r.size.x
	ci.draw_texture_rect(tex, r, false, tinte)


## Como dibujar(), pero solo una región (cuadro de una hoja de sprites).
static func dibujar_region(ci: CanvasItem, tex: Texture2D, region: Rect2, pos: Vector2,
		ancla := Vector2(0.5, 1.0), tinte := Color.WHITE, voltear := false, escala := ESCALA) -> void:
	var tam := region.size * escala
	var r := Rect2(pos - tam * ancla, tam)
	if voltear:
		r.position.x += r.size.x
		r.size.x = -r.size.x
	ci.draw_texture_rect_region(tex, r, region, tinte)


## Cuadro n de una tira horizontal de cuadros de ancho fijo.
static func cuadro(tex: Texture2D, n: int, cuadros: int) -> Rect2:
	var w := tex.get_width() / cuadros
	return Rect2(w * n, 0, w, tex.get_height())


## Repite tex (o una franja de ella) para llenar rect en coordenadas del mundo.
## Requiere texture_repeat = Enabled en el nodo que dibuja (o en un padre).
## desfase mueve el patrón en píxeles del mundo, para que no "nade".
static func mosaico(ci: CanvasItem, tex: Texture2D, rect: Rect2, desfase := Vector2.ZERO,
		tinte := Color.WHITE, escala := ESCALA) -> void:
	var origen := Rect2((rect.position + desfase) / escala, rect.size / escala)
	ci.draw_texture_rect_region(tex, rect, origen, tinte)
