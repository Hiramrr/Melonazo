class_name PestanaPasaporte
extends ScrollContainer
## Pestaña "Pasaporte" del taller: postales visitadas y poderes de la ruta.
##
## Nodo: Taller/.../Pestanas/Pasaporte (pantallas/taller/taller.tscn).
##   ListaPasaporte          todo el contenido; se crea aquí con refrescar():
##                           resumen, una tarjeta por postal y una por poder
##
## Solo lee Juego (visitados, intentos, récord) y Config (postales, poderes), así
## que no emite señales. Nada del taller cambia esos datos: el contenido se arma
## una vez en _ready() y Taller no necesita refrescarlo en cada cambio.

const ARTE := preload("res://recursos/arte_xalapa.tres")
const VERDE := Color("3f8f4a")
const ROJO := Color("c8402f")
const LADO_PODER := 48.0

@onready var lista: VBoxContainer = %ListaPasaporte


func _ready() -> void:
	refrescar()


## Vuelve a armar el pasaporte desde Juego y Config.
func refrescar() -> void:
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()
	var visitados: Array = Juego.visitados
	_agregar(ComunTaller.titulo_seccion("Pasaporte de Xalapa", 24))
	var resumen := HBoxContainer.new()
	resumen.add_theme_constant_override("separation", 10)
	resumen.add_child(Ficha.crear(Iconos.LUGAR, "%d de %d lugares" % [visitados.size(), Config.postales.size()], false, 16))
	resumen.add_child(Ficha.crear(Iconos.APLAUSO, "+%d por lugar nuevo" % Config.bonus_postal, false, 16))
	_agregar(resumen)
	_agregar(ComunTaller.etiqueta("Intentos: %d. Ruta y distancias de fantasía." % Juego.intentos, 14, true))
	var hay_postales := _agregar_postales(visitados)
	var hay_poderes := _agregar_poderes()
	if not hay_postales and not hay_poderes:
		_agregar(ComunTaller.etiqueta("Rueda lejos y el pasaporte se llena solo.", 16, true))


# --- Secciones ---------------------------------------------------------------

## Una tarjeta por postal: nombre, sello de visitado (o cuántos metros faltan),
## nota y foto si la hay. Devuelve false si Config no tiene postales.
func _agregar_postales(visitados: Array) -> bool:
	var postales: Variant = Config.postales
	if not (postales is Array) or (postales as Array).is_empty():
		return false
	_agregar(ComunTaller.titulo_seccion("Postales"))
	var rejilla := _rejilla()
	var record_m := int(Juego.record_m)
	for p in (postales as Array):
		var pd := p as Dictionary
		var pid := str(pd.get("id", ""))
		var metros := int(pd.get("metros", 0))
		var visitado := pid != "" and pid in visitados
		var caja := _tarjeta(rejilla)
		var cabeza := HBoxContainer.new()
		cabeza.add_theme_constant_override("separation", 6)
		caja.add_child(cabeza)
		var pin := Iconos.imagen(Iconos.LUGAR if visitado else Iconos.CANDADO, 26.0)
		cabeza.add_child(pin)
		var nombre := ComunTaller.titulo_seccion(str(pd.get("nombre", "?")), 16)
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cabeza.add_child(nombre)
		var estado := ComunTaller.titulo_seccion("", 14)
		if visitado:
			estado.text = "¡VISITADO!"
			estado.add_theme_color_override("font_color", VERDE)
		else:
			estado.text = "A %d m · faltan %d m" % [metros, maxi(0, metros - record_m)]
			estado.add_theme_color_override("font_color", ROJO)
		caja.add_child(estado)
		if visitado:
			var nota := ComunTaller.etiqueta(str(pd.get("nota", "")), 13, true)
			nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			caja.add_child(nota)
		if ARTE.fotografias.has(pid):
			var foto := FotoLugar.new()
			foto.configurar(ARTE.fotografias[pid], 130.0, false)
			caja.add_child(foto)
	return true


## Una tarjeta por poder: insignia, nombre, duración y qué hace.
## Devuelve false si Config no tiene poderes.
func _agregar_poderes() -> bool:
	var poderes: Variant = Config.poderes
	if not (poderes is Dictionary) or (poderes as Dictionary).is_empty():
		return false
	_agregar(ComunTaller.titulo_seccion("Poderes en la ruta"))
	_agregar(ComunTaller.etiqueta("Se activan al recogerlos. Cada uno tiene su propio efecto.", 14, true))
	var rejilla := _rejilla()
	for id in (poderes as Dictionary).keys():
		var pw := (poderes as Dictionary)[id] as Dictionary
		var d := float(pw.get("duracion", 0.0))
		var txt_d := str(int(d)) if d == float(int(d)) else str(d)
		var caja := _tarjeta(rejilla)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		caja.add_child(fila)
		var insignia := Control.new()
		insignia.custom_minimum_size = Vector2(LADO_PODER, LADO_PODER)
		insignia.draw.connect(func() -> void:
			insignia.draw_set_transform(insignia.size * 0.5, 0.0, Vector2.ONE * LADO_PODER / (Poder.RADIO_INSIGNIA * 2.0 + 4.0))
			Poder.dibujar_insignia(insignia, str(id)))
		fila.add_child(insignia)
		var textos := VBoxContainer.new()
		textos.add_theme_constant_override("separation", 0)
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(textos)
		var nombre := ComunTaller.titulo_seccion(str(pw.get("nombre", "?")), 16)
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textos.add_child(nombre)
		textos.add_child(ComunTaller.etiqueta("%s s" % txt_d if d > 0 else "Instantáneo", 13, true))
		var desc := ComunTaller.etiqueta(str(pw.get("descripcion", "")), 14)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caja.add_child(desc)
	return true


# --- Piezas ------------------------------------------------------------------

func _agregar(nodo: Control) -> void:
	lista.add_child(nodo)


## Rejilla de dos columnas para tarjetas.
func _rejilla() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	lista.add_child(g)
	return g


## Tarjeta vacía en la rejilla; devuelve la columna donde va su contenido.
func _tarjeta(rejilla: GridContainer) -> VBoxContainer:
	var t := PanelContainer.new()
	t.theme_type_variation = &"Tarjeta"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_child(t)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	t.add_child(caja)
	return caja
