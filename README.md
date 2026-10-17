# ¡Rueda, Melón!

Un juego de lanzamiento y rebotes desde Xalapa hasta el Centro Universitario de la Costa de la Universidad de Guadalajara. Preparas tu melón en el taller y eliges la potencia para soltarlo por la bajada de Xallitic. Rueda solo hasta saltar del trampolín del final. Desde ahí puedes rodar por las calles o encadenar saltos y papalotes hasta la meta.

## Abrir en Godot

Probado con Godot 4.6.1. Importa `project.godot` y presiona F5. El juego abre en el menú principal. No necesita plugins, paquetes ni imágenes descargadas.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

La resolución de diseño es 1280 × 720, con ventana redimensionable desde 960 × 540, escalado `canvas_items` y física a 120 pasos por segundo. Las acciones ya están declaradas en Proyecto > Configuración del proyecto > Mapa de entradas. Las capas tienen nombre en Capas 2D de física.

## Qué puedes hacer

- Elegir tres tamaños, ponerle nombre al melón y combinar ocho pieles, colores propios para cuerpo y rayas, seis patrones, nueve caras, seis detalles y cinco estelas. Los cambios de apariencia son gratuitos y no cambian la física.
- Dibujar sobre el melón en la pestaña Dibujo: pincel con ocho colores o uno libre, grosor ajustable, goma (también con clic derecho), deshacer (Ctrl+Z) y borrar todo. El dibujo gira con el melón durante la carrera y se guarda solo.
- Equipar hasta tres de ocho accesorios. El rebozo permite planear, la flor recupera resistencia y atrae aplausos, y la jarana impulsa y añade un rebote. Los accesorios originales siguen disponibles.
- Comprar en la Tiendita del taller mejoras permanentes de fuerza, resistencia y rebotes, y hasta tres Salsas Valentina para revivir.
- Llegar al CUCosta y completar los 19 lugares del pasaporte. Cada lugar nuevo da 60 aplausos una sola vez.
- Guardar automáticamente el aspecto, el equipo, las compras, el récord y el pasaporte entre sesiones.
- Conservar hasta 24 melones personalizados en el almanaque, con nombre, tamaño, colores, dibujo, estela y equipo. Puedes volver a usarlos, actualizar sus fichas o eliminarlas.
- Consultar un almanaque con cuadrícula de melones, accesorios y poderes. Cada ficha muestra su ilustración y sus datos.

Para guardar una creación, pulsa "Guardar melón en el almanaque" en la pestaña Tu melón. Abre "Almanaque" desde la cabecera del taller para elegirla y pulsa "Usar melón" para volver a editarla o salir a rodar. "Actualizar con el actual" reemplaza la ficha seleccionada con el melón del taller y pide confirmación, igual que eliminar. Guardar dos veces el mismo melón no crea duplicados.

## Objetivo del viaje

La meta está a 5200 metros de juego, el doble del recorrido anterior. El recorrido tiene cuatro etapas visibles en el HUD: Xalapa, bosques y volcanes desde los 2400 metros, centro del país desde los 3600 y Puerto Vallarta desde los 4600. Los fondos cambian de forma gradual, el bosque deja atrás las casas y en la costa aparecen palmeras. Cada uno de los 19 lugares tiene una señal con la distancia restante. Una puerta a cuadros marca la meta del CUCosta. Cruzarla termina el viaje, incluso en el aire.

La barra del HUD muestra el recorrido total, la etapa y los metros que faltan. El lugar actual y el siguiente destino siguen visibles al volar. La ficha de altura muestra en su ayuda la altura máxima y el bono acumulado. Detenerse o romperse sigue terminando el intento.

Todo el terreno después del lanzamiento es plano, desde la primera calle hasta la meta. Solo la bajada y el trampolín de salida conservan su curva. Las rampas siguen siendo obstáculos de impulso sobre ese suelo.

