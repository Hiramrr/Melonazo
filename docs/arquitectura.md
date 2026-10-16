# Arquitectura de ¡Rueda, Melón!

Este documento explica cómo está organizado el proyecto en Godot: qué hace cada escena, cómo se comunican los nodos y dónde tocar para cambiar o añadir cosas. Para jugar, controles y créditos, consulta el [README](../README.md).

## Ideas generales

- **Una carpeta por parte del juego.** La escena y su script están en la misma carpeta (`melon/melon.tscn` + `melon/melon.gd`). Los nombres de archivos y carpetas están en `snake_case`.
- **Un script por nodo.** Cada nodo con comportamiento propio tiene su script y un `class_name` (por ejemplo `Melon`, `Tramo` o `HUD`). Los demás nodos solo organizan la escena.
- **Datos en `Config`, estado en `Juego`.** Ningún script guarda números de balance sueltos. Si quieres ajustar algo, lo más probable es que esté en `globales/config.gd`.
- **Señales hacia arriba, llamadas hacia abajo.** Un nodo hijo avisa con señales (`Melon.aviso`, `GeneradorTerreno.obstaculo_tocado`). El nodo padre llama métodos de sus hijos (`terreno.actualizar(x)`, `hud.actualizar(self)`). Las conexiones estables están en los `.tscn` (sección `[connection]`), así se ven en el editor.
- **Dibujo vectorial.** El melón, el terreno, las postales y los obstáculos se dibujan con `_draw()`. No hacen falta sprites. Los scripts con `@tool` también se ven en el editor.

## Autoloads (`globales/`)

| Nombre | Archivo | Qué contiene |
| --- | --- | --- |
| `Config` | `globales/config.gd` | Reglas y valores ajustables: física, lanzamiento, terreno, economía, apariencia, poderes y postales. Al iniciar carga los accesorios de `melon/accesorios/`. |
| `Juego` | `globales/juego.gd` | Progreso del jugador: aplausos, mejoras, accesorios, aspecto, récord y pasaporte. Calcula las recompensas (`registrar_intento`) y guarda en `user://progreso.json`. |

## Flujo entre pantallas

```text
Taller ──"¡A rodar!"──▶ Recorrido ──fin de carrera──▶ Resultados ──▶ Taller
                           │
                           └──Pausa ▸ "Volver al taller" (sin cobrar)──▶ Taller
```

Las pantallas no se pasan datos directamente: el Taller escribe la elección del jugador en `Juego`, el Recorrido la lee, y al terminar llama a `Juego.registrar_intento()`. Resultados lee `Juego.ultimo`.

## Taller (`pantallas/taller/`)

```text
Taller (taller.gd)                 Coordina pestañas, pie y vista previa
├─ Fondo
└─ Margen/Raiz
   ├─ Cabecera                     Título
   ├─ Medio
   │  ├─ Previa
   │  │  ├─ Vista (vista_melon.gd) Dibuja el melón; recibe el ratón para pintar
   │  │  ├─ NombreVista
   │  │  └─ Carisma
   │  └─ Pestanas (TabContainer)
   │     ├─ TuMelon      (pestanas/pestana_melon.gd)       Nombre, tamaño y aspecto
   │     ├─ Dibujo       (pestanas/pestana_dibujo.tscn)    Pincel, goma y colores
   │     ├─ Accesorios   (pestanas/pestana_accesorios.gd)  Equipar y desbloquear
   │     ├─ Mejoras      (pestanas/pestana_mejoras.gd)     Comprar mejoras
   │     └─ Pasaporte    (pestanas/pestana_pasaporte.gd)   Postales, fotos y poderes
   └─ Pie                          Aplausos, récord, errores y botón "¡A rodar!"
```

Cada pestaña modifica `Juego` y emite su señal `cambio`. El Taller escucha todas y llama a `refrescar()` en cada pestaña, en el pie y en la vista previa. Así ninguna pestaña necesita conocer a las demás. Hay dos excepciones que solo redibujan la vista, porque llegan en cada movimiento del ratón: `Dibujo.cambio` y `TuMelon.color_cambiado`.

Las filas de las listas (tamaños, aspecto, accesorios, mejoras, pasaporte) se generan desde `Config`, por eso no aparecen en el `.tscn`. `comun.gd` (`ComunTaller`) crea esas etiquetas y botones con el mismo estilo en todas las pestañas.

