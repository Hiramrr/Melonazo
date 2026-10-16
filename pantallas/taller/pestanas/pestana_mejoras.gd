class_name PestanaMejoras
extends ScrollContainer
## Pestaña "Mejoras" del taller: comprar niveles de fuerza, resistencia y rebotes.
##
## Nodo: Taller/.../Pestanas/Mejoras (pantallas/taller/taller.tscn).
##   ListaMejoras            por cada Config.orden_mejoras (se crean aquí): un texto
##                           con nivel y efecto, y el botón de compra
##
## Las compras las hace Juego.comprar_mejora(), que cobra y guarda.
## Emite cambio tras comprar; Taller refresca la pantalla (y llama refrescar()).

signal cambio


@onready var lista: VBoxContainer = %ListaMejoras

var filas := {}                         # id -> {texto, boton}


func _ready() -> void:
	for id in Config.orden_mejoras:
		var caja := VBoxContainer.new()
		caja.add_theme_constant_override("separation", 4)
		lista.add_child(caja)
		var texto := ComunTaller.etiqueta("")
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caja.add_child(texto)
		var b := ComunTaller.boton("")
		b.pressed.connect(_comprar.bind(id))
		caja.add_child(b)
		filas[id] = {"texto": texto, "boton": b}


## Pone al día niveles, efectos y precios con Juego.
func refrescar() -> void:
	for id in Config.orden_mejoras:
		var m: Dictionary = Config.mejoras[id]
		var txt := "%s, nivel %d de %d" % [m["nombre"], Juego.niveles[id], m["max"]]
		var efecto := _efecto(id)
		if efecto != "":
			txt += " · %s" % efecto
		filas[id]["texto"].text = txt
		var b: Button = filas[id]["boton"]
		if Juego.mejora_al_max(id):
			b.text = "Al máximo"
			b.disabled = true
		else:
			b.text = "Comprar · %d aplausos" % Juego.costo_mejora(id)
			b.disabled = Juego.aplausos < Juego.costo_mejora(id)


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
	cambio.emit()
