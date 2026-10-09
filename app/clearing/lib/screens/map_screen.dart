import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart' as ml;

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/cells.dart';
import '../widgets/app_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiService();
  final _mapController = MapController();
  Timer? _debounce;
  String? _userId;
  String? _error;
  String? _mapError;
  List<MapPhoto> _photos = const [];
  LatLng _center = const LatLng(19.4326, -99.1332);
  bool _loading = true;
  bool _styleLoading = true;
  bool _refreshing = false;
  int _requestVersion = 0;
  double _zoom = 15;
  String? _mapStyleJson;
  String? _styleError;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/clearing_pastel.json');
      if (mounted) setState(() => _mapStyleJson = style);
    } catch (_) {
      if (mounted) setState(() => _styleError = 'Could not load the map style.');
    } finally {
      if (mounted) setState(() => _styleLoading = false);
    }
  }

  Future<void> _loadLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _center = LatLng(position.latitude, position.longitude);
      _userId = await _api.userId();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load your location. Enable GPS and retry.';
        });
      }
    }
  }

  void _scheduleMapRefresh(MapCamera camera) {
    if (mounted) {
      setState(() => _zoom = camera.zoom);
    }
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _refreshMap(camera),
    );
  }

  Future<void> _refreshMap(MapCamera camera) async {
    final userId = _userId;
    if (userId == null) return;
    final bounds = camera.visibleBounds;
    // Keep viewport requests bounded so a far zoom-out cannot trigger an
    // oversized query. Existing pins remain anchored to their true positions.
    if (!isApiBboxAllowed(bounds)) return;
    final requestVersion = ++_requestVersion;
    if (mounted) {
      setState(() {
        _refreshing = true;
        _mapError = null;
      });
    }
    try {
      final result = await _api.fetchMap(userId, apiBboxString(bounds));
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _photos = result.photos;
        _refreshing = false;
      });
    } catch (error) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          _refreshing = false;
          _mapError = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<MapPhoto> _photosForZoom(double zoom) {
    final revealSteps = (zoom - 9).clamp(0, 11);
    final bucketSize = 0.20 / math.pow(2, revealSteps);
    final representatives = <String, MapPhoto>{};
    for (final photo in _photos) {
      final row = (photo.latitude / bucketSize).floor();
      final column = (photo.longitude / bucketSize).floor();
      representatives.putIfAbsent('$row:$column', () => photo);
    }
    return representatives.values.toList();
  }

  Widget _photoMarkerLayer() {
    final zoom = _zoom;
    final scale = (zoom / 15).clamp(0.68, 1.0).toDouble();
    final width = 68 * scale;
    final height = 88 * scale;
    final visiblePhotos = _photosForZoom(zoom);
    final markers = visiblePhotos
        .map(
          (photo) => Marker(
            point: LatLng(photo.latitude, photo.longitude),
            width: width,
            height: height,
            alignment: Alignment.bottomCenter,
            child: _PhotoMapPin(photo: photo, scale: scale),
          ),
        )
        .toList();
    final markerIds = visiblePhotos.map((photo) => photo.id).join(',');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: MarkerLayer(key: ValueKey(markerIds), markers: markers),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.terracotta,
              ),
              const SizedBox(height: 20),
              const Text(
                'Error',
                style: TextStyle(
                  color: AppColors.terracotta,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.slate),
              ),
              const SizedBox(height: 24),
              AppButton(
                variant: AppButtonVariant.accent,
                onPressed: () {
                  setState(() => _error = null);
                  _loadLocation();
                },
                icon: Icons.refresh,
                label: 'Try again',
              ),
            ],
          ),
        ),
      );
    }
    if (_styleLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_styleError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 56, color: AppColors.terracotta),
              const SizedBox(height: 16),
              Text(_styleError!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              AppButton(
                variant: AppButtonVariant.accent,
                onPressed: () {
                  setState(() {
                    _styleError = null;
                    _styleLoading = true;
                  });
                  _loadMapStyle();
                },
                icon: Icons.refresh,
                label: 'Retry',
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: Stack(
        children: [
          _buildMap(),
          if (_mapError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                color: AppColors.surface,
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.terracotta),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Could not update photos. The map is still available.',
                          style: const TextStyle(color: AppColors.slate),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Retry loading photos',
                        onPressed: () => _refreshMap(_mapController.camera),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_refreshing)
            const Positioned(
              top: 16,
              left: 16,
              child: Chip(
                avatar: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: Text('Updating area'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() => FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      initialCenter: _center,
      initialZoom: 15,
      maxZoom: 20,
      initialRotation: 0,
      cameraConstraint: CameraConstraint.contain(
        bounds: LatLngBounds(const LatLng(-85, -180), const LatLng(85, 180)),
      ),
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      onMapReady: () => _refreshMap(_mapController.camera),
      onMapEvent: (event) {
        if (event is MapEventMoveEnd) _scheduleMapRefresh(event.camera);
      },
    ),
    children: [
      _MapLibreBaseLayer(
        key: const ValueKey('clearing-vector-map'),
        styleJson: _mapStyleJson!,
      ),
      _photoMarkerLayer(),
      RichAttributionWidget(
        attributions: [
          TextSourceAttribution('OpenStreetMap contributors'),
          TextSourceAttribution('OpenFreeMap'),
        ],
      ),
    ],
  );
}

class _MapLibreBaseLayer extends StatefulWidget {
  const _MapLibreBaseLayer({super.key, required this.styleJson});

  final String styleJson;

  @override
  State<_MapLibreBaseLayer> createState() => _MapLibreBaseLayerState();
}

class _MapLibreBaseLayerState extends State<_MapLibreBaseLayer> {
  ml.MapController? _mapLibreController;
  StreamSubscription<MapEvent>? _mapEventSubscription;
  MapCamera? _pendingCamera;
  bool _cameraSyncScheduled = false;

  void _queueCameraSync(MapCamera camera) {
    _pendingCamera = camera;
    if (_cameraSyncScheduled) return;

    _cameraSyncScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _cameraSyncScheduled = false;
      if (!mounted) return;

      final current = _pendingCamera;
      final controller = _mapLibreController;
      if (current == null || controller == null) return;

      unawaited(
        controller.moveCamera(
          center: ml.Geographic(
            lon: current.center.longitude,
            lat: current.center.latitude,
          ),
          zoom: current.zoom - 1,
          bearing: -current.rotation,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final flutterCamera = MapCamera.of(context);
    final flutterController = MapController.of(context);
    _mapEventSubscription ??= flutterController.mapEventStream.listen((event) {
      if (event is MapEventWithMove) _queueCameraSync(event.camera);
    });

    return ml.MapLibreMap(
      options: ml.MapOptions(
        initCenter: ml.Geographic(
          lon: flutterCamera.center.longitude,
          lat: flutterCamera.center.latitude,
        ),
        initZoom: flutterCamera.zoom - 1,
        initBearing: -flutterCamera.rotation,
        maxZoom: 19,
        maxPitch: 0,
        initStyle: widget.styleJson,
        gestures: const ml.MapGestures.none(),
      ),
      gestureRecognizers: const {},
      onMapCreated: (controller) {
        _mapLibreController = controller;
        _queueCameraSync(flutterController.camera);
      },
    );
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    super.dispose();
  }
}

class _PhotoMapPin extends StatelessWidget {
  const _PhotoMapPin({required this.photo, required this.scale});

  final MapPhoto photo;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final imageWidth = 62 * scale;
    final imageHeight = 72 * scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: imageWidth,
          height: imageHeight,
          padding: EdgeInsets.all(2 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(color: Colors.white, width: 1.4 * scale),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9 * scale),
            child: Semantics(
              image: true,
              label: photo.description ?? 'Photo from this location',
              child: CachedNetworkImage(
                imageUrl: photo.imageUrl,
                httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
                fit: BoxFit.cover,
                memCacheWidth: 180,
                placeholder: (_, _) => ColoredBox(color: AppColors.beige),
                errorWidget: (_, _, _) => ColoredBox(
                  color: AppColors.beige,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.slate,
                    size: 20 * scale,
                  ),
                ),
              ),
            ),
          ),
        ),
        CustomPaint(
          size: Size(16 * scale, 9 * scale),
          painter: _PinTipPainter(),
        ),
      ],
    );
  }
}

class _PinTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset(1, 1),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = const Color(0xFFD9D6CF)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width - 1, 1),
      Paint()
        ..color = const Color(0xFFD9D6CF)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
