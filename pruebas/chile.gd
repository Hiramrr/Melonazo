extends SceneTree
var fallos := 0
func _initialize() -> void:
	call_deferred("verificar")
func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)
func verificar() -> void:
	change_scene_to_file("res://pantallas/recorrido/recorrido.tscn")
	await process_frame
	await process_frame
	var r = current_scene
	r.set_physics_process(false)
	var melon = r.melon
	melon.controlable = true
	melon._dv = Vector2.ZERO
	melon.recibir_poder("chile")
	var chile = melon.get_children().filter(func(n): return n.get_script() == load("res://melon/chile_encendido.gd"))[0]
	chile.set_physics_process(false)
	comprobar(chile.audio.playing, "El audio empieza al recoger el chile")
	await physics_frame
	await process_frame
	var reproduccion = chile.audio.get_stream_playback()
	comprobar(melon._dv == Vector2.ZERO and chile.sprite.visible, "Chile aparece sin impulsar al recoger")
	chile._physics_process(0.99)
	comprobar(not chile.exploto and melon._dv == Vector2.ZERO, "Espera un segundo antes de explotar")
	paused = true
	await process_frame
	comprobar(chile.tiempo == 0.99, "La pausa conserva la mecha")
	comprobar(chile.audio.stream_paused, "La pausa detiene también el audio de la mecha")
	paused = false
	chile._physics_process(0.01)
	comprobar(chile.exploto and not chile.sprite.visible, "Explota en el segundo uno")
	comprobar(chile.audio.get_stream_playback() == reproduccion, "La explosión no reinicia el audio")
	reproduccion = null
	comprobar(melon._dv.x >= root.get_node("Config").chile_vel_min and melon._dv.y < 0, "Explosión dispara al jugador")
	comprobar(chile.audio.playing and chile.fuego.emitting, "Explosión tiene audio y partículas de fuego")
	var impulso: Vector2 = melon._dv
	chile._physics_process(0.1)
	comprobar(melon._dv == impulso, "Cada chile impulsa una sola vez")
	chile._physics_process(2.5)
	comprobar(not chile.fuego.emitting, "La estela tiene duración limitada")
	melon.recibir_poder("chile")
	var pendiente = melon.get_children().filter(func(n): return n.get_script() == load("res://melon/chile_encendido.gd"))[-1]
	melon.roto = true
	pendiente._physics_process(1.0)
	comprobar(not pendiente.exploto and pendiente.is_queued_for_deletion(), "No explota después de romperse el melón")
	current_scene.queue_free()
	await process_frame
	await process_frame
	root.get_node("Musica").stop()
	await create_timer(0.1).timeout
	print("Chile: %d fallos." % fallos)
	quit(1 if fallos else 0)
