import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _metersPerDegree = 111320.0;
const _cellSizeMeters = 200.0;

double get _cellStep => _cellSizeMeters / _metersPerDegree;

String _formatIndex(int value) {
  final sign = value < 0 ? '-' : '+';
  return '$sign${value.abs().toString().padLeft(6, '0')}';
}

String latLonToCell(double lat, double lon) {
  final latIndex = (lat / _cellStep).floor();
  final lonIndex = (lon / _cellStep).floor();
  return '${_formatIndex(latIndex)}_${_formatIndex(lonIndex)}';
}

LatLngBounds cellToBounds(String cellId) {
  final parts = cellId.split('_');
  if (parts.length != 2) throw FormatException('Invalid cell id: $cellId');
  final lat = int.parse(parts[0]) * _cellStep;
  final lon = int.parse(parts[1]) * _cellStep;
  return LatLngBounds(
    LatLng(lat, lon),
    LatLng(lat + _cellStep, lon + _cellStep),
  );
}

Iterable<String> cellsInBounds(LatLngBounds bounds) sync* {
  final startLat = (bounds.south / _cellStep).floor();
  final endLat = (bounds.north / _cellStep).floor();
  final startLon = (bounds.west / _cellStep).floor();
  final endLon = (bounds.east / _cellStep).floor();
  for (var lat = startLat; lat <= endLat; lat++) {
    for (var lon = startLon; lon <= endLon; lon++) {
      yield '${_formatIndex(lat)}_${_formatIndex(lon)}';
    }
  }
}

String bboxString(LatLngBounds bounds) =>
    '${bounds.south},${bounds.west},${bounds.north},${bounds.east}';

String apiBboxString(LatLngBounds bounds) {
  const maxDegrees = 50000.0 / _metersPerDegree;
  final centerLat = (bounds.south + bounds.north) / 2;
  final centerLon = (bounds.west + bounds.east) / 2;
  final halfLat = ((bounds.north - bounds.south) / 2).clamp(
    0.0,
    maxDegrees / 2,
  );
  final halfLon = ((bounds.east - bounds.west) / 2).clamp(0.0, maxDegrees / 2);
  return '${centerLat - halfLat},${centerLon - halfLon},'
      '${centerLat + halfLat},${centerLon + halfLon}';
}

bool isApiBboxAllowed(LatLngBounds bounds) {
  const maxDegrees = 50000.0 / _metersPerDegree;
  return bounds.north - bounds.south <= maxDegrees &&
      bounds.east - bounds.west <= maxDegrees;
}
