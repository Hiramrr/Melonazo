@tool
class_name Papalote
extends Node2D
## Ayuda de la ruta aérea: un papalote flotando. Si el melón pasa cerca y el jugador
## presiona E, lo lanza hacia arriba y adelante y lo protege
## de la siguiente caída fuerte.
## Cada papalote se puede usar una sola vez.
##
## Escena: mundo/ayudas/papalote.tscn (un solo Node2D, z 4; todo se dibuja en _draw()).
##
## Quién lo usa: GeneradorTerreno._poner_papalotes() lo instancia en el contenedor Aire
## del tramo (y lo anota en Tramo.papalotes). Recorrido._actualizar_interacciones()
## asigna `en_rango` cada cuadro y llama impulsar() con el más cercano al presionar E.
## Ajustes: Config.papalote_rango, papalote_avance y papalote_elevacion.

const TINTA := Color("294b43")
const CREMA := Color("fff4d6")

@export var corriente := false

## Ya se usó en esta carrera; se dibuja en gris.
var usado := false
## El melón está lo bastante cerca para usarlo (muestra el aro y "E · Impulso").
var en_rango := false:
	set(valor):
		if en_rango != valor:
			en_rango = valor
			queue_redraw()


## Impulsa al melón si está a alcance y el papalote no se ha usado. Devuelve true si
## hubo impulso. Asegura una velocidad mínima hacia adelante y hacia arriba (no suma
## si el melón ya va más rápido) y activa su escudo. Los saltos ilimitados llegan con el café.
func impulsar(melon: Melon) -> bool:
	if usado or not melon.controlable or melon.roto or global_position.distance_to(melon.global_position) > Config.papalote_rango:
		return false
	usado = true
	en_rango = false
	# Se lee melon._dv (privado, sin getter público) para contar también los impulsos
	# pedidos en este mismo paso de física; así Espacio + E no duplican la elevación.
	var v := melon.linear_velocity + melon._dv
	melon.empujar(Vector2(maxf(0.0, Config.papalote_avance - v.x), minf(0.0, -Config.papalote_elevacion - v.y)))
	melon.proteger()
	queue_redraw()
	return true


# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	var estado := 2 if usado else (1 if en_rango else 0)
	Sprites.dibujar(self, "ayudas/%s_%d" % ["corriente" if corriente else "papalote", estado], Rect2(-112, -100, 224, 200))


func nombre() -> String:
	return "Corriente de niebla" if corriente else "Papalote"
