import 'package:flutter/material.dart';

import '../../../app_config.dart';
import '../../data/app_scope.dart';
import '../../theme/ora_palette.dart';
import '../auth/sign_in_sheet.dart';
import 'beranda/beranda_page.dart';
import 'customer/customer_page.dart';
import 'history/history_page.dart';
import 'profil/profil_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.config});

  final AppConfig config;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _profileTab = 3;

  int selectedTab = 0;
  bool _authSheetOpen = false;

  Future<void> _onTabTap(int index) async {
    final leavingOrEnteringProfile = selectedTab != index;
    setState(() => selectedTab = index);

    if (index != _profileTab || !leavingOrEnteringProfile) return;
    if (AppScope.of(context).authStore.isSignedIn) return;
    if (_authSheetOpen) return;

    _authSheetOpen = true;
    try {
      await showSignInSheet(context);
      if (mounted) setState(() {});
    } finally {
      _authSheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final pages = [
      BerandaPage(config: widget.config),
      const HistoryPage(),
      const CustomerPage(),
      const ProfilPage(),
    ];

    return Scaffold(
      backgroundColor: ora.bg,
      body: IndexedStack(index: selectedTab, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ora.panel2,
          border: Border(top: BorderSide(color: ora.line)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: selectedTab,
            onTap: _onTabTap,
            backgroundColor: ora.panel2,
            selectedItemColor: ora.lime,
            unselectedItemColor: ora.muted2,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.support_agent_outlined),
                activeIcon: Icon(Icons.support_agent_rounded),
                label: 'Customer',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
