# Imágenes provisionales de poderes, Salsa Valentina y pájaros

Todas son PNG cuadrados de 256 × 256 píxeles con fondo transparente. Son provisionales: se pueden sustituir por el arte definitivo sin tocar código.

## Cómo reemplazarlas

- **Lo más fácil:** sobrescribe el PNG con otro del mismo nombre. Godot lo vuelve a importar solo. Conserva el fondo transparente y un lienzo cuadrado para no deformar el dibujo.
- **Otro nombre u otro formato** (WebP, un `AtlasTexture` recortado de una hoja de sprites…): cámbialo en el sitio indicado en la tabla. Los que dicen "inspector" se cambian en el editor, sin programar.
- **Animación en tira:** el pájaro y la explosión aceptan una tira horizontal de cuadros del mismo ancho. En el inspector, pon la tira en la textura y el número de cuadros en `cuadros` / `cuadros_explosion`. Con 1 cuadro, el juego anima la imagen fija (aleteo o crecimiento).

| Archivo | Qué es | Dónde se usa | Dónde se cambia |
| --- | --- | --- | --- |
| `chile.png` | Chile jalapeño | Poder del camino, almanaque, pasaporte | `TEXTURAS` en `mundo/ayudas/poder.gd` |
| `cafe.png` | Café de Coatepec | Poder del camino, almanaque, pasaporte | `TEXTURAS` en `mundo/ayudas/poder.gd` |
| `pizza.png` | Pizza con yogur | Poder del camino, almanaque, pasaporte | `TEXTURAS` en `mundo/ayudas/poder.gd` |
| `pizza.png` | La pizza en la que viaja el melón | Sobre el melón en la carrera | Inspector de `melon/melon.tscn`, `textura_pizza` |
| `explosion.png` | Explosión del chile | Sobre el melón en la carrera | Inspector de `melon/melon.tscn`, `textura_explosion` y `cuadros_explosion` |
| `valentina.png` | Salsa Valentina | Tiendita, almanaque y contador del HUD | `TEXTURAS` en `mundo/ayudas/poder.gd` y la ficha `Valentinas` de `pantallas/recorrido/hud/hud.tscn` |
| `pajaro.png` | Pájaro, mirando a la izquierda | Obstáculo en el aire | Inspector de `mundo/obstaculos/pajaro.tscn`, `textura`, `cuadros` y `lado` |

La pizza del poder y la del melón usan el mismo archivo. Si quieren un dibujo distinto para cuando el melón va montado, agreguen otro PNG y asígnenlo a `textura_pizza`.

## Origen

`cafe.png`, `pajaro.png` y la base de `pizza.png` son imágenes 3D de [Microsoft Fluent Emoji](https://github.com/microsoft/fluentui-emoji), revisión `1ffb34c752ecf5d402f04cfb4b392c77f57c54bc`. Copyright Microsoft Corporation. Licencia MIT, incluida completa en [LICENSE.txt](LICENSE.txt).

| Archivo | Imagen original |
| --- | --- |
| `cafe.png` | [Hot beverage](https://github.com/microsoft/fluentui-emoji/blob/1ffb34c752ecf5d402f04cfb4b392c77f57c54bc/assets/Hot%20beverage/3D/hot_beverage_3d.png), sin cambios |
| `chile.png` | Imagen de jalapeño proporcionada por el usuario el 17 de octubre de 2026; reemplaza el recurso provisional anterior |
| `pajaro.png` | [Bird](https://github.com/microsoft/fluentui-emoji/blob/1ffb34c752ecf5d402f04cfb4b392c77f57c54bc/assets/Bird/3D/bird_3d.png), sin cambios |
| `pizza.png` | [Pizza](https://github.com/microsoft/fluentui-emoji/blob/1ffb34c752ecf5d402f04cfb4b392c77f57c54bc/assets/Pizza/3D/pizza_3d.png), con un chorro de yogur dibujado encima |

`valentina.png` y `explosion.png` son dibujos simples hechos para el proyecto.
