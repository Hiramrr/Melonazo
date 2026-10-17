# Sprites de LibreSprite

El arte que antes dibujaba Godot con líneas, círculos y polígonos está convertido a hojas PNG con transparencia y metadatos JSON Hash. La conversión usa los dibujos existentes, sin generación de imágenes con IA.

Cada hoja tiene dos archivos con el mismo nombre. El PNG contiene los cuadros. El JSON indica su posición, tamaño y duración, con los campos `frame`, `rotated`, `trimmed`, `spriteSourceSize`, `sourceSize`, `duration` y `meta`. El esquema sigue el [exportador de LibreSprite](https://github.com/LibreSprite/LibreSprite/blob/master/src/app/document_exporter.cpp).

| Hoja | Contenido |
| --- | --- |
| `melon` | Cuerpo, borde, sombra, luz, tallo, grieta, patrones, caras y detalles |
| `accesorios` | Los ocho accesorios, orientados hacia arriba |
| `terreno` | Suelos, muro, calle de la bajada, casas, árboles, papel picado, barrera y letrero |
| `postales` | Ilustraciones de lugares |
| `obstaculos` | Los ocho obstáculos y el puesto roto |
| `ayudas` | Público por pose y por capa de color, papalotes, corrientes e insignia |
| `paisaje` | Cielo por altura, sol, nubes, aves, papalotes, cerros, ciudad, niebla y costa |
| `interfaz` | Fondos, rayos, papel picado y marco de la postal |
| `efectos` | Estelas, aros, fragmentos, marcas, soplo y flechas |
| `transiciones` | Dieciséis cuadros de la cortina circular entre pantallas |

Los iconos existentes siguen en `recursos/iconos/`, los poderes en `recursos/poderes/` y el fondo del taller en `recursos/taller_xallitic.png`. Ya son PNG. Las fotografías conservan sus archivos y créditos.

## Editar en LibreSprite

1. Abre la hoja PNG y edita los píxeles del cuadro que quieras cambiar. El JSON identifica sus coordenadas.
2. Conserva las dimensiones del PNG y la posición de cada cuadro. Guarda como PNG RGBA con transparencia. No hace falta modificar el JSON si solo cambias los píxeles.
3. Guarda tu archivo de trabajo como `.ase` si necesitas conservar capas. Godot consume el PNG y el JSON, no el `.ase`.
4. Para sustituir una hoja mediante Export Sprite Sheet, elige JSON Hash, conserva los nombres de los cuadros y desactiva el recorte y la rotación de cuadros. Los lienzos originales de cada cuadro deben conservar sus medidas. Puedes cambiar las posiciones en la hoja si actualizas su JSON junto con el PNG.

Las animaciones `aves_0` a `aves_7` y `papalote_0` a `papalote_7` toman la duración de cada cuadro del JSON. Los demás cuadros son variantes o capas independientes.

`paleta.gpl` es una referencia de colores, no una paleta obligatoria de la conversión. Los dibujos convertidos conservan los colores originales.

## Uso en Godot

`globales/sprites.gd` carga ambos archivos con `preload`, por lo que Godot los incluye al exportar el juego. Cada píxel del PNG ocupa dos píxeles del mundo antes de aplicar la escala del objeto. El filtro Nearest mantiene los bordes al ampliar.

El melón combina capas teñidas para conservar colores propios, caras y patrones. Los accesorios usan el mismo ángulo y radio que su colisión. El terreno coloca columnas de textura a la altura de la superficie física. Las coordenadas vectoriales que quedan en el juego describen movimiento y colisiones.

El dibujo libre conserva sus puntos en el guardado. `Aspecto.dibujar_trazos()` los rasteriza al cambiar el trazo y reutiliza la textura al mover o girar el melón. Los textos y controles nativos de Godot conservan sus fuentes y su comportamiento.

## Verificar

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://pruebas/sprites.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/aspecto.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/pincel.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://pruebas/rendimiento.gd
```
