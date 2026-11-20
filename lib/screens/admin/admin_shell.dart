import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../widgets/common.dart';
import '../profile_screen.dart';
import 'admin_pages.dart';

/// Kerangka navigasi admin: navigation drawer dengan 6 halaman.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _items = [
    (Icons.dashboard_outlined, 'Ringkasan'),
    (Icons.verified_user_outlined, 'Verifikasi organisasi'),
    (Icons.fact_check_outlined, 'Moderasi kegiatan'),
    (Icons.category_outlined, 'Kategori'),
    (Icons.flag_outlined, 'Laporan pengguna'),
    (Icons.person_outline, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(title: Text(_items[_index].$2)),
      drawer: NavigationDrawer(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          Navigator.pop(context);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.eco, color: kGreen, size: 36),
              const SizedBox(height: 8),
              Text('VoluGreen Admin', style: Theme.of(context).textTheme.titleLarge),
              Text(user.username),
            ]),
          ),
          for (final it in _items)
            NavigationDrawerDestination(icon: Icon(it.$1), label: Text(it.$2)),
        ],
      ),
      body: switch (_index) {
        0 => AdminSummaryPage(onOpen: (i) => setState(() => _index = i)),
        1 => const OrganizationsPage(),
        2 => const ActivityModerationPage(),
        3 => const CategoriesPage(),
        4 => const ReportsPage(),
        _ => const ProfileScreen(),
      },
    );
  }
}
