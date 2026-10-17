# Editar las interfaces en Godot

El recurso `interfaz/tema_xalapa.tres` contiene los estilos del menú, taller, almanaque, HUD, pausa y resultados. Godot lo aplica a todo el proyecto mediante `GUI > Theme > Custom`. Las escenas eligen sus variantes con `Theme > Type Variation`.

## Cambiar un estilo

1. Abre `interfaz/tema_xalapa.tres` desde el panel FileSystem.
2. Selecciona el tipo o la variación en el editor de temas del panel inferior.
3. Edita Colors, Constants, Font Sizes, Fonts o Styles según lo que quieras cambiar. Al abrir un StyleBox puedes ajustar su relleno, borde, radios y márgenes interiores.
4. Guarda el recurso y ejecuta la pantalla. El logo y los controles nativos también actualizan su vista en el editor. Reinicia la partida para ver cambios en los rellenos de las barras, que cada HUD copia al crearse.

Para cambiar todos los botones corrientes, edita `Button`. Para cambiar la acción principal, edita `Principal`. `Jugar`, `Rodar` y `Continuar` heredan de `Principal` y tienen sus propios tamaños de letra.

Para sustituir Fredoka en toda la interfaz, cambia Base Font en las dos FontVariation compartidas, `Texto` y `Grueso`. `Pips` usa la fuente sin variación en Fonts/font y se cambia por separado. Default Font Size es el tamaño de reserva. Las variantes con un tamaño propio lo conservan.

## Dónde está cada estilo

| Qué quieres editar | Tipos o variaciones |
| --- | --- |
| Fuente y tamaños base | Default Font y Default Font Size. `Texto` y `Grueso` comparten la familia Fredoka con pesos distintos |
| Botones y sus estados | `Button`, `Principal`, `Comprar`, `Seleccion`, `BotonPequeno`, `BotonMediano`, `BotonSecundario` |
| Logo y títulos | `LogoMenu`, `Titulo`, `TituloTaller`, `TituloPanel`, `TituloPausa` |
| Texto de tarjetas y notas | `NombreTarjeta`, `NombreFicha`, `Subtitulo`, `Suave`, `Descripcion`, `Nota`, `Detalle` |
| Paneles del taller | `PanelPrevia`, `MarcoVista`, `TabContainer`, `Tarjeta` |
| Contadores con iconos | `Chip`, `ChipClaro`, `TextoFichaOscura`, `TextoFichaClara`, `ContadorPrincipal`, `ContadorHUD`, `ContadorTarjeta` |
| Paleta de dibujo | `MuestraColor` y `MuestraColorElegida` |
| Estado del pasaporte | `PostalVisitada`, `PostalPendiente` |
| Mensajes de error | `ErrorGuardado`, `AvisoAccesorios` |
| Lugar y avisos del HUD | `PanelHUD`, `AvisoHUD`, `TextoHUD`, `NombreHUD`, `LugarHUD`, `SiguienteHUD`, `IndicacionHUD`, `IndicacionUrgente` |
| Barras del HUD | `BarraRuta`, `BarraResistencia`, `BarraFuerza` |
| Accesorios y teclas del HUD | `CasillaAccesorio`, `NombreAccesorio`, `TeclaAccesorio`, `TeclaAyuda`, `TeclaAviso` |
| Pausa | `CintaPausa`, `TituloPausa`, `Continuar`, `BotonVolver` |
| Resultados | `CintaResultados`, `PanelResultados`, `DistanciaResultado`, `SelloRecord`, `TotalResultado`, `ValorResultado` |
| Foto y créditos | `Postal`, `MargenPostal`, `TituloFoto`, `TextoPostal`, `Credito`, `EnlaceCredito` |
| Iconos de impulsos y niveles | `Pips`, `ImpulsosHUD`, `NivelesMejora` |
| Fondo de las pantallas | `FondoTaller`, `FondoResultados` |
| Texto sobre el mundo | `AvisoFlotante`, `ObjetivoAereo` |

Los tipos derivados heredan las propiedades que no definen. Por ejemplo, `NombreTarjeta` cambia el tamaño de `Subtitulo` y conserva su fuente. Los botones que cambian de estado usan variaciones derivadas como `SeleccionMediana` y `ComprarMediano` para conservar el tamaño.

