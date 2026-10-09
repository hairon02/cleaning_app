# Terra — Organic Design

## UI/UX workflow (mandatory)

Todo trabajo frontend debe usar las dos skills instaladas en este orden:

1. **ui-ux-pro-max primero:** define y verifica la dirección visual, tokens, tipografía, layout, interacción, accesibilidad y guía específica de Flutter. Las decisiones deben quedar reflejadas aquí o en la spec de la feature antes de implementar.
2. **Impeccable después:** audita la interfaz real implementada, revisa UX, accesibilidad, responsive, rendimiento y estados límite, y aplica el pulido final. Sus hallazgos deben resolverse antes de cerrar la tarea.

La primera skill establece la dirección; la segunda valida y eleva la calidad de la implementación. Este flujo no sustituye los requisitos funcionales ni los criterios de aceptación.

### Evidencia requerida

- Registrar las decisiones y consultas relevantes de ui-ux-pro-max.
- Ejecutar Impeccable sobre las pantallas o componentes modificados y registrar su resultado.
- Validar safe areas, targets táctiles, contraste, texto dinámico, estados de carga/error y dispositivos objetivo.
- Documentar cualquier excepción a este orden en el plan de la feature.

## North Star: "Rooted Warmth"
Calm, grounded, and human. Earthy tones, soft shapes, and natural textures create a warm, approachable experience. The camera is the main screen; everything else is glanceable, because the app is used outdoors.

## Colors
- **Primary (`#2D4F1E`):** Forest green — actions, navigation, shutter ring, interactive states.
- **Background (`#F5E6CC`):** Warm beige — organic, never sterile white.
- **Accent (`#E27D60`):** Terracotta — points, streaks, challenge badges, large buttons and icons. Fills and icons only, never small text.
- **Text (`#4A4A4A`):** Slate grey for body text.
- **Surface (`#FBF3E4`, derived):** Lighter beige for cards, so they separate from the background without borders. Optional; remove if the tonal difference isn't needed.
- **Palette philosophy:** Earthy and desaturated. No neon or pure-hue colors.
- Define all colors as tokens in a single Flutter theme file; never hard-code hex values in widgets.

## Typography
- **App name & large titles:** Gebuk — decorative, used sparingly (app name, screen titles only).
- **Body, labels, numbers, Gemma descriptions:** Literata — serif built for reading; legible at small sizes.
- Generous line-height (1.6+ for body). Comfortable, unhurried reading.
- Bundle fonts as Flutter assets; never load them from the internet at runtime. Literata is currently bundled under SIL OFL and is the active family for body and title text.
- Gebuk remains the intended display face, but its available distribution requires a commercial embedding license. Add it only after acquiring that license and verifying coverage for `á é í ó ú ñ ¿ ¡`; until then, Literata is the approved title fallback.

## Elevation
- Very soft shadows only: `0 4px 20px rgba(74, 74, 74, 0.08)`.
- Prefer tonal separation over shadows — layer beige and the lighter surface tone.
- Borders: green at low opacity when needed.

## Components
- **Buttons:** Primary = solid forest green with beige text, large border-radius (12px). Secondary = beige bg + green text + thin green border. Terracotta buttons only for large, high-emphasis actions.
- **Cards:** Surface fill, generous padding (24px), rounded corners (12px). No harsh borders.
- **Inputs:** Beige background, rounded, soft green focus ring.
- **Map:** Colorful pastel vector basemap with blue water, green spaces, warm non-yellow roads, and photo-location pins. Hide building footprints, labels, and map signage; no fog, cell grid, or cleared-area overlay. Pan and zoom stay enabled while rotation is locked.

## Rules
- Large touch targets, generous spacing, one-handed use.
- Soft shapes and rounded corners, but **text and key controls must keep strong contrast**: the app is used in direct sunlight. Check every text/background pair with a contrast checker (e.g. WebAIM) and test on a phone outdoors at midday.
- Screens: camera first; map, journal and ranking are glanceable rewards.
- Images should feel natural and warm — avoid clinical or tech-stock imagery.
