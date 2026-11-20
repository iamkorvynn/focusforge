import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/tasks_screen.dart';
import 'services/timer_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FocusForgeApp());
}

/// App root: holds one [TimerController] for the whole app and switches
/// between the four tabs with a bottom navigation bar.
class FocusForgeApp extends StatefulWidget {
  const FocusForgeApp({super.key});

  @override
  State<FocusForgeApp> createState() => _FocusForgeAppState();
}

class _FocusForgeAppState extends State<FocusForgeApp> {
  final TimerController _controller = TimerController();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusForge',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (!_controller.initialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final pages = <Widget>[
            HomeScreen(controller: _controller),
            TasksScreen(controller: _controller),
            StatsScreen(controller: _controller),
            SettingsScreen(controller: _controller),
          ];
          return Scaffold(
            body: IndexedStack(index: _tabIndex, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (index) {
                setState(() => _tabIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: 'Timer',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Stats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
