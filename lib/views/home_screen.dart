import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../services/call_service.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final SystemHealthService _systemHealthService;
  final CallService _callService = CallService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _incomingSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;
    final firestore = context.read<FirestoreService>();
    _systemHealthService = SystemHealthService(firestore);
    _systemHealthService.start();
    _incomingSubscription ??= _callService.listenForCalls().listen((call) {
      if (!mounted) return;
      final data = call.data();
      if (data == null) return;
      final callerId = data['callerId'] as String? ?? '';
      final callerName = data['callerName'] as String? ?? 'Svinobook user';
      final video = data['type'] != 'audio';
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callId: call.id,
            callerName: callerName,
            video: video,
            onAccepted: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    callId: call.id,
                    targetUserId: callerId,
                    chatName: callerName,
                    video: video,
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _systemHealthService.stop();
    _incomingSubscription?.cancel();
    _callService.dispose();
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
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 760;
          return Column(
            children: [
              const _ClassicTopBar(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isDesktop)
                          _ClassicSidebar(
                            currentIndex: _currentIndex,
                            onTap: (index) =>
                                setState(() => _currentIndex = index),
                          ),
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: _tabs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isDesktop)
                _GlassNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassicTopBar extends StatelessWidget {
  const _ClassicTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              const SizedBox(width: 24),
              const Text(
                '✳ svinobook',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Copernicus',
                  fontFamilyFallback: [
                    'Tiempos Headline',
                    'Cormorant Garamond',
                    'serif',
                  ],
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 230,
                height: 28,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 17,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceSoft,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.notifications_none,
                color: AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassicSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ClassicSidebar({required this.currentIndex, required this.onTap});

  static const items = [
    _NavItem(icon: Icons.person_outline, label: 'My page'),
    _NavItem(icon: Icons.public, label: 'News'),
    _NavItem(icon: Icons.forum_outlined, label: 'Messages'),
    _NavItem(icon: Icons.check_box_outlined, label: 'Tasks'),
    _NavItem(icon: Icons.shield_outlined, label: 'Security'),
    _NavItem(icon: Icons.people_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 208,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              return InkWell(
                onTap: () => onTap(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  color: selected
                      ? AppColors.surfaceCreamStrong
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 19,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'COMMUNITY',
                style: TextStyle(
                  color: AppColors.textMutedSoft,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Help  •  Settings',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
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
                color: selected
                    ? AppColors.surfaceCreamStrong
                    : Colors.transparent,
                border: selected
                    ? Border.all(color: AppColors.glassBorder)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                    size: 19,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textMuted,
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
