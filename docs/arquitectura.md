# Arquitectura de ¡Rueda, Melón!

Este documento explica cómo está organizado el proyecto en Godot: qué hace cada escena, cómo se comunican los nodos y dónde tocar para cambiar o añadir cosas. Para jugar, controles y créditos, consulta el [README](../README.md).

## Ideas generales

- **Una carpeta por parte del juego.** La escena y su script están en la misma carpeta (`melon/melon.tscn` + `melon/melon.gd`). Los nombres de archivos y carpetas están en `snake_case`.
- **Un script por nodo.** Cada nodo con comportamiento propio tiene su script y un `class_name` (por ejemplo `Melon`, `Tramo` o `HUD`). Los demás nodos solo organizan la escena.
- **Datos en `Config`, estado en `Juego`.** Ningún script guarda números de balance sueltos. Si quieres ajustar algo, lo más probable es que esté en `globales/config.gd`.
- **Señales hacia arriba, llamadas hacia abajo.** Un nodo hijo avisa con señales (`Melon.aviso`, `GeneradorTerreno.obstaculo_tocado`). El nodo padre llama métodos de sus hijos (`terreno.actualizar(x)`, `hud.actualizar(self)`). Las conexiones estables están en los `.tscn` (sección `[connection]`), así se ven en el editor.
- **Sprites PNG.** `globales/sprites.gd` carga hojas PNG y sus regiones desde JSON Hash de LibreSprite. `_draw()` compone texturas para el melón, terreno, obstáculos, escenario y efectos. Los lugares usan fotografías como postales al terminar el intento. Los scripts con `@tool` también se ven en el editor.

## Autoloads (`globales/`)

| Nombre | Archivo | Qué contiene |
| --- | --- | --- |
| `Config` | `globales/config.gd` | Reglas y valores ajustables: física, lanzamiento, terreno, economía, apariencia, poderes y postales. Al iniciar carga los accesorios de `melon/accesorios/`. |
| `Juego` | `globales/juego.gd` | Progreso del jugador: aplausos, mejoras, accesorios, Salsas Valentina, aspecto, colección de melones, récord y pasaporte. Calcula las recompensas (`registrar_intento`) y guarda en `user://progreso.json`. |
| `Musica` | `globales/musica.gd` | Un reproductor persistente con fundidos breves. Menú en la portada, Tiendita en taller y almanaque. Base Lenta al iniciar, Media desde el 50 % de la ruta y Rápida desde el 80 %. Derrota suena una vez al detenerse o romperse el melón y continúa en resultados. Al llegar a la meta suena Menú. |

Las seis pistas están en `recursos/musica/`, comprimidas en Ogg Vorbis estéreo a 44,1 kHz. Sus archivos `.import` activan el bucle salvo en `derrota.ogg`. `Musica` pausa con la carrera y conserva la reproducción al pedir la misma pista.

## Flujo entre pantallas

```text
Menú ──"Jugar"──▶ Taller ──"¡A rodar!"──▶ Recorrido ──fin de carrera──▶ Resultados ──▶ Taller
                                             │
                                             └──Pausa ▸ "Volver al taller" (sin cobrar)──▶ Taller
```

Las pantallas no se pasan datos directamente: el Taller escribe la elección del jugador en `Juego`, el Recorrido la lee, y al terminar llama a `Juego.registrar_intento()`. Resultados lee `Juego.ultimo`.

Los cambios de pantalla pasan por `Animacion.cambiar_escena(ruta)`: carga la escena al instante y abre encima una cortina circular.

El botón "Almanaque" del taller abre `pantallas/almanaque/almanaque.tscn`. "Volver al taller" y Esc regresan. "Usar melón" restaura la ficha elegida en `Juego` y regresa al taller.

## Interfaz (`interfaz/` y `globales/animacion.gd`)

El estilo de todas las pantallas sale del tema `interfaz/tema_xalapa.tres`, que también es el tema del proyecto (`gui/theme/custom`). Usa la fuente incluida `recursos/fuentes/Fredoka.ttf` (licencia OFL), así se ve igual en Windows, macOS y Linux. No uses fuentes del sistema: no existen en todos los equipos.

