extends Node
## Autoload "Config": todas las reglas y valores ajustables del juego.
##
## Se lee desde cualquier script como Config.gravedad, Config.tamanos[1], etc.
## Aquí solo hay datos; la lógica vive en los nodos que los usan. Las formas de
## colisión no están aquí: se editan en sus escenas (mundo/obstaculos/, melon/).
##
## Unidades: píxeles, segundos y px/s. Un metro del juego son px_por_metro píxeles.
## Las velocidades "dv" son cambios de velocidad, no velocidades absolutas.

# --- Mundo -------------------------------------------------------------------
var gravedad := 980.0
var px_por_metro := 10.0

# --- Tamaños del melón -------------------------------------------------------
# mult_lanzamiento: multiplica la velocidad de salida (ligero = sale más rápido).
# amortiguacion: frenado por aire (linear_damp). friccion_rodado: frenado en suelo (px/s²).
# inercia: 0..1, cuánto ignora los obstáculos que frenan (1 = no le afectan).
# umbral_caida: velocidad de impacto (px/s, normal al suelo) que cuesta un golpe.
var tamanos: Array = [
	{"nombre": "Chico", "desc": "Ligero: sale volando lejos, pero pierde velocidad rápido y aguanta poco.",
		"radio": 16.0, "masa": 1.0, "mult_lanzamiento": 1.3, "rebote": 0.45, "friccion": 0.9,
		"amortiguacion": 0.3, "friccion_rodado": 200.0, "inercia": 0.0, "resistencia": 2, "umbral_caida": 900.0},
	{"nombre": "Mediano", "desc": "Equilibrado.",
		"radio": 22.0, "masa": 2.0, "mult_lanzamiento": 1.0, "rebote": 0.35, "friccion": 0.9,
		"amortiguacion": 0.23, "friccion_rodado": 170.0, "inercia": 0.3, "resistencia": 3, "umbral_caida": 1050.0},
	{"nombre": "Grande", "desc": "Pesado: sale corto, pero conserva la inercia y aguanta más golpes.",
		"radio": 30.0, "masa": 3.6, "mult_lanzamiento": 0.75, "rebote": 0.22, "friccion": 0.9,
		"amortiguacion": 0.2, "friccion_rodado": 155.0, "inercia": 0.6, "resistencia": 4, "umbral_caida": 1250.0},
]

# --- Accesorios --------------------------------------------------------------
# Cada accesorio es un archivo en melon/accesorios/ (ver accesorio.gd). Se cargan
# solos: para añadir uno basta con crear su archivo. Sus valores viven ahí mismo.
const CARPETA_ACCESORIOS := "res://melon/accesorios/"
var accesorios: Dictionary = {}       # id -> Accesorio
var orden_accesorios: Array = []      # ids ordenados por Accesorio.orden
var accesorios_iniciales: Array = []  # ids con inicial = true
var max_accesorios := 3
# Ángulo (grados, en el melón) donde va el accesorio de cada tecla 1-2-3.
# -90 = arriba. La parte de abajo queda redonda.
var angulos_slots: Array = [-90.0, -20.0, -160.0]

# --- Lanzamiento -------------------------------------------------------------
var bajada_inicio := Vector2(-2900, -1000)   # arriba hay una explanada plana para la salida
var bajada_fin := Vector2(40, 0)      # borde del trampolín; aquí vuelven los controles
var bajada_hondo := 240.0             # px que el fondo de la bajada queda bajo el borde
var bajada_subida := 560.0            # px de largo del trampolín final
var bajada_embalaje := 500.0          # px/s extra al llegar al fondo; se pierde en el trampolín
var bajada_salto := 0.8               # parte del impulso hacia arriba del trampolín que se conserva al salir
var fuerza_freq := 0.75              # ciclos por segundo de la barra
var lanz_vel_min := 430.0
var lanz_vel_max := 760.0
var zona_perfecta := Vector2(0.80, 1.0)    # tramo de la barra (0..1) con bonus
var bonus_perfecto := 1.15

