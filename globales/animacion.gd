extends CanvasLayer
## Autoload "Animacion": movimiento de la interfaz.
##
##   - Cambio de pantalla con cortina circular: Animacion.cambiar_escena(ruta).
##     La escena nueva se carga al instante y la cortina se abre encima.
##   - Todos los botones crecen un poco con el ratón y se aplastan al pulsarlos.
##     Se conectan solos al entrar al árbol (señal node_added). Los que están dentro
##     de un contenedor que recorta (las listas con scroll del taller) no crecen,
##     porque el borde agrandado quedaría cortado; solo se aplastan.
##   - Atajos para animar nodos: aparecer(), rebotar(), latir(), sellar() y contar().
##   - Al iniciar cambia ThemeDB.fallback_font por la letra gruesa del tema, así
##     los letreros que el mundo dibuja con draw_string() usan la misma fuente.
##
## Es un CanvasLayer en la capa 100 con process_mode ALWAYS, así la cortina queda
## por encima de todo y funciona aunque el juego esté en pausa.

const DURACION_CORTINA := 0.55
const ESCALA_RATON := 1.05
const ESCALA_PULSADO := 0.94
var _cortina: TextureRect


func _ready() -> void:
	var tema := ThemeDB.get_project_theme()
	if tema:
		ThemeDB.fallback_font = tema.get_font("font", "Titulo")
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cortina = TextureRect.new()
	_cortina.texture = Sprites.textura("transiciones/cortina_0")
	_cortina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cortina.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_cortina.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cortina.visible = false
	add_child(_cortina)
	get_tree().node_added.connect(_al_agregar_nodo)


# --- Pantallas ---------------------------------------------------------------

## Cambia de escena y abre la cortina sobre la nueva.
func cambiar_escena(ruta: String) -> void:
	get_tree().change_scene_to_file(ruta)
	_cortina.visible = true
	_cortina.texture = Sprites.textura("transiciones/cortina_0")
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		_cortina.texture = Sprites.textura("transiciones/cortina_%d" % clampi(int(v * 16), 0, 15)),
		0.0, 1.0, DURACION_CORTINA).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_cortina.hide)


# --- Botones -----------------------------------------------------------------

func _al_agregar_nodo(nodo: Node) -> void:
	if not nodo is BaseButton or nodo is LinkButton:
		return
	var b := nodo as BaseButton
	b.resized.connect(_centrar_pivote.bind(b))
	b.mouse_entered.connect(_escalar.bind(b, ESCALA_RATON))
	b.mouse_exited.connect(_escalar.bind(b, 1.0))
	b.button_down.connect(_escalar.bind(b, ESCALA_PULSADO))
	b.button_up.connect(func() -> void: _escalar(b, ESCALA_RATON if b.is_hovered() else 1.0))


func _centrar_pivote(c: Control) -> void:
	c.pivot_offset = c.size * 0.5


func _escalar(b: BaseButton, escala: float) -> void:
	if b.has_meta("latido"):
		return
	if escala > 1.0 and (b.disabled or _dentro_de_recorte(b)):
		escala = 1.0
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2.ONE * escala, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## true si algún contenedor de c recorta lo que se sale (clip_contents o ScrollContainer).
func _dentro_de_recorte(c: Control) -> bool:
	var padre := c.get_parent()
	while padre is Control:
		if (padre as Control).clip_contents or padre is ScrollContainer:
			return true
		padre = padre.get_parent()
	return false


# --- Atajos ------------------------------------------------------------------

## Entra desde pequeño y transparente, con un pequeño rebote, tras retraso segundos.
func aparecer(c: Control, retraso := 0.0, desde := 0.6) -> Tween:
	c.modulate.a = 0.0
	c.scale = Vector2.ONE * desde
	var t := c.create_tween().set_parallel()
	t.tween_callback(_centrar_pivote.bind(c)).set_delay(retraso)
	t.tween_property(c, "modulate:a", 1.0, 0.18).set_delay(retraso)
	t.tween_property(c, "scale", Vector2.ONE, 0.35).set_delay(retraso).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t


## Un salto corto de escala, para llamar la atención sobre un cambio.
func rebotar(c: Control, fuerza := 1.15) -> void:
	_centrar_pivote(c)
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2.ONE * fuerza, 0.07)
	t.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Late sin parar (el botón principal de cada pantalla). Desactiva el efecto del ratón.
func latir(c: Control, fuerza := 1.05, periodo := 0.9) -> void:
	c.set_meta("latido", true)
	var centrar := _centrar_pivote.bind(c)
	if not c.resized.is_connected(centrar):
		c.resized.connect(centrar)
	_centrar_pivote(c)
	var t := c.create_tween().set_loops()
	t.tween_property(c, "scale", Vector2.ONE * fuerza, periodo * 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(c, "scale", Vector2.ONE, periodo * 0.5).set_trans(Tween.TRANS_SINE)


## Cae desde grande como un sello de goma.
func sellar(c: Control, retraso := 0.0) -> void:
	c.modulate.a = 0.0
	var t := c.create_tween().set_parallel()
	t.tween_callback(func() -> void:
		_centrar_pivote(c)
		c.scale = Vector2.ONE * 2.4).set_delay(retraso)
	t.tween_property(c, "modulate:a", 1.0, 0.12).set_delay(retraso)
	t.tween_property(c, "scale", Vector2.ONE, 0.3).set_delay(retraso).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Cuenta de desde a hasta en la etiqueta, con formato ("%d m"). Termina en el valor exacto.
func contar(l: Label, hasta: int, formato := "%d", duracion := 0.8, retraso := 0.0, desde := 0) -> Tween:
	l.text = formato % desde
	var t := l.create_tween()
	t.tween_interval(retraso)
	t.tween_method(func(v: float) -> void: l.text = formato % int(v), float(desde), float(hasta), duracion) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: l.text = formato % hasta)
	return t
