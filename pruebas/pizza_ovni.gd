extends SceneTree
var fallos := 0
func _initialize():
    call_deferred("probar")
func comprobar(ok: bool, mensaje: String):
    if not ok:
        fallos += 1
        push_error(mensaje)
func probar():
    # Carga la escena completa antes de las escenas con dependencias circulares.
    load("res://pantallas/recorrido/recorrido.tscn")
    var m = load("res://melon/melon.tscn").instantiate()
    root.add_child(m)
    m.configurar(1, [], 50.0, 2)
    m.position = Vector2(0, -10000)
    m.controlable = true
    m.freeze = false
    m.linear_velocity = Vector2(730, 0)
    m.recibir_poder("pizza")
    var ovni = m.get_node("PizzaOvni")
    comprobar(ovni.audio.playing, "El audio comienza al recoger")
    comprobar(m.t_pizza == 3.0, "Dura tres segundos")
    var y: float = m.position.y
    for i in 120:
        await physics_frame
    comprobar(absf(m.linear_velocity.x - 730) < 1, "Conserva velocidad")
    comprobar(m.position.y < y - 300, "Eleva al melón")
    var restante: float = m.t_pizza
    paused = true
    for i in 15:
        await process_frame
    comprobar(m.t_pizza == restante, "La pausa conserva el tiempo")
    paused = false
    while m.t_pizza > 0:
        await physics_frame
    await physics_frame
    comprobar(ovni.partiendo, "Al segundo tres se retira el ovni")
    var vy: float = m.linear_velocity.y
    for i in 15:
        await physics_frame
    comprobar(m.linear_velocity.y > vy, "Vuelve la gravedad")
    m.recibir_poder("pizza")
    comprobar(m.get_node("PizzaOvni") != ovni, "Recoger otra pizza sustituye el efecto")
    m.queue_free()
    await process_frame
    print("Pizza ovni: ", fallos, " fallos")
    quit(fallos)
