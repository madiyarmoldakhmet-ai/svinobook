import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'project_showcase_view.dart';
import 'global_chat_tab.dart';
import 'direct_messages_tab.dart';
import 'tasks_tab.dart';
import 'security_dashboard_tab.dart';
import 'profile_tab.dart';
import '../services/firestore_service.dart';
import '../services/system_health_service.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final SystemHealthService _systemHealthService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;
    final firestore = context.read<FirestoreService>();
    _systemHealthService = SystemHealthService(firestore);
    _systemHealthService.start();
  }

  @override
  void dispose() {
    _systemHealthService.stop();
    super.dispose();
  }

  final List<Widget> _tabs = const [
    ProjectShowcaseView(),
    GlobalChatTab(),
    DirectMessagesTab(),
    TasksTab(),
    SecurityDashboardTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDarkest,
      body: Stack(
        children: [
          // Tab content
          IndexedStack(index: _currentIndex, children: _tabs),

          // Glassmorphic navigation bar
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _GlassNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.explore_rounded, label: 'Discover'),
      _NavItem(icon: Icons.public_rounded, label: 'Global'),
      _NavItem(icon: Icons.forum_rounded, label: 'Messages'),
      _NavItem(icon: Icons.checklist_rounded, label: 'Tasks'),
      _NavItem(icon: Icons.shield_rounded, label: 'Security'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE2EDF7) : Colors.transparent,
                border: selected ? Border.all(color: const Color(0xFFB8CBDE)) : null,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: selected ? AppColors.neonCyan : AppColors.textMuted, size: 19),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? AppColors.neonCyan : AppColors.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}