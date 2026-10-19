class_name PestanaPasaporte
extends ScrollContainer
## Pestaña "Pasaporte" del taller: postales visitadas y poderes de la ruta.
##
## Nodo: Taller/.../Pestanas/Pasaporte (pantallas/taller/taller.tscn).
##   ListaPasaporte          todo el contenido; se crea aquí con refrescar():
##                           resumen, una tarjeta por postal y una por poder
##
## Solo lee Juego (visitados, intentos, récord), Config y las fotos de ArteXalapa, así
## que no emite señales. Nada del taller cambia esos datos: el contenido se arma
## una vez en _ready() y Taller no necesita refrescarlo en cada cambio.

const LADO_PODER := 48.0
const ARTE := preload("res://recursos/arte_xalapa.tres")

@onready var lista: VBoxContainer = %ListaPasaporte


func _ready() -> void:
	refrescar()

## Vuelve a armar el pasaporte desde Juego y Config.
func refrescar() -> void:
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()
	var visitados: Array = Juego.visitados
	_agregar(ComunTaller.titulo_seccion("De Xalapa al CUCosta", Estilos.TITULO_PASAPORTE))
	
	var objetivo := ComunTaller.etiqueta(
		"Llega al %s de la %s. Meta a %d m de juego." % [Config.nombre_meta, Config.institucion_meta, int(Config.meta_m)],
		Estilos.TEXTO_FICHA)
	objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_agregar(objetivo)

	var resumen := HBoxContainer.new()
	resumen.theme_type_variation = Estilos.FILA_DETALLE
	resumen.custom_minimum_size.y = 40.0
	resumen.add_child(Ficha.crear(Iconos.LUGAR, "%d de %d lugares" % [visitados.size(), Config.postales.size()], false, Estilos.CONTADOR_PASAPORTE))
	resumen.add_child(Ficha.crear(Iconos.APLAUSO, "+%d por lugar nuevo" % Config.bonus_postal, false, Estilos.CONTADOR_PASAPORTE))
	_agregar(resumen)
	_agregar(ComunTaller.etiqueta("Intentos: %d. Ruta y distancias de fantasía." % Juego.intentos, Estilos.NOTA))
	var hay_postales := _agregar_postales(visitados)
	var hay_poderes := _agregar_poderes()
	if not hay_postales and not hay_poderes:
		_agregar(ComunTaller.etiqueta("Rueda lejos y el pasaporte se llena solo.", Estilos.DESCRIPCION))


# --- Secciones ---------------------------------------------------------------

## Una tarjeta por postal: nombre, foto con créditos, sello de visitado
## o metros pendientes, y nota al visitar el lugar.
func _agregar_postales(visitados: Array) -> bool:
	var postales: Variant = Config.postales
	if not (postales is Array) or (postales as Array).is_empty():
		return false
	_agregar(ComunTaller.titulo_seccion("Postales", Estilos.SUBTITULO))
	
	var rejilla := _rejilla()
	var record_m := int(Juego.record_m)
	for p in (postales as Array):
		var pd := p as Dictionary
		var pid := str(pd.get("id", ""))
		var metros := int(pd.get("metros", 0))
		var visitado := pid != "" and pid in visitados
		
		var t := Tarjeta.new()
		t.icono = Iconos.LUGAR if visitado else Iconos.CANDADO
		t.titulo = str(pd.get("nombre", "?"))
		if visitado:
			t.estado = "¡VISITADO!"
			t.estado_estilo = Estilos.POSTAL_VISITADA
			t.descripcion = str(pd.get("nota", ""))
		else:
			t.estado = "A %d m · faltan %d m" % [metros, maxi(0, metros - record_m)]
			t.estado_estilo = Estilos.POSTAL_PENDIENTE
			t.estado_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var datos: Dictionary = ARTE.fotografias.get(pid, {}).duplicate()
		if datos.get("textura") is Texture2D:
			# La nota ya aparece bajo la foto cuando el lugar está visitado.
			datos.erase("dato_curioso")
			var foto := FotoLugar.new()
			foto.configurar(datos, 140.0, false)
			t.cuerpo.add_child(foto)
		rejilla.add_child(t)
	return true

## Una tarjeta por poder: insignia, nombre, duración y qué hace.
## Devuelve false si Config no tiene poderes.
func _agregar_poderes() -> bool:
	var poderes: Variant = Config.poderes
	if not (poderes is Dictionary) or (poderes as Dictionary).is_empty():
		return false
		
	_agregar(ComunTaller.titulo_seccion("Poderes en la ruta", Estilos.SUBTITULO))
	_agregar(ComunTaller.etiqueta("Se activan al recogerlos. Cada uno tiene su propio efecto.", Estilos.NOTA))
	
	var rejilla := _rejilla()
	for id in (poderes as Dictionary).keys():
		var pw := (poderes as Dictionary)[id] as Dictionary
		var d := float(pw.get("duracion", 0.0))
		var txt_d := str(int(d)) if d == float(int(d)) else str(d)
		
		var t := Tarjeta.new()
		var fila := HBoxContainer.new()
		fila.theme_type_variation = Estilos.FILA_DETALLE
		t.cuerpo.add_child(fila)
		var insignia := Control.new()
		insignia.custom_minimum_size = Vector2(LADO_PODER, LADO_PODER)
		insignia.draw.connect(func() -> void:
			insignia.draw_set_transform(insignia.size * 0.5, 0.0,
				Vector2.ONE * LADO_PODER / (Poder.RADIO_INSIGNIA * 2.0 + 4.0))
			Poder.dibujar_insignia(insignia, str(id)))
		fila.add_child(insignia)
		var textos := VBoxContainer.new()
		textos.theme_type_variation = Estilos.COLUMNA_UNIDA
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(textos)
		textos.add_child(ComunTaller.titulo_seccion(str(pw.get("nombre", "?")), Estilos.NOMBRE_TARJETA))
		textos.add_child(ComunTaller.etiqueta("%s s" % txt_d if d > 0 else "Instantáneo", Estilos.DETALLE))
		t.descripcion = str(pw.get("descripcion", ""))
		rejilla.add_child(t)
	return true

# --- Piezas ------------------------------------------------------------------

func _agregar(nodo: Control) -> void:
	lista.add_child(nodo)


## Rejilla responsiva
func _rejilla() -> RejillaTarjetas:
	var g := RejillaTarjetas.new()
	g.ancho_minimo = 220.0
	g.max_columnas = 3
	lista.add_child(g)
	return g
