# Fotografías reales de Xalapa

Las imágenes se descargaron de Wikimedia Commons el 15 de octubre de 2026. Se incluyen localmente y funcionan sin conexión. Las versiones reducidas y su presentación conservan la licencia indicada en cada fotografía. No se usaron retoques generativos.

El juego muestra los créditos y los enlaces a la fuente y licencia debajo de cada fotografía. `creditos.json` conserva los datos de descarga.

## Cambiar o quitar las fotos

Abre `recursos/arte_xalapa.tres` en Godot y edita `fotografias`. Cada clave corresponde a un lugar de `Config.postales`. Cambia `textura` y los créditos cuando sustituyas una foto. Para quitar una foto, elimina su entrada y guarda el recurso antes de borrar el JPG. Para quitar todas, vacía `fotografias`. Los resultados recuperan la panorámica real y el pasaporte conserva los textos.

Las fotografías aparecen en el pasaporte, con independencia de los lugares desbloqueados. La postal de resultados usa el último lugar con fotografía alcanzado en esa carrera. Una vista desde Parque Juárez muestra el Pico de Orizaba, no el parque en primer plano.

## Puente de Xallitic

- Archivo: `xallitic.jpg`.
- Autor: Juan Javier Mora-Rivera.
- Fuente: [Puente de Xallitic](https://commons.wikimedia.org/wiki/File:Bajos_del_Puente_de_Xallitic,_Xalapa,_Veracruz.jpg).
- Licencia: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0).
- Cambios: Versión reducida de Wikimedia. Encuadre al mostrar en el juego. Sin retoques generativos.
- Descarga: [versión incluida](https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Bajos_del_Puente_de_Xallitic%2C_Xalapa%2C_Veracruz.jpg/1280px-Bajos_del_Puente_de_Xallitic%2C_Xalapa%2C_Veracruz.jpg).

## Catedral de Xalapa

- Archivo: `catedral.jpg`.
- Autor: Soundtrckk.
- Fuente: [Catedral de Xalapa](https://commons.wikimedia.org/wiki/File:Catedral_Metropolitana_de_Xalapa.jpg).
- Licencia: [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0).
- Cambios: Versión reducida de Wikimedia. Encuadre al mostrar en el juego. Sin retoques generativos.
- Descarga: [versión incluida](https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0e/Catedral_Metropolitana_de_Xalapa.jpg/1280px-Catedral_Metropolitana_de_Xalapa.jpg).

## Vista desde Parque Juárez

- Archivo: `juarez.jpg`.
- Autor: Burkhard Mücke.
- Fuente: [Vista desde Parque Juárez](https://commons.wikimedia.org/wiki/File:Vista_del_Pico_de_Orizaba_desde_Parque_Ju%C3%A1rez_01.jpg).
- Licencia: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0).
- Cambios: Versión reducida de Wikimedia. Encuadre al mostrar en el juego. Sin retoques generativos.
- Descarga: [versión incluida](https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fb/Vista_del_Pico_de_Orizaba_desde_Parque_Ju%C3%A1rez_01.jpg/1280px-Vista_del_Pico_de_Orizaba_desde_Parque_Ju%C3%A1rez_01.jpg).

## Paseo de Los Lagos

- Archivo: `lagos.jpg`.
- Autor: Adam Jones from Kelowna, BC, Canada.
- Fuente: [Paseo de Los Lagos](https://commons.wikimedia.org/wiki/File:Park_Scene_-_Paseo_de_los_Lagos_-_Xalapa_-_Veracruz_-_Mexico_-_04_(15470840693).jpg).
- Licencia: [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0).
- Cambios: Versión reducida de Wikimedia. Encuadre al mostrar en el juego. Sin retoques generativos.
- Descarga: [versión incluida](https://thumb.wikimedia.org/wikipedia/commons/thumb/4/46/Park_Scene_-_Paseo_de_los_Lagos_-_Xalapa_-_Veracruz_-_Mexico_-_04_%2815470840693%29.jpg/1280px-Park_Scene_-_Paseo_de_los_Lagos_-_Xalapa_-_Veracruz_-_Mexico_-_04_%2815470840693%29.jpg).


## Fondo fotográfico del taller y del recorrido

- Archivo: `panorama_xalapa.jpg`.
- Autor: Koffermejia.
- Fuente: [Xalapa desde el Ágora](https://commons.wikimedia.org/wiki/File:Panorama_xalapa_desde_el_agora.jpg).
- Licencia: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0).
- Cambios: Archivo original. Recorte proporcional en pantalla mediante AtlasTexture para excluir los bordes vacíos de la panorámica. Sin retoques generativos.
- Descarga: [archivo original](https://upload.wikimedia.org/wikipedia/commons/2/25/Panorama_xalapa_desde_el_agora.jpg).

El fondo se configura en `paisaje`, por separado de las fotos del pasaporte. Al cambiarlo también hay que actualizar `credito_paisaje`. El encuadre excluye bordes vacíos del panorama mediante AtlasTexture. La imagen generada anterior ya no se carga.
