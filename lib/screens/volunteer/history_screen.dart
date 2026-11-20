import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';

/// Modul 3: riwayat partisipasi, metrik dampak, dan refleksi relawan.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.active = true});
  final bool active;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _key = GlobalKey<AsyncListViewState<Registration>>();
  int _total = 0;
  int _hours = 0;

  @override
  void didUpdateWidget(covariant HistoryScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _key.currentState?.reload();
  }

  Future<List<Registration>> _load() async {
    final res = await context.read<ApiClient>().get('volunteer/history/') as Map<String, dynamic>;
    final done = [for (final r in res['riwayat'] as List) Registration.fromJson(r as Map<String, dynamic>)];
    if (mounted) {
      setState(() {
        _total = res['total_kegiatan_diikuti'] as int;
        _hours = res['total_jam_kontribusi'] as int;
      });
    }
    return done;
  }

  Future<void> _reflect(Registration r, Future<void> Function() reload) async {
    final text = await askText(context, 'Refleksi partisipasi', hint: 'Ceritakan pengalamanmu (min. 5 karakter)');
    if (text == null || !mounted) return;
    await guarded(context, () async {
      await context.read<ApiClient>().post(
          'volunteer/registrations/${r.id}/reflection/', {'refleksi_relawan': text});
    }, success: 'Refleksi tersimpan.');
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncListView<Registration>(
      key: _key,
      load: _load,
      emptyText: 'Belum ada kegiatan yang selesai kamu ikuti.',
      header: Row(children: [
        Expanded(child: StatTile('Kegiatan diikuti', _total, Icons.eco)),
        Expanded(child: StatTile('Jam kontribusi', _hours, Icons.schedule)),
      ]),
      itemBuilder: (context, r, reload) => Card(
        margin: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.kegiatanNama, style: Theme.of(context).textTheme.titleMedium),
            Text('${formatDate(r.tanggalMulai)} · ${r.jamKontribusi} jam'),
            if (r.catatanDampak.isNotEmpty) Text('Dampak: ${r.catatanDampak}'),
            const SizedBox(height: 6),
            if (r.refleksi.isNotEmpty)
              Text('Refleksimu: ${r.refleksi}', style: const TextStyle(fontStyle: FontStyle.italic))
            else
              TextButton.icon(
                  onPressed: () => _reflect(r, reload),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Tulis refleksi')),
          ]),
        ),
      ),
    );
  }
}