# --- Control en el aire ------------------------------------------------------
var giro_max := 9.0                  # rad/s
var giro_acel := 30.0                # rad/s²
var control_aereo := 110.0           # px/s² con A/D o flechas
var control_aereo_max := 520.0       # el control no recorta impulsos más rápidos
var salto_aereo_vel := 900.0
var salto_aereo_avance := 100.0
var vel_crucero := 1800.0            # px/s; por encima, frenado extra (evita rozar el suelo sin fin)
var arrastre_extra := 1.0            # fracción por segundo del exceso que se pierde

# --- Rebote impulsado --------------------------------------------------------
var ventana_rebote := 0.26           # s antes de tocar suelo en que cuenta el Espacio
var bloqueo_rebote := 0.45           # s sin poder volver a intentarlo (evita machacar)
var rebote_mult_normal := 0.95       # multiplica la velocidad de impacto
var rebote_min := 520.0              # velocidad mínima de salida del rebote
var rebote_mult_tang := 1.25         # multiplica la velocidad a lo largo del suelo
var rebote_pared_conserva := 0.6     # velocidad horizontal que queda al rebotar contra una pared
var vista_indicador := 0.6           # s de anticipación del aro indicador
var rebotes_base := 2

# --- Slam --------------------------------------------------------------------
var slam_caida := 1250.0             # velocidad mínima del picado
var slam_impulso := Vector2(420, -850)
var slam_conserva := 0.6             # velocidad que queda al fallar contra el suelo
var slam_recarga := 0.45
var slam_margen := Vector2(16, 40)   # tolerancia lateral mínima y máxima, en píxeles
var slam_tolerancia := 0.035         # margen según la velocidad relativa, en segundos
var slam_alcance := 460.0            # altura máxima a la que el picado busca un melón debajo
var slam_guiado := 1700.0            # px/s² de corrección horizontal hacia ese melón
var slam_confianza_aviso := 0.5      # parte del margen y la corrección que cuenta el aviso de S
var rivales_salida := 6
var separacion_salida := 75.0
var carriles_salida := Vector2(28, 76)
var ritmo_rivales := Vector2(0.94, 1.16)
var frenado_melones := 180.0          # px/s² al pasar de su ritmo en el suelo
var aceleracion_melones := 320.0      # px/s² para recuperar su ritmo
var velocidad_melones := Vector2(420, 620)   # ritmo de crucero de cada melón
var ritmo_melones := Vector2(0.75, 1.35)     # ajuste del ritmo según su distancia al jugador
var alcance_ritmo_melones := 4000.0   # px de distancia para llegar a ese ajuste
var salto_melones := Vector2(340, 640)       # velocidad vertical de sus saltos
var pausa_saltos_melones := Vector2(1.1, 2.8)
var prob_rebote_melones := 0.35       # caídas que rebotan con impulso
var salida_min_melones := 90.0        # por debajo de este rebote se quedan rodando
var aplastado_melones := 0.4          # s achatado y lento tras recibir un slam
# Vuelo: si el jugador está a más de vuelo_melones_desde px sobre el suelo y a menos de
# alcance_vuelo_melones px de distancia, los rivales lo siguen al aire, por debajo de él.
var vuelo_melones_desde := 650.0      # más que un salto normal
var alcance_vuelo_melones := 1800.0
# Más hondo que lo que devuelve un slam (slam_impulso.y ≈ 370 px): cada golpe en
# lo alto cuesta algo de altura y no sostiene el vuelo por sí solo.
var bajo_jugador_melones := Vector2(320, 540)  # px por debajo del jugador
var impulso_vuelo_melones := 1500.0   # px/s de cada impulso en el aire, como máximo
var margen_vuelo_melones := 40.0      # px extra que sube cada impulso
var aleteo_melones := Vector2(0.45, 1.0)     # s entre impulsos
var control_vuelo_melones := 700.0    # px/s² para igualar el avance del jugador
var primer_melon_camino_x := 1000.0
var separacion_melones := Vector2(1000, 1500)
var prob_pareja_melones := 0.3        # a veces llegan dos juntos, para encadenar slams
# Carácter de cada rival. peso: qué tan seguido sale (los tontos abundan al inicio y los
# listos al final, ver GeneradorTerreno._elegir_tipo_melon). cara: índice en caras, solo
# para los melones del camino. ritmo: multiplica su rapidez. pausa_saltos: multiplica la
# espera entre saltos. tropiezos: frenones por segundo. sigue_aire: sube tras el jugador.
# esquiva: probabilidad de apartarse la primera vez que un picado lo apunta.
# margen_slam: multiplica la tolerancia del slam (más = más fácil de acertar).
var tipos_melones: Dictionary = {
	"tonto": {"peso": 3.0, "cara": 2, "ritmo": 0.85, "pausa_saltos": 0.6, "tropiezos": 0.35,
		"sigue_aire": false, "esquiva": 0.0, "margen_slam": 1.5},
	"normal": {"peso": 4.0, "cara": 1, "ritmo": 1.0, "pausa_saltos": 1.0, "tropiezos": 0.0,
		"sigue_aire": true, "esquiva": 0.0, "margen_slam": 1.0},
	"listo": {"peso": 2.0, "cara": 3, "ritmo": 1.12, "pausa_saltos": 1.6, "tropiezos": 0.0,
		"sigue_aire": true, "esquiva": 0.5, "margen_slam": 0.85},
}
var tropiezo_melones := 0.7           # s frenado en cada tropiezo de un tonto
var esquiva_melones := Vector2(300, 380)  # px/s: empujón hacia un lado y saltito al esquivar
var separacion_pareja_melones := Vector2(200, 300)