La dificultad aumenta de forma gradual entre los 100 metros y la meta. Los obstáculos se acercan, los postes y banquetas ganan peso, y aparecen más bandadas y rivales que esquivan. Al final también hay más parejas de melones para encadenar slams. Los poderes, papalotes y rescates siguen repartidos durante todo el viaje. Los intentos cortos permiten ganar aplausos y comprar mejoras para llegar más lejos. Los sellos y récords anteriores se conservan, sin multiplicar sus metros.

La ruta sigue los 19 lugares del PDF elegido por ListiStar, en ese orden. Incluye El Águila, la FEI, el MAX, Bachilleres Experimental, La Joya, los bosques y volcanes rumbo a Perote, Puebla, Tlaxcala, el centro del país y la llegada al CUCosta. La lista y sus distancias de juego están en `Config.postales`. Las fotografías y sus datos curiosos se asignan por el mismo `id` en `recursos/arte_xalapa.tres`.

Cada punto de interés muestra una imagen provisional de su lugar en el mapa, junto a su letrero. Las imágenes conservan sus proporciones y no tienen colisión. Al terminar el intento, la postal corresponde al lugar más lejano alcanzado en esa carrera. Si ese lugar aún no tiene foto de resultados, se oculta la postal. El pasaporte conserva los nombres y sellos, sin fotos.

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

El medidor de potencia aparece en la salida de la bajada. Espacio fija el valor, retira la barrera y suelta a todos los melones. Los rivales bajan por dos filas, saltan del trampolín y continúan por el camino con ritmos distintos. Después aparecen más melones durante el viaje. La zona perfecta está entre 80 % y 100 %. Más potencia da más velocidad al llegar a Xalapa. Durante la bajada no puedes saltar, girar, usar accesorios ni pedir empujones. La pausa sigue disponible. Al salir del trampolín recuperas todos los controles de carrera.

Empiezas con dos rebotes impulsados y puedes pulsar Espacio hasta 0.26 segundos antes de tocar suelo. Caer sobre el lado redondo conserva velocidad. Los accesorios son solo imagen: no tienen colisión ni cambian el aterrizaje. Usarlos consume su carisma durante esa carrera. Vuelven a estar equipados en el siguiente intento.

## Slam y melones rodantes

Además de los seis rivales de la salida, aparecen melones medianos y grandes desde los 100 metros, separados entre 170 y 230 metros. Se generan por delante del jugador hasta la meta y dejan de ocupar memoria al quedar lejos. Cada uno permite un único slam, así hay más oportunidades de recuperar velocidad sin repetir el mismo apoyo.

Los rivales corren como tu melón: aceleran en las bajadas, frenan en las subidas, despegan en las crestas, rebotan al caer y saltan cada uno o tres segundos. Cada uno tiene su ritmo de crucero, entre 420 y 620 px/s. Si se quedan muy atrás apuran el paso, y si te sacan mucha ventaja lo aflojan, así siguen cerca durante el viaje. Cuando vuelas a más de 65 metros sobre la calle, los rivales cercanos te siguen al aire con impulsos, entre 32 y 54 metros por debajo de ti, y ajustan su avance al tuyo. Cada impulso deja un soplo blanco bajo el melón. No suben mientras caes en picado, y el que ya recibió un slam se queda abajo. Como vuelan más hondo de lo que devuelve un slam, golpearlos en lo alto cuesta algo de altura.

Pulsa S o flecha abajo en el aire para caer en picado. Golpear uno desde arriba te impulsa hacia arriba y añade velocidad hacia delante. El rival queda achatado un momento, frena y sigue corriendo, pero ya no sirve para otro slam. Si caes al suelo sin acertar, conservas el 60 % de tu velocidad horizontal. El slam no consume saltos, tiene una recarga de 0.45 segundos tras resolverse y bloquea el salto y los papalotes mientras caes.

