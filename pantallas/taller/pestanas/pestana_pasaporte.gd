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
	_agregar(ComunTaller.titulo_seccion("De Xalapa al CUCosta", &"TituloPasaporte"))
	var objetivo := ComunTaller.etiqueta("Llega al %s de la %s. Meta a %d m de juego." % [Config.nombre_meta, Config.institucion_meta, int(Config.meta_m)], &"TextoFicha")
	objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_agregar(objetivo)
	var resumen := HBoxContainer.new()
	resumen.theme_type_variation = &"FilaDetalle"
	resumen.add_child(Ficha.crear(Iconos.LUGAR, "%d de %d lugares" % [visitados.size(), Config.postales.size()], false, &"ContadorPasaporte"))
	resumen.add_child(Ficha.crear(Iconos.APLAUSO, "+%d por lugar nuevo" % Config.bonus_postal, false, &"ContadorPasaporte"))
	_agregar(resumen)
	_agregar(ComunTaller.etiqueta("Intentos: %d. Ruta y distancias de fantasía." % Juego.intentos, &"Nota"))
	var hay_postales := _agregar_postales(visitados)
	var hay_poderes := _agregar_poderes()
	if not hay_postales and not hay_poderes:
		_agregar(ComunTaller.etiqueta("Rueda lejos y el pasaporte se llena solo.", &"Descripcion"))


# --- Secciones ---------------------------------------------------------------

## Una tarjeta por postal: nombre, sello de visitado (o cuántos metros faltan),
## y nota. Las fotos solo se muestran al terminar el intento.
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
		cabeza.theme_type_variation = &"FilaIconos"
		caja.add_child(cabeza)
		var pin := Iconos.imagen(Iconos.LUGAR if visitado else Iconos.CANDADO, 26.0)
		cabeza.add_child(pin)
		var nombre := ComunTaller.titulo_seccion(str(pd.get("nombre", "?")), &"NombreTarjeta")
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cabeza.add_child(nombre)
		var estado := ComunTaller.titulo_seccion("", &"EstadoPostal")
		if visitado:
			estado.text = "¡VISITADO!"
			estado.theme_type_variation = &"PostalVisitada"
		else:
			estado.text = "A %d m · faltan %d m" % [metros, maxi(0, metros - record_m)]
			estado.theme_type_variation = &"PostalPendiente"
		caja.add_child(estado)
		if visitado:
			var nota := ComunTaller.etiqueta(str(pd.get("nota", "")), &"Detalle")
			nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			caja.add_child(nota)
	return true


## Una tarjeta por poder: insignia, nombre, duración y qué hace.
## Devuelve false si Config no tiene poderes.
func _agregar_poderes() -> bool:
	var poderes: Variant = Config.poderes
	if not (poderes is Dictionary) or (poderes as Dictionary).is_empty():
		return false
	_agregar(ComunTaller.titulo_seccion("Poderes en la ruta"))
	_agregar(ComunTaller.etiqueta("Se activan al recogerlos. Cada uno tiene su propio efecto.", &"Nota"))
	var rejilla := _rejilla()
	for id in (poderes as Dictionary).keys():
		var pw := (poderes as Dictionary)[id] as Dictionary
		var d := float(pw.get("duracion", 0.0))
		var txt_d := str(int(d)) if d == float(int(d)) else str(d)
		var caja := _tarjeta(rejilla)
		var fila := HBoxContainer.new()
		fila.theme_type_variation = &"FilaDetalle"
		caja.add_child(fila)
		var insignia := Control.new()
		insignia.custom_minimum_size = Vector2(LADO_PODER, LADO_PODER)
		insignia.draw.connect(func() -> void:
			insignia.draw_set_transform(insignia.size * 0.5, 0.0, Vector2.ONE * LADO_PODER / (Poder.RADIO_INSIGNIA * 2.0 + 4.0))
			Poder.dibujar_insignia(insignia, str(id)))
		fila.add_child(insignia)
		var textos := VBoxContainer.new()
		textos.theme_type_variation = &"ColumnaUnida"
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(textos)
		var nombre := ComunTaller.titulo_seccion(str(pw.get("nombre", "?")), &"NombreTarjeta")
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textos.add_child(nombre)
		textos.add_child(ComunTaller.etiqueta("%s s" % txt_d if d > 0 else "Instantáneo", &"Detalle"))
		var desc := ComunTaller.etiqueta(str(pw.get("descripcion", "")), &"TextoBreve")
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
	g.theme_type_variation = &"RejillaTarjetas"
	lista.add_child(g)
	return g


## Tarjeta vacía en la rejilla; devuelve la columna donde va su contenido.
func _tarjeta(rejilla: GridContainer) -> VBoxContainer:
	var t := PanelContainer.new()
	t.theme_type_variation = &"Tarjeta"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_child(t)
	var caja := VBoxContainer.new()
	caja.theme_type_variation = &"ColumnaCompacta"
	t.add_child(caja)
	return caja