# --- Aterrizaje --------------------------------------------------------------
var aire_min_aterrizaje := 0.15      # s en el aire para contar como caída
var lado_acc_freno := 0.72           # multiplica la velocidad al caer del lado del accesorio
var lado_acc_giro := 6.0             # giro aleatorio extra (rad/s)
var umbral_perder_acc := 520.0       # impacto que tira el accesorio
var lado_redondo_conserva := 0.98    # fracción de velocidad conservada al caer redondo
var caida_a_rodado := 0.2             # parte del impacto que se vuelve rodado hacia adelante
var invulnerable_tras_golpe := 0.6
# Raspón: una caída entre raspon_desde * umbral_caida y umbral_caida quita una
# fracción de golpe que crece con el impacto, hasta raspon_max.
var raspon_desde := 0.6
var raspon_max := 0.35

# --- Público -----------------------------------------------------------------
var publico_rango := 165.0
var empuje_base := 240.0
var empuje_por_carisma := 0.08       # +8% de empuje por punto de carisma
var empuje_dir := Vector2(1.0, -0.55)
var empuje_cansancio := 0.75         # cada empujón de la misma carrera vale 75% del anterior

# --- Ruta aérea --------------------------------------------------------------
var primer_papalote_x := 600.0
var separacion_papalotes := Vector2(950.0, 1250.0)
var altura_papalotes := Vector2(380.0, 3300.0)
var papalote_rango := 185.0
var papalote_elevacion := 1180.0
var papalote_avance := 850.0         # velocidad horizontal mínima al recibir el impulso
var zonas_cielo: Array = [
	{"nombre": "Tejados de Xallitic", "metros": 60.0},
	{"nombre": "Niebla de Xalapa", "metros": 140.0},
	{"nombre": "Viento del Macuiltépetl", "metros": 240.0},
]
var aplausos_por_metro_altura := 1.0
# Premios a alturas de salto, papalote y vuelo con accesorios.
var franjas_premios_aire: Array = [Vector2(500, 800), Vector2(1100, 1500), Vector2(1900, 2300), Vector2(2800, 3300)]
var separacion_premios_aire := Vector2(1400.0, 2000.0)

# --- Obstáculos e impulsores -------------------------------------------------
# plano: se inclina con el suelo. Las medidas y formas viven en mundo/obstaculos.
var obstaculos: Dictionary = {
	"coladera": {"plano": true}, "charco": {"plano": true},
	"puesto": {"plano": false}, "poste": {"plano": false},
	"banqueta": {"plano": true}, "rampa": {"plano": true}, "toldo": {"plano": false},
}
var pesos_obstaculos: Dictionary = {
	"coladera": 3.0, "charco": 3.0, "puesto": 2.0, "poste": 2.0,
	"banqueta": 1.5, "rampa": 2.0, "toldo": 2.0,
}
var coladera_freno := 0.65
var charco_freno := 0.75
var puesto_freno := 0.6
var poste_freno := 0.65
var banqueta_freno := 0.85
var banqueta_salto := 220.0
var rampa_impulso := 280.0
var rampa_angulo := 35.0             # grados sobre la rampa
var toldo_rebote := 0.9
var toldo_avance := 160.0            # impulso horizontal solo al caer sobre el toldo

