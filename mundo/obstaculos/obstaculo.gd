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
## Los rivales (MelonRodante) no tienen física: GeneradorTerreno.actualizar_melones()
## comprueba toca_circulo() y llama tocar_rival(), que aplica un efecto equivalente.
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
var _rivales: Array[int] = []              # ids de los rivales que ya lo tocaron


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


## Efecto sobre un rival, una sola vez por rival. No gasta el obstáculo para el jugador,
## salvo el puesto, que queda destrozado. Devuelve true si hubo efecto.
##   coladera, charco  frenan como al jugador
##   puesto            frena, daña media resistencia (Config.rival_dano_puesto) y se rompe
##   poste, banqueta   golpe completo (Config.rival_dano_golpe) y frenan; la banqueta
##                     además lo hace saltar
##   rampa, toldo      lo lanzan como al jugador (el toldo solo si cae encima)
## Los aplausos no le interesan.
func tocar_rival(rival: MelonRodante) -> bool:
	if tipo == "aplauso" or not activo or rival.get_instance_id() in _rivales:
		return false
	if tipo == "toldo" and rival.velocidad.y <= 0.0:
		return false                    # desde abajo no cuenta, puede caerle después
	_rivales.append(rival.get_instance_id())
	match tipo:
		"coladera":
			rival.frenar(Config.coladera_freno)
		"charco":
			rival.frenar(Config.charco_freno)
		"puesto":
			romper()
			rival.frenar(Config.puesto_freno)
			rival.danar(Config.rival_dano_puesto)
		"poste":
			rival.frenar(Config.poste_freno)
			rival.danar(Config.rival_dano_golpe)
		"banqueta":
			rival.frenar(Config.banqueta_freno)
			rival.danar(Config.rival_dano_golpe)
			_lanzar_rival(rival, rival.velocidad + Vector2(0, -Config.banqueta_salto))
		"rampa":
			_lanzar_rival(rival, rival.velocidad + Vector2.from_angle(rotation - deg_to_rad(Config.rampa_angulo)) * Config.rampa_impulso)
		"toldo":
			_lanzar_rival(rival, Vector2(rival.velocidad.x + Config.toldo_avance, -rival.velocidad.y * Config.toldo_rebote))
	return true


## Lo despega del suelo con esa velocidad; MelonRodante sigue el arco por su cuenta.
func _lanzar_rival(rival: MelonRodante, velocidad: Vector2) -> void:
	rival.velocidad = velocidad
	rival.en_suelo = false


## true si un círculo (centro global) toca la zona de colisión de la escena. La
## zona puede estar inclinada con el suelo; se mide en su espacio local.
func toca_circulo(centro: Vector2, radio: float) -> bool:
	var zona := $Zona as CollisionShape2D
	var local := zona.global_transform.affine_inverse() * centro
	if zona.shape is CircleShape2D:
		return local.length() <= radio + (zona.shape as CircleShape2D).radius
	var mitad: Vector2 = (zona.shape as RectangleShape2D).size * 0.5
	return local.distance_to(local.clamp(-mitad, mitad)) <= radio


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
