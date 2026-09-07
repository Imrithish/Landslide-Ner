import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/map/interactive_map_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/reports/my_reports_screen.dart';
import '../features/profile/profile_screen.dart';
import '../constants/app_colors.dart';
import '../providers/sync_provider.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    InteractiveMapScreen(),
    AlertsScreen(),
    MyReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_rounded),
                    // TODO: Badge with unread count once backend provides it
                  ],
                ),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.assignment_rounded),
                    if (syncState.pendingCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.syncPending,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Reports',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