# --- Pájaros -----------------------------------------------------------------
# Vuelan contra el melón por encima de la calle (mundo/obstaculos/pajaro.gd).
# Chocar con uno le quita velocidad; cada pájaro estorba una sola vez.
var primer_pajaro_x := 1800.0
var separacion_pajaros := Vector2(1000.0, 1700.0)
var altura_pajaros := Vector2(110.0, 750.0)   # px sobre la calle
var prob_bandada := 0.35             # probabilidad de que llegue otro pájaro detrás
var pajaro_vel := 150.0              # px/s hacia la izquierda
var pajaro_freno := 0.55             # multiplica la velocidad del melón

# --- Terreno -----------------------------------------------------------------
var semilla_terreno := -1            # fija un número para repetir una ruta en pruebas
var paso_puntos := 40.0
var largo_tramo := 2400.0
var generar_adelante := 3500.0       # px de terreno listos por delante
var borrar_atras := 2500.0
# Primer tramo: calle empedrada plana, al pie del trampolín.
var calle_inicio_x := 40.0
var casas_inicio_x := -800.0         # origen del sorteo de casas del primer tramo; moverlo cambia cada ruta
var calle_fin_x := 2800.0
var calle_y := 260.0                 # el borde del trampolín está en y = 0
var inicio_obstaculos_x := 900.0
# Todo el camino después del lanzamiento es plano.
# Dificultad del camino según la distancia: 0 al inicio, 1 desde dificultad_metros.y.
# Los obstáculos se juntan conforme avanza la carrera.
var dificultad_metros := Vector2(50.0, 800.0)
var obstaculos_holgura := 1.6        # multiplica la separación de obstáculos con dificultad 0
var prob_empedrado := 0.5
var separacion_obstaculos := Vector2(280, 560)
var separacion_publico := Vector2(380, 750)
var separacion_aplausos := Vector2(700, 1000)
var altura_aplausos := Vector2(55, 125)
var prob_casas := 0.6

# Letreros de distancia cada tantos metros. Donde hay una postal no se pone
# letrero, porque la postal ya muestra el nombre del lugar.
var marcador_cada_m := 50
var lugares: Dictionary = {}          # metros -> nombre; se llena con las postales al iniciar

# Ruta de fantasía, medida desde el borde del trampolín. Los huecos entre postales
# de Xalapa se reservan para añadir lugares sin mover la meta ni los guardados.
var salida_xalapa_m := 1200.0
var costa_m := 2300.0
var meta_m := 2600.0
var nombre_meta := "Centro Universitario de la Costa"
var institucion_meta := "Universidad de Guadalajara"

# --- Fin del intento ---------------------------------------------------------
var velocidad_min_avance := 25.0   # por debajo de 2.5 m/s ya casi no rueda
var tiempo_sin_avance := 1.6
var espera_fin := 1.8

# --- Economía ----------------------------------------------------------------
var aplausos_iniciales := 0
var aplausos_por_metro := 0.5
var aplausos_por_carisma := 8
var valor_aplauso_suelto := 5
# costo = costo_base * crecimiento^nivel
var orden_mejoras: Array = ["fuerza", "resistencia", "rebotes"]
var mejoras: Dictionary = {
	"fuerza": {"nombre": "Fuerza de lanzamiento", "costo_base": 250, "crecimiento": 1.45, "max": 6},
	"resistencia": {"nombre": "Resistencia del melón", "costo_base": 220, "crecimiento": 1.5, "max": 5},
	"rebotes": {"nombre": "Rebotes impulsados", "costo_base": 300, "crecimiento": 1.5, "max": 5},
}
var fuerza_por_nivel := 0.2         # +20% de velocidad de salida
var resistencia_por_nivel := 1
var rebotes_por_nivel := 1
# Salsa Valentina: se compra en el taller y revive al melón si se rompe o se detiene.
# Se muestra en la tiendita y el almanaque con la imagen de Poder.TEXTURAS.
var poderes_tienda: Dictionary = {
	"valentina": {"nombre": "Salsa Valentina", "descripcion": "Revive al melón si se rompe o se detiene.", "color": Color("b8261a"), "duracion": 0.0},
}
var valentina_costo := 350
var valentinas_max := 3
var valentina_invulnerable := 2.0    # s sin daño después de revivir
var valentina_impulso := Vector2(750.0, -650.0)  # velocidad mínima al revivir

