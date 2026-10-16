# ¡Rueda, Melón!

Un juego de lanzamiento y rebotes por una Xalapa de fantasía. Preparas tu melón en el taller, sales del puente de Xallitic y eliges entre rodar por las calles o encadenar saltos y papalotes sobre la ciudad.

## Abrir en Godot

Probado con Godot 4.6.1. Importa `project.godot` y presiona F5. El taller ya es la escena inicial. No necesita plugins, paquetes ni imágenes descargadas.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

La resolución de diseño es 1280 × 720, con ventana redimensionable desde 960 × 540, escalado `canvas_items` y física a 120 pasos por segundo. Las acciones ya están declaradas en Proyecto > Configuración del proyecto > Mapa de entradas. Las capas tienen nombre en Capas 2D de física.

## Qué puedes hacer

- Elegir tres tamaños, ponerle nombre al melón y combinar ocho pieles, colores propios para cuerpo y rayas, seis patrones, nueve caras, seis detalles y cinco estelas. Los cambios de apariencia son gratuitos y no cambian la física.
- Dibujar sobre el melón en la pestaña Dibujo: pincel con ocho colores o uno libre, grosor ajustable, goma (también con clic derecho), deshacer (Ctrl+Z) y borrar todo. El dibujo gira con el melón durante la carrera y se guarda solo.
- Equipar hasta tres de ocho accesorios. El rebozo permite planear, la flor recupera resistencia y atrae aplausos, y la jarana impulsa y añade un rebote. Los accesorios originales siguen disponibles.
- Comprar mejoras permanentes de fuerza, resistencia y rebotes con los aplausos de cada carrera.
- Completar ocho postales del pasaporte. Cada lugar nuevo da 60 aplausos una sola vez.
- Guardar automáticamente el aspecto, el equipo, las compras, el récord y el pasaporte entre sesiones.

## Controles

| Entrada | Acción |
| --- | --- |
| Espacio dos veces | Fijar ángulo y luego fuerza de lanzamiento |
| Espacio durante la carrera | Saltar desde el suelo o dar un salto aéreo, consume un impulso |
| Espacio antes de tocar suelo | Rebote impulsado cuando el aro esté verde |
| Flechas izquierda y derecha, o A y D | Mover y rotar en el aire |
| 1, 2 y 3 | Consumir el accesorio del espacio correspondiente |
| E | Activar un papalote cercano o pedir un empujón al público |
| Esc o P | Pausar y continuar |
| Tab, flechas y Enter | Recorrer y activar los controles del taller |

La zona de fuerza perfecta está entre 80 % y 100 %. Empiezas con dos rebotes impulsados y puedes pulsar Espacio hasta 0.26 segundos antes de tocar suelo. Caer sobre el lado redondo conserva velocidad. Los accesorios tienen colisión propia y pueden frenar o caerse al aterrizar sobre ellos. Usarlos consume su carisma durante esa carrera. Vuelven a estar equipados en el siguiente intento.

## Ruta aérea

Los papalotes grandes de colores están entre 38 y 78 metros sobre la calle. Los aplausos en diagonal indican la subida. Acércate y pulsa E cuando aparezca el aro y el aviso de impulso. Cada papalote eleva al melón, recupera una carga hasta su máximo y protege la siguiente caída fuerte. Solo puedes usarlo una vez por carrera.

Espacio permite corregir una caída con un salto aéreo. Comparte cargas con los rebotes del suelo. A y D ajustan la velocidad horizontal además del giro, así puedes acercarte a un papalote o frenar antes de pasarlo. El HUD muestra la altura y los papalotes usados, y cambia el aviso según la acción disponible. La cámara anticipa el vuelo y la ciudad baja en el fondo al ganar altura.

## Poderes del camino

Se activan al recogerlos y tienen siluetas diferentes. Aparecen cada 200 a 300 metros, alternados y por encima del camino. Hay que aprovechar un salto, un rebote o un accesorio para alcanzarlos.

| Poder | Efecto |
| --- | --- |
| Café de altura | Impulso breve y aceleración durante 2 segundos |
| Chile xalapeño | Embestida, rompe puestos y protege de golpes durante 1.5 segundos |
| Niebla de Xalapa | Protege de golpes y del frenado de obstáculos durante 3 segundos |
| Tamal de hoja | Recupera un punto de resistencia y un rebote hasta su máximo. Conserva los rebotes extra de la jarana |

## Escenas y nodos

Las tres pantallas tienen su estructura estable en archivos `.tscn`. Las listas de opciones y el terreno infinito se generan durante la partida.