Los paneles, tamaños de letra y colores de estado se editan en ese Theme. Las escenas solo eligen sus variaciones y conservan la distribución. La [guía de temas](temas.md) explica qué variación corresponde a cada parte y cómo editarla desde Godot. Los helpers `ComunTaller`, `Ficha` e `Iconos.tecla` reciben nombres de variaciones en lugar de tamaños de letra.

| Variación del tema | Base | Para qué |
| --- | --- | --- |
| `Titulo` | Label | Letra gruesa crema con contorno y sombra (logo, distancias, listones) |
| `Subtitulo`, `Suave` | Label | Texto grueso de sección y texto secundario |
| `TextoHUD` | Label | Texto crema con contorno, legible sobre el juego |
| `Tecla` | Label | Tecla dibujada ("Espacio", "E", "1") |
| `Principal`, `Comprar`, `Seleccion` | Button | Botón coral grande, botón verde de compra y opción elegida (amarilla) |
| `Tarjeta`, `Chip`, `ChipClaro` | PanelContainer | Tarjetas de listas y fichas redondeadas |

Los botones tienen "labio": el borde inferior es más grueso y, al presionarlos, el relleno baja y se hunden. La fuente no trae flechas, estrellas ni el símbolo de pausa. Esos dibujos son sprites PNG en `recursos/iconos/` y se usan desde `Iconos` (`interfaz/iconos.gd`).

| Componente | Archivo | Qué hace |
| --- | --- | --- |
| `Ficha` | `interfaz/ficha.gd` | Contador con ícono: aplausos, récord, carisma, altura |
| `Pips` | `interfaz/pips.gd` | Fila de íconos que se llenan: impulsos, niveles |
| `Selector` | `interfaz/selector.gd` | Elegir de una lista con flechas, como en un vestidor |
| `FondoJuego` | `interfaz/fondo_juego.gd` | Fondo animado con rayos y papel picado (Taller y Resultados) |

El autoload `Animacion` hace que cada botón crezca un poco con el ratón y se aplaste al pulsarlo. Se conecta solo a todos los botones. Dentro de listas con scroll no crece, porque el borde se cortaría. También ofrece `aparecer()`, `rebotar()`, `latir()`, `sellar()` y `contar()` para animar las entradas de pantalla, los contadores del HUD y el desglose de resultados.

## Menú principal (`pantallas/menu/`)

```text
Menu (menu.gd)                     Bajada de la cámara, entrada del título y botón
├─ Paisaje (mundo/paisaje/)        El mismo fondo de Xalapa que el recorrido
├─ CieloAlto (cielo_menu.gd)       Tapa el fondo con cielo arriba y pone nubes que se cruzan
├─ Mundo
│  ├─ BajadaXallitic               La misma calle empedrada, casas y público
│  └─ Melones (melones_menu.gd)    Crea, mueve y hace explotar los MelonMenu
├─ Camara
└─ Interfaz (CanvasLayer)
   └─ Centro
      ├─ Titulo (titulo_melonazo.gd)  Logo "MELONAZO"; la última O es un melón que gira
      └─ BtnJugar                     Va al taller
```

Al entrar, `Menu` baja la cámara desde 3200 px sobre la calle. `CieloAlto` tapa las montañas mientras la cámara está alta y se desvanece al llegar; sus nubes están ancladas al mundo, así la cámara las atraviesa. Cualquier clic o tecla salta la bajada. Después cae el título y aparece el botón.

Los melones bajan por la calle de Xallitic con una física propia y sencilla sobre `Tramo.altura()` (gravedad, despegue en los bordes y rebote). Cada `MelonMenu` (`melon_menu.tscn`) dibuja su aspecto una sola vez en un `SubViewport`, como los rivales del recorrido; por eso muchos melones no cuestan casi nada. Un clic sobre uno lo hace explotar en trozos, semillas y jugo que deja manchas en el empedrado, y el público cercano levanta los brazos. A veces aparecen el melón del jugador o los de su almanaque. `Titulo.indice_melon` elige qué letra es el melón.

