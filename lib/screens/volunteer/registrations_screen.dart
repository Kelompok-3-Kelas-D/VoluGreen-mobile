import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../explore/activity_detail_screen.dart';
import 'register_form_screen.dart';

/// Modul 3: status pendaftaran milik relawan (ubah, batalkan).
class RegistrationsScreen extends StatefulWidget {
  const RegistrationsScreen({super.key, this.active = true});

  /// Tab sedang terlihat; memuat ulang data setiap kali tab dibuka kembali.
  final bool active;

  @override
  State<RegistrationsScreen> createState() => _RegistrationsScreenState();
}

class _RegistrationsScreenState extends State<RegistrationsScreen> {
  final _key = GlobalKey<AsyncListViewState<Registration>>();
  String _status = '';

  @override
  void didUpdateWidget(covariant RegistrationsScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _key.currentState?.reload();
  }

  Future<List<Registration>> _load() async {
    final res = await context.read<ApiClient>().get('volunteer/registrations/',
        query: {'status': _status}) as List;
    return [for (final r in res) Registration.fromJson(r as Map<String, dynamic>)];
  }

  @override
  Widget build(BuildContext context) {
    const filters = {
      '': 'Semua',
      'PENDING': 'Menunggu',
      'ACCEPTED': 'Diterima',
      'REJECTED': 'Ditolak',
      'CANCELLED': 'Dibatalkan',
    };
    return AsyncListView<Registration>(
      key: _key,
      load: _load,
      emptyText: 'Belum ada pendaftaran.\nCari kegiatan di tab Jelajah.',
      header: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final f in filters.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.value),
                selected: _status == f.key,
                onSelected: (_) {
                  _status = f.key;
                  _key.currentState?.reload();
                },
              ),
            ),
        ]),
      ),
      itemBuilder: (context, r, reload) => _RegistrationCard(reg: r, reload: reload),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.reg, required this.reload});
  final Registration reg;
  final Future<void> Function() reload;

  Future<void> _cancel(BuildContext context) async {
    final reason = await askText(context, 'Alasan pembatalan', hint: 'Minimal 5 karakter');
    if (reason == null || !context.mounted) return;
    await guarded(context, () async {
      await context.read<ApiClient>().post(
          'volunteer/registrations/${reg.id}/cancel/', {'alasan_pembatalan': reason});
    }, success: 'Pendaftaran dibatalkan.');
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(reg.kegiatanNama, style: Theme.of(context).textTheme.titleMedium)),
            StatusChip(reg.status, reg.statusLabel),
          ]),
          const SizedBox(height: 6),
          Text(formatDate(reg.tanggalMulai)),
          Text(reg.lokasi),
          if (reg.pesanPenyelenggara.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Pesan penyelenggara: ${reg.pesanPenyelenggara}',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          if (reg.alasanPembatalan.isNotEmpty) Text('Alasan batal: ${reg.alasanPembatalan}'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            TextButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ActivityDetailScreen(id: reg.kegiatanId)));
                await reload();
              },
              child: const Text('Lihat kegiatan'),
            ),
            if (reg.bisaDiubah)
              TextButton(
                onPressed: () async {
                  final changed = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => RegisterFormScreen(existing: reg)));
                  if (changed == true) await reload();
                },
                child: const Text('Ubah'),
              ),
            if (reg.bisaDibatalkan)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => _cancel(context),
                child: const Text('Batalkan'),
              ),
          ]),
        ]),
      ),
    );
  }
}