La pestaña se llama `TuMelon` en el árbol, sin acento ni espacio, y el Taller le pone el título "Tu melón" con `set_tab_title()`. La `Vista` necesita `mouse_filter` en *Stop* para recibir el ratón y poder pintar.

## Recorrido (`pantallas/recorrido/`)

```text
Recorrido (recorrido.gd)           Reglas de la carrera y fases
├─ Paisaje (mundo/paisaje/)        Fondo con paralaje, sigue a la cámara
├─ Mundo
│  ├─ Puente                       Salida; colisión independiente
│  ├─ LimiteDeSalida               Pared invisible detrás del puente
│  ├─ Terreno (GeneradorTerreno)   Crea los tramos como hijos
│  │  ├─ Tramo000 (Tramo)
│  │  ├─ Tramo001 …
│  └─ Melon (Melon)
├─ Camara (CamaraRecorrido)        Sigue al melón y ajusta el zoom
├─ Efectos (EfectosRecorrido)      Flecha de puntería y avisos flotantes
└─ Interfaz (HUD)                  Datos, equipo, indicaciones y pausa
```

**Fases** (`Recorrido.Fase`): `ANGULO` → `FUERZA` → `RECORRIDO` → `FIN`. Espacio fija el ángulo y luego la fuerza. La carrera termina si el melón se rompe o avanza menos de `Config.velocidad_min_avance` durante `Config.tiempo_sin_avance` segundos.

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
| `Melon.se_rompio` | `_on_melon_roto` | Termina la carrera |
| `Terreno.obstaculo_tocado(cuerpo, ob)` | `_al_tocar_obstaculo` | Llama a `ob.tocar(melon)` y muestra el aviso |
| `Terreno.poder_recogido(tipo)` | `_al_recoger_poder` | `melon.recibir_poder(tipo)` |

El **HUD** (`hud/hud.tscn`) es un `CanvasLayer` con `process_mode` *Always*, así funciona en pausa. No guarda estado: el Recorrido llama a `hud.actualizar(self)` cada cuadro. Las tres casillas de accesorios son instancias de `hud/slot_accesorio.tscn`.

## El melón (`melon/`)

```text
Melon (RigidBody2D, melon.gd)
├─ Cuerpo          CircleShape2D; el radio depende del tamaño
├─ Accesorio1..3   Una forma convexa por accesorio equipado, en su lado
└─ Estela          Rastro decorativo (estela.gd, top_level)
```

- `melon.gd` lee el control (A/D, Espacio, 1-2-3) y ajusta la velocidad en `_integrate_forces()`: aterrizajes, rebote impulsado, rodado y efectos activos.
- Otros nodos **no cambian `linear_velocity` directamente**. Piden cambios con `empujar(dv)`, `frenar(mult)` o `fijar_velocidad(v)`, y el melón los aplica en el siguiente paso. Así nunca se pisan dos cambios en el mismo cuadro.
- Los temporizadores de efectos (`t_planeo`, `t_cafe`…) se descuentan solos. Están en la lista `TEMPORIZADORES`.
- `aspecto.gd` (`Aspecto`) dibuja piel, patrón, cara, detalle, dibujo libre y accesorios. Solo tiene funciones estáticas. Lo usan el melón del recorrido y la vista previa del taller.

### Capas de física

| Capa | Nombre | Quién |
| --- | --- | --- |
| 1 | Terreno | Segmentos del suelo, puente, cuña de la rampa |
| 2 | Melón | El melón; solo choca con la capa 1 |
| 3 | Recogibles y obstáculos | Áreas que detectan al melón (máscara 2) |

## El mundo (`mundo/`)

| Carpeta | Escenas | Qué hacen |
| --- | --- | --- |
| `terreno/` | `tramo.tscn`, `puente.tscn`, `postal.tscn` + `generador_terreno.gd` | `GeneradorTerreno` crea tramos de `Config.largo_tramo` píxeles y los llena. Cada `Tramo` tiene contenedores fijos: `Decoracion`, `Postales`, `Suelo`, `Obstaculos`, `Publico`, `Coleccionables` y `Aire`. |
| `obstaculos/` | `obstaculo.tscn` y ocho escenas heredadas | Cada tipo edita su forma de colisión en su escena. El efecto está en `Obstaculo.tocar()`. |
| `ayudas/` | `poder.tscn`, `papalote.tscn`, `persona.tscn` | Poderes que se recogen, papalotes que impulsan con E y público que empuja con E. |
| `paisaje/` | `paisaje.tscn` | Fondo lejano con paralaje. Cada capa del cielo es un nodo `CapaCielo` que puedes ocultar o ajustar en el inspector. |

