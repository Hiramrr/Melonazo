# Imágenes de poderes, Salsa Valentina y pájaros

Los cinco iconos de poderes y Salsa Valentina son PNG transparentes de 64 × 64 píxeles proporcionados por el usuario.

## Cómo reemplazarlas

- **Lo más fácil:** sobrescribe el PNG con otro del mismo nombre. Godot lo vuelve a importar solo. Conserva el fondo transparente y un lienzo cuadrado para no deformar el dibujo.
- **Otro nombre u otro formato** (WebP, un `AtlasTexture` recortado de una hoja de sprites…): cámbialo en el sitio indicado en la tabla. Los que dicen "inspector" se cambian en el editor, sin programar.
- **Animación en tira:** el pájaro y la explosión aceptan una tira horizontal de cuadros del mismo ancho. En el inspector, pon la tira en la textura y el número de cuadros en `cuadros` / `cuadros_explosion`. Con 1 cuadro, el juego anima la imagen fija (aleteo o crecimiento).

| Archivo | Qué es | Dónde se usa | Dónde se cambia |
| --- | --- | --- | --- |
| `chile.png` | Chile jalapeño | Poder del camino, almanaque, pasaporte | `TEXTURAS` en `mundo/ayudas/poder.gd` |
| `cafe.png` | Café de Coatepec | Poder del camino, almanaque, pasaporte | `TEXTURAS` en `mundo/ayudas/poder.gd` |
| `pizza.png` | Pizza con yogur | Poder del camino, almanaque, pasaporte | `TEXTURAS` en `mundo/ayudas/poder.gd` |
| `elote.png` | Elote de feria | Poder del camino, almanaque, pasaporte | `TEXTURAS` en `mundo/ayudas/poder.gd` |
| `pizza.png` | Pizza ovni que abduce al melón | Sobre el melón en la carrera | `TEXTURA` en `melon/pizza_ovni.gd` |
| `explosion.png` | Explosión del chile | Sobre el melón en la carrera | Inspector de `melon/melon.tscn`, `textura_explosion` y `cuadros_explosion` |
| `valentina.png` | Salsa Valentina | Tiendita, almanaque y contador del HUD | `TEXTURAS` en `mundo/ayudas/poder.gd` y la ficha `Valentinas` de `pantallas/recorrido/hud/hud.tscn` |
| `pajaro.png` | Pájaro, mirando a la izquierda | Obstáculo en el aire | Inspector de `mundo/obstaculos/pajaro.tscn`, `textura`, `cuadros` y `lado` |

La pizza del poder y el ovni usan el mismo archivo.

## Origen

`cafe.png`, `chile.png`, `elote.png`, `pizza.png` y `valentina.png`: sprites proporcionados por el usuario el 19 de octubre de 2026.

`pajaro.png`: paloma pixel art proporcionada por el usuario el 19 de octubre de 2026, adaptada a 64 × 64 y orientada a la izquierda.

`explosion.png` es un dibujo hecho para el proyecto.
