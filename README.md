# ¡Rueda, Melón!

Un juego de lanzamiento y rebotes desde Xalapa hasta el Centro Universitario de la Costa de la Universidad de Guadalajara. Preparas tu melón en el taller y eliges la potencia para soltarlo por la bajada de Xallitic. Rueda solo hasta pasar el puente. Desde ahí puedes rodar por las calles o encadenar saltos y papalotes hasta la meta.

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
- Llegar al CUCosta y completar once lugares del pasaporte. Cada lugar nuevo da 60 aplausos una sola vez.
- Guardar automáticamente el aspecto, el equipo, las compras, el récord y el pasaporte entre sesiones.
- Conservar hasta 24 melones personalizados en el almanaque, con nombre, tamaño, colores, dibujo, estela y equipo. Puedes volver a usarlos, actualizar sus fichas o eliminarlas.
- Consultar un almanaque con cuadrícula de melones, accesorios y poderes. Cada ficha muestra su ilustración y sus datos.

Para guardar una creación, pulsa "Guardar melón en el almanaque" en la pestaña Tu melón. Abre "Almanaque" desde la cabecera del taller para elegirla y pulsa "Usar melón" para volver a editarla o salir a rodar. "Actualizar con el actual" reemplaza la ficha seleccionada con el melón del taller y pide confirmación, igual que eliminar. Guardar dos veces el mismo melón no crea duplicados.

## Objetivo del viaje

La meta está a 2600 metros de juego. Los primeros 1800 metros corresponden a Xalapa. Después sigue el camino entre montañas, la costa aparece a los 2300 metros y el viaje termina al cruzar la meta del CUCosta, incluso en el aire. La barra del HUD muestra el recorrido total y los metros que faltan. Detenerse o romperse sigue terminando el intento.

Una carrera de prueba con mejoras máximas, saltos y papalotes completó el recorrido en 40.7 segundos, sin accesorios. Los intentos cortos permiten ganar aplausos y comprar mejoras para llegar más lejos.

Los intervalos de 350 a 420, 650 a 800, 950 a 1250 y 1450 a 1750 metros quedan libres de lugares para agregar los suyos. Se añaden como entradas de `Config.postales`, ordenadas por metros y con un `id` nuevo. No requieren crear edificios ni escenarios. Su fotografía se asigna con ese mismo `id` en `fotografias` de `recursos/arte_xalapa.tres`.

Las fotos aparecen únicamente como postales al terminar el intento. La postal corresponde al lugar más lejano alcanzado en esa carrera. Si ese lugar aún no tiene foto, no se muestra una imagen de otro sitio ni una ilustración de reemplazo. El pasaporte conserva los nombres y sellos, sin fotos.

## Controles

| Entrada | Acción |
| --- | --- |
| Espacio antes de salir | Fijar la potencia y soltar el melón cuesta abajo |
| Espacio durante la carrera | Saltar desde el suelo o dar un salto aéreo, consume un impulso |
| Espacio antes de tocar suelo | Rebote impulsado cuando el aro esté verde |
| S o flecha abajo en el aire | Slam en picado, rebota y acelera al golpear otro melón |
| Flechas izquierda y derecha, o A y D | Mover y rotar en el aire |
| 1, 2 y 3 | Consumir el accesorio del espacio correspondiente |
| E | Activar un papalote cercano o pedir un empujón al público |
| Esc o P | Pausar y continuar |
| Tab, flechas y Enter | Recorrer y activar los controles del taller |

En la salida esperan seis rivales junto a tu melón. Cada intento toma al azar hasta seis diseños del almanaque sin repetir fichas. Si faltan, completa el grupo con otros melones. Conservan su tamaño, colores, patrón, cara, dibujo y accesorios. La carrera usa copias y no cambia tus fichas guardadas.

El medidor de potencia aparece en la salida de la bajada. Espacio fija el valor, retira la barrera y suelta a todos los melones. Los rivales bajan por dos filas, cruzan el puente y continúan por el camino con ritmos distintos. Todos los rivales salen de esa parrilla. La zona perfecta está entre 80 % y 100 %. Más potencia da más velocidad al llegar a Xalapa. Durante la bajada y el cruce del puente no puedes saltar, girar, usar accesorios ni pedir empujones. La pausa sigue disponible. Al salir del puente recuperas todos los controles de carrera.

Empiezas con dos rebotes impulsados y puedes pulsar Espacio hasta 0.26 segundos antes de tocar suelo. Caer sobre el lado redondo conserva velocidad. Los accesorios tienen colisión propia y pueden frenar o caerse al aterrizar sobre ellos. Usarlos consume su carisma durante esa carrera. Vuelven a estar equipados en el siguiente intento.

## Slam y melones rodantes

