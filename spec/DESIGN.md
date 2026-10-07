# Terra — Organic Design

## North Star: "Rooted Warmth"
Calm, grounded, and human. Earthy tones, soft shapes, and natural textures create a warm, approachable experience. The camera is the main screen; everything else is glanceable, because the app is used outdoors.

## Colors
- **Primary (`#2D4F1E`):** Forest green — actions, navigation, shutter ring, interactive states.
- **Background (`#F5E6CC`):** Warm beige — organic, never sterile white.
- **Accent (`#E27D60`):** Terracotta — points, streaks, challenge badges, large buttons and icons. Fills and icons only, never small text.
- **Text / Fog (`#4A4A4A`):** Slate grey — body text, and the map fog at ~60–70% opacity. Cleared cells carry no overlay.
- **Surface (`#FBF3E4`, derived):** Lighter beige for cards, so they separate from the background without borders. Optional; remove if the tonal difference isn't needed.
- **Palette philosophy:** Earthy and desaturated. No neon or pure-hue colors.
- Define all colors as tokens in a single Flutter theme file; never hard-code hex values in widgets.

## Typography
- **App name & large titles:** Gebuk — decorative, used sparingly (app name, screen titles only).
- **Body, labels, numbers, Gemma descriptions:** Literata — serif built for reading; legible at small sizes.
- Generous line-height (1.6+ for body). Comfortable, unhurried reading.
- Bundle both fonts as Flutter assets; never load them from the internet at runtime.
- Before shipping, verify Gebuk covers `á é í ó ú ñ ¿ ¡` and that its license allows public/portfolio use. If it fails, fall back to Literata for titles.

## Elevation
- Very soft shadows only: `0 4px 20px rgba(74, 74, 74, 0.08)`.
- Prefer tonal separation over shadows — layer beige and the lighter surface tone.
- Borders: green at low opacity when needed.

## Components
- **Buttons:** Primary = solid forest green with beige text, large border-radius (12px). Secondary = beige bg + green text + thin green border. Terracotta buttons only for large, high-emphasis actions.
- **Cards:** Surface fill, generous padding (24px), rounded corners (12px). No harsh borders.
- **Inputs:** Beige background, rounded, soft green focus ring.
- **Map fog:** Slate grey overlay on unvisited cells; cleared cells fully transparent.

## Rules
- Large touch targets, generous spacing, one-handed use.
- Soft shapes and rounded corners, but **text and key controls must keep strong contrast**: the app is used in direct sunlight. Check every text/background pair with a contrast checker (e.g. WebAIM) and test on a phone outdoors at midday.
- Screens: camera first; map, journal and ranking are glanceable rewards.
- Images should feel natural and warm — avoid clinical or tech-stock imagery.