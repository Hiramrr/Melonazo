class_name MelonMenu
extends Node2D
## Un melón decorativo que baja rodando por la calle del menú principal.
##
## Escena: pantallas/menu/melon_menu.tscn. Igual que los rivales del recorrido, el
## aspecto se dibuja una sola vez en Lienzo (SubViewport, UPDATE_ONCE) y Aspecto
## (Sprite2D) muestra esa textura. Así girar y mover el melón no vuelve a dibujar
## la piel, la cara y el patrón en cada cuadro.
##
## No tiene física propia: MelonesMenu (melones_menu.gd) lo mueve y lo hace explotar.

const RADIO_LIENZO := 96.0             # radio al que se dibuja en el lienzo de 256 px

var radio := 30.0
var velocidad := Vector2.ZERO
var giro := 0.0                        # rad/s
var carril := 0.0                      # px dentro de la calle: más alto = más cerca
var datos: Dictionary = {}


func _ready() -> void:
	$Lienzo.world_2d = World2D.new()
	$Aspecto.texture = $Lienzo.get_texture()
	$Aspecto.scale = Vector2.ONE * radio / RADIO_LIENZO


func configurar(p_datos: Dictionary, p_radio: float) -> void:
	datos = p_datos
	radio = p_radio


## Color de la cáscara, para los trozos de la explosión.
func color_cascara() -> Color:
	var piel: Color = Config.pieles[datos.get("piel", 0)]["cuerpo"]
	return Color.from_string(datos.get("cuerpo_propio", ""), piel)


func _dibujar_aspecto() -> void:
	Aspecto.dibujar_melon($Lienzo/Dibujo, RADIO_LIENZO, [], false, false, datos)
