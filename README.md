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
pantallas/       Las tres pantallas del juego
  taller/          Preparar el melón: aspecto, dibujo, accesorios, mejoras y pasaporte
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

El pasaporte y las postales de resultados también usan fotografías reales de Xallitic, la Catedral de Xalapa, la vista del Pico de Orizaba desde Parque Juárez y Los Lagos. Están en `recursos/fotos/`, con sus autores, fuentes y licencias Creative Commons en `recursos/fotos/README.md`. Cada foto muestra sus créditos y enlaces dentro del juego. No necesitan conexión para verse.

Las entradas de `fotografias` en `recursos/arte_xalapa.tres` permiten sustituir o quitar las fotos sin tocar los scripts. Al vaciar ese diccionario, los resultados usan la ilustración del puente y el pasaporte conserva su contenido. El fondo fotográfico del recorrido se controla por separado con `paisaje`.

El taller muestra una ilustración vectorial de Xallitic en `recursos/taller_xallitic.svg`. También aparece en los resultados cuando no hay una foto del lugar. El tema compartido usa verde tinta, papel crema y botones coral con relieve, y la fuente Fredoka incluida en `recursos/fuentes/` (licencia OFL) para verse igual en cualquier sistema. El HUD muestra cada accesorio con su dibujo y tecla, y marca la zona perfecta en el medidor.

El fondo del recorrido es una fotografía real de Xalapa desde el Ágora, de Koffermejia, con licencia CC BY-SA 4.0. Se incluye en `recursos/fotos/panorama_xalapa.jpg`. `paisaje` usa un AtlasTexture para excluir los bordes vacíos de la panorámica y conserva sus proporciones. Los créditos y enlaces aparecen en el menú de pausa.

Para sustituir el fondo, cambia `paisaje` y actualiza `credito_paisaje` en `recursos/arte_xalapa.tres`. Para quitarlo, vacía `paisaje` y guarda el recurso. El recorrido recupera los fondos dibujados por código. Los autores y licencias están en `recursos/fotos/README.md`.

El personaje y sus accesorios siguen dibujados por código en `melon/aspecto.gd` y `melon/accesorios/`. El tema compartido de botones, pestañas, menús y medidor está en `interfaz/tema_xalapa.tres`.

Los cuatro poderes usan imágenes 3D provisionales de Microsoft Fluent Emoji, incluidas en `recursos/poderes/` con licencia MIT. Se muestran en la ruta y en el pasaporte sin conexión. Las fuentes y la forma de cambiarlas están en [recursos/poderes/README.md](recursos/poderes/README.md).

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
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/distribucion.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/rendimiento.gd
```

La segunda orden comprueba entradas, compras, desbloqueos, premios sin duplicados, persistencia, datos inválidos, poderes, accesorios, pausa y una carrera real completa hasta volver al taller. Utiliza un archivo de prueba separado y lo borra al terminar. No modifica tu progreso.

`balance.gd` comprueba 54 carreras sin input después del lanzamiento, con tres tamaños, tres ángulos, tres semillas y mejoras iniciales o al máximo. Todas deben terminar en menos de 30 segundos, recoger como máximo tres cafés o chiles y quedarse antes del 80 % de la última postal. También compara una carrera sin controles con otra que usa rebotes, accesorios y empujones. Comprueba que un lanzamiento al 70 %, con equipo inicial y controles, avance al menos 400 metros sin mejoras. Por último, mide la progresión media con tres semillas. Sin mejoras, las carreras con controles básicos deben promediar menos de novecientos metros. Las mejoras deben superar el alcance inicial y, al máximo, permitir un promedio de al menos mil metros. Utiliza su propio archivo de prueba.

`vuelo.gd` comprueba el consumo y bloqueo de saltos, el alcance de E y el uso único de cada ayuda sin recargar saltos ni perder las cargas extra de la jarana. También recorre la ruta aérea con tres tamaños y tres semillas, sin mejoras ni accesorios, tanto con D sostenida como sin ella. Exige encadenar al menos dos ayudas, llegar a 140 metros de altura y permanecer seis segundos sobre los 40 metros. Las carreras deben terminar dentro de un minuto y antes de 2500 metros. Repite con el melón mediano y mejoras máximas, con un límite de 3500 metros. Esos límites detectan vuelos que no terminan; no son un tope dentro del juego. Usa un guardado de prueba separado.

`distribucion.gd` revisa seis semillas, las monedas desde el inicio, la frecuencia de poderes, la cobertura de puntos en las cuatro franjas de altura y la variedad de poderes. Limita la densidad a doce monedas por cada mil píxeles de camino y a dieciséis monedas en una vista de 1500 por 1000 píxeles. También comprueba que los premios aéreos no cambien el suelo ni las ayudas, que todos los premios queden dentro de su tramo, que una semilla fija repita la distribución y que los intentos al azar sean diferentes.

`rendimiento.gd` necesita una ventana con render real. Comprueba que el melón conserve una textura con el máximo de seis mil puntos al moverse y girar, que solo la actualice al consumir equipo o romperse y que sus efectos sigan cambiando. La textura se dibuja a doble resolución para conservar los detalles. También comprueba que el fondo conserve su dibujo hasta cambiar de altura o tamaño de ventana. No escribe el progreso del jugador.

## Xalapa en el juego

La ruta incluye Xallitic, Callejón del Diamante, Catedral de Xalapa, Parque Juárez, Los Berros, Los Lagos, zona universitaria y Macuiltépetl. Los dibujos son interpretaciones y la ruta no representa un mapa ni distancias reales. Los poderes también son ficción del juego.

Referencias de lugares: [archivo del Callejón del Diamante de la UV](https://fciuv.uv.mx/index.php/callejon-del-diamante?listLimit=10&sort=alphabetic&sortDir=asc&subjects=976), [USBI Xalapa](https://www.uv.mx/usbi/como-llegar/) y [ruta universitaria que pasa por Los Lagos y la USBI](https://www.uv.mx/daduv/files/2024/08/Ruta-Xalapa-Ajuste-29-AGO-2024.pdf).
