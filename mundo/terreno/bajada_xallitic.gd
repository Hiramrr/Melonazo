class_name BajadaXallitic
extends Tramo
## Bajada de salida, sin obstáculos ni ayudas antes de cruzar Xallitic.

const PersonaEscena := preload("res://mundo/ayudas/persona.tscn")
var barrera: Sprite2D


func _ready() -> void:
	var inicio := Config.bajada_inicio
	var fin := Config.bajada_fin
	var desde := inicio.x - maxf(1280.0, get_viewport_rect().size.x)
	var n := int(ceil((fin.x - desde) / Config.paso_puntos))
	for i in n + 1:
		var x := lerpf(desde, fin.x, float(i) / n)
		puntos.append(Vector2(x, _perfil(x)))
	empedrado = true
	color_suelo = Color("aaa18e")
	construir()
	var cantidad := int((fin.x - desde) / 190.0)
	for i in cantidad:
		var x := desde + i * 190.0
		var alto := 150.0 + 70.0 * _azar(x)
		var base := maxf(altura(x), altura(x + 125.0))
		casas.append({"rect": Rect2(x, base - alto, 125, alto + 40),
			"color": GeneradorTerreno.COLORES_CASAS[i % GeneradorTerreno.COLORES_CASAS.size()]})
	for i in int((fin.x - desde - 80.0) / 68.0):
		var x := desde + 40.0 + i * 68.0
		for fila in 2:
			var persona := PersonaEscena.instantiate() as Persona
			persona.position = Vector2(x + fila * 24.0, altura(x + fila * 24.0) + (-12.0 if fila == 0 else 132.0))
			persona.color_ropa = GeneradorTerreno.COLORES_ROPA[(i + fila * 2) % GeneradorTerreno.COLORES_ROPA.size()]
			persona.color_piel = Color("d4a17d").darkened(0.12 * (i % 4))
			persona.usado = i % 4 == 0
			get_node("Decoracion" if fila == 0 else "Publico").add_child(persona)
	get_node("Publico").z_index = 2
	marcadores.append({"pos": Vector2(inicio.x - 80, altura(inicio.x - 80)), "texto": "Salida"})
	barrera = Sprite2D.new()
	barrera.name = "BarreraSalida"
	var salida := Vector2(inicio.x + 60.0, altura(inicio.x + 60.0))
	barrera.texture = Sprites.textura("terreno/barrera")
	barrera.position = salida + Vector2(12, 50)
	barrera.scale = Vector2.ONE * Pixel.ESCALA
	barrera.z_index = 3
	add_child(barrera)


## Explanada de salida, caída casi vertical que se suaviza en un fondo largo
## y un trampolín que se empina hasta el borde, donde sale el melón.
func _perfil(x: float) -> float:
	var inicio := Config.bajada_inicio
	var fin := Config.bajada_fin
	var fondo_x := fin.x - Config.bajada_subida
	var fondo_y := fin.y + Config.bajada_hondo
	if x >= fondo_x:
		return fondo_y - Config.bajada_hondo * pow(inverse_lerp(fondo_x, fin.x, x), 2.0)
	var v := maxf(inverse_lerp(inicio.x, fondo_x, x), 0.0)
	var caida := (1.0 - pow(1.0 - v, 3.0)) * smoothstep(0.0, 0.08, v)  # borde redondeado arriba
	return lerpf(inicio.y, fondo_y, caida)


## Rapidez extra por lo que ya cayó: crece en la caída y se pierde en el
## trampolín, así que al salir solo queda la potencia elegida.
func embalaje(x: float) -> float:
	var inicio := Config.bajada_inicio
	var caida := clampf(inverse_lerp(inicio.y, Config.bajada_fin.y, altura(x)), 0.0, 1.0)
	var fondo_x := Config.bajada_fin.x - Config.bajada_subida
	return Config.bajada_embalaje * sqrt(caida) * (1.0 - smoothstep(fondo_x, Config.bajada_fin.x, x))


## Como pendiente(), pero en el borde conserva la inclinación del trampolín.
func inclinacion(x: float) -> float:
	return pendiente(minf(x, x1 - 10.0))


## Velocidad al dejar el trampolín: conserva la rapidez elegida hacia adelante
## y el borde le suma parte del impulso hacia arriba (Config.bajada_salto).
func velocidad_salida(rapidez: float) -> Vector2:
	return Vector2(rapidez, rapidez * sin(inclinacion(x1)) * Config.bajada_salto)


func abrir_salida() -> void:
	barrera.hide()


func _draw() -> void:
	if puntos.size() < 2:
		return
	_dibujar_suelo("terreno/calle_bajada", true)
	for m in marcadores:
		var p: Vector2 = m["pos"]
		Sprites.dibujar(self, "terreno/letrero", Rect2(p + Vector2(-40, -100), Vector2(80, 104)))
		draw_string(ThemeDB.fallback_font, p + Vector2(-35, -77), m["texto"], HORIZONTAL_ALIGNMENT_CENTER, 70, 15, Color(0.15, 0.15, 0.15))