# --- Apariencia ---------------------------------------------------------------
# Solo cambia el dibujo, nunca el peso ni la colisión.
# Para añadir una opción, agrega su entrada aquí y su dibujo en melon/aspecto.gd
# (busca el id en el match correspondiente). Los índices se guardan, así que
# agrega siempre al final de cada lista.
var pieles: Array = [
	{"id": "clasico", "nombre": "Verde de mercado", "cuerpo": Color("a6cc62"), "rayas": Color("48743e")},
	{"id": "cantalupo", "nombre": "Cantalupo", "cuerpo": Color("eebd77"), "rayas": Color("a6754d")},
	{"id": "niebla", "nombre": "Niebla xalapeña", "cuerpo": Color("c6dfda"), "rayas": Color("598c89")},
	{"id": "bugambilia", "nombre": "Bugambilia", "cuerpo": Color("dc8eaa"), "rayas": Color("88475e")},
	{"id": "cafe", "nombre": "Café tostado", "cuerpo": Color("c49a73"), "rayas": Color("644d3b")},
	{"id": "noche", "nombre": "Noche en Xallitic", "cuerpo": Color("7988b2"), "rayas": Color("3b446b")},
	{"id": "sandia", "nombre": "Sandía de feria", "cuerpo": Color("4f8f45"), "rayas": Color("1f4d2a")},
	{"id": "dorado", "nombre": "Melón dorado", "cuerpo": Color("e9c84f"), "rayas": Color("9c7a1f")},
]
var patrones: Array = [
	{"id": "rayas", "nombre": "Rayas de melón"}, {"id": "lunares", "nombre": "Lunares"},
	{"id": "red", "nombre": "Red de cantalupo"}, {"id": "zigzag", "nombre": "Zigzag de sarape"},
	{"id": "franjas", "nombre": "Franjas"}, {"id": "liso", "nombre": "Liso"},
]
var caras: Array = [
	{"id": "sonrisa", "nombre": "Contento"}, {"id": "valiente", "nombre": "Valiente"},
	{"id": "dormido", "nombre": "Con sueño"}, {"id": "lentes", "nombre": "Con lentes"},
	{"id": "susto", "nombre": "¡Ay, nanita!"}, {"id": "guino", "nombre": "Guiño"},
	{"id": "lengua", "nombre": "Travieso"}, {"id": "enamorado", "nombre": "Enamorado"},
	{"id": "sin_cara", "nombre": "Sin cara"},
]
var detalles: Array = [
	{"id": "ninguno", "nombre": "Sin detalle"}, {"id": "mejillas", "nombre": "Mejillas chapeadas"},
	{"id": "pecas", "nombre": "Pecas"}, {"id": "bigote", "nombre": "Bigote de charro"},
	{"id": "curita", "nombre": "Curita"}, {"id": "brillo", "nombre": "Brillo recién lavado"},
]
var estelas: Array = [
	{"id": "ninguna", "nombre": "Sin estela", "color": Color.TRANSPARENT},
	{"id": "papel", "nombre": "Papel de fiesta", "color": Color("d86b51")},
	{"id": "flores", "nombre": "Pétalos", "color": Color("cf75a1")},
	{"id": "niebla", "nombre": "Niebla", "color": Color("c3ded7")},
	{"id": "cafe", "nombre": "Granos de café", "color": Color("77503b")},
]
# Dibujo libre sobre el melón (en unidades del radio).
var colores_dibujo: Array = [Color("253e32"), Color.WHITE, Color("cf5142"), Color("f1ce67"),
	Color("467d88"), Color("dc80a6"), Color("7a4fa0"), Color("e98a3c")]
