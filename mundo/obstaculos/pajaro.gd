class_name Pajaro
extends Area2D
## Pájaro que vuela contra el melón por encima de la calle. Si lo toca, le quita
## velocidad y sale volando. Cada pájaro estorba una sola vez.
##
## Escena: mundo/obstaculos/pajaro.tscn (Area2D en la capa 4; detecta la capa 2, la del melón)
##   Zona   CollisionShape2D circular, del tamaño del dibujo
## En la escena, body_entered está conectada a _al_entrar().
##
## Quién lo usa: GeneradorTerreno._poner_pajaros() lo instancia en el contenedor Aire
## del tramo y reenvía `tocado` como su señal pajaro_tocado, que atiende
## Recorrido._al_tocar_pajaro(). Ese método llama a tocar(), que aplica el freno.
## Los rivales no tienen física: GeneradorTerreno.actualizar_melones() mide la distancia
## (radio_toque()), los frena y llama huir().
## Ajustes: Config, sección Pájaros.

## Se emite una sola vez, cuando el melón (controlable) lo toca.
signal tocado(pajaro: Pajaro)

## Dibujo del pájaro, mirando a la izquierda. Se cambia en el inspector de pajaro.tscn
## (PNG, WebP o un AtlasTexture). Si es una tira horizontal de aleteo, indica sus cuadros.
@export var textura: Texture2D = preload("res://recursos/poderes/pajaro.png")
@export_range(1, 32) var cuadros := 1
@export var cuadros_por_segundo := 10.0
@export var lado := 64.0                ## tamaño en pantalla

var activo := true                      # false = ya chocó en esta carrera
var fase := 0.0                         # desfase del aleteo; lo elige el generador
var _t := 0.0
var _y_base := 0.0


func _ready() -> void:
	_y_base = position.y


func _process(delta: float) -> void:
	_t += delta
	if activo:
		position.x -= Config.pajaro_vel * delta
		position.y = _y_base + sin(_t * 2.2 + fase) * 14.0
	queue_redraw()


## Conectada a body_entered. Solo cuenta el melón mientras el jugador lo controla.
func _al_entrar(cuerpo: Node2D) -> void:
	if activo and cuerpo is Melon and cuerpo.controlable:
		tocado.emit(self)


## Frena al melón y se va volando. Devuelve el texto del aviso.
func tocar(melon: Melon) -> String:
	if not activo:
		return ""
	melon.frenar(Config.pajaro_freno)
	huir()
	return "¡Pájaro! Te frena"


## Deja de estorbar y sale volando hacia arriba hasta desaparecer.
func huir() -> void:
	if not activo:
		return
	activo = false
	var huida := create_tween().set_parallel()
	huida.tween_property(self, "position", position + Vector2(-140, -260), 0.8).set_ease(Tween.EASE_OUT)
	huida.tween_property(self, "rotation", -0.6, 0.8)
	huida.tween_property(self, "modulate:a", 0.0, 0.8)
	huida.chain().tween_callback(queue_free)


## Radio de su zona de choque (CollisionShape2D "Zona" de la escena).
func radio_toque() -> float:
	return ($Zona.shape as CircleShape2D).radius


func _draw() -> void:
	if textura == null:
		return
	var destino := Rect2(-lado * 0.5, -lado * 0.5, lado, lado)
	if cuadros > 1:
		var ancho := textura.get_width() / float(cuadros)
		var cuadro := int(_t * cuadros_por_segundo + fase) % cuadros
		draw_texture_rect_region(textura, destino, Rect2(cuadro * ancho, 0, ancho, textura.get_height()))
		return
	# Con una sola imagen el aleteo aplasta y estira un poco el dibujo.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0 + sin(_t * 14.0 + fase) * 0.12))
	draw_texture_rect(textura, destino, false)