## Taller (`pantallas/taller/`)

```text
Taller (taller.gd)                 Coordina pestañas, pie y vista previa
├─ Fondo (FondoJuego)
└─ Margen/Raiz
   ├─ Cabecera                     Logo y fichas de aplausos (Balance) y récord (Record)
   ├─ Medio
   │  ├─ Previa
   │  │  ├─ MarcoVista/Vista (vista_melon.gd) Dibuja el melón; recibe el ratón para pintar
   │  │  ├─ NombreVista
   │  │  └─ Info                   Tamaño y ficha de carisma
   │  └─ Pestanas (TabContainer)
   │     ├─ TuMelon      (pestanas/pestana_melon.gd)       Nombre, tamaño y aspecto
   │     ├─ Dibujo       (pestanas/pestana_dibujo.tscn)    Pincel, goma y colores
   │     ├─ Accesorios   (pestanas/pestana_accesorios.gd)  Equipar y desbloquear
   │     ├─ Mejoras      (pestanas/pestana_mejoras.gd)     "Tiendita": mejoras y Salsa Valentina
   │     └─ Pasaporte    (pestanas/pestana_pasaporte.gd)   Postales, fotos y poderes
   └─ Pie                          Errores, teclas de ayuda y botón "¡A rodar!"
```

Cada pestaña modifica `Juego` y emite su señal `cambio`. El Taller escucha todas y llama a `refrescar()` en cada pestaña, en el pie y en la vista previa. Así ninguna pestaña necesita conocer a las demás. Hay dos excepciones que solo redibujan la vista, porque llegan en cada movimiento del ratón: `Dibujo.cambio` y `TuMelon.color_cambiado`.

Las filas de las listas (tamaños, aspecto, accesorios, mejoras, pasaporte) se generan desde `Config`, por eso no aparecen en el `.tscn`. `comun.gd` (`ComunTaller`) crea esas etiquetas y botones con el mismo estilo en todas las pestañas.

La pestaña se llama `TuMelon` en el árbol, sin acento ni espacio, y el Taller le pone el título "Tu melón" con `set_tab_title()`. La `Vista` necesita `mouse_filter` en *Stop* para recibir el ratón y poder pintar.

## Almanaque (`pantallas/almanaque/`)

`almanaque.gd` organiza las categorías Mis melones, Accesorios y Poderes. A la izquierda genera una cuadrícula con las entradas y a la derecha muestra la ficha elegida. La consulta no cambia el melón del taller. Los accesorios y poderes salen de `Config`, igual que en las otras pantallas.

`ilustracion_ficha.gd` dibuja las miniaturas y la ilustración grande. `Aspecto.dibujar_melon()` acepta un diccionario opcional para dibujar un melón guardado sin modificar las propiedades de `Juego`. El taller y la carrera siguen usando los valores actuales por defecto.

`Juego.melones_guardados` conserva hasta 24 diccionarios con las propiedades de `PROPIEDADES_MELON`. `datos_melon()` copia el estado actual, incluido el dibujo. `guardar_melon()` crea una ficha sin duplicados idénticos o reemplaza el índice indicado. `usar_melon()` restaura una copia independiente y `eliminar_melon()` retira una ficha. El progreso global no forma parte de las fichas.

El JSON de versión 2 añade `melones_guardados` y conserva los campos anteriores. Cada ficha pasa por la misma validación de nombre, índices, colores, dibujo y equipo que el melón actual. Los accesorios deben existir y estar comprados. Si el campo no existe, la colección empieza vacía. Actualizar y eliminar piden confirmación en la interfaz.

## Recorrido (`pantallas/recorrido/`)

```text
Recorrido (recorrido.gd)           Reglas de la carrera y fases
├─ Paisaje (mundo/paisaje/)        Fondo con paralaje, sigue a la cámara
├─ Mundo
│  ├─ BajadaXallitic               Calle empedrada, público, barrera y trampolín; reutiliza Tramo
│  ├─ LimiteDeSalida               Pared invisible bajo el borde del trampolín
│  ├─ Terreno (GeneradorTerreno)   Crea los tramos como hijos
│  │  ├─ Tramo000 (Tramo)
│  │  ├─ Tramo001 …
│  └─ Melon (Melon)
├─ Camara (CamaraRecorrido)        Sigue al melón y ajusta el zoom
├─ Efectos (EfectosRecorrido)      Flecha de puntería y avisos flotantes
└─ Interfaz (HUD)                  Datos, equipo, indicaciones y pausa
```

