# Tasks — 007 · Map Screen

## Implemented

- [x] Load verified user photos in the visible map bounds and return thumbnail URLs.
- [x] Render photos as lightweight location pins with a subtle border and downward tip.
- [x] Keep a sparse representative set of photos when zoomed out and progressively reveal more at closer zooms.
- [x] Fade marker groups smoothly when the visible density changes.
- [ ] Replace raster tiles with MapLibre vector rendering; preserve photo pins and lock rotation.
- [x] Add three Puebla demo pins backed by `test1.jpg`, `test2.jpg`, and `test3.jpg`.
- [x] Keep the map visible when photo requests fail and provide an in-map retry action.
- [x] Keep map requests bounded to avoid oversized viewports and the previous 400 response.
- [x] Remove the rectangular/circular fog overlays and cell-progress counter.
- [ ] Add a Clearing pastel vector style: blue water, green parks, warm roads, no buildings, labels, or map signage.
- [ ] Add MapLibre WebGL assets and OpenFreeMap/OpenStreetMap attribution.

## Backlog

- [ ] Tapping a photo pin opens a detail modal with place, challenge, and captured photo.
- [ ] Link the three Puebla demo pins to their detail-modal content.

## Verification

- [x] Use ui-ux-pro-max before implementing the map experience.
- [ ] Use Impeccable after implementation and review the result.
- [ ] Verify marker behavior on a physical phone with real uploaded photos and map gestures.
