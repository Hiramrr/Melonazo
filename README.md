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
recursos/        Imágenes, fotografías, icono y datos de arte (arte_xalapa.tres)
pruebas/         Scripts de verificación automática
docs/            Documentación técnica
```

La escena inicial es `pantallas/taller/taller.tscn`. El flujo es Taller → Recorrido → Resultados → Taller.

La explicación de cada escena, su árbol de nodos, cómo se comunican y cómo añadir accesorios, opciones de aspecto, obstáculos o postales está en [docs/arquitectura.md](docs/arquitectura.md).

## Arte y sustitución de recursos

El pasaporte y las postales de resultados también usan fotografías reales de Xallitic, la Catedral de Xalapa, la vista del Pico de Orizaba desde Parque Juárez y Los Lagos. Están en `recursos/fotos/`, con sus autores, fuentes y licencias Creative Commons en `recursos/fotos/README.md`. Cada foto muestra sus créditos y enlaces dentro del juego. No necesitan conexión para verse.

Las entradas de `fotografias` en `recursos/arte_xalapa.tres` permiten sustituir o quitar las fotos sin tocar los scripts. Al vaciar ese diccionario, los resultados usan la ilustración del puente y el pasaporte conserva su contenido. El fondo fotográfico del recorrido se controla por separado con `paisaje`.

El taller muestra una ilustración vectorial de Xallitic en `recursos/taller_xallitic.svg`. También aparece en los resultados cuando no hay una foto del lugar. El tema compartido usa verde tinta, papel crema y botones coral, con títulos redondeados. El HUD muestra cada accesorio con su dibujo y tecla, y marca la zona perfecta en el medidor.

El fondo del recorrido es una fotografía real de Xalapa desde el Ágora, de Koffermejia, con licencia CC BY-SA 4.0. Se incluye en `recursos/fotos/panorama_xalapa.jpg`. `paisaje` usa un AtlasTexture para excluir los bordes vacíos de la panorámica y conserva sus proporciones. Los créditos y enlaces aparecen en el menú de pausa. La imagen generada anterior ya no se carga.

Para sustituir el fondo, cambia `paisaje` y actualiza `credito_paisaje` en `recursos/arte_xalapa.tres`. Para quitarlo, vacía `paisaje` y guarda el recurso. El recorrido recupera los fondos dibujados por código. Los autores y licencias están en `recursos/fotos/README.md`.

El personaje y sus accesorios siguen dibujados por código en `melon/aspecto.gd` y `melon/accesorios/`. El tema compartido de botones, pestañas, menús y medidor está en `interfaz/tema_xalapa.tres`.

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