**Fases** de `Recorrido.Fase`. `FUERZA` → `BAJADA` → `RECORRIDO` → `FIN`. La salida muestra el medidor de potencia con el melón inmóvil y la barrera puesta. Espacio fija la potencia, retira la barrera y lanza cuesta abajo. Durante `BAJADA`, `_avanzar_bajada()` hace rodar al melón sobre la calle y acelera según la potencia elegida, más un embalaje por la caída (`BajadaXallitic.embalaje()`) que se pierde al subir el trampolín final. `Melon.freeze` es verdadero y `Melon.controlable` es falso. Así el largo de la bajada y las colisiones no borran la potencia de salida. Cuando el melón llega al borde del trampolín (`Config.bajada_fin`), comienza `RECORRIDO`, se activa la física del cuerpo con la velocidad elegida hacia adelante más parte del impulso hacia arriba del trampolín (`Config.bajada_salto`) y vuelven los controles habituales. Los accesorios conservan su dibujo y su equipo. La distancia y los bonos de altura se cuentan en la ruta por Xalapa, después del trampolín. La carrera termina al llegar a `Config.meta_m`, si el melón se rompe o si avanza menos de `Config.velocidad_min_avance` durante `Config.tiempo_sin_avance` segundos.

**Cada paso de física**, `Recorrido._physics_process()`:

1. Revisa si el melón sigue avanzando.
2. Pide a `Terreno` que genere por delante y borre por detrás.
3. Mide la altura sobre el suelo para el HUD.
4. Marca qué persona y qué papalote están al alcance de la tecla E.
5. Atrae aplausos si la flor está activa y anuncia las postales alcanzadas.

**Señales conectadas en `recorrido.tscn`:**

| Señal | Receptor | Para qué |
| --- | --- | --- |
| `Melon.aviso(texto)` | `_on_melon_aviso` | Texto flotante sobre el melón |
| `Melon.se_rompio` | `_on_melon_roto` | Ofrece revivir con Valentina o termina la carrera |
| `Terreno.obstaculo_tocado(cuerpo, ob)` | `_al_tocar_obstaculo` | Llama a `ob.tocar(melon)` y muestra el aviso |
| `Terreno.poder_recogido(tipo)` | `_al_recoger_poder` | `melon.recibir_poder(tipo)` |
| `Terreno.pajaro_tocado(pajaro)` | `_al_tocar_pajaro` | Llama a `pajaro.tocar(melon)`, que frena al melón |

**Salsa Valentina.** `_on_melon_roto()` y la falta de avance llaman a `_ofrecer_valentina()`. Si queda salsa, entra en `REVIVIR`, pausa el árbol y abre la elección del HUD durante `Config.valentina_espera`, cinco segundos. El HUD funciona en pausa y emite `valentina_elegida(usar)`. Solo al aceptar, `Juego.usar_valentina()` consume una y `Melon.revivir()` devuelve resistencia, cargas e impulso. Rechazar, pulsar Esc o agotar el tiempo lleva a `FIN` sin consumir. Sin existencias, la carrera termina directamente. Se compra con `Juego.comprar_valentina()` y se guarda como `valentinas` en el JSON.

El **HUD** (`hud/hud.tscn`) es un `CanvasLayer` con `process_mode` *Always*, así funciona en pausa. El Recorrido llama a `hud.actualizar(self)` cada cuadro; el HUD lleva la cuenta regresiva de Valentina durante la elección. Las tres casillas de accesorios son instancias de `hud/slot_accesorio.tscn`.

## El melón (`melon/`)

