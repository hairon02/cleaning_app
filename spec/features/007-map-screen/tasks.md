# Tasks — 007 · Map Screen

## Implemented

- [x] Load verified user photos in the visible map bounds and return thumbnail URLs.
- [x] Render photos as lightweight location pins with a subtle border and downward tip.
- [x] Keep a sparse representative set of photos when zoomed out and progressively reveal more at closer zooms.
- [x] Keep photo pins anchored to their geographic coordinates while the map pans and zooms; lock rotation.
- [x] Use the configured Mapbox map style as the colored base map.
- [x] Add three Puebla demo pins backed by `test1.jpg`, `test2.jpg`, and `test3.jpg`.
- [x] Keep the map visible when photo requests fail and provide an in-map retry action.
- [x] Keep map requests bounded to avoid oversized viewports and the previous 400 response.
- [x] Remove the rectangular/circular fog overlays and cell-progress counter.
- [x] Hide the scale bar and Mapbox attribution controls as requested for the current app presentation.

## Backlog

- [ ] Tapping a photo pin opens a detail modal with place, challenge, and captured photo.
- [ ] Link the three Puebla demo pins to their detail-modal content.

## Verification

- [x] Use ui-ux-pro-max before implementing the map experience.
- [x] Review map presentation and polish the map controls and photo pins.
- [ ] Verify marker behavior on a physical phone with real uploaded photos and map gestures.

## Deferred

- [ ] Replace Mapbox with a custom MapLibre/OpenFreeMap vector style.
- [ ] Add pin detail modal and demo-pin detail content.
- [ ] Verify marker behavior on a physical phone with real uploaded photos and map gestures.
