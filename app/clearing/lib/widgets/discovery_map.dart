import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DiscoveryMap extends StatefulWidget {
  const DiscoveryMap({
    super.key,
    required this.styleUri,
    required this.center,
    required this.photos,
    required this.onViewportChanged,
    required this.onMapError,
  });

  final String styleUri;
  final LatLng center;
  final List<MapPhoto> photos;
  final void Function(LatLngBounds bounds, double zoom) onViewportChanged;
  final ValueChanged<String> onMapError;

  @override
  State<DiscoveryMap> createState() => DiscoveryMapState();
}

class DiscoveryMapState extends State<DiscoveryMap> {
  final _markerOffsets = ValueNotifier<Map<String, Offset>>({});
  MapboxMap? _map;
  Timer? _projectionTimer;
  ui.Size _size = ui.Size.zero;
  int _projectionVersion = 0;
  bool _projectingMarkers = false;
  bool _projectionPending = false;

  void moveTo(LatLng point) {
    final map = _map;
    if (map == null) return;
    unawaited(
      map.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(point.longitude, point.latitude)),
          zoom: 15,
          bearing: 0,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 450),
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    try {
      await map.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: false,
          simultaneousRotateAndPinchToZoomEnabled: false,
          pitchEnabled: false,
          pitchWithRotateEnabled: false,
        ),
      );
      await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
      // Keep Mapbox attribution visible as required by the map style terms,
      // but move it away from the bottom edge and hide the verbose text.
      await map.attribution.updateSettings(
        AttributionSettings(
          enabled: true,
          position: OrnamentPosition.TOP_LEFT,
          marginTop: 8,
          marginLeft: 8,
        ),
      );
      await map.setBounds(
        CameraBoundsOptions(maxZoom: 20, maxPitch: 0, minPitch: 0),
      );
      await _publishViewport();
      _scheduleProjection();
    } catch (error) {
      widget.onMapError(error.toString());
    }
  }

  Future<void> _publishViewport() async {
    final map = _map;
    if (map == null) return;
    try {
      final camera = await map.getCameraState();
      final bounds = await map.coordinateBoundsForCamera(
        camera.toCameraOptions(),
      );
      final southwest = bounds.southwest.coordinates;
      final northeast = bounds.northeast.coordinates;
      widget.onViewportChanged(
        LatLngBounds(
          LatLng(southwest.lat.toDouble(), southwest.lng.toDouble()),
          LatLng(northeast.lat.toDouble(), northeast.lng.toDouble()),
        ),
        camera.zoom,
      );
    } catch (error) {
      widget.onMapError(error.toString());
    }
  }

  void _scheduleProjection() {
    if (_projectionTimer?.isActive ?? false) return;
    if (_projectingMarkers) {
      _projectionPending = true;
      return;
    }
    _projectionTimer = Timer(
      const Duration(milliseconds: 60),
      () {
        _projectionTimer = null;
        unawaited(_projectMarkers());
      },
    );
  }

  Future<void> _projectMarkers() async {
    if (_projectingMarkers) {
      _projectionPending = true;
      return;
    }
    _projectingMarkers = true;
    final map = _map;
    final photos = widget.photos;
    final version = ++_projectionVersion;
    if (map == null ||
        photos.isEmpty ||
        _size.width <= 0 ||
        _size.height <= 0) {
      _markerOffsets.value = const {};
      _finishProjection();
      return;
    }

    try {
      final pixels = await map.pixelsForCoordinates(
        photos
            .map(
              (photo) => Point(
                coordinates: Position(photo.longitude, photo.latitude),
              ),
            )
            .toList(),
      );
      if (!mounted || version != _projectionVersion) return;

      final offsets = <String, Offset>{};
      for (
        var index = 0;
        index < photos.length && index < pixels.length;
        index++
      ) {
        final pixel = pixels[index];
        final x = pixel.x.toDouble();
        final y = pixel.y.toDouble();
        final isVisible =
            x >= -72 &&
            x <= _size.width + 72 &&
            y >= -84 &&
            y <= _size.height + 84;
        if (isVisible) {
          offsets[photos[index].id] = Offset(x, y);
        }
      }
      _markerOffsets.value = offsets;
    } catch (_) {
      // A transient camera/style update can invalidate projection; the next
      // camera event will project the markers again.
    } finally {
      _finishProjection();
    }
  }

  void _finishProjection() {
    _projectingMarkers = false;
    if (!mounted) return;
    if (_projectionPending) {
      _projectionPending = false;
      _scheduleProjection();
    }
  }

  void _onCameraChanged(CameraChangedEventData _) => _scheduleProjection();

  void _onMapIdle(MapIdleEventData _) {
    unawaited(_publishViewport());
    _scheduleProjection();
  }

  @override
  void didUpdateWidget(covariant DiscoveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center) moveTo(widget.center);
    if (oldWidget.styleUri != widget.styleUri && _map != null) {
      unawaited(_map!.loadStyleURI(widget.styleUri));
    }
    if (oldWidget.photos != widget.photos) _scheduleProjection();
  }

  @override
  void dispose() {
    _projectionTimer?.cancel();
    _markerOffsets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final nextSize = ui.Size(constraints.maxWidth, constraints.maxHeight);
      if (nextSize != _size) {
        _size = nextSize;
        _scheduleProjection();
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          MapWidget(
            styleUri: widget.styleUri,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(
                  widget.center.longitude,
                  widget.center.latitude,
                ),
              ),
              zoom: 15,
              bearing: 0,
              pitch: 0,
            ),
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChanged,
            onMapIdleListener: _onMapIdle,
            onStyleLoadedListener: (_) {
              unawaited(_publishViewport());
              _scheduleProjection();
            },
            onMapLoadErrorListener: (event) =>
                widget.onMapError('${event.type}: ${event.message}'),
          ),
          Positioned.fill(
            child: ValueListenableBuilder<Map<String, Offset>>(
              valueListenable: _markerOffsets,
              builder: (context, offsets, _) => Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final photo in widget.photos)
                    if (offsets[photo.id] case final point?)
                      Positioned(
                        left: point.dx - 34,
                        top: point.dy - 78,
                        width: 68,
                        height: 78,
                        child: IgnorePointer(child: _PhotoPin(photo: photo)),
                      ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PhotoPin extends StatelessWidget {
  const _PhotoPin({required this.photo});
  final MapPhoto photo;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(photo.takenAt ?? '')?.toLocal();
    final now = DateTime.now();
    final isToday =
        date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.iconSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? AppColors.terracotta : AppColors.iconSurface,
              width: isToday ? 3 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photo.imageUrl,
              headers: const {'ngrok-skip-browser-warning': 'true'},
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.beige,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.slate,
                ),
              ),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const ColoredBox(
                      color: AppColors.beige,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        CustomPaint(size: const ui.Size(16, 9), painter: _PinTipPainter()),
      ],
    );
  }
}

class _PinTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.iconSurface);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