```text
Melon (RigidBody2D, melon.gd)
├─ Cuerpo          CircleShape2D; el radio depende del tamaño
├─ Aspecto         Sprite2D con la textura de piel, cara, trazos y los PNG de los accesorios (sin colisión)
├─ Lienzo/Dibujo   SubViewport de 512 píxeles, dibuja el aspecto a doble resolución
└─ Estela          Rastro decorativo (estela.gd, top_level)
```

- `melon.gd` lee el control (A/D, Espacio, 1-2-3) y ajusta la velocidad en `_integrate_forces()`: aterrizajes, rebote impulsado, rodado y efectos activos.
- Otros nodos **no cambian `linear_velocity` directamente**. Piden cambios con `empujar(dv)`, `frenar(mult)` o `fijar_velocidad(v)`, y el melón los aplica en el siguiente paso. Así nunca se pisan dos cambios en el mismo cuadro.
- Los temporizadores de efectos (`t_planeo`, `t_cafe`…) se descuentan solos. Están en la lista `TEMPORIZADORES`.
- `aspecto.gd` (`Aspecto`) combina sprites de piel, patrón, cara, detalle y accesorios. Rasteriza los trazos libres al cambiar y reutiliza la textura. Sus funciones estáticas sirven al recorrido, el taller y el almanaque. El formato y la edición de las hojas están en [recursos/sprites/README.md](../recursos/sprites/README.md).
- En el recorrido, la señal `draw` de `Melon/Lienzo/Dibujo` llama a `_dibujar_aspecto()`. El `SubViewport` actualiza una textura una sola vez y el `Sprite2D` la muestra al mover y girar el cuerpo. `configurar()`, `_quitar_slot()` y la rotura piden un nuevo dibujo con `UPDATE_ONCE`. El `_draw()` del cuerpo solo actualiza aros y efectos. Así ni la CPU ni la GPU tienen que dibujar miles de puntos en cada fotograma.

### Capas de física

| Capa | Nombre | Quién |
| --- | --- | --- |
| 1 | Terreno | Segmentos del suelo, cuña de la rampa |
| 2 | Melón | El melón; solo choca con la capa 1 |
| 3 | Recogibles y obstáculos | Áreas que detectan al melón (máscara 2) |

## El mundo (`mundo/`)

| Carpeta | Escenas | Qué hacen |
| --- | --- | --- |
| `terreno/` | `tramo.tscn`, `postal.tscn` + `generador_terreno.gd`, `bajada_xallitic.gd` | `GeneradorTerreno` crea tramos de `Config.largo_tramo` píxeles y los llena. Cada `Tramo` tiene contenedores fijos: `Decoracion`, `Postales`, `Suelo`, `Obstaculos`, `Publico`, `Coleccionables` y `Aire`. |
| `obstaculos/` | `obstaculo.tscn` y ocho escenas heredadas, `pajaro.tscn` | Cada tipo edita su forma de colisión en su escena. El efecto está en `Obstaculo.tocar()`. `Pajaro` vuela hacia la izquierda y frena una vez; `GeneradorTerreno._poner_pajaros()` los coloca en `Aire` con su propio `rng_pajaros`. |
| `ayudas/` | `poder.tscn`, `papalote.tscn`, `persona.tscn` | Poderes que se recogen, papalotes que impulsan con E y público que empuja con E. |
| `paisaje/` | `paisaje.tscn` | Fondo lejano con paralaje. Cada capa del cielo es un nodo `CapaCielo` que puedes ocultar o ajustar en el inspector. |

**Generación reproducible.** El terreno usa `Config.semilla_terreno`, con -1 por defecto para cambiar en cada intento. Una semilla fija permite repetir una ruta. Los papalotes usan `rng_aire` y las rutas de premios altos usan `rng_premios`. Ambos conservan el azar del suelo. Cambiar las llamadas a `rng` en `GeneradorTerreno._poblar()` cambia las rutas del suelo y puede afectar las pruebas de balance.

La ruta aérea asciende desde `Config.altura_papalotes.x` hasta `Config.altura_papalotes.y`. Cada tercera ayuda activa `Papalote.corriente` y dibuja niebla con flechas de viento. Ambas variantes usan `impulsar()` con E y nunca recargan saltos. Los cafés cercanos a la primera ayuda y cada cuatro ayudas permiten saltar sin gastar cargas. `Recorrido.papalote_siguiente` y `EfectosRecorrido.objetivo_aereo` señalan el siguiente destino fuera de pantalla.

