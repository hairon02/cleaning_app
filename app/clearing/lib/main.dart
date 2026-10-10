import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'screens/camera_screen.dart';
import 'screens/map_screen.dart';
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
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const CameraScreen(),
      MapScreen(
        onBackToCamera: () => setState(() => _selectedIndex = 0),
        onOpenJournal: () => setState(() => _selectedIndex = 4),
      ),
      const _PlaceholderScreen(title: 'Challenges'),
      const _PlaceholderScreen(title: 'Ranking'),
      const _PlaceholderScreen(title: 'Journal'),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _selectedIndex == 1 ? null : BottomNav(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
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