```text
escenas/
  Taller.tscn                 Vista previa, pestañas y pie con balance
  Recorrido.tscn
	Paisaje                   Instancia del fondo con paralaje
	Mundo
	  Puente                  Instancia con cuerpo estático y calzada
	  Terreno                 Contenedor de los tramos generados
	  Melon                   Instancia del cuerpo físico
	Camara                    Cámara con seguimiento
	Efectos                   Flecha y avisos del recorrido
	Interfaz                  Instancia de HUD.tscn
  Resultados.tscn              Desglose de la carrera y regreso al taller
  Melon.tscn                  Cuerpo, tres colisiones de accesorios y estela
  interfaz/
	HUD.tscn                  Datos, lanzamiento, efectos, ayuda y menú de pausa
  mundo/
	Tramo.tscn                Suelo, Decoracion, Postales, Obstaculos,
							  Publico, Coleccionables y Aire
	Paisaje.tscn              Cielo, cerros, ciudad y niebla dibujados por capas
							  Ilustración opcional. Fondo dibujado sin imagen.
							  Nodos Cielo, Sol, NubesAltas, NubesCercanas,
							  Bandadas y Papalotes
	Puente.tscn               Puente de salida con colisión independiente
	Postal.tscn               Monumento o lugar del recorrido
	Poder.tscn                Area2D, zona de recogida y etiqueta
	Papalote.tscn             Impulso aéreo con E, recarga y protección
	Obstaculo.tscn            Área de interacción y colisión de las rampas
	Publico.tscn              Persona que puede empujar una vez
	obstaculos/               Ocho variantes heredadas con colisiones editables
```

`Config` y `Juego` son los únicos autoloads. `scripts/config.gd` reúne los valores de física, economía, opciones de apariencia, accesorios, poderes y postales. `scripts/juego.gd` conserva el estado y calcula las recompensas. Cada componente tiene un script propio, salvo el puente, cuya geometría está hecha con nodos editables. `recursos/tema_xalapa.tres` controla el aspecto de los menús y `recursos/icono.svg` es el icono del proyecto.

### Añadir un accesorio

Cada accesorio es un archivo en `scripts/accesorios/` que extiende `Accesorio` (`scripts/accesorios/accesorio.gd`). `Config` carga todos los archivos de esa carpeta al iniciar, así que no hay listas que actualizar en otro lado:

1. Copia un accesorio parecido, por ejemplo `sombrero.gd`, con el nombre del nuevo id (`maraca.gd`).
2. En `_init()` define `nombre`, `carisma`, `accion`, `costo`, `orden`, `color`, `forma` e `inicial`.
3. En `usar(m)` combina los efectos de `Melon`: `planear`, `embestir`, `caida_lenta`, `rodar`, `proteger`, `reparar`, `atraer_aplausos`, `sumar_rebote`, `empujar` y `fijar_velocidad`.
4. Si necesita física propia durante unos segundos, llama a `m.activar(self, segundos)` y escribe `fisica(m, v, dt)`. El HUD muestra su tiempo restante solo.
5. Para un dibujo especial escribe `dibujar_detalle()` o reemplaza `dibujar()`, como hace el paraguas.

### Añadir opciones de aspecto

Pieles, patrones, caras, detalles y estelas son listas en `Config`. Agrega la entrada al final de su lista (los índices se guardan) y su dibujo en el `match` correspondiente de `scripts/aspecto.gd`. El taller crea las opciones solo. La pestaña Dibujo vive en `escenas/interfaz/PanelDibujo.tscn` con `scripts/panel_dibujo.gd`; los colores rápidos y los límites de trazos están en `Config.colores_dibujo`, `grosor_dibujo`, `max_trazos` y `max_puntos_dibujo`.

Las capas de física son 1 para terreno, 2 para melón y 3 para recogibles y obstáculos. El melón solo colisiona con terreno. Las áreas detectan al melón. Cada segmento del suelo tiene una colisión convexa con nombre `Segmento###`.

Para cambiar el terreno, ajusta `formas_tramo`, `largo_tramo`, `semilla_terreno` y las separaciones en `Config`. La semilla fija permite practicar la misma ruta. Las rampas y los toldos dan impulso una sola vez por carrera. El toldo devuelve parte de la velocidad de caída; no relanza un melón lento a una velocidad mínima. Para cambiar un lugar, edita sus datos en `postales` y su dibujo en `scripts/postal.gd`. El tipo de poder se puede seleccionar desde el inspector de `Poder.tscn`.

En `Paisaje.tscn`, cada capa del cielo tiene un nodo independiente. Puedes ocultar el sol, las bandadas o los papalotes del fondo, y ajustar `separacion`, `velocidad` y `paralaje` desde el inspector. Esas capas son decorativas. Los papalotes jugables viven en `Papalote.tscn` y el contenedor `Aire` de cada tramo. Sus alturas, separación e impulso se ajustan en `Config`. La generación aérea usa su propio azar para conservar la ruta del suelo.

El melón pierde velocidad por el aire y por el rodado. La bajada inicial es menos pronunciada que en el primer prototipo. Si el avance cae por debajo de 2.5 metros por segundo durante 1.6 segundos, termina el intento. No hay un temporizador que castigue dejar de pulsar botones.

## Arte y sustitución de recursos

El pasaporte y las postales de resultados también usan fotografías reales de Xallitic, la Catedral de Xalapa, la vista del Pico de Orizaba desde Parque Juárez y Los Lagos. Están en `recursos/fotos/`, con sus autores, fuentes y licencias Creative Commons en `recursos/fotos/README.md`. Cada foto muestra sus créditos y enlaces dentro del juego. No necesitan conexión para verse.

