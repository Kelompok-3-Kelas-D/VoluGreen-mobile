import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../widgets/common.dart';
import '../profile_screen.dart';
import 'activity_form_screen.dart';
import 'organizer_activities_screen.dart';

/// Kerangka navigasi penyelenggara: Ringkasan, Kegiatan, Profil.
class OrganizerShell extends StatefulWidget {
  const OrganizerShell({super.key});

  @override
  State<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends State<OrganizerShell> {
  int _index = 0;
  static const _titles = ['Dashboard penyelenggara', 'Kegiatan saya', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: [
        OrganizerSummaryScreen(active: _index == 0),
        OrganizerActivitiesScreen(active: _index == 1),
        const ProfileScreen(),
      ]),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Ajukan kegiatan'),
              onPressed: () async {
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
                setState(() => _index = 1); // memicu muat ulang daftar
              },
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Ringkasan'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Kegiatan'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

class OrganizerSummaryScreen extends StatefulWidget {
  const OrganizerSummaryScreen({super.key, required this.active});
  final bool active;

  @override
  State<OrganizerSummaryScreen> createState() => _OrganizerSummaryScreenState();
}

class _OrganizerSummaryScreenState extends State<OrganizerSummaryScreen> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async =>
      await context.read<ApiClient>().get('organizer/summary/') as Map<String, dynamic>;

  @override
  void didUpdateWidget(covariant OrganizerSummaryScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ErrorState(message: '${snap.error}', onRetry: () => setState(() => _future = _load()));
        }
        final s = snap.data!;
        final status = s['organization_status'] as String?;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (status != 'verified')
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.hourglass_top, color: Colors.orange),
                  title: Text(status == 'rejected'
                      ? 'Verifikasi organisasi ditolak'
                      : 'Organisasi menunggu verifikasi admin'),
                  subtitle: const Text('Kegiatan baru dapat terbit setelah organisasi terverifikasi.'),
                ),
              ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                StatTile('Total kegiatan', s['total_kegiatan'], Icons.event),
                StatTile('Menunggu tinjauan', s['draft'], Icons.hourglass_empty),
                StatTile('Terbit', s['terbit'], Icons.public),
                StatTile('Pendaftar menunggu', s['pendaftar_menunggu'], Icons.person_add_alt),
                StatTile('Perlu laporan dampak', s['perlu_laporan_dampak'], Icons.eco),
              ],
            ),
          ]),
        );
      },
    );
  }
}
