class_name CamaraRecorrido
extends Camera2D
## Cámara del recorrido (nodo "Camara" de recorrido.tscn).
##
## Mientras se elige la fuerza se queda fija mirando la bajada. Después
## sigue al melón un poco por delante, anticipa subidas y caídas, y se aleja
## (zoom out) cuanto más rápido va. El suavizado de posición está en la escena.

const ADELANTO := Vector2(260, -40)    # el melón queda a la izquierda: se ve lo que viene
const ANTICIPACION_MAX := Vector2(-70.0, 60.0)  # px hacia arriba / abajo según la velocidad vertical
const VELOCIDAD_ZOOM_MIN := 3000.0     # a esta rapidez el zoom llega a ZOOM_MIN
const ZOOM_MIN := 0.72


## Llamar cada cuadro. Si siguiendo es false, encuadra la salida de la bajada.
func actualizar(melon: Melon, siguiendo: bool, delta: float) -> void:
	var z := 1.0
	if not siguiendo:
		position = melon.global_position + Vector2(100, 60)
	else:
		var anticipacion := clampf(melon.linear_velocity.y * 0.1, ANTICIPACION_MAX.x, ANTICIPACION_MAX.y)
		position = melon.global_position + ADELANTO + Vector2(0, anticipacion)
		z = clampf(1.0 - melon.linear_velocity.length() / VELOCIDAD_ZOOM_MIN, ZOOM_MIN, 1.0)
	zoom = zoom.lerp(Vector2(z, z), clampf(delta * 1.5, 0.0, 1.0))
