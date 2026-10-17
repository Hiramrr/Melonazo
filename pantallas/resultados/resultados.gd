extends Control
## Pantalla de Resultados: resumen de la carrera que acaba de terminar.
##
## Escena: pantallas/resultados/resultados.tscn
##   Fondo                         FondoJuego cálido (rayos y papel picado)
##   Margen/Columnas
##     Postal                      foto del lugar alcanzado (postal_resultados.gd)
##     Derecha/Cinta               listón con %Titulo
##     Derecha/Tarjeta/Caja        %Nombre, %Distancia, %Record, %Carisma, %ListaAplausos,
##                                 %Total, %Ahora y el botón %BtnVolver
##
## Quién llega aquí: Recorrido, al terminar, llama Juego.registrar_intento() (que deja el
## desglose en Juego.ultimo) y cambia a esta escena. La estructura estable vive en la
## escena; este script rellena textos, genera el desglose de aplausos y lo anima:
## la distancia cuenta hacia arriba, las filas entran una por una, el récord cae como
## sello y al final cuenta el total.
## BtnVolver (señal pressed) o la acción "confirmar" llevan de vuelta al Taller.

const TALLER := "res://pantallas/taller/taller.tscn"
const PASO_FILA := 0.12                # segundos entre filas del desglose

@onready var lbl_titulo: Label = %Titulo
@onready var lbl_nombre: Label = %Nombre
@onready var lbl_distancia: Label = %Distancia
@onready var lbl_record: Label = %Record
@onready var lbl_carisma: Label = %Carisma
@onready var lista_aplausos: VBoxContainer = %ListaAplausos
@onready var lbl_total: Label = %Total
@onready var lbl_ahora: Label = %Ahora
@onready var btn_volver: Button = %BtnVolver

var _filas_animadas: Array[Control] = []


func _ready() -> void:
	var r: Dictionary = Juego.ultimo
	Musica.tocar(Musica.MENU if bool(r.get("llegada", false)) else Musica.DERROTA)
	lbl_titulo.text = "¡Se rompió el melón!" if bool(r.get("roto", false)) else "¡Qué buena rodada!"
	if bool(r.get("llegada", false)):
		lbl_titulo.text = "¡Llegaste al CUCosta!"
	lbl_nombre.text = Juego.nombre_melon
	var metros := int(r.get("distancia", 0.0))
	lbl_distancia.text = "%d m" % metros
	var record_nuevo := bool(r.get("record_nuevo", false))
	if record_nuevo:
		_estilo_sello(lbl_record)
		lbl_record.text = "¡NUEVO\nRÉCORD!"
	else:
		lbl_record.text = "Récord\n%d m" % int(Juego.record_m)
	lbl_carisma.text = "Altura máxima: %d m · Carisma: %d" % [int(r.get("altura", 0)), int(r.get("carisma", 0))]
	if bool(r.get("llegada", false)):
		%Destino.text = "%s\n%s" % [Config.nombre_meta, Config.institucion_meta]
	else:
		%Destino.text = "%s\nFaltan %d m para llegar al CUCosta" % [$Margen/Columnas/Postal.lugar_nombre, ceili(maxf(0.0, Config.meta_m - metros))]
		for postal in Config.postales:
			if float(postal["metros"]) > metros:
				%Destino.text = "Siguiente: %s\nTe faltaron %d m para alcanzarlo" % [postal["nombre"], ceili(float(postal["metros"]) - metros)]
				break
	_generar_desglose(r)
	var total := int(r.get("total", 0))
	lbl_total.text = "+%d" % total
	lbl_ahora.text = "Saldo en el taller: %d aplausos" % Juego.aplausos
	btn_volver.grab_focus()
	_animar(metros, total, record_nuevo)


