import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'screens/camera_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/map_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/registration_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final environment = dotenv.env;
  for (final entry in environment.entries.toList()) {
    if (entry.key.startsWith('\uFEFF')) {
      environment.remove(entry.key);
      environment[entry.key.substring(1)] = entry.value;
    }
  }
  MapboxOptions.setAccessToken(
    dotenv.env['MAPBOX_ACCESS_TOKEN']?.trim() ?? '',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _LaunchGate(),
    );
  }
}

class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  final _api = ApiService();
  LocalProfile? _profile;
  bool _loading = true;
  bool _onboardingComplete = false;
  String? _syncError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _syncError = null;
    });
    try {
      final profile = await _api.loadProfile();
      if (profile != null) {
        await _api.registerUser(profile.userId, profile.name);
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _syncError =
            'Could not sync your profile. Check your connection and try again.';
      });
    }
  }

  Future<void> _saveProfile(String name) async {
    final profile = await _api.saveProfile(name);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_syncError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                Text(_syncError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_profile != null) return AppShell(profile: _profile!);
    if (!_onboardingComplete) {
      return OnboardingScreen(
        onFinished: () => setState(() => _onboardingComplete = true),
      );
    }
    return RegistrationScreen(onContinue: _saveProfile);
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.profile});

  final LocalProfile profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 1;
  final _challengesKey = GlobalKey<ChallengesScreenState>();
  bool _showChallengeGuide = true;
  ActiveChallenge? _selectedChallenge;
  bool _cameraFlowActive = false;
  bool _cameraRequested = false;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      if (_cameraRequested)
        CameraScreen(
          key: const ValueKey('camera-screen'),
          challenge: _selectedChallenge,
          onFlowStateChanged: (active) {
            if (_cameraFlowActive != active) {
              setState(() => _cameraFlowActive = active);
            }
          },
          onReturnToChallenges: () {
            setState(() {
              _selectedIndex = 1;
              _selectedChallenge = null;
              _cameraRequested = false;
              _cameraFlowActive = false;
            });
            _challengesKey.currentState?.refresh();
          },
        )
      else
        const SizedBox.shrink(),
      ChallengesScreen(
        key: _challengesKey,
        onTakePhoto: () => setState(() {
          _cameraRequested = true;
          _selectedChallenge = null;
          _selectedIndex = 0;
        }),
        onTakeChallengePhoto: (challenge) => setState(() {
          _cameraRequested = true;
          _selectedChallenge = challenge;
          _selectedIndex = 0;
        }),
        showWelcomeGuide: _showChallengeGuide,
        onWelcomeGuideDismissed: () =>
            setState(() => _showChallengeGuide = false),
        userName: widget.profile.name,
      ),
      MapScreen(
        onBackToCamera: () => setState(() {
          _cameraRequested = true;
          _selectedIndex = 0;
        }),
        onOpenJournal: () => setState(() => _selectedIndex = 3),
      ),
      const _PlaceholderScreen(title: 'Journal'),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _selectedIndex == 0 || _cameraFlowActive ? null : BottomNav(
        selectedIndex: _selectedIndex - 1,
        onSelected: (index) {
          final screenIndex = index + 1;
          setState(() => _selectedIndex = screenIndex);
          if (screenIndex == 1) _challengesKey.currentState?.refresh();
        },
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}
