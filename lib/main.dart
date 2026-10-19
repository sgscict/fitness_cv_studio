import 'package:flutter/material.dart';
import 'screens/algorithm_sandbox_screen.dart';
import 'screens/cv_fitness_studio_screen.dart';
import 'screens/exercise_guide_screen.dart';
import 'screens/movement_hub_screen.dart';
import 'theme/studio_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessCvStudioApp());
}

class FitnessCvStudioApp extends StatelessWidget {
  const FitnessCvStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness & Movement Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: StudioColors.background,
        colorScheme: const ColorScheme.dark(
          primary: StudioColors.coral,
          secondary: StudioColors.cyan,
          surface: StudioColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: StudioColors.surface,
          elevation: 0,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MovementHubScreen(),
    CvFitnessStudioScreen(),
    AlgorithmSandboxScreen(),
    ExerciseGuideScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: StudioColors.surface,
        indicatorColor: StudioColors.coral.withValues(alpha: 0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined, color: StudioColors.textMuted),
            selectedIcon: Icon(Icons.directions_run_rounded, color: StudioColors.coral),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined, color: StudioColors.textMuted),
            selectedIcon: Icon(Icons.videocam_rounded, color: StudioColors.coral),
            label: 'AI Camera CV',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined, color: StudioColors.textMuted),
            selectedIcon: Icon(Icons.science_rounded, color: StudioColors.coral),
            label: 'CV Sandbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: StudioColors.textMuted),
            selectedIcon: Icon(Icons.menu_book_rounded, color: StudioColors.coral),
            label: 'Exercise Guide',
          ),
        ],
      ),
    );
  }
}
