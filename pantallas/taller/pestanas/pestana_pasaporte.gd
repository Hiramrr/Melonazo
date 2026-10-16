class_name PestanaPasaporte
extends ScrollContainer
## Pestaña "Pasaporte" del taller: postales visitadas y poderes de la ruta.
##
## Nodo: Taller/.../Pestanas/Pasaporte (pantallas/taller/taller.tscn).
##   ListaPasaporte          todo el contenido; se crea aquí con refrescar()
##
## Solo lee Juego (visitados, intentos, récord) y Config (postales, poderes), así
## que no emite señales. Nada del taller cambia esos datos: el contenido se arma
## una vez en _ready() y Taller no necesita refrescarlo en cada cambio.

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
	_agregar(ComunTaller.etiqueta("Pasaporte de Xalapa", 20))
	_agregar(ComunTaller.etiqueta("Cada lugar nuevo suma %d aplausos. Ruta y distancias de fantasía." % Config.bonus_postal, 15, true))
	_agregar(ComunTaller.etiqueta("Intentos: %d. Sitios visitados: %d." % [Juego.intentos, visitados.size()]))
	var hay_postales := _agregar_postales(visitados)
	var hay_poderes := _agregar_poderes()
	if not hay_postales and not hay_poderes:
		_agregar(ComunTaller.etiqueta("Rueda lejos y el pasaporte se llena solo.", 16, true))


# --- Secciones ---------------------------------------------------------------

## Una línea por postal (visitada o cuántos metros faltan) y su foto si la hay.
## Devuelve false si Config no tiene postales.
func _agregar_postales(visitados: Array) -> bool:
	var postales: Variant = Config.postales
	if not (postales is Array) or (postales as Array).is_empty():
		return false
	_agregar(ComunTaller.etiqueta("Postales", 20))
	var record_m := int(Juego.record_m)
	for p in (postales as Array):
		var pd := p as Dictionary
		var pid := str(pd.get("id", ""))
		var metros := int(pd.get("metros", 0))
		var linea := ""
		if pid != "" and pid in visitados:
			linea = "Visitado: %s. %s" % [pd.get("nombre", "?"), pd.get("nota", "")]
		else:
			linea = "A %d m: %s. Te faltan %d m." % [metros, pd.get("nombre", "?"), maxi(0, metros - record_m)]
		_agregar_parrafo(linea)
		if ARTE.fotografias.has(pid):
			var foto := FotoLugar.new()
			foto.configurar(ARTE.fotografias[pid])
			_agregar(foto)
	return true


## Una línea por poder: nombre, duración y qué hace.
## Devuelve false si Config no tiene poderes.
func _agregar_poderes() -> bool:
	var poderes: Variant = Config.poderes
	if not (poderes is Dictionary) or (poderes as Dictionary).is_empty():
		return false
	_agregar(ComunTaller.etiqueta("Poderes en la ruta", 20))
	_agregar(ComunTaller.etiqueta("Se activan al recogerlos. Cada uno tiene su propio efecto.", 15, true))
	for id in (poderes as Dictionary).keys():
		var pw := (poderes as Dictionary)[id] as Dictionary
		var d := float(pw.get("duracion", 0.0))
		var txt_d := str(int(d)) if d == float(int(d)) else str(d)
		var tiempo := " · %s s" % txt_d if d > 0 else " · instantáneo"
		_agregar_parrafo("%s%s. %s" % [pw.get("nombre", "?"), tiempo, pw.get("descripcion", "")])
	return true


func _agregar(nodo: Control) -> void:
	lista.add_child(nodo)


## Texto que se parte en varias líneas si no cabe.
func _agregar_parrafo(texto: String) -> void:
	var l := ComunTaller.etiqueta(texto)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(l)
