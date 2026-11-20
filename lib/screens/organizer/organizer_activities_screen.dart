import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import 'activity_form_screen.dart';
import 'applications_screen.dart';
import 'impact_screen.dart';

/// Modul 4: daftar kegiatan milik organizer + aksi (edit draft, hapus, pendaftar, dampak).
class OrganizerActivitiesScreen extends StatefulWidget {
  const OrganizerActivitiesScreen({super.key, required this.active});
  final bool active;

  @override
  State<OrganizerActivitiesScreen> createState() => _OrganizerActivitiesScreenState();
}

class _OrganizerActivitiesScreenState extends State<OrganizerActivitiesScreen> {
  final _key = GlobalKey<AsyncListViewState<Activity>>();

  @override
  void didUpdateWidget(covariant OrganizerActivitiesScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _key.currentState?.reload();
  }

  Future<List<Activity>> _load() async => [
        for (final a in await context.read<ApiClient>().get('organizer/activities/') as List)
          Activity.fromJson(a as Map<String, dynamic>)
      ];

  @override
  Widget build(BuildContext context) {
    return AsyncListView<Activity>(
      key: _key,
      load: _load,
      emptyText: 'Belum ada kegiatan.\nAjukan kegiatan pertamamu dengan tombol di bawah.',
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemBuilder: (context, a, reload) => _OrganizerActivityCard(activity: a, reload: reload),
    );
  }
}

class _OrganizerActivityCard extends StatelessWidget {
  const _OrganizerActivityCard({required this.activity, required this.reload});
  final Activity activity;
  final Future<void> Function() reload;

  static const _labels = {
    'draft': 'Menunggu tinjauan admin',
    'published': 'Terbit',
    'archived': 'Diarsipkan',
  };

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(a.nama, style: Theme.of(context).textTheme.titleMedium)),
            StatusChip(a.status, _labels[a.status] ?? a.status),
          ]),
          const SizedBox(height: 6),
          Text(formatDate(a.tanggalMulai)),
          Text('${a.namaLokasi}, ${a.kota}'),
          Text('Kuota ${a.kuota} · ${a.jumlahPendaftar} pendaftar'
              '${a.pendaftarMenunggu > 0 ? ' (${a.pendaftarMenunggu} menunggu)' : ''}'),
          const SizedBox(height: 6),
          Wrap(spacing: 4, children: [
            if (a.status == 'draft') ...[
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                onPressed: () async {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ActivityFormScreen(existing: a)));
                  await reload();
                },
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
                onPressed: () async {
                  if (!await confirm(context, 'Hapus draft kegiatan ini?') || !context.mounted) return;
                  await guarded(context, () async {
                    await context.read<ApiClient>().delete('organizer/activities/${a.id}/');
                  }, success: 'Draft dihapus.');
                  await reload();
                },
              ),
            ],
            if (a.status == 'published')
              TextButton.icon(
                icon: const Icon(Icons.groups, size: 18),
                label: const Text('Pendaftar'),
                onPressed: () async {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ApplicationsScreen(activity: a)));
                  await reload();
                },
              ),
            if (a.bisaCatatDampak)
              TextButton.icon(
                icon: const Icon(Icons.eco, size: 18),
                label: Text(a.dampak == null ? 'Catat dampak' : 'Lihat dampak'),
                onPressed: () async {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ImpactScreen(activity: a)));
                  await reload();
                },
              ),
          ]),
        ]),
      ),
    );
  }
}