Las entradas de `fotografias` en `recursos/arte_xalapa.tres` permiten sustituir o quitar las fotos sin tocar los scripts. Al vaciar ese diccionario, los resultados usan la ilustración del puente y el pasaporte conserva su contenido. El fondo fotográfico del recorrido se controla por separado con `paisaje`.

El taller muestra una ilustración vectorial de Xallitic en `recursos/taller_xallitic.svg`. También aparece en los resultados cuando no hay una foto del lugar. El tema compartido usa verde tinta, papel crema y botones coral, con títulos redondeados. El HUD muestra cada accesorio con su dibujo y tecla, y marca la zona perfecta en el medidor.

El fondo del recorrido es una fotografía real de Xalapa desde el Ágora, de Koffermejia, con licencia CC BY-SA 4.0. Se incluye en `recursos/fotos/panorama_xalapa.jpg`. `paisaje` usa un AtlasTexture para excluir los bordes vacíos de la panorámica y conserva sus proporciones. Los créditos y enlaces aparecen en el menú de pausa. La imagen generada anterior ya no se carga.

Para sustituir el fondo, cambia `paisaje` y actualiza `credito_paisaje` en `recursos/arte_xalapa.tres`. Para quitarlo, vacía `paisaje` y guarda el recurso. El recorrido recupera los fondos dibujados por código. Los autores y licencias están en `recursos/fotos/README.md`.

El personaje y sus accesorios siguen dibujados por código en `Aspecto.dibujar_melon` y `scripts/accesorios/`. El tema compartido de botones, pestañas, menús y medidor está en `recursos/tema_xalapa.tres`.

La revisión gráfica usa una ventana con render real y no modifica el progreso. Comprueba los límites de los controles y guarda capturas de todas las pestañas y pantallas en `user://revision_grafica/`, a 1280 × 720 y a 960 × 540. Incluye la fuerza de lanzamiento, los espacios de accesorios vacíos, un resultado con todas las recompensas y el modo sin fotografías.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/graficos.gd
```

## Guardado

El juego escribe `user://progreso.json` mediante un archivo temporal. En macOS la carpeta es `~/Library/Application Support/RuedaMelon/`. Puedes abrirla desde Proyecto > Abrir carpeta de datos del usuario. El cargador limita índices y niveles, y descarta accesorios o postales desconocidos. El dibujo libre se guarda en unidades del radio, así sirve con cualquier tamaño; los trazos dañados se descartan y los puntos se limitan al melón.

Si un archivo no se puede leer, el juego lo respalda con sufijo `.danado` antes de escribir otro. Si el guardado falla, el taller muestra el error. Al abandonar una carrera desde la pausa no se cobran sus recompensas. Las compras y la personalización anteriores ya están guardadas.

## Verificación

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/verificar.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/balance.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/vuelo.gd
```

La segunda orden comprueba entradas, compras, desbloqueos, premios sin duplicados, persistencia, datos inválidos, poderes, accesorios, pausa y una carrera real completa hasta volver al taller. Utiliza un archivo de prueba separado y lo borra al terminar. No modifica tu progreso.

`balance.gd` comprueba 54 carreras sin input después del lanzamiento, con tres tamaños, tres ángulos, tres semillas y mejoras iniciales o al máximo. Todas deben terminar en menos de 30 segundos, recoger como máximo tres poderes y quedarse antes del 80 % de la última postal. También compara una carrera sin controles con otra que usa rebotes, accesorios y empujones. Comprueba que un lanzamiento al 70 %, con equipo inicial y controles, avance al menos 400 metros sin mejoras. Por último, mide la progresión media con tres semillas y verifica que las mejoras al máximo permitan alcanzar la última postal. Utiliza su propio archivo de prueba.

`vuelo.gd` comprueba el consumo y bloqueo de saltos, el alcance de E, el uso único de cada papalote y la recarga sin perder las cargas extra de la jarana. También recorre la ruta aérea con tres tamaños y tres semillas, sin mejoras ni accesorios, y mide los papalotes encadenados, la altura y el tiempo sobre la ciudad. Usa un guardado de prueba separado.

## Xalapa en el juego

La ruta incluye Xallitic, Callejón del Diamante, Catedral de Xalapa, Parque Juárez, Los Berros, Los Lagos, zona universitaria y Macuiltépetl. Los dibujos son interpretaciones y la ruta no representa un mapa ni distancias reales. Los poderes también son ficción del juego.

Referencias de lugares: [archivo del Callejón del Diamante de la UV](https://fciuv.uv.mx/index.php/callejon-del-diamante?listLimit=10&sort=alphabetic&sortDir=asc&subjects=976), [USBI Xalapa](https://www.uv.mx/usbi/como-llegar/) y [ruta universitaria que pasa por Los Lagos y la USBI](https://www.uv.mx/daduv/files/2024/08/Ruta-Xalapa-Ajuste-29-AGO-2024.pdf).