var grosor_dibujo := Vector2(0.03, 0.3)    # mínimo y máximo del pincel
var max_trazos := 300
var max_puntos_dibujo := 6000


# --- Poderes del camino ------------------------------------------------------
# Se activan al recogerlos (mundo/ayudas/poder.gd). Su efecto está en
# Melon.recibir_poder(). Los accesorios, en cambio, se usan con 1, 2 y 3.
var orden_poderes: Array = ["chile", "cafe", "pizza"]
var poderes: Dictionary = {
	"chile": {"nombre": "Chile jalapeño", "descripcion": "Explota y te lanza hacia adelante.", "color": Color("4f9a3a"), "duracion": 0.0, "impulso": Vector2(900, -320)},
	"cafe": {"nombre": "Café de Coatepec", "descripcion": "Energía ilimitada: saltas todo lo que quieras sin gastar cargas durante 4 s.", "color": Color("a56d43"), "duracion": 4.0, "impulso": Vector2.ZERO},
	"pizza": {"nombre": "Pizza con yogur", "descripcion": "Te subes a una pizza que avanza unos metros sin perder altura.", "color": Color("f1ce67"), "duracion": 2.5, "impulso": Vector2.ZERO},
}
var chile_vel_min := 1100.0          # px/s hacia adelante tras la explosión, como mínimo
var cafe_bloqueo := 0.18             # s entre saltos mientras dura el café
var pizza_vel := 1000.0              # px/s hacia adelante sobre la pizza, como mínimo
var primer_poder_x := 700.0
var separacion_poderes := Vector2(950.0, 1400.0)
var altura_poderes := Vector2(70.0, 150.0)   # los más bajos se tocan rodando
# Rescates: si el melón va mal un rato (lento en el suelo o sin cargas de salto),
# aparece por delante el poder que le hace falta, a ras de calle.
var rescate_velocidad := 450.0       # px/s; por debajo, rodando, cuenta como lento
var rescate_tras := 0.5              # s seguidos en apuros antes del rescate
var rescate_espera := 7.0            # s mínimos entre rescates
var rescate_altura := 45.0           # px sobre el suelo; se alcanza sin saltar
var rescate_distancia := Vector2(160.0, 1100.0)  # px por delante, según la velocidad
var bonus_postal := 60

