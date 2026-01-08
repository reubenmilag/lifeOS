import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'screens/home_screen.dart';
import 'screens/finances_screen.dart';
import 'screens/health_screen.dart';
import 'screens/planner_screen.dart';

void main() {
  runApp(const LifeOSApp());
}

class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => FTheme(
        data: FThemes.blue.light,
        child: child!,
      ),
      title: 'LifeOS',
      home: const MainTabScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      contentPad: false,
      content: _buildBody(),
      footer: FBottomNavigationBar(
        index: _selectedIndex,
        onChange: (index) => setState(() => _selectedIndex = index),
        children: [
          FBottomNavigationBarItem(
            icon: FIcon(FAssets.icons.house),
            label: const Text('Home'),
          ),
          FBottomNavigationBarItem(
            icon: FIcon(FAssets.icons.banknote),
            label: const Text('Finance'),
          ),
          FBottomNavigationBarItem(
            icon: FIcon(FAssets.icons.calendar),
            label: const Text('Planner'),
          ),
          FBottomNavigationBarItem(
            icon: FIcon(FAssets.icons.activity),
            label: const Text('Health'),
          ),
          FBottomNavigationBarItem(
            icon: FIcon(FAssets.icons.ellipsis),
            label: const Text('More'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FinancesScreen();
      case 2:
        return const PlannerScreen();
      case 3:
        return const HealthScreen();
      case 4:
        return const Center(child: Text('More'));
      default:
        return const HomeScreen();
    }
  }
}
