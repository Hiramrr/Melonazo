class_name PestanaMelon
extends ScrollContainer
## Pestaña "Tu melón" del taller: nombre, tamaño y aspecto del melón.
##
## Nodo: Taller/.../Pestanas/TuMelon (pantallas/taller/taller.tscn). El título
## visible "Tu melón" lo pone Taller, porque el nodo tiene nombre sin acento.
##   LineaNombre             nombre del melón (sus señales están conectadas en la escena)
##   FilaTamanos             un botón por Config.tamanos (se crean aquí)
##   DescTamano              descripción del tamaño elegido
##   CajaListas              filas Piel, Colores, Patrón, Cara, Detalle y Estela (se crean aquí);
##                           cada lista es un Selector (interfaz/selector.gd) con flechas
##
## Escribe lo elegido en Juego, lo guarda y avisa:
##   cambio              cambió el estado de Juego; Taller refresca toda la pantalla
##   color_cambiado      el jugador arrastra un selector de color; basta con redibujar
##                       la vista (refrescar todo movería el selector mientras se usa)
##   nombre_confirmado   pulsó Enter en el nombre; Taller pasa el foco a "¡A rodar!"

signal cambio
signal color_cambiado
signal nombre_confirmado


@onready var linea_nombre: LineEdit = %LineaNombre
@onready var fila_tamanos: HBoxContainer = %FilaTamanos
@onready var lbl_desc_tamano: Label = %DescTamano
@onready var caja_listas: VBoxContainer = %CajaListas

var botones_tamano: Array[Button] = []
var listas := {}                        # propiedad de Juego -> Selector
var _colores: Array[ColorPickerButton] = []  # [cuerpo, rayas]


func _ready() -> void:
	linea_nombre.text = ComunTaller.nombre_melon()
	_crear_tamanos()
	_agregar_lista("Piel", "piel", Config.pieles)
	_agregar_colores()
	_agregar_lista("Patrón", "patron", Config.patrones)
	_agregar_lista("Cara", "cara", Config.caras)
	_agregar_lista("Detalle", "detalle", Config.detalles)
	_agregar_lista("Estela", "estela", Config.estelas)


## Pone los controles al día con Juego (tamaño, nombre, listas y colores).
func refrescar() -> void:
	for i in botones_tamano.size():
		var b := botones_tamano[i]
		b.text = Config.tamanos[i]["nombre"]
		b.theme_type_variation = Estilos.SELECCION_MEDIANA if i == Juego.tamano else Estilos.BOTON_MEDIANO
	lbl_desc_tamano.text = Config.tamanos[Juego.tamano]["desc"]
	if not linea_nombre.has_focus():
		linea_nombre.text = ComunTaller.nombre_melon()
	for prop in listas.keys():
		(listas[prop] as Selector).elegir(int(Juego.get(prop)))
	if _colores.size() == 2:
		_colores[0].color = Juego.color_cuerpo()
		_colores[1].color = Juego.color_rayas()


# --- Construcción de los controles -------------------------------------------

func _crear_tamanos() -> void:
	for i in Config.tamanos.size():
		var b := ComunTaller.boton(Config.tamanos[i]["nombre"], Estilos.BOTON_MEDIANO)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 48
		b.pressed.connect(_elegir_tamano.bind(i))
		fila_tamanos.add_child(b)
		botones_tamano.append(b)


## Fila con un Selector para elegir un índice de la lista datos (de Config)
## y guardarlo en Juego.prop. Si la lista está vacía no se crea la fila.
func _agregar_lista(titulo: String, prop: String, datos: Variant) -> void:
	if not (datos is Array) or (datos as Array).is_empty():
		return
	var fila := ComunTaller.fila_con_titulo(titulo)
	caja_listas.add_child(fila)
	var selector := Selector.new()
	var nombres := PackedStringArray()
	for d in (datos as Array):
		nombres.append(str((d as Dictionary).get("nombre", "?")))
	selector.opciones = nombres
	selector.elegir(int(Juego.get(prop)))
	selector.cambiado.connect(_elegir_lista.bind(prop))
	fila.add_child(selector)
	listas[prop] = selector


## Fila "Colores": dos selectores (cuerpo y rayas) que cambian los colores de la
## piel elegida, y el botón "Original" para volver a los de la piel.
func _agregar_colores() -> void:
	var fila := ComunTaller.fila_con_titulo("Colores")
	caja_listas.add_child(fila)
	for prop in ["cuerpo_propio", "rayas_propio"]:
		var picker := ColorPickerButton.new()
		picker.edit_alpha = false
		picker.custom_minimum_size = Vector2(64, 42)
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.tooltip_text = "Color del cuerpo" if prop == "cuerpo_propio" else "Color de las rayas y el borde"
		picker.color_changed.connect(_elegir_color.bind(prop))
		picker.popup_closed.connect(Juego.guardar)  # se guarda al cerrar, no en cada arrastre
		fila.add_child(picker)
		_colores.append(picker)
	var original := ComunTaller.boton("Original", Estilos.BOTON_SECUNDARIO)
	original.tooltip_text = "Usar los colores de la piel"
	original.pressed.connect(_colores_de_piel)
	fila.add_child(original)


# --- Respuestas a los controles ----------------------------------------------

func _cambiar_nombre(nuevo: String) -> void:
	Juego.nombre_melon = nuevo.strip_edges().left(24)
	Juego.guardar()
	cambio.emit()


func _nombre_listo(_texto: String) -> void:
	Juego.guardar()
	nombre_confirmado.emit()


func _elegir_tamano(i: int) -> void:
	Juego.tamano = i
	Juego.guardar()
	cambio.emit()


func _elegir_lista(idx: int, prop: String) -> void:
	Juego.set(prop, idx)
	if prop == "piel":
		# Una piel nueva trae sus propios colores.
		Juego.cuerpo_propio = ""
		Juego.rayas_propio = ""
	Juego.guardar()
	cambio.emit()


func _elegir_color(c: Color, prop: String) -> void:
	Juego.set(prop, c.to_html(false))
	color_cambiado.emit()


func _colores_de_piel() -> void:
	Juego.cuerpo_propio = ""
	Juego.rayas_propio = ""
	Juego.guardar()
	cambio.emit()