Durante el picado tu melón corrige un poco su avance hacia el rival que tiene debajo, hasta 1700 px/s². Picar desde más alto da más tiempo para corregir. Picar encima del rival apenas cambia nada. Un mal cálculo sigue fallando. El rival que apuntas deja de saltar mientras caes, aunque sigue rebotando si venía en el aire. El golpe admite entre 16 y 40 píxeles de margen lateral según la velocidad relativa. Los golpes laterales y desde abajo no cuentan. El HUD solo muestra el aviso de S cuando la caída sale con la mitad de esa corrección, y tiene en cuenta el arco del rival si está en el aire. En ese momento el rival lleva una mira amarilla con una flecha hacia abajo: si pulsas S, aciertas. Durante el picado, la mira se vuelve coral sobre el rival hacia el que se corrige la caída.

Las rampas dan 280 px/s de impulso, frente a los 240 anteriores. Caer sobre un toldo añade 160 px/s hacia delante y devuelve el 90 % de la velocidad de caída como rebote. Tocar el toldo al subir no da impulso. Ambos se usan una sola vez por carrera.

## Ruta aérea

La primera ayuda está a 60 metros de la salida y a 38 metros sobre la calle. Desde ahí, la ruta asciende entre 28 y 40 metros por ayuda hasta llegar a 330 metros de altura. Las ayudas están separadas entre 95 y 125 metros. Cada tercera ayuda es una corriente de niebla, con una silueta distinta del papalote. Acércate y pulsa E cuando aparezca el aro y el aviso de impulso. Ambas ayudan a subir y avanzar, protegen la siguiente caída fuerte y se usan una sola vez por carrera. No regalan saltos. Hay un café de Coatepec cerca de la primera ayuda y después cada cuatro ayudas para saltar sin gastar cargas.

Las monedas de aplausos aparecen desde la salida en grupos de tres, separados entre 70 y 100 metros. En el cielo hay grupos de dos o tres premios, separados entre 140 y 200 metros en cuatro franjas entre 50 y 330 metros de altura. Alternan filas, arcos y diagonales cortas. Los primeros grupos de cada altura aparecen escalonados para dejar espacio libre. Cada intento genera una distribución distinta. La cámara conserva un zoom mínimo de 0.72 para distinguir las ayudas y al melón.

Espacio permite corregir una caída con un salto aéreo. Comparte cargas con los rebotes del suelo. A y D ajustan la velocidad horizontal además del giro, así puedes acercarte a una ayuda o frenar antes de pasarla. Una flecha señala la siguiente ayuda cuando queda fuera de pantalla. La carrera solo termina por falta de avance después de tocar suelo, aunque el lanzamiento sea casi vertical.

Subir tiene sus propios objetivos. A 60 metros llegas a los Tejados de Xallitic, a 140 a la Niebla de Xalapa y a 240 al Viento del Macuiltépetl. Un aviso anuncia cada altura alcanzada. El HUD conserva el siguiente destino de la ruta. El fondo conserva la ciudad al principio; después aparecen las capas de nubes y cambia el azul del cielo. Al terminar recibes un aplauso por metro de altura máxima, además de los premios por distancia y recogibles. Bajar y volver a subir no duplica ese bono.

## Poderes del camino

Se activan al recogerlos y tienen siluetas diferentes. El primero aparece a los 70 metros. Después aparecen cada 110 a 160 metros, alternados y por encima del camino. Hay que aprovechar un salto, un rebote o un accesorio para alcanzarlos.

| Poder | Efecto |
| --- | --- |
| Chile jalapeño | Explota y lanza al melón hacia adelante, como mínimo a 110 m/s, y un poco hacia arriba |
| Café de Coatepec | Energía ilimitada durante 4 segundos: saltas y rebotas todo lo que quieras sin gastar cargas |
| Pizza con yogur | El melón se sube a una pizza que avanza 2.5 segundos sin perder altura. Saltar o hacer slam lo baja |

