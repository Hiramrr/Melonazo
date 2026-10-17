@tool
class_name Obstaculo
extends Area2D
## Algo del camino que el melón toca al pasar: frena, daña, impulsa o se recoge.
##
## Escena base: mundo/obstaculos/obstaculo.tscn (Area2D + CollisionShape2D "Zona").
## Cada tipo es una escena heredada en la misma carpeta (coladera.tscn, rampa.tscn...)
## donde se editan su medida y su forma de colisión. La rampa añade un StaticBody2D
## "Cuna" para que el melón ruede encima.
##
## El origen está a ras de suelo y el área crece hacia arriba.
## GeneradorTerreno los coloca; cuando el melón entra en el área, Recorrido llama
## a tocar(), que aplica el efecto (los valores están en Config, sección Obstáculos).
## El dibujo usa recursos/sprites/obstaculos. @tool permite verlo en el editor.

@export_enum("coladera", "charco", "puesto", "poste", "banqueta", "rampa", "toldo", "aplauso") var tipo := "coladera":
	set(valor):
		tipo = valor
		queue_redraw()
@export var medida := Vector2(56, 10):     # ancho y alto del dibujo
	set(valor):
		medida = valor
		queue_redraw()
@export var altura_toldo := 115.0
@export var radio_aplauso := 22.0
var activo := true                         # false = ya no tiene efecto en esta carrera
var roto := false                          # puesto destrozado


func configurar(p_tipo: String) -> void:
	tipo = p_tipo
	queue_redraw()


## Aplica el efecto sobre el melón y devuelve el texto del aviso ("" = sin aviso).
## Recorrido solo lo llama si el obstáculo sigue activo.
func tocar(melon: Melon) -> String:
	match tipo:
		"aplauso":
			activo = false
			queue_free()
			return "+%d" % Config.valor_aplauso_suelto
		"coladera":
			activo = false
			melon.frenar(Config.coladera_freno)
			return "Coladera"
		"charco":
			melon.frenar(Config.charco_freno)  # sigue activo: frena mientras chapotea
			return "¡Splash!"
		"puesto":
			romper()
			if melon.t_embestida > 0.0:
				return "¡Puesto destrozado!"
			melon.frenar(Config.puesto_freno)
			return "Se llevó un puesto"
		"poste":
			activo = false
			melon.golpe()                   # el golpe ya muestra su propio aviso
			melon.frenar(Config.poste_freno)
		"banqueta":
			activo = false
			melon.golpe()
			melon.frenar(Config.banqueta_freno)
			melon.empujar(Vector2(0, -Config.banqueta_salto))
		"rampa":
			activo = false
			melon.empujar(Vector2.from_angle(rotation - deg_to_rad(Config.rampa_angulo)) * Config.rampa_impulso)
			return "¡Rampa!"
		"toldo":
			# La caída sobre el toldo da avance; tocarlo desde abajo no ayuda.
			var v: Vector2 = melon.linear_velocity
			if v.y > 0.0:
				activo = false
				melon.fijar_velocidad(Vector2(v.x + Config.toldo_avance, -v.y * Config.toldo_rebote))
				return "¡Toldo! Más velocidad"
	return ""


## Deja el puesto tirado: ya no frena y se dibuja roto.
func romper() -> void:
	activo = false
	roto = true
	queue_redraw()


func _draw() -> void:
	var medidas := {"coladera": Vector2(56, 10), "charco": Vector2(130, 8), "puesto": Vector2(110, 80),
		"poste": Vector2(14, 150), "banqueta": Vector2(90, 30), "rampa": Vector2(130, 46),
		"toldo": Vector2(150, 18), "aplauso": Vector2(44, 44)}
	var escala: Vector2 = medida / medidas[tipo]
	if tipo == "aplauso":
		escala = Vector2.ONE * radio_aplauso / 22.0
	var id := "puesto_roto" if tipo == "puesto" and roto else tipo
	var pos := Vector2(0, 115.0 * escala.y - altura_toldo) if tipo == "toldo" else Vector2.ZERO
	Sprites.dibujar(self, "obstaculos/" + id, Rect2(Vector2(-90, -170) * escala + pos, Vector2(180, 200) * escala))
