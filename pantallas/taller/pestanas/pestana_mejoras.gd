class_name PestanaMejoras
extends ScrollContainer
## Pestaña "Mejoras" del taller: comprar niveles de fuerza, resistencia y rebotes.
##
## Nodo: Taller/.../Pestanas/Mejoras (pantallas/taller/taller.tscn).
##   ListaMejoras            una tarjeta por Config.orden_mejoras (se crean aquí):
##                           ícono, nombre, niveles (Pips), efecto y botón de compra
##
## Las compras las hace Juego.comprar_mejora(), que cobra y guarda.
## Emite cambio tras comprar; Taller refresca la pantalla (y llama refrescar()).

signal cambio

const ICONOS := {"fuerza": Iconos.IMPULSO, "resistencia": Iconos.CORAZON, "rebotes": Iconos.ALTURA}
const CUADRO_NIVEL := preload("res://recursos/iconos/perilla.png")

@onready var lista: VBoxContainer = %ListaMejoras

var filas := {}                         # id -> {nombre, niveles, texto, boton}


func _ready() -> void:
	for id in Config.orden_mejoras:
		var tarjeta := PanelContainer.new()
		tarjeta.theme_type_variation = &"Tarjeta"
		lista.add_child(tarjeta)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 14)
		tarjeta.add_child(fila)
		fila.add_child(Iconos.imagen(ICONOS.get(id, Iconos.PODER), 52.0))
		var columna := VBoxContainer.new()
		columna.add_theme_constant_override("separation", 4)
		columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(columna)
		var nombre := ComunTaller.titulo_seccion("", 18)
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		columna.add_child(nombre)
		var niveles := Pips.new()
		niveles.icono = CUADRO_NIVEL
		niveles.lado = 20.0
		niveles.apagado = Color(0.2, 0.25, 0.24, 0.3)
		columna.add_child(niveles)
		var texto := ComunTaller.etiqueta("", 14, true)
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		columna.add_child(texto)
		var b := ComunTaller.boton("", 18)
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
			b.theme_type_variation = &""
		else:
			b.text = str(Juego.costo_mejora(id))
			b.icon = Iconos.APLAUSO
			b.disabled = Juego.aplausos < Juego.costo_mejora(id)
			b.theme_type_variation = &"" if b.disabled else &"Comprar"


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
	Juego.comprar_mejora(id)
	Animacion.rebotar(filas[id]["niveles"], 1.25)
	cambio.emit()