Los rivales de la salida avanzan por el suelo durante la carrera. Pulsa S o flecha abajo en el aire para caer en picado. Golpear uno desde arriba te impulsa hacia arriba y añade velocidad hacia delante. Cada melón sirve una sola vez. Si caes al suelo sin acertar, conservas el 60 % de tu velocidad horizontal. El slam no consume saltos, tiene una recarga de 0.45 segundos tras resolverse y bloquea el salto y los papalotes mientras caes. El golpe admite entre 12 y 36 píxeles de margen lateral según la velocidad relativa. A más velocidad, más tolerancia, con ese límite. Los golpes laterales y desde abajo no cuentan. El HUD anticipa dónde estaréis ambos al caer para avisar cuándo conviene pulsar S.

## Ruta aérea

La primera ayuda está a 60 metros de la salida y a 38 metros sobre la calle. Desde ahí, la ruta asciende entre 28 y 40 metros por ayuda hasta llegar a 330 metros de altura. Las ayudas están separadas entre 95 y 125 metros. Cada tercera ayuda es una corriente de niebla, con una silueta distinta del papalote. Acércate y pulsa E cuando aparezca el aro y el aviso de impulso. Ambas ayudan a subir y avanzar, protegen la siguiente caída fuerte y se usan una sola vez por carrera. No regalan saltos. Hay un tamal cerca de la primera ayuda y después cada cuatro ayudas para recuperar una carga.

Las monedas de aplausos aparecen desde la salida en grupos de tres, separados entre 70 y 100 metros. En el cielo hay grupos de dos o tres premios, separados entre 140 y 200 metros en cuatro franjas entre 50 y 330 metros de altura. Alternan filas, arcos y diagonales cortas. Los primeros grupos de cada altura aparecen escalonados para dejar espacio libre. Cada intento genera una distribución distinta. La cámara conserva un zoom mínimo de 0.72 para distinguir las ayudas y al melón.

Espacio permite corregir una caída con un salto aéreo. Comparte cargas con los rebotes del suelo. A y D ajustan la velocidad horizontal además del giro, así puedes acercarte a una ayuda o frenar antes de pasarla. Una flecha señala la siguiente ayuda cuando queda fuera de pantalla. La carrera solo termina por falta de avance después de tocar suelo, aunque el lanzamiento sea casi vertical.

Subir tiene sus propios objetivos. A 60 metros llegas a los Tejados de Xallitic, a 140 a la Niebla de Xalapa y a 240 al Viento del Macuiltépetl. El HUD cambia de objetivo al ganar altura. El fondo conserva la ciudad al principio; después aparecen las capas de nubes y cambia el azul del cielo. Al terminar recibes un aplauso por metro de altura máxima, además de los premios por distancia y recogibles. Bajar y volver a subir no duplica ese bono.

## Poderes del camino

Se activan al recogerlos y tienen siluetas diferentes. El primero aparece a los 70 metros. Después aparecen cada 110 a 160 metros, alternados y por encima del camino. Hay que aprovechar un salto, un rebote o un accesorio para alcanzarlos.

| Poder | Efecto |
| --- | --- |
| Café de altura | Impulso breve y aceleración durante 2 segundos |
| Chile xalapeño | Embestida, rompe puestos y protege de golpes durante 1.5 segundos |
| Niebla de Xalapa | Protege de golpes y del frenado de obstáculos durante 3 segundos |
| Tamal de hoja | Recupera un punto de resistencia y un rebote hasta su máximo. Conserva los rebotes extra de la jarana |

## Estructura del proyecto

Cada carpeta agrupa una parte del juego. Las escenas (`.tscn`) y sus scripts (`.gd`) viven juntos, con nombres en `snake_case`.

```text
globales/        Autoloads: Config (reglas y valores) y Juego (progreso y guardado)
pantallas/       Las pantallas del juego
  taller/          Preparar el melón: aspecto, dibujo, accesorios, mejoras y pasaporte
  almanaque/       Colección de melones y fichas de accesorios y poderes
  recorrido/       La carrera: lanzamiento, cámara, efectos y HUD
  resultados/      Desglose de aplausos y postal del lugar alcanzado
melon/           El melón: física, dibujo, estela y accesorios
  accesorios/      Un archivo por accesorio; se cargan solos
mundo/           Todo lo que aparece en la carrera
  terreno/         Generador del camino, tramos, puente y postales de lugares
  obstaculos/      Escena base y una escena heredada por tipo
  ayudas/          Poderes, papalotes y público que empuja
  paisaje/         Fondo con paralaje y capas del cielo
interfaz/        Tema visual compartido y componentes de interfaz
recursos/        Imágenes, fotografías, fuente, íconos SVG y datos de arte (arte_xalapa.tres)
pruebas/         Scripts de verificación automática
docs/            Documentación técnica
```

