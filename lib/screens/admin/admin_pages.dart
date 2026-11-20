import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../widgets/common.dart';

ApiClient _api(BuildContext c) => c.read<ApiClient>();

Future<List<Map<String, dynamic>>> _list(BuildContext c, String path, [Map<String, String?>? q]) async => [
      for (final e in await _api(c).get(path, query: q) as List) e as Map<String, dynamic>
    ];

// ---------------------------------------------------------------- ringkasan
class AdminSummaryPage extends StatefulWidget {
  const AdminSummaryPage({super.key, required this.onOpen});
  final void Function(int index) onOpen;

  @override
  State<AdminSummaryPage> createState() => _AdminSummaryPageState();
}

class _AdminSummaryPageState extends State<AdminSummaryPage> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async =>
      await _api(context).get('admin/summary/') as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorState(message: '${snap.error}', onRetry: () => setState(() => _future = _load()));
          }
          final s = snap.data!;
          Widget tile(String label, String key, IconData icon, int page) => InkWell(
                onTap: () => widget.onOpen(page),
                child: StatTile(label, s[key], icon),
              );
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  tile('Organisasi menunggu', 'organisasi_menunggu', Icons.verified_user, 1),
                  tile('Kegiatan menunggu', 'kegiatan_menunggu', Icons.fact_check, 2),
                  tile('Kategori aktif', 'kategori_aktif', Icons.category, 3),
                  tile('Laporan terbuka', 'laporan_terbuka', Icons.flag, 4),
                ],
              ),
            ]),
          );
        },
      );
}

// ---------------------------------------------------------------- organisasi
class OrganizationsPage extends StatelessWidget {
  const OrganizationsPage({super.key});

  @override
  Widget build(BuildContext context) => AsyncListView<Map<String, dynamic>>(
        load: () => _list(context, 'admin/organizations/'),
        emptyText: 'Belum ada pengajuan organisasi.',
        itemBuilder: (context, o, reload) {
          Future<void> decide(String d) async {
            await guarded(context, () async {
              await _api(context).post('admin/organizations/${o['id']}/decision/', {'decision': d});
            }, success: d == 'approve' ? 'Organisasi diverifikasi.' : 'Organisasi ditolak.');
            await reload();
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${o['name']}', style: Theme.of(context).textTheme.titleMedium)),
                  StatusChip('${o['status']}', '${o['status_label']}'),
                ]),
                Text('${o['type']} · ${o['city']}'),
                Text('${o['contact_email']}'),
                if ('${o['description']}'.isNotEmpty) Text('${o['description']}'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  if (o['status'] != 'verified')
                    FilledButton.tonal(onPressed: () => decide('approve'), child: const Text('Verifikasi')),
                  if (o['status'] != 'rejected')
                    OutlinedButton(onPressed: () => decide('reject'), child: const Text('Tolak')),
                ]),
              ]),
            ),
          );
        },
      );
}

// ---------------------------------------------------------------- moderasi kegiatan
class ActivityModerationPage extends StatelessWidget {
  const ActivityModerationPage({super.key});

  @override
  Widget build(BuildContext context) => AsyncListView<Map<String, dynamic>>(
        load: () => _list(context, 'admin/activities/'),
        emptyText: 'Belum ada kegiatan untuk dimoderasi.',
        itemBuilder: (context, a, reload) {
          Future<void> decide(String d) async {
            String? note;
            if (a['source'] == 'moderation') {
              note = await askText(context, 'Catatan moderator (opsional)');
              if (note == null || !context.mounted) return;
            }
            await guarded(context, () async {
              await _api(context).post('admin/activities/${a['source']}/${a['id']}/decision/',
                  {'decision': d, 'moderator_note': ?note});
            }, success: d == 'approve' ? 'Kegiatan diterbitkan.' : 'Kegiatan ditolak.');
            await reload();
          }

          const labels = {'pending': 'Menunggu', 'approved': 'Disetujui', 'rejected': 'Ditolak'};
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${a['title']}', style: Theme.of(context).textTheme.titleMedium)),
                  StatusChip('${a['status']}', labels['${a['status']}'] ?? '${a['status']}'),
                ]),
                Text('${a['organizer_name']} · ${a['category'] ?? '-'}'),
                Text('${a['location']}'),
                if ('${a['moderator_note']}'.isNotEmpty) Text('Catatan: ${a['moderator_note']}'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  if (a['status'] != 'approved')
                    FilledButton.tonal(onPressed: () => decide('approve'), child: const Text('Terbitkan')),
                  if (a['status'] != 'rejected')
                    OutlinedButton(onPressed: () => decide('reject'), child: const Text('Tolak')),
                ]),
              ]),
            ),
          );
        },
      );
}

// ---------------------------------------------------------------- kategori
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _key = GlobalKey<AsyncListViewState<Map<String, dynamic>>>();

  Future<void> _edit([Map<String, dynamic>? c]) async {
    final name = TextEditingController(text: c?['name'] as String?);
    final desc = TextEditingController(text: c?['description'] as String?);
    var active = (c?['is_active'] ?? true) as bool;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(c == null ? 'Tambah kategori' : 'Ubah kategori'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama (min. 5 karakter)')),
            const SizedBox(height: 12),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Deskripsi')),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: (v) => setLocal(() => active = v),
                title: const Text('Aktif')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final body = {'name': name.text, 'description': desc.text, 'is_active': active};
                final ok = await guarded(ctx, () async {
                  c == null
                      ? await _api(context).post('admin/categories/', body)
                      : await _api(context).put('admin/categories/${c['id']}/', body);
                });
                if (ok && ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) await _key.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AsyncListView<Map<String, dynamic>>(
          key: _key,
          load: () => _list(context, 'admin/categories/'),
          emptyText: 'Belum ada kategori.',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemBuilder: (context, c, reload) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${c['name']}'),
              subtitle: Text(('${c['description']}').isEmpty ? (c['is_active'] as bool ? 'Aktif' : 'Nonaktif') : '${c['description']}'),
              leading: Icon(c['is_active'] as bool ? Icons.check_circle : Icons.pause_circle_outline,
                  color: c['is_active'] as bool ? kGreen : Colors.grey),
              onTap: () => _edit(c),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (!await confirm(context, 'Hapus kategori "${c['name']}"?') || !context.mounted) return;
                  await guarded(context, () async {
                    await _api(context).delete('admin/categories/${c['id']}/');
                  }, success: 'Kategori dihapus.');
                  await reload();
                },
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Tambah kategori',
          onPressed: () => _edit(),
          child: const Icon(Icons.add),
        ),
      );
}

// ---------------------------------------------------------------- laporan
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) => AsyncListView<Map<String, dynamic>>(
        load: () => _list(context, 'admin/reports/'),
        emptyText: 'Belum ada laporan pengguna.',
        itemBuilder: (context, r, reload) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${r['subject']}', style: Theme.of(context).textTheme.titleMedium)),
                StatusChip('${r['status']}', '${r['status_label']}'),
              ]),
              Text('Dari: ${r['reporter']}'),
              const SizedBox(height: 4),
              Text('${r['details']}'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final s in const {'open': 'Baru', 'reviewing': 'Ditinjau', 'resolved': 'Selesai'}.entries)
                  if (s.key != r['status'])
                    OutlinedButton(
                      onPressed: () async {
                        await guarded(context, () async {
                          await _api(context).patch('admin/reports/${r['id']}/', {'status': s.key});
                        }, success: 'Status laporan diperbarui.');
                        await reload();
                      },
                      child: Text(s.value),
                    ),
              ]),
            ]),
          ),
        ),
      );
}
