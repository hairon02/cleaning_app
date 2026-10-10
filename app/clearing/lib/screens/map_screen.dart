import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/cells.dart';
import '../widgets/discovery_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.onBackToCamera, this.onOpenJournal});
  final VoidCallback? onBackToCamera;
  final VoidCallback? onOpenJournal;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiService();
  final _map = GlobalKey<DiscoveryMapState>();
  Timer? _refreshTimer;
  String? _userId;
  List<MapPhoto> _photos = const [];
  LatLng _center = const LatLng(19.4326, -99.1332);
  bool _hasUserLocation = false;
  bool _locationDisabled = false;
  bool _loadingPhotos = false;
  String? _error;
  String? _tileError;
  int _totalCleared = 0;
  int _requestVersion = 0;
  double _zoom = 15;

  String get _token => dotenv.env['MAPBOX_ACCESS_TOKEN']?.trim() ?? '';
  String get _styleUri {
    final configured = dotenv.env['MAPBOX_STYLE_ID']?.trim();
    if (configured == null || configured.isEmpty) {
      return 'mapbox://styles/mapbox/streets-v12';
    }
    if (configured.startsWith('mapbox://styles/')) {
      return configured.split('?').first;
    }
    final uri = Uri.tryParse(configured);
    if (uri?.host == 'api.mapbox.com') {
      final parts = uri!.pathSegments;
      final versionIndex = parts.indexOf('v1');
      if (versionIndex >= 0 && parts.length > versionIndex + 2) {
        final owner = parts[versionIndex + 1];
        final style = parts[versionIndex + 2].replaceFirst(
          RegExp(r'\.html$'),
          '',
        );
        return 'mapbox://styles/$owner/$style';
      }
    }
    return 'mapbox://styles/$configured';
  }

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      _userId ??= await _api.userId();
      final enabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (enabled && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!enabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationDisabled = true);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      _center = LatLng(position.latitude, position.longitude);
      _hasUserLocation = true;
      if (mounted) {
        setState(() => _locationDisabled = false);
        _map.currentState?.moveTo(_center);
      }
    } catch (_) {
      if (mounted) setState(() => _locationDisabled = true);
    }
  }

  void _onMapViewportChanged(LatLngBounds bounds, double zoom) {
    _zoom = zoom;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(
      const Duration(milliseconds: 400),
      () => _loadPhotos(bounds),
    );
  }

  Future<void> _loadPhotos(LatLngBounds bounds) async {
    final userId = _userId ??= await _api.userId();
    final version = ++_requestVersion;
    if (mounted) {
      setState(() {
        _loadingPhotos = true;
        _error = null;
      });
    }
    try {
      final result = await _api.fetchMap(userId, apiBboxString(bounds));
      if (!mounted || version != _requestVersion) return;
      setState(() {
        // Demo photos make the map pins visible in development even before
        // this user has uploaded verified photos.
        _photos = result.photos;
        _totalCleared = result.totalCleared;
        _loadingPhotos = false;
      });
    } catch (_) {
      if (mounted && version == _requestVersion) {
        setState(() {
          _loadingPhotos = false;
          _error = 'No se pudieron cargar las fotos.';
        });
      }
    }
  }

  List<MapPhoto> get _visiblePhotos {
    final bucket = 0.20 / math.pow(2, (_zoom - 9).clamp(0, 11));
    final visible = <String, MapPhoto>{};
    for (final photo in _photos) {
      final key =
          '${(photo.latitude / bucket).floor()}:${(photo.longitude / bucket).floor()}';
      visible.putIfAbsent(key, () => photo);
      if (visible.length == 80) break;
    }
    return visible.values.toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_token.isEmpty || _token.startsWith('pk.your_')) {
      return const Center(
        child: Text('Configura MAPBOX_ACCESS_TOKEN en app/clearing/.env'),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: DiscoveryMap(
            key: _map,
            styleUri: _styleUri,
            center: _center,
            photos: _visiblePhotos,
            onViewportChanged: _onMapViewportChanged,
            onMapError: (error) {
              if (mounted && _tileError == null) {
                setState(() => _tileError = error.toString());
              }
            },
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              _button(
                Icons.arrow_back,
                'Volver a la cámara',
                widget.onBackToCamera ?? () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: _surface(26),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _locationDisabled
                            ? Icons.warning_amber_rounded
                            : Icons.explore_outlined,
                        size: 19,
                        color: _locationDisabled
                            ? AppColors.danger
                            : AppColors.forest,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _locationDisabled
                              ? 'Ubicación desactivada'
                              : '$_totalCleared lugares descubiertos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_loadingPhotos) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 58),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 74,
          right: 16,
          child: Column(
            children: [
              _button(
                Icons.my_location,
                'Centrar en mi ubicación',
                _loadLocation,
              ),
              const SizedBox(height: 10),
              _button(
                Icons.menu_book_outlined,
                'Abrir diario',
                widget.onOpenJournal ?? () {},
              ),
            ],
          ),
        ),
        if (_error != null || _tileError != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Material(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _tileError == null
                      ? _error!
                      : 'Mapbox no pudo cargar el estilo:\n$_tileError',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
      ],
    );
  }

  BoxDecoration _surface(double radius) => BoxDecoration(
    color: AppColors.beige,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: AppColors.forest.withValues(alpha: 0.08),
        offset: const Offset(0, 4),
        blurRadius: 20,
      ),
    ],
  );

  Widget _button(IconData icon, String tooltip, VoidCallback onPressed) =>
      Container(
        width: 52,
        height: 52,
        decoration: _surface(26),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: AppColors.forest),
        ),
      );
}
