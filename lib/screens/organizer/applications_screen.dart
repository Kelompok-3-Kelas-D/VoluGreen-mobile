import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';

/// Modul 4: tinjau pendaftar, terima/tolak, lalu tandai hadir/tidak hadir setelah acara.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key, required this.activity});
  final Activity activity;

  Future<void> _update(BuildContext context, Registration r, String status,
      Future<void> Function() reload, {Map<String, dynamic> extra = const {}}) async {
    await guarded(context, () async {
      await context.read<ApiClient>().patch('organizer/applications/${r.id}/', {'status': status, ...extra});
    }, success: 'Status pendaftar diperbarui.');
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pendaftar · ${activity.nama}')),
      body: AsyncListView<Registration>(
        load: () async => [
          for (final r in await context
              .read<ApiClient>()
              .get('organizer/activities/${activity.id}/applications/') as List)
            Registration.fromJson(r as Map<String, dynamic>)
        ],
        emptyText: 'Belum ada relawan yang mendaftar.',
        itemBuilder: (context, r, reload) {
          final over = !activity.tanggalMulai.isAfter(DateTime.now());
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text(r.namaRelawan ?? 'Relawan', style: Theme.of(context).textTheme.titleMedium)),
                  StatusChip(r.status, r.statusLabel),
                ]),
                const SizedBox(height: 6),
                Text('Motivasi: ${r.motivasi}'),
                Text('Kontak darurat: ${r.kontakDarurat}'),
                if (r.pengalaman.isNotEmpty) Text('Pengalaman: ${r.pengalaman}'),
                if (r.kebutuhanKhusus.isNotEmpty) Text('Kebutuhan khusus: ${r.kebutuhanKhusus}'),
                if (r.status == 'COMPLETED') Text('Kontribusi: ${r.jamKontribusi} jam'),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  if (!over && r.status == 'PENDING')
                    FilledButton.tonal(
                        onPressed: () => _update(context, r, 'ACCEPTED', reload), child: const Text('Terima')),
                  if (!over && (r.status == 'PENDING' || r.status == 'ACCEPTED'))
                    OutlinedButton(
                        onPressed: () => _update(context, r, 'REJECTED', reload), child: const Text('Tolak')),
                  if (over && r.status == 'ACCEPTED') ...[
                    FilledButton.tonal(
                      onPressed: () async {
                        final hours = await askText(context, 'Jam kontribusi', hint: 'Contoh: 3');
                        if (hours == null || !context.mounted) return;
                        await _update(context, r, 'COMPLETED', reload,
                            extra: {'jam_kontribusi': hours.isEmpty ? 3 : hours});
                      },
                      child: const Text('Hadir'),
                    ),
                    OutlinedButton(
                        onPressed: () => _update(context, r, 'ABSENT', reload),
                        child: const Text('Tidak hadir')),
                  ],
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }
}