## Orden de la función: listón, distancia que cuenta, récord, filas, total y botón.
func _animar(metros: int, total: int, record_nuevo: bool) -> void:
	Animacion.aparecer(%Cinta, 0.0, 0.3)
	Animacion.aparecer(%Tarjeta, 0.05, 0.9)
	Animacion.contar(lbl_distancia, metros, "%d m", 0.9, 0.2)
	if record_nuevo:
		Animacion.sellar(lbl_record, 1.1)
	else:
		Animacion.aparecer(lbl_record, 1.0)
	var retraso := 0.6
	for fila in _filas_animadas:
		Animacion.aparecer(fila, retraso, 0.7)
		retraso += PASO_FILA
	Animacion.aparecer(%FilaTotal, retraso, 0.4)
	Animacion.contar(lbl_total, total, "+%d", 5.0, retraso + 0.1)
	if total > 0:
		var sonido := create_tween()
		sonido.tween_interval(retraso + 0.1)
		sonido.tween_callback(func() -> void: Sonidos.monedas(self, 5.0))
	Animacion.aparecer(btn_volver, retraso + 0.5, 0.6).finished.connect(Animacion.latir.bind(btn_volver))


## Etiqueta amarilla, inclinada y con borde: el sello de "¡Nuevo récord!".
func _estilo_sello(l: Label) -> void:
	l.theme_type_variation = &"SelloRecord"
	l.rotation_degrees = -8.0


# --- Desglose de aplausos (hijos de %ListaAplausos) ---------------------------

func _generar_desglose(r: Dictionary) -> void:
	_fila("Por distancia", int(r.get("por_distancia", 0)))
	if int(r.get("por_altura", 0)) > 0:
		_fila("Por altura máxima", int(r["por_altura"]))
	_fila("Por carisma", int(r.get("por_carisma", 0)))
	_fila("Recogidos en el camino", int(r.get("por_recolectados", 0)))
	if int(r.get("por_visitas", 0)) > 0:
		_fila("Por lugares nuevos", int(r.get("por_visitas", 0)))
	var reto: Dictionary = r.get("reto", {})
	if not reto.is_empty():
		if int(r.get("por_reto", 0)) > 0:
			_fila("Por reto cumplido", int(r["por_reto"]))
		_linea("%s · %d/%d" % [reto["texto"], r.get("avance_reto", 0), reto["meta"]])
		var siguiente := Juego.reto_actual()
		if int(r.get("por_reto", 0)) > 0 and not siguiente.is_empty():
			_linea("Siguiente reto: %s" % siguiente["texto"])
	var nuevas: Array = r.get("visitas_nuevas", [])
	if not nuevas.is_empty():
		_linea("%d lugares nuevos en el pasaporte" % nuevas.size())
	if int(r.get("poderes", 0)) > 0:
		_linea("Poderes encontrados: %d" % int(r.get("poderes", 0)))
	if int(r.get("valentinas", 0)) > 0:
		_linea("Salsas Valentina usadas: %d" % int(r["valentinas"]))


## Fila "concepto ........ (moneda) cantidad".
func _fila(concepto: String, cantidad: int) -> void:
	var fila := HBoxContainer.new()
	fila.theme_type_variation = &"FilaIconos"
	lista_aplausos.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = concepto
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(etiqueta)
	fila.add_child(Iconos.imagen(Iconos.APLAUSO, 22.0))
	var valor := Label.new()
	valor.theme_type_variation = &"ValorResultado"
	valor.text = str(cantidad)
	valor.custom_minimum_size.x = 56
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(valor)
	_filas_animadas.append(fila)


## Nota de texto libre en letra suave.
func _linea(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = &"Nota"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista_aplausos.add_child(l)
	_filas_animadas.append(l)
	return l


# --- Salida ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirmar"):
		# Si un botón tiene el foco, él mismo atiende la tecla.
		if get_viewport().gui_get_focus_owner() is BaseButton:
			return
		_volver()


## Vuelve al Taller. Conectada a BtnVolver.pressed en la escena.
func _volver() -> void:
	Animacion.cambiar_escena(TALLER)
