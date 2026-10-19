class_name PestanaAccesorios
extends ScrollContainer
## Pestaña "Accesorios" del taller: equipar, quitar y desbloquear accesorios.
##
## Nodo: Taller/.../Pestanas/Accesorios (pantallas/taller/taller.tscn).
##   FeedbackAcc             cuántos van equipados y avisos (p. ej. el máximo)
##   ListaAcc                GridContainer con una tarjeta por Config.orden_accesorios
##                           (se crean aquí): dibujo, nombre, qué hace, carisma o precio
##
## Cada tarjeta es un botón. Si el accesorio está libre, equipa o quita; si está
## bloqueado, lo compra. La tarjeta equipada se pinta amarilla y lleva la tecla
## (1, 2 o 3) en la esquina.
## Los equipados se guardan en Juego.accesorios en el orden de las teclas 1-2-3.
## Emite cambio al tocar Juego; Taller refresca la pantalla (y llama refrescar()).

signal cambio

const LADO_ICONO := 56.0
const ALTO_TARJETA := 195.0
# const ANCHO_MIN_TRES := 480.0          # ancho de la lista a partir del cual van 3 columnas

@onready var lbl_feedback: Label = %FeedbackAcc
@onready var lista: RejillaTarjetas = %ListaAcc

var filas := {}                         # id -> {boton, tecla, pie, precio, icono, candado}
var _aviso := ""                        # se muestra una vez en FeedbackAcc


func _ready() -> void:
	for id in Config.orden_accesorios:
		_crear_tarjeta(id)

## Pone al día el texto de ayuda y las tarjetas con Juego.
func refrescar() -> void:
	var base := "Equipados %d de %d · teclas 1, 2 y 3 en el aire" % [Juego.accesorios.size(), Config.max_accesorios]
	lbl_feedback.text = base if _aviso == "" else _aviso
	lbl_feedback.theme_type_variation = Estilos.AVISO_ACCESORIOS if _aviso != "" else Estilos.SUBTITULO_CHICO
	_aviso = ""
	for id in Config.orden_accesorios:
		var a: Accesorio = Config.accesorios[id]
		var f: Dictionary = filas[id]
		var b: BotonTarjeta = f["boton"]
		var libre: bool = id in Juego.desbloqueados
		var pos := Juego.accesorios.find(id)
		b.seleccionado = pos >= 0                     # ← reemplaza theme_type_variation manual
		b.disabled = not libre and Juego.aplausos < a.costo
		f["tecla"].visible = pos >= 0
		f["tecla"].text = str(pos + 1)
		f["candado"].visible = not libre
		f["icono"].modulate = Color.WHITE if libre else b.get_theme_color("accesorio_bloqueado")
		f["carisma"].visible = libre
		f["carisma"].texto = "+%d" % a.carisma
		f["precio"].visible = not libre
		f["precio"].texto = str(a.costo)
		b.tooltip_text = "%s\n%s" % [a.nombre, a.accion] if libre else "Desbloquear por %d aplausos" % a.costo

## Tarjeta de un accesorio:
##   [tecla]          [candado]
##          (dibujo)
##        Nombre
##   qué hace, en letra suave
##        carisma o precio
func _crear_tarjeta(id: String) -> void:
	var accesorio: Accesorio = Config.accesorios[id]
	var b := BotonTarjeta.new()
	b.custom_minimum_size = Vector2(0, ALTO_TARJETA)
	b.pressed.connect(_pulsar.bind(id))
	lista.add_child(b)

	var icono := Control.new()
	icono.custom_minimum_size = Vector2(LADO_ICONO, LADO_ICONO)
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icono.draw.connect(accesorio.dibujar_icono.bind(icono, Rect2(0, 0, LADO_ICONO, LADO_ICONO)))
	icono.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.cuerpo.add_child(icono)

	var nombre := ComunTaller.titulo_seccion(accesorio.nombre, Estilos.NOMBRE_TARJETA)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.cuerpo.add_child(nombre)

	var info := ComunTaller.etiqueta(accesorio.accion, Estilos.DETALLE)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.cuerpo.add_child(info)

	var carisma := Ficha.crear(Iconos.CARISMA, "", false, Estilos.CONTADOR_TARJETA)
	carisma.lado_icono = 20.0
	b.pie.add_child(carisma)
	var precio := Ficha.crear(Iconos.APLAUSO, "", false, Estilos.CONTADOR_TARJETA)
	precio.lado_icono = 20.0
	b.pie.add_child(precio)

	# Overlays específicos de Accesorios (van al Button, no al contenido)
	var tecla := Iconos.tecla("1", Estilos.TECLA_TARJETA)
	tecla.position = Vector2(8, 6)
	b.add_child(tecla)
	var candado := Iconos.imagen(Iconos.CANDADO, 28.0)
	b.add_child(candado)
	candado.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	candado.position += Vector2(-36, 8)

	filas[id] = {"boton": b, "tecla": tecla, "carisma": carisma, "precio": precio, "icono": icono, "candado": candado}

## Equipa, quita o compra según el estado del accesorio.
func _pulsar(id: String) -> void:
	if not id in Juego.desbloqueados:
		Juego.desbloquear(id)            # cobra los aplausos y guarda
		if id in Juego.desbloqueados:
			Animacion.rebotar(filas[id]["icono"], 1.35)
		cambio.emit()
		return
	_alternar(id)


## Equipa o quita el accesorio. Si ya van Config.max_accesorios, avisa.
func _alternar(id: String) -> void:
	if id in Juego.accesorios:
		Juego.accesorios.erase(id)
	elif Juego.accesorios.size() < Config.max_accesorios:
		Juego.accesorios.append(id)
		Animacion.rebotar(filas[id]["icono"], 1.3)
	else:
		_aviso = "Ya llevas %d accesorios. Quita uno para ponerte otro." % Config.max_accesorios
	Juego.guardar()
	cambio.emit()
