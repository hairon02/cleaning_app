import 'dart:convert';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhotoResult {
  const PhotoResult({
    required this.status,
    this.description,
    this.tags = const [],
    this.challengesCompleted = const [],
  });
  final String status;
  final String? description;
  final List<String> tags;
  final List<String> challengesCompleted;

  factory PhotoResult.fromJson(Map<String, dynamic> json) => PhotoResult(
    status: json['status'] as String? ?? 'pending_review',
    description: json['description'] as String?,
    tags: List<String>.from(json['tags'] as List? ?? const []),
    challengesCompleted: List<String>.from(
      json['challenges_completed'] as List? ?? const [],
    ),
  );
}

class MapResult {
  const MapResult({required this.photos});
  final List<MapPhoto> photos;

  factory MapResult.fromJson(Map<String, dynamic> json) => MapResult(
    photos: (json['photos'] as List? ?? const [])
        .map(
          (photo) => MapPhoto.fromJson(
            photo as Map<String, dynamic>,
            ApiService.baseUrl,
          ),
        )
        .toList(),
  );
}

class MapPhoto {
  const MapPhoto({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.takenAt,
    this.description,
    this.isDemo = false,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String? takenAt;
  final String? description;
  final bool isDemo;

  factory MapPhoto.fromJson(Map<String, dynamic> json, String apiBaseUrl) =>
      MapPhoto(
        id: json['id'] as String,
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
        imageUrl: Uri.parse(apiBaseUrl)
            .resolve(json['image_url'] as String)
            .toString(),
        takenAt: json['taken_at'] as String?,
        description: json['description'] as String?,
        isDemo: json['demo'] as bool? ?? false,
      );
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _userKey = 'guest_user_id';

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      );

  Future<String> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_userKey);
    if (existing != null) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await prefs.setString(_userKey, id);
    return id;
  }

  Future<PhotoResult> uploadPhoto(
    XFile file,
    double lat,
    double lon,
    DateTime takenAt,
  ) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'))
          ..fields['lat'] = lat.toString()
          ..fields['lon'] = lon.toString()
          ..fields['taken_at'] = takenAt.toIso8601String()
          ..fields['user_id'] = await _userId()
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              await file.readAsBytes(),
              filename: file.name,
            ),
          );
    request.headers['ngrok-skip-browser-warning'] = 'true';
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload failed (${response.statusCode})');
    }
    return PhotoResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> userId() => _userId();

  Future<MapResult> fetchMap(String userId, String bbox) async {
    final uri = Uri.parse('$baseUrl/api/map')
        .replace(queryParameters: {'user_id': userId, 'bbox': bbox});
    final response = await _client
        .get(uri, headers: const {'ngrok-skip-browser-warning': 'true'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Map request failed (${response.statusCode})');
    }
    return MapResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @visibleForTesting
  Future<void> clearUserId() async =>
      (await SharedPreferences.getInstance()).remove(_userKey);
}
