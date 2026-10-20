extends SceneTree
var fallos := 0
func _initialize():
    call_deferred("probar")
func comprobar(ok: bool, mensaje: String):
    if not ok:
        fallos += 1
        push_error(mensaje)
func probar():
    var escena = load("res://pantallas/recorrido/recorrido.tscn")
    var rival = load("res://mundo/ayudas/melon_rodante.tscn").instantiate()
    root.add_child(rival)
    rival.set_physics_process(false)
    var melon = load("res://melon/melon.tscn").instantiate()
    root.add_child(melon)
    melon.controlable = true
    melon.freeze = true
    var papalote = load("res://mundo/ayudas/papalote.tscn").instantiate()
    root.add_child(papalote)
    comprobar(papalote.impulsar_rival(rival), "El rival usa el papalote")
    comprobar(not papalote.usado, "El rival no gasta el papalote")
    comprobar(not papalote.impulsar_rival(rival), "No repite el mismo impulso")
    comprobar(papalote.impulsar(melon) and papalote.usado, "El jugador sí lo gasta")
    var poder = load("res://mundo/ayudas/poder.tscn").instantiate()
    poder.tipo = "cafe"
    root.add_child(poder)
    comprobar(poder.recibir_rival(rival) and not poder.consumido, "El rival no gasta el poder")
    comprobar(not poder.recibir_rival(rival), "No repite el poder")
    poder._recoger(melon)
    comprobar(poder.consumido, "El jugador recoge el poder")
    var puesto = load("res://mundo/obstaculos/puesto.tscn").instantiate()
    root.add_child(puesto)
    puesto.tocar_rival(rival)
    comprobar(puesto.activo and not puesto.roto, "El rival no rompe el puesto")
    puesto.tocar(melon)
    comprobar(puesto.roto and not puesto.activo, "El jugador rompe el puesto")
    var pajaro = load("res://mundo/obstaculos/pajaro.tscn").instantiate()
    root.add_child(pajaro)
    pajaro.tocar_rival(rival)
    comprobar(pajaro.activo, "El rival no gasta el pájaro")
    pajaro.tocar(melon)
    comprobar(not pajaro.activo, "El jugador hace huir al pájaro")
    for nodo in [rival, melon, papalote, puesto, pajaro]:
        nodo.queue_free()
    await process_frame
    print("Objetos compartidos: ", fallos, " fallos")
    quit(fallos)