Si el melón va lento en el suelo y sin cargas de salto, aparece por delante, a ras de calle, un café. Hay como mucho un rescate cada 7 segundos.

## Salsa Valentina

Se compra en la Tiendita del taller por 350 aplausos; puedes tener hasta tres. Si el melón se rompe o se detiene, se usa sola una salsa: el melón vuelve con toda su resistencia y sus cargas, dos segundos invulnerable y con impulso para seguir. El HUD muestra cuántas te quedan.

## Pájaros

Desde los 180 metros vuelan pájaros contra el melón, a veces en pareja, entre 11 y 75 metros sobre la calle. Chocar con uno le quita casi la mitad de la velocidad. Cada pájaro estorba una sola vez.

Los melones rivales tienen carácter: los tontos (cara de sueño) van lentos, tropiezan y son fáciles de aplastar; los listos (con lentes) van más rápido y a veces esquivan el primer slam. Al principio abundan los tontos y hacia el final, los listos.

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
  terreno/         Generador del camino, tramos, bajada de salida y postales de lugares
  obstaculos/      Escena base y una escena heredada por tipo
  ayudas/          Poderes, papalotes y público que empuja
  paisaje/         Fondo con paralaje y capas del cielo
interfaz/        Tema visual compartido y componentes de interfaz
recursos/        Imágenes, fotografías, fuente, íconos PNG y datos de arte (arte_xalapa.tres)
pruebas/         Scripts de verificación automática
docs/            Documentación técnica
```

La escena inicial es `pantallas/menu/menu.tscn`. El flujo es Menú → Taller → Recorrido → Resultados → Taller.

La explicación de cada escena, su árbol de nodos, cómo se comunican y cómo añadir accesorios, opciones de aspecto, obstáculos o postales está en [docs/arquitectura.md](docs/arquitectura.md).

## Arte y sustitución de recursos

El arte dibujado del juego usa hojas PNG con JSON Hash compatible con LibreSprite. El melón, los accesorios, el terreno, el paisaje y los efectos se cargan desde `recursos/sprites/`. Para editar o sustituir cuadros, consulta [recursos/sprites/README.md](recursos/sprites/README.md).

Las postales de resultados muestran una fotografía del lugar alcanzado y un dato curioso para los 19 destinos elegidos, incluida la entrada del CUCosta. Las imágenes están en `recursos/fotos/` y funcionan sin conexión. Los autores, las fuentes y los derechos de cada fotografía están en [recursos/fotos/README.md](recursos/fotos/README.md). El juego muestra estos créditos y el enlace a la fuente del dato.

Las entradas de `fotografias` en `recursos/arte_xalapa.tres` permiten sustituir o quitar las fotos sin tocar los scripts. Al vaciar ese diccionario, los resultados ocultan la postal y conservan el resumen del intento.

`lugares_mapa` en ese mismo recurso asigna una textura a cada uno de los 19 puntos del mapa. Por ahora usa sus fotos. Para poner un sprite, sustituye la textura de su `id` por el PNG o `AtlasTexture` correspondiente. La fotografía y el dato curioso de resultados se conservan. Al quitar una entrada, desaparece su imagen del mapa y permanece el letrero.

El taller muestra una ilustración de Xallitic en `recursos/taller_xallitic.png`. El tema compartido usa verde tinta, papel crema y botones coral con relieve, y la fuente Fredoka incluida en `recursos/fuentes/` (licencia OFL) para verse igual en cualquier sistema. El HUD muestra cada accesorio con su dibujo y tecla, y marca la zona perfecta en el medidor. La barra de resistencia baja un tramo completo con cada golpe y una fracción con las caídas medianas.

El recorrido usa fondos dibujados de ciudad, montañas y costa. `paisaje` queda vacío para mantener esos fondos. Las fotos provisionales de los lugares aparecen sobre ellos. La panorámica de Xalapa desde el Ágora se conserva entre los recursos, con sus créditos en `recursos/fotos/README.md`.

El personaje se compone en `melon/aspecto.gd`; los accesorios son sprites PNG de `recursos/sprites/accesorios.png`, sin colisión, y su efecto está en `melon/accesorios/`. El tema compartido de botones, pestañas, menús y medidor está en `interfaz/tema_xalapa.tres`.

Los estilos de todas las pantallas, incluidos paneles, tipografía, colores de estado y barras del HUD, se editan en ese recurso desde el editor de Godot. La [guía de temas](docs/temas.md) indica qué variación controla cada parte. Los márgenes y la distribución de cada pantalla se editan en su escena.

Los poderes, la Salsa Valentina, la explosión del chile y los pájaros usan imágenes PNG provisionales en `recursos/poderes/`, algunas de Microsoft Fluent Emoji con licencia MIT. Para cambiarlas basta con sobrescribir el PNG o elegir otra textura en el inspector. La tabla de archivos y la forma de cambiarlos están en [recursos/poderes/README.md](recursos/poderes/README.md).

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
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/musica.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/verificar.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/ruta.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/progresion.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/lugares.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/almanaque.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/slam.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/lanzamiento.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/balance.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/impulsos.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 120 --script res://pruebas/vuelo.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/distribucion.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/paralaje.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/rendimiento.gd
```