`Recorrido` conserva `altura_max_m` aunque el melón descienda. Al finalizar la pasa como sexto argumento opcional a `Juego.registrar_intento()`, que calcula `por_altura` con `Config.aplausos_por_metro_altura`. Las entradas de `Config.zonas_cielo` anuncian las alturas alcanzadas. El HUD conserva el lugar actual y el próximo destino al volar; la ficha de altura muestra el bono en su ayuda. La falta de avance horizontal solo termina la carrera cuando el melón está en el suelo.

## Resultados (`pantallas/resultados/`)

`resultados.gd` rellena los textos con `Juego.ultimo` y los anima. `ultimo.llegada` indica si el melón cruzó la meta sin romperse. El panel `Postal` de `postal_resultados.gd` busca el lugar más lejano alcanzado en ese intento y muestra exclusivamente su fotografía. Si ese lugar no tiene imagen, oculta la postal. No usa imágenes de otros lugares ni dibujos como sustitutos. El pasaporte conserva solo nombres y sellos. El recorrido asigna sus imágenes por separado en `ArteXalapa.lugares_mapa`.

## Cómo añadir cosas

### Un accesorio

Cada accesorio es un archivo en `melon/accesorios/` que extiende `Accesorio`. `Config` carga todos los archivos de esa carpeta al iniciar, así que no hay listas que actualizar:

1. Copia un accesorio parecido, por ejemplo `sombrero.gd`, con el nombre del nuevo id (`maraca.gd`).
2. En `_init()` define `nombre`, `carisma`, `accion`, `costo`, `orden`, `color` e `inicial`.
3. En `usar(m)` combina los efectos de `Melon`: `planear`, `embestir`, `caida_lenta`, `rodar`, `proteger`, `reparar`, `atraer_aplausos`, `sumar_rebote`, `empujar` y `fijar_velocidad`.
4. Si necesita física propia durante unos segundos, llama a `m.activar(self, segundos)` y escribe `fisica(m, v, dt)`. El HUD muestra su tiempo restante solo.
5. Añade el sprite con su id a `recursos/sprites/accesorios.png` y su cuadro a `accesorios.json`. El lienzo mide 96 × 96 píxeles y representa un melón de radio 32, orientado hacia arriba. `Accesorio.dibujar()` aplica el ángulo y el tamaño del melón. Los accesorios son solo imagen: no tienen forma de colisión.

### Una opción de aspecto

Pieles, patrones, caras, detalles y estelas son listas en `Config`. Agrega la entrada **al final** de su lista (los índices se guardan) y su cuadro en `recursos/sprites/melon.png` con el nombre `patron_<id>`, `cara_<id>` o `detalle_<id>`, junto con los metadatos de `melon.json`. Las estelas se eligen en `melon/estela.gd` y usan `efectos.png`. El taller crea las opciones solo. Los colores rápidos y los límites del dibujo libre están en `Config.colores_dibujo`, `grosor_dibujo`, `max_trazos` y `max_puntos_dibujo`.

### Un obstáculo

1. Crea una escena heredada de `mundo/obstaculos/obstaculo.tscn` (por ejemplo `tope.tscn`) y ajusta su `Zona` de colisión.
2. Añade el tipo al `@export_enum` y las medidas base en `_draw()` de `obstaculo.gd`, su sprite a `recursos/sprites/obstaculos.png` con su entrada en `obstaculos.json`, y su efecto en `tocar()`.
3. Registra la escena en `GeneradorTerreno.OBSTACULOS` y su peso en `Config.pesos_obstaculos` y `Config.obstaculos`.

### Un poder

Agrega su entrada en `Config.poderes` y su id en `Config.orden_poderes`, su efecto en `Melon.recibir_poder()` y su imagen en `Poder.TEXTURAS`, en `mundo/ayudas/poder.gd`. Los objetos de la tiendita, como la Salsa Valentina, van en `Config.poderes_tienda`. Las imágenes provisionales están en `recursos/poderes/`; su README explica cómo reemplazarlas, también la pizza y la explosión que se asignan en el inspector de `melon/melon.tscn` y el pájaro en `mundo/obstaculos/pajaro.tscn`.

