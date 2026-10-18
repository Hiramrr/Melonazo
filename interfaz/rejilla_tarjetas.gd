class_name RejillaTarjetas
extends GridContainer
## Rejilla de tarjetas que ajusta sus columnas al ancho disponible.
##
## Parámetros:
##   ancho_minimo   ancho mínimo por columna (px). A partir de aquí se agrega
##                  una columna más si el ancho total lo permite.
##   max_columnas   tope de columnas, para no tener tarjetas diminutas en
##                  pantallas muy anchas.
##
## Uso:
##   var g := RejillaTarjetas.new()
##   g.ancho_minimo = 160.0
##   g.max_columnas = 4
##   contenedor.add_child(g)
##   g.add_child(tarjeta)   # añade tarjetas normalmente
##
## Internamente: en resized(), recalcula columns = clamp(int(size.x / ancho_minimo), 1, max_columnas).

@export var ancho_minimo := 100.0:
	set(v):
		ancho_minimo = maxf(v, 1.0)   # evita división por cero
		if is_inside_tree():
			_ajustar.call_deferred()

@export var max_columnas := 4:
	set(v):
		max_columnas = maxi(v, 1)
		if is_inside_tree():
			_ajustar.call_deferred()

var _scroll: ScrollContainer

func _init() -> void:
	theme_type_variation = Estilos.REJILLA_TARJETAS


func _ready() -> void:
	resized.connect(_ajustar)
	_scroll = _buscar_scroll()
	if _scroll and not _scroll.resized.is_connected(_ajustar):
		_scroll.resized.connect(_ajustar)
	# Aplazar: en _ready el layout aún no está hecho, size.x suele ser 0.
	_ajustar.call_deferred()


func _ajustar() -> void:
	if not is_inside_tree():
		return
	var ancho := _ancho_disponible()
	if ancho <= 0.0:
		return
	var nuevas := clampi(int(ancho / ancho_minimo), 1, max_columnas)
	if columns != nuevas:
		columns = nuevas


## El ScrollContainer ancestro, si lo hay.
func _buscar_scroll() -> ScrollContainer:
	var nodo: Node = get_parent()
	while nodo != null:
		if nodo is ScrollContainer:
			return nodo
		nodo = nodo.get_parent()
	return null


## Ancho disponible para la rejilla. Restamos ~20px como holgura para la
## barra de desplazamiento vertical, que el ScrollContainer puede mostrar.
func _ancho_disponible() -> float:
	var vista := get_viewport_rect().size.x - 80.0
	var scroll := (_scroll.size.x - 20.0) if is_instance_valid(_scroll) else INF
	return maxf(minf(vista, scroll), 100.0)
