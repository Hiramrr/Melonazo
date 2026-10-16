class_name SlotAccesorio
extends PanelContainer
## Casilla del HUD que muestra el accesorio de una tecla (1, 2 o 3).
##
## Escena: pantallas/recorrido/hud/slot_accesorio.tscn, instanciada tres veces
## en el contenedor Equipo de hud.tscn. El HUD llama a mostrar() cuando cambia
## el equipo del melón (al usar o perder un accesorio). Al vaciarse, la casilla
## da un salto y se apaga.

@export_range(1, 3) var tecla := 1:
	set(valor):
		tecla = valor
		if is_node_ready():
			%Tecla.text = str(tecla)

@onready var nombre: Label = %Nombre
@onready var icono: Control = %Icono

var _id = null                         # id del accesorio o null si está vacío


func _ready() -> void:
	%Tecla.text = str(tecla)
	mostrar(null)


## Muestra el accesorio id, o la casilla vacía si id es null.
func mostrar(id) -> void:
	if _id != null and id == null and is_inside_tree():
		Animacion.rebotar(self, 1.2)
	_id = id
	modulate = Color.WHITE if id != null else Color(1, 1, 1, 0.55)
	var accesorio: Accesorio = Config.accesorios.get(id) if id != null else null
	nombre.text = accesorio.nombre.get_slice(" ", 0) if accesorio else "Vacío"
	tooltip_text = accesorio.nombre if accesorio else "Sin accesorio"
	icono.queue_redraw()


## Conectada a la señal draw del nodo Icono.
func _dibujar_icono() -> void:
	if _id == null:
		var c := icono.size * 0.5
		icono.draw_arc(c, 12.0, 0, TAU, 24, Color(1, 1, 1, 0.35), 3.0, true)
		return
	var lado := minf(icono.size.x, icono.size.y)
	Config.accesorios[_id].dibujar_icono(icono, Rect2((icono.size - Vector2(lado, lado)) * 0.5, Vector2(lado, lado)))