### Una postal

Agrega el lugar en `Config.postales`, en orden de metros y con un `id` que no se repita. Añade su fotografía y dato curioso con el mismo `id` en `fotografias` de `recursos/arte_xalapa.tres` para los resultados. Asigna también una textura a ese `id` en `lugares_mapa`. El generador crea `postal.tscn` en la posición del lugar, detrás del suelo y sin colisión. `Postal` ajusta la imagen a un máximo de 520 × 280 píxeles sin deformarla, con su base en el suelo y a la derecha del letrero. Las fotos del mapa son provisionales. Para cambiarlas por sprites, sustituye cada textura de `lugares_mapa` por su PNG o `AtlasTexture`, sin modificar `fotografias`.

La ruta sigue los 19 lugares elegidos por el equipo, en el orden del PDF. Los primeros 2400 metros corresponden a Xalapa; La Joya inicia el tramo de montaña. La meta está en `Config.meta_m`, a 5200 metros. `Config.etapas_ruta` define las cuatro etapas del HUD. Los fondos de Xalapa, bosques y volcanes, centro del país y costa se mezclan durante los 80 metros anteriores a cada cambio. `GeneradorTerreno._poner_marcadores()` crea una señal por lugar sin consumir azar; `Tramo._dibujar_lugar()` dibuja los nombres, la distancia restante y la puerta a cuadros del CUCosta con sprites. Los letreros de distancia terminan antes de la meta. `Recorrido._revisar_avance()` detecta la llegada, limita la distancia y congela el melón. El generador conserva terreno de margen tras la meta, pero deja de extenderlo. Los lugares conservados mantienen sus identificadores para conservar sus sellos del pasaporte. El cargador descarta los identificadores que ya no forman parte de la ruta, sin afectar al resto del progreso.

### Cambiar el terreno

El generador mantiene todos los puntos del recorrido en `Config.calle_y`, incluida la primera calle. Solo `BajadaXallitic` tiene un perfil curvo para el lanzamiento. Ajusta `largo_tramo`, `calle_y`, `semilla_terreno`, `dificultad_metros` y las separaciones en `Config`. Las rampas y los toldos dan impulso una sola vez por carrera. `dificultad(x)` usa una curva suave entre 100 y 5200 metros. La misma curva ajusta la separación y los pesos de obstáculos, la frecuencia y altura de pájaros, la probabilidad de bandadas y los tipos de rivales. Las parejas de melones aumentan del 30 al 60 % para sostener las oportunidades de slam al final. Ningún melón ni pájaro nuevo aparece más allá de la meta.

## Pruebas (`pruebas/`)

Se ejecutan desde la terminal y nunca tocan tu guardado: cada una usa su propio archivo de prueba y lo borra al terminar. Los comandos están en el README.

| Script | Qué comprueba |
| --- | --- |
| `verificar.gd` | Compras, guardado, datos inválidos, poderes, accesorios, taller, dibujo con ratón, pausa y una carrera completa |
| `ruta.gd` | Llegada al CUCosta, límite de terreno, recompensas únicas y selección exacta de fotos por lugar |
| `almanaque.gd` | Colección, copias independientes, carga de partidas anteriores, datos inválidos y navegación por el almanaque |
| `balance.gd` | 54 carreras sin controles y la progresión con mejoras |
| `impulsos.gd` | Distribución de melones y comparación de alcance con las ayudas adicionales activas o desactivadas |
| `vuelo.gd` | Saltos, papalotes y la ruta aérea |
| `distribucion.gd` | Cobertura del cielo, variedad de poderes y generación reproducible sin alterar el suelo |
| `rendimiento.gd` | Dibujo personalizado conservado al mover y girar, con actualización de equipo, rotura y cielo. Abre una ventana |
| `graficos.gd` | Capturas de todas las pantallas a dos resoluciones (abre una ventana) |