# --- Postales (pasaporte) -----------------------------------------------------
# Ruta de fantasía. Las distancias son del juego, no distancias de la ciudad.
# Las fotografías se asignan por id en recursos/arte_xalapa.tres y solo aparecen
# al terminar el intento. Los lugares no generan edificios ni fotos en el camino.
var postales: Array = [
	{"id": "xallitic", "nombre": "Xallitic", "metros": 0, "nota": "En 1778 se hicieron obras para conducir agua de este barrio hacia la Plaza del Rey."},
	{"id": "juarez", "nombre": "Parque Juárez", "metros": 150, "nota": "El parque ocupa el lugar donde estuvo un convento franciscano del siglo XVI."},
	{"id": "lagos", "nombre": "Paseo de los Lagos", "metros": 300, "nota": "En 1837 se solicitó construir un dique para aprovechar el agua del río Santiago en una fábrica textil."},
	{"id": "aguila", "nombre": "El Águila", "metros": 450, "nota": "La escultura se colocó en 1926, antes de que existiera la Universidad Veracruzana. La UV celebró su centenario en 2026."},
	{"id": "fei", "nombre": "Facultad de Estadística e Informática", "metros": 600, "nota": "La FEI inició en 1966 con Técnico en Estadística. Aquí estudian Ingeniería en Sistemas y Tecnologías de la Información los integrantes de ListiStar.", "nombre_corto": "FEI · UV"},
	{"id": "macuiltepetl", "nombre": "Cerro de Macuiltépetl", "metros": 750, "nota": "Este cerro es un volcán monogenético, formado durante un solo episodio eruptivo.", "nombre_corto": "Macuiltépetl"},
	{"id": "max", "nombre": "Museo de Antropología de Xalapa", "metros": 900, "nota": "El MAX tiene antecedentes desde 1937. Su edificio actual se construyó en los años ochenta y conserva esculturas olmecas.", "nombre_corto": "MAX"},
	{"id": "experimental", "nombre": "Bachilleres Experimental", "metros": 1050, "nota": "Dos integrantes de ListiStar estudiaron en la Escuela de Bachilleres Experimental."},
	{"id": "joya", "nombre": "La Joya", "metros": salida_xalapa_m, "nota": "Esta comunidad de Acajete es conocida por sus quesos artesanales. Elaborarlos y venderlos sostiene a muchas familias de la localidad."},
	{"id": "bosques_perote", "nombre": "Bosques rumbo a Perote", "metros": 1350, "nota": "Los bosques de pinos y oyameles de esta región ayudan a captar y conservar el agua que abastece a poblaciones cercanas."},
	{"id": "cofre_perote", "nombre": "Cofre de Perote", "metros": 1500, "nota": "También se llama Nauhcampatépetl, Cerro de los Cuatro Costados. Es parque nacional desde el 4 de mayo de 1937."},
	{"id": "pico_orizaba", "nombre": "Pico de Orizaba", "metros": 1650, "nota": "Citlaltépetl significa Cerro de la Estrella. Es la montaña más alta de México y conserva una zona glaciar en su parte elevada."},
	{"id": "estrella_puebla", "nombre": "Estrella de Puebla", "metros": 1800, "nota": "Esta rueda de observación alcanza 80 metros de altura y tiene 54 cabinas. Obtuvo un Récord Guinness por su estructura transportable."},
	{"id": "escaleras_tlaxcala", "nombre": "Escaleras eléctricas de Tlaxcala", "metros": 1900, "nota": "La inauguración de estas escaleras en Apizaco, en abril de 2017, se volvió viral y provocó memes en todo México.", "nombre_corto": "Escaleras de Tlaxcala"},
	{"id": "angel", "nombre": "Ángel de la Independencia", "metros": 2000, "nota": "La figura es la Victoria Alada, inspirada en Niké. La columna se inauguró en 1910 para celebrar el centenario de la Independencia."},
	{"id": "teotihuacan", "nombre": "Teotihuacán", "metros": 2100, "nota": "La Pirámide del Sol mide unos 65 metros de altura. Los mexicas dieron su nombre actual a la ciudad siglos después de su construcción."},
	{"id": "monarca", "nombre": "Santuario de la Mariposa Monarca", "metros": 2200, "nota": "Cada otoño, las monarca viajan hasta 4200 kilómetros para pasar el invierno en México. Su reserva es Patrimonio Mundial desde 2008.", "nombre_corto": "Mariposa Monarca"},
	{"id": "costa", "nombre": "Puerto Vallarta", "metros": costa_m, "nota": "Antes se llamaba Las Peñas. En 1918 recibió el nombre de Puerto Vallarta al convertirse en municipio."},
	{"id": "cucosta", "nombre": nombre_meta, "metros": meta_m, "nota": "El CUCosta nació en 1994. Sus primeras carreras fueron Turismo, Administración, Contaduría y Derecho.", "nombre_corto": "CUCosta · UdeG"}
]


func _init() -> void:
	_cargar_accesorios()


func _ready() -> void:
	for postal in postales:
		lugares[postal["metros"]] = postal["nombre"]


## Crea una instancia de cada archivo de CARPETA_ACCESORIOS y los ordena.
func _cargar_accesorios() -> void:
	for archivo in ResourceLoader.list_directory(CARPETA_ACCESORIOS):
		if not archivo.ends_with(".gd") or archivo == "accesorio.gd":
			continue
		var acc = (load(CARPETA_ACCESORIOS + archivo) as GDScript).new()
		if not acc is Accesorio:
			push_warning("%s no extiende Accesorio" % archivo)
			continue
		if acc.id == "":
			acc.id = archivo.get_basename()
		accesorios[acc.id] = acc
	orden_accesorios = accesorios.keys()
	orden_accesorios.sort_custom(func(a: String, b: String) -> bool:
		return [accesorios[a].orden, a] < [accesorios[b].orden, b])
	accesorios_iniciales = orden_accesorios.filter(func(id: String) -> bool: return accesorios[id].inicial)