La segunda orden comprueba entradas, compras, desbloqueos, premios sin duplicados, persistencia, datos inválidos, poderes, accesorios, pausa y una carrera real completa hasta volver al taller. Utiliza un archivo de prueba separado y lo borra al terminar. No modifica tu progreso.

`ruta.gd` comprueba los límites del viaje, las cuatro etapas del HUD, las 19 señales del camino, la llegada por aire, el cierre del terreno y el cobro único de recompensas. También comprueba las fotos y los datos curiosos de los 19 destinos elegidos en sus límites de distancia. Si se quita una foto, verifica que no se sustituya por la de otro lugar. `balance.gd` exige completar al menos una carrera de 5200 metros con mejoras, equipo y slams, con física real.

`lugares.gd` comprueba que los 19 puntos tengan su imagen en la posición correcta, sin duplicados en los límites de tramo ni colisiones. También verifica que cambiar una imagen del mapa por un sprite conserve la foto de resultados.

`almanaque.gd` comprueba la colección, la independencia de los dibujos guardados, el límite de fichas, la carga de partidas anteriores y la validación de datos dañados. También recorre los botones de guardar, consultar, actualizar, eliminar y usar un melón. Usa un archivo separado y lo borra al terminar. La revisión gráfica incluye el almanaque vacío, la colección, accesorios, poderes y la confirmación de eliminación a ambas resoluciones.

`slam.gd` comprueba aciertos sobre melones en movimiento, impactos entre pasos a gran velocidad, fallos contra el suelo, recarga, pausa y conservación de saltos. También verifica que los melones continúen entre tramos y que la carrera los retire al quedar atrás. Prueba roces, fallos claros y 81 caídas con los tres tamaños, tres velocidades y nueve desfases de puntería. Usa un guardado de prueba separado.

`lanzamiento.gd` comprueba la parrilla con el almanaque vacío y con fichas guardadas, la salida conjunta, las copias independientes, la pausa y la continuidad de los rivales al saltar del trampolín. También compara fuerza mínima y máxima con los tres tamaños. Comprueba que más fuerza conserve más velocidad al salir del trampolín y aumente el alcance. Repite la bajada con todas las teclas de carrera pulsadas y verifica que no cambien la trayectoria ni consuman saltos o equipo. También comprueba la pausa y que los controles y los accesorios vuelvan después del trampolín. Usa un guardado de prueba separado.

