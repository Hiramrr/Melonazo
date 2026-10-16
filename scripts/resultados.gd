extends Control
## Resultados del intento. La estructura estable vive en Resultados.tscn.
## Este script solo rellena textos y genera el desglose de aplausos.

const VERDE := Color(0.16, 0.38, 0.22)

@onready var lbl_titulo: Label = %Titulo
@onready var lbl_nombre: Label = %Nombre
@onready var lbl_distancia: Label = %Distancia
@onready var lbl_record: Label = %Record
@onready var lbl_carisma: Label = %Carisma
@onready var lista_aplausos: VBoxContainer = %ListaAplausos
@onready var lbl_total: Label = %Total
@onready var lbl_ahora: Label = %Ahora
@onready var btn_volver: Button = %BtnVolver


func _ready() -> void:
	var r: Dictionary = Juego.ultimo
	lbl_titulo.text = "¡Se rompió el melón!" if bool(r.get("roto", false)) else "¡Qué buena rodada!"
	lbl_nombre.text = _nombre_melon()
	lbl_distancia.text = "%d m" % int(r.get("distancia", 0.0))
	if bool(r.get("record_nuevo", false)):
		lbl_record.text = "¡Nuevo récord!"
		lbl_record.add_theme_color_override("font_color", VERDE)
		lbl_record.add_theme_font_size_override("font_size", 26)
	else:
		lbl_record.text = "Récord: %d m" % int(Juego.record_m)
	lbl_carisma.text = "Carisma conservado: %d" % int(r.get("carisma", 0))
	_generar_desglose(r)
	lbl_total.text = "+%d aplausos" % int(r.get("total", 0))
	lbl_ahora.text = "Saldo en el taller: %d aplausos" % Juego.aplausos
	btn_volver.grab_focus()


func _nombre_melon() -> String:
	return Juego.nombre_melon


func _linea(texto: String, tam := 18) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if tam != 16:
		l.add_theme_font_size_override("font_size", tam)
	lista_aplausos.add_child(l)
	return l


func _generar_desglose(r: Dictionary) -> void:
	_fila("Por distancia", int(r.get("por_distancia", 0)))
	_fila("Por carisma", int(r.get("por_carisma", 0)))
	_fila("Recogidos en el camino", int(r.get("por_recolectados", 0)))
	if int(r.get("por_visitas", 0)) > 0:
		_fila("Por lugares nuevos", int(r.get("por_visitas", 0)))
	var nuevas: Array = r.get("visitas_nuevas", [])
	if not nuevas.is_empty():
		_linea("Postales nuevas: %s" % ", ".join(PackedStringArray(nuevas)), 15)
	if int(r.get("poderes", 0)) > 0:
		_linea("Poderes encontrados: %d" % int(r.get("poderes", 0)), 15)


func _fila(concepto: String, cantidad: int) -> void:
	var fila := HBoxContainer.new()
	lista_aplausos.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = concepto
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(etiqueta)
	var valor := Label.new()
	valor.text = str(cantidad)
	fila.add_child(valor)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirmar"):
		if get_viewport().gui_get_focus_owner() is BaseButton:
			return
		_volver()


func _volver() -> void:
	get_tree().change_scene_to_file("res://escenas/Taller.tscn")