La escena inicial es `pantallas/taller/taller.tscn`. El flujo es Taller → Recorrido → Resultados → Taller.

La explicación de cada escena, su árbol de nodos, cómo se comunican y cómo añadir accesorios, opciones de aspecto, obstáculos o postales está en [docs/arquitectura.md](docs/arquitectura.md).

## Arte y sustitución de recursos

Las postales de resultados usan fotografías reales de Xallitic, la Catedral de Xalapa, la vista del Pico de Orizaba desde Parque Juárez y Los Lagos. Están en `recursos/fotos/`, con sus autores, fuentes y licencias Creative Commons en `recursos/fotos/README.md`. Cada foto muestra sus créditos y enlaces dentro del juego. No necesitan conexión para verse. Las fotos de los demás lugares, incluido el CUCosta, quedan pendientes de sus imágenes.

Las entradas de `fotografias` en `recursos/arte_xalapa.tres` permiten sustituir o quitar las fotos sin tocar los scripts. Al vaciar ese diccionario, los resultados ocultan la postal y conservan el resumen del intento.

El taller muestra una ilustración vectorial de Xallitic en `recursos/taller_xallitic.svg`. El tema compartido usa verde tinta, papel crema y botones coral con relieve, y la fuente Fredoka incluida en `recursos/fuentes/` (licencia OFL) para verse igual en cualquier sistema. El HUD muestra cada accesorio con su dibujo y tecla, y marca la zona perfecta en el medidor.

El recorrido usa fondos dibujados de ciudad, montañas y costa. `paisaje` queda vacío para reservar las fotografías a las postales del final. La panorámica de Xalapa desde el Ágora se conserva entre los recursos, con sus créditos en `recursos/fotos/README.md`.

El personaje y sus accesorios siguen dibujados por código en `melon/aspecto.gd` y `melon/accesorios/`. El tema compartido de botones, pestañas, menús y medidor está en `interfaz/tema_xalapa.tres`.

Los cuatro poderes usan imágenes 3D provisionales de Microsoft Fluent Emoji, incluidas en `recursos/poderes/` con licencia MIT. Se muestran en la ruta y en el pasaporte sin conexión. Las fuentes y la forma de cambiarlas están en [recursos/poderes/README.md](recursos/poderes/README.md).

La revisión gráfica usa una ventana con render real y no modifica el progreso. Comprueba los límites de los controles y guarda capturas de todas las pestañas y pantallas en `user://revision_grafica/`, a 1280 × 720 y a 960 × 540. Incluye la fuerza de lanzamiento, los espacios de accesorios vacíos, un resultado con todas las recompensas y el modo sin fotografías.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/graficos.gd
```

## Guardado

El juego escribe `user://progreso.json` mediante un archivo temporal. En macOS la carpeta es `~/Library/Application Support/RuedaMelon/`. Puedes abrirla desde Proyecto > Abrir carpeta de datos del usuario. El cargador limita índices y niveles, y descarta accesorios o postales desconocidos. El dibujo libre se guarda en unidades del radio, así sirve con cualquier tamaño; los trazos dañados se descartan y los puntos se limitan al melón.

La colección vive en ese mismo archivo. Editar o usar un melón no modifica su ficha guardada hasta que la actualices. Las compras, las mejoras, los aplausos y el pasaporte son comunes a todos los melones. Las partidas anteriores siguen cargando con una colección vacía. "Reiniciar progreso" también borra los melones del almanaque.

Si un archivo no se puede leer, el juego lo respalda con sufijo `.danado` antes de escribir otro. Si el guardado falla, el taller muestra el error. Al abandonar una carrera desde la pausa no se cobran sus recompensas. Las compras y la personalización anteriores ya están guardadas.

