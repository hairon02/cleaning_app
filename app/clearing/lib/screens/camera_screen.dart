import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final _api = ApiService();
  String? _error;
  String? _captureInfo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!kIsWeb) {
      final camera = await Permission.camera.request();
      final location = await Permission.locationWhenInUse.request();
      if (!camera.isGranted || !location.isGranted) {
        setState(() => _error = 'Camera and location permissions are required. Enable them in Settings and retry.');
        return;
      }
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _error = 'No camera is available on this device.');
      return;
    }
    final rear = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
    final controller = CameraController(rear, ResolutionPreset.medium, enableAudio: false);
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      await controller.dispose();
      if (mounted) setState(() => _error = 'Unable to initialize the camera: $e');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_busy || controller == null || !controller.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw const _UserFacingError('Location services are disabled.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw const _UserFacingError('Location permission is required before taking a photo.');
      }
      final position = await Geolocator.getCurrentPosition();
      final takenAt = DateTime.now();
      if (mounted) {
        setState(() => _captureInfo = 'Ubicación y hora registradas');
      }
      final file = await controller.takePicture();
      final result = await _api.uploadPhoto(file, position.latitude, position.longitude, takenAt);
      if (mounted) _showResult(result);
    } catch (error) {
      if (mounted) _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showResult(PhotoResult result) {
    final (icon, color, text) = switch (result.status) {
      'verified' => (Icons.check_circle, AppColors.forest, result.description ?? 'Photo verified.'),
      'duplicate' => (Icons.copy, AppColors.terracotta, 'This photo is a duplicate.'),
      'rejected' => (Icons.cancel, AppColors.danger, 'This photo was rejected.'),
      _ => (Icons.hourglass_top, AppColors.slate, 'Photo is pending review.'),
    };
    final challenges = result.challengesCompleted.isEmpty ? '' : ' Challenges: ${result.challengesCompleted.join(', ')}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: AppColors.beige),
            const SizedBox(width: 12),
            Expanded(child: Text('$text$challenges')),
          ],
        ),
      ),
    );
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), action: SnackBarAction(label: 'Retry', onPressed: _capture)),
      );

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_outlined, size: 64, color: AppColors.terracotta),
                const SizedBox(height: 20),
                const Text('Camera unavailable', style: TextStyle(color: AppColors.forest, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)),
                const SizedBox(height: 24),
                AppButton(label: 'Try again', icon: Icons.refresh, onPressed: _initialize),
              ],
            ),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return const SafeArea(child: Center(child: CircularProgressIndicator()));
    return SafeArea(
      child: Stack(fit: StackFit.expand, children: [
        CameraPreview(controller),
        if (_captureInfo != null)
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _captureInfo!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.beige, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 24), child: FloatingActionButton.large(onPressed: _busy ? null : _capture, child: _busy ? const CircularProgressIndicator() : const Icon(Icons.camera_alt)))),
      ]),
    );
  }
}

class _UserFacingError implements Exception {
  const _UserFacingError(this.message);
  final String message;
  @override
  String toString() => message;
}
