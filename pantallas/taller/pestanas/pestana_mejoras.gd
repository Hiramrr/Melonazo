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
var texto_reto: Label


func _ready() -> void:
<<<<<<< HEAD
	texto_reto = ComunTaller.etiqueta("", &"TextoBreve")
=======
	texto_reto = ComunTaller.etiqueta("", Estilos.TEXTO_BREVE)
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
	texto_reto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(texto_reto)
	for id in Config.orden_mejoras:
		_crear_tarjeta(id, ICONOS.get(id, Iconos.PODER), CUADRO_NIVEL)
	_crear_tarjeta(VALENTINA, Poder.TEXTURAS[VALENTINA], Poder.TEXTURAS[VALENTINA])

<<<<<<< HEAD

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
=======
func _crear_tarjeta(id: String, icono: Texture2D, cuadro: Texture2D) -> void:
	var tarjeta := Tarjeta.new()
	lista.add_child(tarjeta)
	var fila := HBoxContainer.new()
	fila.theme_type_variation = Estilos.FILA_AMPLIA
	tarjeta.cuerpo.add_child(fila)
	fila.add_child(Iconos.imagen(icono, 52.0))
	var columna := VBoxContainer.new()
	columna.theme_type_variation = Estilos.COLUMNA_COMPACTA
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(columna)
	var nombre := ComunTaller.titulo_seccion("", Estilos.SUBTITULO_MEDIANO)
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(nombre)
	var niveles := Pips.new()
	niveles.icono = cuadro
	niveles.lado = 20.0
<<<<<<< HEAD
	niveles.theme_type_variation = &"NivelesMejora"
	columna.add_child(niveles)
	var texto := ComunTaller.etiqueta("", &"Nota")
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(texto)
	var b := ComunTaller.boton("", &"BotonMediano")
=======
	niveles.theme_type_variation = Estilos.NIVELES_MEJORA
	columna.add_child(niveles)
	var texto := ComunTaller.etiqueta("", Estilos.NOTA)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(texto)
	var b := ComunTaller.boton("", Estilos.BOTON_MEDIANO)
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
	b.custom_minimum_size = Vector2(150, 56)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.icon = Iconos.APLAUSO
	b.expand_icon = true
	b.pressed.connect(_comprar.bind(id))
	fila.add_child(b)
	filas[id] = {"nombre": nombre, "niveles": niveles, "texto": texto, "boton": b}


## Pone al día niveles, efectos y precios con Juego.
func refrescar() -> void:
	var reto := Juego.reto_actual()
	texto_reto.text = "Todos los retos completados" if reto.is_empty() else "Reto %d de %d · %s en un intento. Premio: %d aplausos." % [Juego.retos_completados + 1, Config.retos.size(), reto["texto"], reto["premio"]]
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
<<<<<<< HEAD
			b.theme_type_variation = &"BotonMediano"
=======
			b.theme_type_variation = Estilos.BOTON_MEDIANO
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
		else:
			if Juego.aplausos < Juego.costo_mejora(id):
				f["texto"].text += "\nFaltan %d aplausos" % (Juego.costo_mejora(id) - Juego.aplausos)
			b.text = str(Juego.costo_mejora(id))
			b.icon = Iconos.APLAUSO
			b.disabled = Juego.aplausos < Juego.costo_mejora(id)
<<<<<<< HEAD
			b.theme_type_variation = &"BotonMediano" if b.disabled else &"ComprarMediano"
=======
			b.theme_type_variation = Estilos.BOTON_MEDIANO if b.disabled else Estilos.COMPRAR_MEDIANO
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)
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
<<<<<<< HEAD
	b.theme_type_variation = &"BotonMediano" if b.disabled else &"ComprarMediano"
=======
	b.theme_type_variation = Estilos.BOTON_MEDIANO if b.disabled else Estilos.COMPRAR_MEDIANO
>>>>>>> 744a767 (Refactorización completa de interfaces, UI y nombres)


## Qué da el nivel actual de la mejora, en palabras ("" si no hay descripción).
func _efecto(id: String) -> String:
	if Juego.mejora_al_max(id):
		match id:
			"fuerza":
				return "Salida x%.2f · Ritmo %d m/s" % [Juego.mult_fuerza(), Juego.velocidad_crucero() / Config.px_por_metro]
			"resistencia":
				return "%d golpes con este tamaño" % Juego.resistencia_max()
			"rebotes":
				return "%d impulsos por intento" % Juego.rebotes_max()
	match id:
		"fuerza":
			return "Salida x%.2f → x%.2f\nRitmo %d → %d m/s" % [Juego.mult_fuerza(), Juego.mult_fuerza() + Config.fuerza_por_nivel, Juego.velocidad_crucero() / Config.px_por_metro, (Juego.velocidad_crucero() + Config.crucero_por_nivel) / Config.px_por_metro]
		"resistencia":
			return "%d → %d golpes con este tamaño" % [Juego.resistencia_max(), Juego.resistencia_max() + Config.resistencia_por_nivel]
		"rebotes":
			return "%d → %d impulsos por intento" % [Juego.rebotes_max(), Juego.rebotes_max() + Config.rebotes_por_nivel]
	return ""


func _comprar(id: String) -> void:
	if id == VALENTINA:
		Juego.comprar_valentina()
	else:
		Juego.comprar_mejora(id)
	Animacion.rebotar(filas[id]["niveles"], 1.25)
	cambio.emit()
