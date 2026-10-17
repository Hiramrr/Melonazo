class_name PestanaMejoras
extends ScrollContainer
## Pestaña "Tiendita" del taller: comprar niveles de fuerza, resistencia y rebotes,
## y Salsas Valentina para revivir en la carrera.
##
## Nodo: Taller/.../Pestanas/Mejoras (pantallas/taller/taller.tscn).
##   ListaMejoras            una tarjeta por Config.orden_mejoras y una para la
##                           Salsa Valentina (se crean aquí): ícono, nombre,
##                           niveles o existencias (Pips), efecto y botón de compra
##
## Las compras las hacen Juego.comprar_mejora() y Juego.comprar_valentina(), que cobran y guardan.
## Emite cambio tras comprar; Taller refresca la pantalla (y llama refrescar()).

signal cambio

const ICONOS := {"fuerza": Iconos.IMPULSO, "resistencia": Iconos.CORAZON, "rebotes": Iconos.ALTURA}
const CUADRO_NIVEL := preload("res://recursos/iconos/perilla.png")
const VALENTINA := "valentina"           # clave de la tarjeta de la salsa en filas

@onready var lista: VBoxContainer = %ListaMejoras

var filas := {}                         # id -> {nombre, niveles, texto, boton}


func _ready() -> void:
	for id in Config.orden_mejoras:
		_crear_tarjeta(id, ICONOS.get(id, Iconos.PODER), CUADRO_NIVEL)
	_crear_tarjeta(VALENTINA, Poder.TEXTURAS[VALENTINA], Poder.TEXTURAS[VALENTINA])


func _crear_tarjeta(id: String, icono: Texture2D, cuadro: Texture2D) -> void:
	var tarjeta := PanelContainer.new()
	tarjeta.theme_type_variation = &"Tarjeta"
	lista.add_child(tarjeta)
	var fila := HBoxContainer.new()
	fila.theme_type_variation = &"FilaAmplia"
	tarjeta.add_child(fila)
	fila.add_child(Iconos.imagen(icono, 52.0))
	var columna := VBoxContainer.new()
	columna.theme_type_variation = &"ColumnaCompacta"
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(columna)
	var nombre := ComunTaller.titulo_seccion("", &"SubtituloMediano")
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(nombre)
	var niveles := Pips.new()
	niveles.icono = cuadro
	niveles.lado = 20.0
	niveles.theme_type_variation = &"NivelesMejora"
	columna.add_child(niveles)
	var texto := ComunTaller.etiqueta("", &"Nota")
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(texto)
	var b := ComunTaller.boton("", &"BotonMediano")
	b.custom_minimum_size = Vector2(150, 56)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.icon = Iconos.APLAUSO
	b.expand_icon = true
	b.pressed.connect(_comprar.bind(id))
	fila.add_child(b)
	filas[id] = {"nombre": nombre, "niveles": niveles, "texto": texto, "boton": b}


## Pone al día niveles, efectos y precios con Juego.
func refrescar() -> void:
	for id in Config.orden_mejoras:
		var m: Dictionary = Config.mejoras[id]
		var f: Dictionary = filas[id]
		f["nombre"].text = m["nombre"]
		f["niveles"].total = int(m["max"])
		f["niveles"].llenos = int(Juego.niveles[id])
		var efecto := _efecto(id)
		f["texto"].text = "Nivel %d de %d" % [Juego.niveles[id], m["max"]] + (" · " + efecto if efecto != "" else "")
		var b: Button = f["boton"]
		if Juego.mejora_al_max(id):
			b.text = "¡Máximo!"
			b.icon = null
			b.disabled = true
			b.theme_type_variation = &"BotonMediano"
		else:
			b.text = str(Juego.costo_mejora(id))
			b.icon = Iconos.APLAUSO
			b.disabled = Juego.aplausos < Juego.costo_mejora(id)
			b.theme_type_variation = &"BotonMediano" if b.disabled else &"ComprarMediano"
	_refrescar_valentina()


## Existencias y precio de la Salsa Valentina.
func _refrescar_valentina() -> void:
	var f: Dictionary = filas[VALENTINA]
	f["nombre"].text = Config.poderes_tienda[VALENTINA]["nombre"]
	f["niveles"].total = Config.valentinas_max
	f["niveles"].llenos = Juego.valentinas
	f["texto"].text = "Tienes %d de %d · %s" % [Juego.valentinas, Config.valentinas_max, Config.poderes_tienda[VALENTINA]["descripcion"]]
	var b: Button = f["boton"]
	var lleno := Juego.valentinas >= Config.valentinas_max
	b.text = "¡Lleno!" if lleno else str(Config.valentina_costo)
	b.icon = null if lleno else Iconos.APLAUSO
	b.disabled = lleno or Juego.aplausos < Config.valentina_costo
	b.theme_type_variation = &"BotonMediano" if b.disabled else &"ComprarMediano"


## Qué da el nivel actual de la mejora, en palabras ("" si no hay descripción).
func _efecto(id: String) -> String:
	match id:
		"fuerza":
			return "salida x%.2f" % Juego.mult_fuerza()
		"resistencia":
			return "%d golpes con este tamaño" % Juego.resistencia_max()
		"rebotes":
			return "%d por intento" % Juego.rebotes_max()
	return ""


func _comprar(id: String) -> void:
	if id == VALENTINA:
		Juego.comprar_valentina()
	else:
		Juego.comprar_mejora(id)
	Animacion.rebotar(filas[id]["niveles"], 1.25)
	cambio.emit()
