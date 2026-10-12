import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.challenge,
    this.onReturnToChallenges,
    this.onFlowStateChanged,
  });

  final ActiveChallenge? challenge;
  final VoidCallback? onReturnToChallenges;
  final ValueChanged<bool>? onFlowStateChanged;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final _api = ApiService();
  String? _error;
  String? _captureInfo;
  bool _busy = false;
  bool _initializing = false;
  _CaptureStage _stage = _CaptureStage.camera;
  String? _resultMessage;
  String _errorTitle = 'Photo check failed';
  Timer? _successTimer;

  @override
  void didUpdateWidget(covariant CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge?.id != widget.challenge?.id) {
      _successTimer?.cancel();
      _stage = _CaptureStage.camera;
      _resultMessage = null;
      _busy = false;
      widget.onFlowStateChanged?.call(false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialize();
    });
  }

  Future<void> _initialize() async {
    if (_initializing) return;
    _initializing = true;
    if (mounted) setState(() => _error = null);
    CameraController? controller;
    try {
      if (!kIsWeb) {
        final camera = await Permission.camera.request();
        final location = await Permission.locationWhenInUse.request();
        if (!camera.isGranted || !location.isGranted) {
          if (mounted) setState(() => _error = 'Camera and location permissions are required. Enable them in Settings and retry.');
          return;
        }
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'No camera is available on this device.');
        return;
      }
      final rear = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      controller = CameraController(rear, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      await controller?.dispose();
      if (mounted) setState(() => _error = 'Unable to initialize the camera: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<void> _releaseCamera() async {
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await controller?.dispose();
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
      if (!mounted) return;
      setState(() {
        _stage = _CaptureStage.analyzing;
        _resultMessage = null;
      });
      widget.onFlowStateChanged?.call(true);
      await _releaseCamera();
      final result = await _api.uploadPhoto(
        file,
        position.latitude,
        position.longitude,
        takenAt,
        challengeId: widget.challenge?.id,
      );
      if (!mounted) return;
      final challenge = widget.challenge;
      final completed = result.status == 'verified' &&
          (challenge == null ||
              result.challengesCompleted.contains(challenge.title));
      if (completed) {
        _showSuccess(challenge);
      } else if (challenge != null) {
        _showFlowError(
          _messageForResult(result, challenge),
          title: 'Challenge not completed',
        );
      } else {
        _showFlowError(
          _messageForResult(result, challenge),
          title: 'Photo check failed',
        );
      }
    } catch (error) {
      if (mounted) {
        if (_stage == _CaptureStage.analyzing) {
          _showFlowError(
            'We couldn’t analyze your photo. Check your connection and try again.',
          );
        } else {
          _showError(error.toString().replaceFirst('Exception: ', ''));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageForResult(PhotoResult result, ActiveChallenge? challenge) {
    if (challenge != null && result.status != 'pending_review') {
      return 'Your photo doesn’t meet the “${challenge.title}” challenge criteria. Try again with a photo that clearly matches the challenge.';
    }
    return switch (result.status) {
      'duplicate' => 'This photo looks like one you already uploaded. Try taking a new photo.',
      'rejected' => 'This photo couldn’t be verified as an outdoor scene. Try another photo outside.',
      'pending_review' => 'Your photo could not be verified right now. Please try again.',
      _ => 'We couldn’t complete the photo check. Please try again.',
    };
  }

  void _showSuccess(ActiveChallenge? challenge) {
    setState(() {
      _stage = _CaptureStage.success;
      _resultMessage = challenge == null
          ? 'Photo verified!'
          : 'Challenge complete! You completed “${challenge.title}”.';
    });
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(milliseconds: 2200), _returnToChallenges);
  }

  void _showFlowError(String message, {String title = 'Photo check failed'}) {
    setState(() {
      _stage = _CaptureStage.error;
      _resultMessage = message;
      _errorTitle = title;
    });
  }

  Future<void> _retryCapture() async {
    _successTimer?.cancel();
    setState(() {
      _stage = _CaptureStage.camera;
      _resultMessage = null;
      _captureInfo = null;
    });
    widget.onFlowStateChanged?.call(false);
    await _releaseCamera();
    if (mounted) await _initialize();
  }

  void _returnToChallenges() {
    _successTimer?.cancel();
    widget.onFlowStateChanged?.call(false);
    widget.onReturnToChallenges?.call();
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), action: SnackBarAction(label: 'Retry', onPressed: _capture)),
      );

  @override
  void dispose() {
    _successTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _CaptureStage.analyzing) {
      return const _CaptureStatusView(
        icon: Icons.auto_awesome,
        title: 'Analyzing your photo',
        detail: 'Checking the scene and your selected challenge.',
        showProgress: true,
      );
    }
    if (_stage == _CaptureStage.success) {
      return _CaptureStatusView(
        icon: Icons.check_circle,
        title: widget.challenge == null ? 'Photo verified' : 'Challenge complete!',
        detail: _resultMessage ?? '',
        isSuccess: true,
        actionLabel: 'Back to Challenges',
        onAction: _returnToChallenges,
      );
    }
    if (_stage == _CaptureStage.error) {
      return _CaptureStatusView(
        icon: Icons.error_outline,
        title: _errorTitle,
        detail: _resultMessage ?? 'Please try again.',
        actionLabel: 'Try again',
        onAction: _retryCapture,
        secondaryActionLabel: 'Back to Challenges',
        onSecondaryAction: _returnToChallenges,
      );
    }
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
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.forest)),
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

enum _CaptureStage { camera, analyzing, success, error }

class _CaptureStatusView extends StatelessWidget {
  const _CaptureStatusView({
    required this.icon,
    required this.title,
    required this.detail,
    this.showProgress = false,
    this.isSuccess = false,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool showProgress;
  final bool isSuccess;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSuccess)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.35, end: 1),
                      duration: const Duration(milliseconds: 560),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                      child: Icon(icon, size: 94, color: AppColors.olive),
                    )
                  else
                    Icon(
                      icon,
                      size: 68,
                      color: showProgress ? AppColors.ochre : AppColors.danger,
                    ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(detail, textAlign: TextAlign.center),
                  if (showProgress) ...[
                    const SizedBox(height: 30),
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                      child: LinearProgressIndicator(minHeight: 7),
                    ),
                    const SizedBox(height: 12),
                    const Text('This may take a moment.'),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onAction,
                        icon: Icon(isSuccess ? Icons.flag_outlined : Icons.refresh),
                        label: Text(actionLabel!),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                      ),
                    ),
                  ],
                  if (secondaryActionLabel != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onSecondaryAction,
                        icon: const Icon(Icons.arrow_back),
                        label: Text(secondaryActionLabel!),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class _UserFacingError implements Exception {
  const _UserFacingError(this.message);
  final String message;
  @override
  String toString() => message;
}