Algunos StyleBox son compartidos entre estados o tipos. Por ejemplo, `pressed` y `hover_pressed` pueden apuntar al mismo recurso. Si necesitas editar solo uno, usa Make Unique sobre ese StyleBox antes de modificarlo.

## Colores que dependen del juego

Estas propiedades también viven en el Theme, aunque las dibuje un script.

| Variación | Colors |
| --- | --- |
| `BarraFuerza` | `inicio`, `fin`, `perfecta`, `zona`, `borde_zona`, `marca` |
| `BarraResistencia` | `baja`, `media`, `alta`, `perdida`, `marca` |
| `CasillaAccesorio` | `ocupada`, `vacia`, `icono_vacio` |
| `Button` | `accesorio_bloqueado` |
| `Pips` | `apagado`, `font_color`, `font_outline_color` |
| `FondoTaller`, `FondoResultados` | `arriba`, `abajo`, `rayos` |
| `Postal` | `cinta` |
| `AvisoFlotante` | `color_0`, `color_1`, `color_2`, `color_3`, `font_outline_color` |

Los rellenos de `BarraFuerza` y `BarraResistencia` y los estilos de `MuestraColor` y `MuestraColorElegida` usan StyleBoxFlat. Conserva ese tipo. El código duplica la plantilla antes de aplicar la potencia, el daño o el color elegido para pintar. No cambia el recurso compartido. En las muestras, `bg_color` representa el color del jugador y el Theme controla el borde y la forma.

La postal usa StyleBoxTexture con regiones de `recursos/sprites/interfaz.png`. Puedes cambiar sus texturas desde Styles en `Postal`.

## Distribución y arte

Para mover controles, cambiar columnas, tamaños mínimos, anclajes o márgenes de una pantalla, abre su `.tscn`. Esos valores siguen disponibles en el inspector. Los componentes creados por código usan las variaciones `Fila*`, `Columna*` y `RejillaTarjetas` para su separación.

Los dibujos del melón, sus accesorios y el paisaje siguen usando los PNG de `recursos/sprites/`. Las vistas de estos dibujos conservan el filtro Nearest. Los iconos de interfaz viven en `recursos/iconos/`.

## Añadir un control

Usa un control nativo y selecciona su variación en `Theme > Type Variation`. Evita añadir Theme Overrides de colores, fuentes o estilos al nodo, porque tienen prioridad sobre el Theme.

Los helpers reciben el nombre de la variación.

```gdscript
var nombre := ComunTaller.titulo_seccion("Sombrero", &"NombreTarjeta")
var boton := ComunTaller.boton("Comprar", &"ComprarMediano")
var contador := Ficha.crear(Iconos.APLAUSO, "120", false, &"ContadorTarjeta")
var tecla := Iconos.tecla("E", &"TeclaAyuda")
```

`Ficha.estilo_texto` permite elegir la variante de su etiqueta desde el inspector. Si está vacío, usa `TextoFichaOscura` o `TextoFichaClara` según `oscura`.

En un Control, asigna `theme_type_variation` y consulta `get_theme_color`, `get_theme_font` o `get_theme_stylebox` sin especificar otro tipo. Los Node2D no heredan temas. Los avisos del recorrido consultan `ThemeDB.get_project_theme()` y definen sus propiedades explícitas en `AvisoFlotante` y `ObjetivoAereo`.

En esas dos variaciones puedes cambiar los valores, pero conserva todas las entradas. Las consultas directas al recurso Theme no buscan propiedades heredadas. La prueba de temas detecta si falta alguna.

La [documentación del editor de temas de Godot](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html) describe los controles del editor y la vista previa.

## Verificación

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/temas.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/graficos.gd
```

La primera prueba cambia propiedades del Theme en memoria y comprueba que lleguen a las pantallas, controles dinámicos, selección, barras y sello de récord. Usa un guardado separado. La segunda comprueba los límites de los controles y captura las pantallas a 1280 × 720 y 960 × 540 en `user://revision_grafica/`.
