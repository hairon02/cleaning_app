# Misión

_Define la razón de ser del proyecto. Es la referencia que decide si una feature "encaja" o no._

## Qué construimos

Una app móvil en ingles que convierte salir al mundo en la única forma de avanzar: tu mapa empieza cubierto de niebla y solo se despeja cuando tomas una foto real del lugar. Un modelo open-weight que corre en tu propia laptop verifica la foto, la describe y decide si cuenta, sin que tus fotos ni tu ubicación pasen por la nube.

1. **Captura verificada** — foto tomada con la cámara en el momento, con GPS y hora de la captura. Gemma comprueba que es un exterior natural (no una captura ni una pantalla) y genera descripción y etiquetas.
2. **Mapa con niebla** — celdas de cuadrícula que se despejan con cada foto verificada. Es la recompensa visible de salir.
3. **Retos y puntos** — retos diarios (fáciles y cercanos) y uno semanal (más ambicioso), generados con Gemma y revisados antes de usarse. Ranking por reglas objetivas: foto verificada, lugar nuevo, reto cumplido, racha de días.
4. **Diario** — tus fotos con sus descripciones, como registro de tus salidas.

## Para quién

- Personas que quieren pasar menos tiempo en el teléfono y más afuera, y que necesitan una razón concreta para salir (explorar, coleccionar lugares, cumplir un reto).
- Quienes valoran la privacidad: no quieren que sus fotos y su ubicación vivan en el servidor de una empresa.
- Jueces y comunidad del hackathon "Touch Grass", como demostración de que la IA open-weight local puede ser el núcleo de un producto.
- El autor, como proyecto de portafolio.

## Principios

- **Salir es el producto, la pantalla es el medio** — la pantalla principal es la cámara; el mapa y el diario se miran unos segundos. Si una feature aumenta el tiempo frente a la pantalla, no encaja.
- **El ranking premia salidas reales, no atención** — los puntos salen de reglas objetivas (fotos verificadas, celdas nuevas, retos, rachas). Sin votos y sin puntuación de calidad por IA. Perder una racha nunca resta puntos.
- **La IA local es parte de la mecánica, no un adorno** — Gemma decide qué cuenta como salida válida. Si se quita el modelo, el proyecto deja de funcionar.
- **Privacidad por diseño** — fotos, ubicación y metadatos se procesan en tu máquina. Las únicas salidas a internet son los tiles del mapa y, de implementarse, consultas de recomendaciones con un área aproximada.
- **Honestidad sobre lo que la IA puede y no puede hacer** — medimos el acierto del modelo con fotos reales y lo reportamos. Los lugares recomendados salen de datos reales, nunca inventados por el modelo.

## Qué NO es

- No es otra red social de fotos: no hay votos, seguidores ni feed público.
- No es un rastreador pasivo de GPS: la niebla no se despeja por caminar, solo por una foto verificada.
- No es un mapa comunitario público: no se muestra la ubicación de nadie a otros usuarios.
- No es un servicio en la nube ni depende de APIs de IA de terceros.
- No es una app de seguridad ni de navegación: las recomendaciones, si existen, no garantizan que un lugar sea seguro o accesible.
- No es infalible contra trampas: el diseño las dificulta (cámara en el momento, puntos por celda nueva, hash de duplicados), pero no pretende detectarlas todas.
- No es una app que castiga ni empuja a abrirla todos los días: los retos son una invitación, no una obligación.