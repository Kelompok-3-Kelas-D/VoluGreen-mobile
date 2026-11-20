import 'package:flutter/material.dart';

import '../explore/explore_screen.dart';
import '../profile_screen.dart';
import 'history_screen.dart';
import 'registrations_screen.dart';

/// Kerangka navigasi relawan: bottom navigation dengan 4 modul.
class VolunteerShell extends StatefulWidget {
  const VolunteerShell({super.key});

  @override
  State<VolunteerShell> createState() => _VolunteerShellState();
}

class _VolunteerShellState extends State<VolunteerShell> {
  int _index = 0;

  static const _titles = ['Jelajah kegiatan', 'Pendaftaran saya', 'Riwayat & dampak', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      // IndexedStack mempertahankan filter/scroll tiap tab saat berpindah.
      body: IndexedStack(index: _index, children: [
        const ExploreScreen(),
        RegistrationsScreen(active: _index == 1),
        HistoryScreen(active: _index == 2),
        const ProfileScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.travel_explore), label: 'Jelajah'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Pendaftaran'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