## Verificación

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/verificar.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/ruta.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/almanaque.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/slam.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/lanzamiento.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/balance.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/vuelo.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/distribucion.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/rendimiento.gd
```

La segunda orden comprueba entradas, compras, desbloqueos, premios sin duplicados, persistencia, datos inválidos, poderes, accesorios, pausa y una carrera real completa hasta volver al taller. Utiliza un archivo de prueba separado y lo borra al terminar. No modifica tu progreso.

`ruta.gd` comprueba los límites del viaje, la llegada por aire, el cierre del terreno y el cobro único de recompensas. También comprueba que cada postal use la foto del lugar alcanzado en ese intento y que no sustituya las fotos pendientes. `vuelo.gd` exige completar al menos una carrera hasta el CUCosta con física real.

`almanaque.gd` comprueba la colección, la independencia de los dibujos guardados, el límite de fichas, la carga de partidas anteriores y la validación de datos dañados. También recorre los botones de guardar, consultar, actualizar, eliminar y usar un melón. Usa un archivo separado y lo borra al terminar. La revisión gráfica incluye el almanaque vacío, la colección, accesorios, poderes y la confirmación de eliminación a ambas resoluciones.

`slam.gd` comprueba aciertos sobre melones en movimiento, impactos entre pasos a gran velocidad, fallos contra el suelo, recarga, pausa y conservación de saltos. También verifica que los melones continúen entre tramos y que la carrera los retire al quedar atrás. Prueba roces, fallos claros y 81 caídas con los tres tamaños, tres velocidades y nueve desfases de puntería. Usa un guardado de prueba separado.

`lanzamiento.gd` comprueba la parrilla con el almanaque vacío y con fichas guardadas, la salida conjunta, las copias independientes, la pausa y la continuidad de los rivales al cruzar el puente. También compara fuerza mínima y máxima con los tres tamaños. Comprueba que más fuerza conserve más velocidad al cruzar el puente y aumente el alcance. Repite la bajada con todas las teclas de carrera pulsadas y verifica que no cambien la trayectoria ni consuman saltos o equipo. También comprueba la pausa y que los controles y las colisiones de accesorios vuelvan después del puente. Usa un guardado de prueba separado.

`balance.gd` comprueba 54 carreras sin input después del lanzamiento, con tres tamaños, tres fuerzas, tres semillas y mejoras iniciales o al máximo. Todas deben terminar en menos de 30 segundos, recoger como máximo tres cafés o chiles y quedarse antes del 80 % de la última postal. También compara una carrera sin controles con otra que usa rebotes, accesorios y empujones. Comprueba que un lanzamiento al 70 %, con equipo inicial y controles, avance al menos 400 metros sin mejoras. Por último, mide la progresión media con tres semillas. Sin mejoras, las carreras con controles básicos deben promediar menos de novecientos metros. Las mejoras deben superar el alcance inicial y, al máximo, permitir un promedio de al menos mil metros. Utiliza su propio archivo de prueba.

`vuelo.gd` comprueba el consumo y bloqueo de saltos, el alcance de E y el uso único de cada ayuda sin recargar saltos ni perder las cargas extra de la jarana. También recorre la ruta aérea con tres tamaños y tres semillas, sin mejoras ni accesorios, tanto con D sostenida como sin ella. Exige encadenar al menos dos ayudas, llegar a 140 metros de altura y permanecer seis segundos sobre los 40 metros. Las carreras deben terminar dentro de un minuto y antes de 2500 metros. Repite con el melón mediano y mejoras máximas, con un límite de 3500 metros. Esos límites detectan vuelos que no terminan; no son un tope dentro del juego. Usa un guardado de prueba separado.

`distribucion.gd` revisa seis semillas, las monedas desde el inicio, la frecuencia de poderes, la cobertura de puntos en las cuatro franjas de altura y la variedad de poderes. Limita la densidad a doce monedas por cada mil píxeles de camino y a dieciséis monedas en una vista de 1500 por 1000 píxeles. También comprueba que los premios aéreos no cambien el suelo ni las ayudas, que todos los premios queden dentro de su tramo, que una semilla fija repita la distribución y que los intentos al azar sean diferentes.

`rendimiento.gd` necesita una ventana con render real. Comprueba que el melón conserve una textura con el máximo de seis mil puntos al moverse y girar, que solo la actualice al consumir equipo o romperse y que sus efectos sigan cambiando. La textura se dibuja a doble resolución para conservar los detalles. También comprueba que el fondo conserve su dibujo hasta cambiar de altura o tamaño de ventana. No escribe el progreso del jugador.

## Xalapa en el juego

La ruta incluye Xallitic, Callejón del Diamante, Catedral de Xalapa, Parque Juárez, Los Berros, Los Lagos, zona universitaria y Macuiltépetl. Continúa hacia Puerto Vallarta y termina en el Centro Universitario de la Costa. El campus pertenece a la Universidad de Guadalajara y está en Puerto Vallarta, según su [ubicación oficial](https://cuc.udg.mx/ubicacion). La ruta y las distancias son de fantasía. Los poderes también son ficción del juego.

Referencias de lugares: [archivo del Callejón del Diamante de la UV](https://fciuv.uv.mx/index.php/callejon-del-diamante?listLimit=10&sort=alphabetic&sortDir=asc&subjects=976), [USBI Xalapa](https://www.uv.mx/usbi/como-llegar/) y [ruta universitaria que pasa por Los Lagos y la USBI](https://www.uv.mx/daduv/files/2024/08/Ruta-Xalapa-Ajuste-29-AGO-2024.pdf).