**Generación reproducible.** El terreno usa `Config.semilla_terreno` (−1 = distinto en cada intento). Los papalotes usan un segundo generador (`rng_aire`) para no cambiar la ruta del suelo. Si cambias el orden de las llamadas en `GeneradorTerreno._poblar()`, cambian todas las rutas y las pruebas de balance pueden fallar.

## Resultados (`pantallas/resultados/`)

`resultados.gd` rellena los textos con `Juego.ultimo`. El panel `Postal` (`postal_resultados.gd`) muestra la foto del último lugar alcanzado que tenga fotografía, o la ilustración del puente si no hay.

## Cómo añadir cosas

### Un accesorio

Cada accesorio es un archivo en `melon/accesorios/` que extiende `Accesorio`. `Config` carga todos los archivos de esa carpeta al iniciar, así que no hay listas que actualizar:

1. Copia un accesorio parecido, por ejemplo `sombrero.gd`, con el nombre del nuevo id (`maraca.gd`).
2. En `_init()` define `nombre`, `carisma`, `accion`, `costo`, `orden`, `color`, `forma` e `inicial`.
3. En `usar(m)` combina los efectos de `Melon`: `planear`, `embestir`, `caida_lenta`, `rodar`, `proteger`, `reparar`, `atraer_aplausos`, `sumar_rebote`, `empujar` y `fijar_velocidad`.
4. Si necesita física propia durante unos segundos, llama a `m.activar(self, segundos)` y escribe `fisica(m, v, dt)`. El HUD muestra su tiempo restante solo.
5. Para un dibujo especial, escribe `dibujar_detalle()` o reemplaza `dibujar()`, como hace el paraguas.

### Una opción de aspecto

Pieles, patrones, caras, detalles y estelas son listas en `Config`. Agrega la entrada **al final** de su lista (los índices se guardan) y su dibujo en el `match` correspondiente de `melon/aspecto.gd` (o de `melon/estela.gd` para las estelas). El taller crea las opciones solo. Los colores rápidos y los límites del dibujo libre están en `Config.colores_dibujo`, `grosor_dibujo`, `max_trazos` y `max_puntos_dibujo`.

### Un obstáculo

1. Crea una escena heredada de `mundo/obstaculos/obstaculo.tscn` (por ejemplo `tope.tscn`) y ajusta su `Zona` de colisión.
2. Añade el tipo al `@export_enum` de `obstaculo.gd`, su dibujo en `_draw()` y su efecto en `tocar()`.
3. Registra la escena en `GeneradorTerreno.OBSTACULOS` y su peso en `Config.pesos_obstaculos` y `Config.obstaculos`.

### Un poder

Agrega su entrada en `Config.poderes` y su id en `Config.orden_poderes`, su efecto en `Melon.recibir_poder()` y su silueta en `mundo/ayudas/poder.gd`.

### Una postal

Agrega el lugar en `Config.postales` y su dibujo en `mundo/terreno/postal.gd` (función con el nombre del `tipo`). Para mostrar una foto, añade una entrada con el mismo id en `fotografias` de `recursos/arte_xalapa.tres`.

### Cambiar el terreno

Ajusta `formas_tramo`, `largo_tramo`, `semilla_terreno`, `dificultad_metros` y las separaciones en `Config`. Las rampas y los toldos dan impulso una sola vez por carrera.

## Pruebas (`pruebas/`)

Se ejecutan desde la terminal y nunca tocan tu guardado: cada una usa su propio archivo de prueba y lo borra al terminar. Los comandos están en el README.

| Script | Qué comprueba |
| --- | --- |
| `verificar.gd` | Compras, guardado, datos inválidos, poderes, accesorios, taller, dibujo con ratón, pausa y una carrera completa |
| `balance.gd` | 54 carreras sin controles y la progresión con mejoras |
| `vuelo.gd` | Saltos, papalotes y la ruta aérea |
| `graficos.gd` | Capturas de todas las pantallas a dos resoluciones (abre una ventana) |