## Slam y melones rodantes

`Melon.iniciar_slam()` activa el picado con S o flecha abajo. `_integrate_forces()` impone la velocidad de caída y resuelve el fallo contra el suelo con `Config.slam_conserva`. `acertar_slam()` aplica el impulso y termina el picado. No consume cargas de salto.

`mundo/ayudas/melon_rodante.gd` dibuja cada objetivo con `Aspecto` y lo mueve con una física propia sobre `Tramo.altura()`, sin cuerpo rígido ni colisiones. En el suelo suma la gravedad a lo largo de la pendiente y un empuje hacia su `rapidez`, fija: no se ajusta a la distancia del jugador. Despega cuando el suelo cae más rápido que su arco, rebota al caer con el rebote de su tamaño y salta a intervalos aleatorios con su propio `rng`. `avanzar()` recibe la posición del jugador solo para saber hacia dónde esquivar; los rivales no lo siguen al aire. `GeneradorTerreno` los conserva como hijos propios, porque cruzan entre tramos. Usa un generador aleatorio separado para conservar la distribución previa del camino. `Recorrido` llama a `preparar_corredores(bajada)` al preparar la salida y a `actualizar_melones()` durante la bajada y la carrera. Los rivales de la salida (`Config.rivales_salida`) arrancan con `_lanzar()`. Después, `_poner_melones()` crea apoyos adicionales por delante del jugador, desde `Config.primer_melon_camino_x` y separados según `Config.separacion_melones`; con `Config.prob_pareja_melones` llega un segundo melón poco después, para encadenar slams. Nunca los crea más allá de la meta ni duplica los existentes al actualizar el mismo punto. Cada objetivo comprueba el recorrido relativo de ambos centros entre pasos para detectar golpes desde arriba, incluso a alta velocidad. Un objetivo acertado queda `usado`, se achata y frena un momento, y sigue corriendo. Cada rival tiene un `tipo` de `Config.tipos_melones` (tonto, normal o listo) que `GeneradorTerreno._elegir_tipo_melon()` sortea con más tontos al inicio y más listos al final. Los tontos van lentos, tropiezan y tienen más margen de slam. Los listos van más rápido y, la primera vez que un picado los apunta, pueden esquivar con `_esquivar()`. Al aplastar un rival, o al romperse el jugador, `Sonidos.muerte()` (`globales/sonidos.gd`) toca al azar `recursos/sonidos/slash.wav` o `splash.wav`. Solo se liberan los que quedan atrás. `margen_slam()` calcula una tolerancia horizontal de 16 a 40 píxeles según la velocidad relativa. El barrido conserva el radio vertical para rechazar golpes desde abajo.

`prevision_slam()` estima cuándo llega el picado al objetivo y cuánto desvío horizontal quedaría. Si el objetivo está en el aire, sigue su arco hasta el suelo. `alcance_slam()` suma los radios, el margen y lo que `Config.slam_guiado` alcanza a corregir en ese tiempo. `GeneradorTerreno.objetivo_slam()` elige el objetivo con menor desvío dentro de ese alcance. Durante el picado, `_guiar_slam()` pide con `Melon.empujar()` una corrección horizontal limitada y marca el objetivo con `en_mira`, que le impide saltar o impulsar un rebote. El HUD llama a `objetivo_slam()` con `Config.slam_confianza_aviso` para avisar solo de caídas con holgura. `actualizar_melones()` usa esa misma consulta para poner `Marca.ACERTABLE` en el objetivo, y durante el picado pone `Marca.FIJADO` en el que devuelve `_guiar_slam()`. `MelonRodante._draw()` dibuja la mira y el soplo de sus impulsos.

`melones_guardados` aporta hasta seis fichas al azar, sin repetirlas. Los espacios vacíos se completan con diseños propios. Cada `MelonRodante` conserva una copia de la apariencia y una textura en su `Lienzo`, igual que el melón del jugador. Así los dibujos grandes no se rehacen al rodar. La bajada usa dos filas, que se unen en el trampolín. Después el rival sale volando hasta la calle y reduce su velocidad hasta su ritmo de rodado.