`balance.gd` comprueba 54 carreras sin input después del lanzamiento, con tres tamaños, tres fuerzas, tres semillas y mejoras iniciales o al máximo. Todas deben terminar en menos de 30 segundos y recoger como máximo tres chiles. Sin mejoras deben terminar antes de la mitad de Xalapa; con mejoras tampoco deben salir de la ciudad. También compara una carrera sin controles con otra que usa rebotes, accesorios y empujones. Comprueba que un lanzamiento al 70 %, con equipo inicial y controles, avance al menos 400 metros sin mejoras. Por último, mide la progresión media con tres semillas. Sin mejoras, las carreras con controles básicos deben promediar menos de novecientos metros. Las mejoras deben superar el alcance inicial y, al máximo, permitir un promedio de al menos mil metros. Las carreras activas pueden durar hasta 120 segundos. Una prueba adicional exige llegar al CUCosta con equipo, mejoras y slams. Utiliza su propio archivo de prueba.

`impulsos.gd` revisa que todo el terreno sea plano, la separación de los melones, el límite de generación y la retirada de los que quedan atrás. Compara 18 carreras con las ayudas adicionales activas o desactivadas, con las mismas semillas y controles. Comprueba que apuntar los slams permita llegar con menos mejoras. Otras tres carreras verifican que pulsar slam sin apuntar siga fallando y termine mucho antes de la meta. Usa un archivo de prueba separado.

`vuelo.gd` comprueba el consumo y bloqueo de saltos, el alcance de E y el uso único de cada ayuda sin recargar saltos ni perder las cargas extra de la jarana. También recorre la ruta aérea con tres tamaños y tres semillas, sin mejoras ni accesorios, tanto con D sostenida como sin ella. Exige encadenar al menos dos ayudas, llegar a 140 metros de altura y permanecer seis segundos sobre los 40 metros. Las carreras deben terminar dentro de dos minutos y, sin mejoras, antes de la meta. Repite con el melón mediano y mejoras máximas y exige alcanzar al menos la salida de Xalapa. El límite de tiempo detecta vuelos que no terminan; no es un tope dentro del juego. Usa un guardado de prueba separado.

`progresion.gd` comprueba la longitud de 5200 metros, que la dificultad siga creciendo hasta la meta y que los obstáculos se acerquen. Compara 3000 sorteos al inicio, en medio y al final para comprobar el aumento de obstáculos dañinos y rivales listos.

`distribucion.gd` revisa seis semillas, las monedas desde el inicio, la frecuencia de poderes, la cobertura de puntos en las cuatro franjas de altura y la variedad de poderes. Limita la densidad a doce monedas por cada mil píxeles de camino y a dieciséis monedas en una vista de 1500 por 1000 píxeles. También comprueba que los premios aéreos no cambien el suelo ni las ayudas, que todos los premios queden dentro de su tramo, que una semilla fija repita la distribución y que los intentos al azar sean diferentes.

`rendimiento.gd` necesita una ventana con render real. Comprueba que el melón conserve una textura con el máximo de seis mil puntos al moverse y girar, que solo la actualice al consumir equipo o romperse y que sus efectos sigan cambiando. La textura se dibuja a doble resolución para conservar los detalles. También comprueba que el fondo conserve su dibujo hasta cambiar de altura o tamaño de ventana. No escribe el progreso del jugador.

## Xalapa en el juego

La ruta incluye Xallitic, Callejón del Diamante, Catedral de Xalapa, Parque Juárez, Los Berros, Los Lagos, zona universitaria y Macuiltépetl. Continúa hacia Puerto Vallarta y termina en el Centro Universitario de la Costa. El campus pertenece a la Universidad de Guadalajara y está en Puerto Vallarta, según su [ubicación oficial](https://cuc.udg.mx/ubicacion). La ruta y las distancias son de fantasía. Los poderes también son ficción del juego.

La selección procede de `Lugares_Xalapa_fotos_reales.pdf`, aportado por ListiStar. Los créditos de las fotografías y las fuentes de los datos están en [recursos/fotos/README.md](recursos/fotos/README.md).
