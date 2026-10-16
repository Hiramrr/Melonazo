class_name PestanaAccesorios
extends ScrollContainer
## Pestaña "Accesorios" del taller: equipar, quitar y desbloquear accesorios.
##
## Nodo: Taller/.../Pestanas/Accesorios (pantallas/taller/taller.tscn).
##   FeedbackAcc             cuántos van equipados y avisos (p. ej. el máximo)
##   ListaAcc                una fila por Config.orden_accesorios (se crean aquí):
##                           icono, botón equipar/quitar, botón desbloquear y qué hace
##
## Los equipados se guardan en Juego.accesorios en el orden de las teclas 1-2-3.
## Emite cambio al tocar Juego; Taller refresca la pantalla (y llama refrescar()).

signal cambio

const LADO_ICONO := 44.0

@onready var lbl_feedback: Label = %FeedbackAcc
@onready var lista: VBoxContainer = %ListaAcc

var filas := {}                         # id -> {boton, desbloquear, info}
var _aviso := ""                        # se muestra una vez en FeedbackAcc


func _ready() -> void:
	for id in Config.orden_accesorios:
		_crear_fila(id)


## Pone al día el texto de ayuda y los botones con Juego.
func refrescar() -> void:
	var base := "Equipados %d de %d. Teclas 1, 2, 3 para usarlos en el aire." % [Juego.accesorios.size(), Config.max_accesorios]
	lbl_feedback.text = base if _aviso == "" else base + " " + _aviso
	_aviso = ""
	for id in Config.orden_accesorios:
		var a: Accesorio = Config.accesorios[id]
		var b: Button = filas[id]["boton"]
		var d: Button = filas[id]["desbloquear"]
		var libre: bool = id in Juego.desbloqueados
		var pos := Juego.accesorios.find(id)
		var marca := "[%d]" % (pos + 1) if pos >= 0 else "[  ]"
		b.text = "%s %s · carisma %d" % [marca, a.nombre, a.carisma]
		b.disabled = not libre or (pos < 0 and Juego.accesorios.size() >= Config.max_accesorios)
		b.theme_type_variation = &"Seleccion" if pos >= 0 else &"Button"
		filas[id]["info"].text = a.accion
		d.visible = not libre
		d.text = "Desbloquear · %d" % a.costo
		d.disabled = Juego.aplausos < a.costo


## Fila de un accesorio: [icono] [equipar/quitar] [desbloquear]
##                                [qué hace, en letra suave]
func _crear_fila(id: String) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	lista.add_child(fila)
	var icono := Control.new()
	icono.custom_minimum_size = Vector2(LADO_ICONO, LADO_ICONO)
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accesorio: Accesorio = Config.accesorios[id]
	icono.draw.connect(accesorio.dibujar_icono.bind(icono, Rect2(0, 0, LADO_ICONO, LADO_ICONO)))
	fila.add_child(icono)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 2)
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(columna)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	columna.add_child(botones)
	var b := ComunTaller.boton("")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.pressed.connect(_alternar.bind(id))
	botones.add_child(b)
	var d := ComunTaller.boton("")
	d.pressed.connect(_desbloquear.bind(id))
	botones.add_child(d)
	var info := ComunTaller.etiqueta("", 14, true)
	columna.add_child(info)
	filas[id] = {"boton": b, "desbloquear": d, "info": info}


## Equipa o quita el accesorio. Si ya van Config.max_accesorios, avisa.
func _alternar(id: String) -> void:
	if id in Juego.accesorios:
		Juego.accesorios.erase(id)
	elif id in Juego.desbloqueados:
		if Juego.accesorios.size() < Config.max_accesorios:
			Juego.accesorios.append(id)
		else:
			_aviso = "Ya llevas %d accesorios. Quita uno para ponerte otro." % Config.max_accesorios
	Juego.guardar()
	cambio.emit()


func _desbloquear(id: String) -> void:
	Juego.desbloquear(id)                # cobra los aplausos y guarda
	cambio.emit()
