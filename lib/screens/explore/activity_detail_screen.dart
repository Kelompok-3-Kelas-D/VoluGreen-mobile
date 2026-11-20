import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_provider.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../volunteer/register_form_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.id, this.guest = false});
  final int id;
  final bool guest;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Future<Activity> _future = _load();

  Future<Activity> _load() async {
    final res = await context.read<ApiClient>().get('activities/${widget.id}/') as Map<String, dynamic>;
    return Activity.fromJson(res);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _toggleArchive(Activity a) async {
    final api = context.read<ApiClient>();
    final ok = await guarded(context, () async {
      a.isArchived ? await api.delete('bookmarks/${a.id}/') : await api.put('bookmarks/${a.id}/');
    }, success: a.isArchived ? 'Dihapus dari arsip.' : 'Tersimpan di arsip.');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canVolunteer = !widget.guest && (user?.isVolunteer ?? false);
    return FutureBuilder<Activity>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
              appBar: AppBar(), body: ErrorState(message: '${snap.error}', onRetry: _reload));
        }
        final a = snap.data!;
        final canRegister = canVolunteer &&
            a.myRegistrationStatus == null &&
            !a.sudahLewat &&
            a.sisaKuota > 0;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail kegiatan'),
            actions: [
              if (canVolunteer)
                IconButton(
                  tooltip: a.isArchived ? 'Hapus dari arsip' : 'Simpan ke arsip',
                  icon: Icon(a.isArchived ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => _toggleArchive(a),
                ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Text(a.nama, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('oleh ${a.penyelenggara}'),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              Chip(label: Text(a.kategori)),
              Chip(label: Text(a.sudahLewat ? 'Sudah berlalu' : 'Sisa kuota ${a.sisaKuota}/${a.kuota}')),
            ]),
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(formatDate(a.tanggalMulai))),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place),
              title: Text(a.namaLokasi),
              subtitle: Text([a.alamat, a.kota].where((e) => e.isNotEmpty).join(', ')),
            ),
            const Divider(),
            Text(a.deskripsi),
            const SizedBox(height: 16),
            if (a.hasCoordinates)
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FlutterMap(
                    options: MapOptions(
                        initialCenter: LatLng(a.latitude!, a.longitude!), initialZoom: 15),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'id.ac.ui.volugreen_mobile',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                            point: LatLng(a.latitude!, a.longitude!),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: kGreen, size: 40)),
                      ]),
                      const RichAttributionWidget(
                          attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
                    ],
                  ),
                ),
              )
            else
              const Text('Lokasi belum memiliki koordinat peta.'),
            const SizedBox(height: 20),
            if (a.myRegistrationStatus != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: const Text('Kamu sudah mendaftar'),
                  trailing: StatusChip(a.myRegistrationStatus!, a.myRegistrationStatus!),
                ),
              ),
            if (widget.guest || user == null)
              const Text('Masuk sebagai relawan untuk mendaftar kegiatan ini.')
            else if (!canVolunteer)
              const Text('Pendaftaran hanya tersedia untuk akun relawan.')
            else if (canRegister)
              FilledButton.icon(
                icon: const Icon(Icons.how_to_reg),
                label: const Text('Daftar jadi relawan'),
                onPressed: () async {
                  final done = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => RegisterFormScreen(activity: a)));
                  if (done == true) _reload();
                },
              )
            else if (a.myRegistrationStatus == null)
              Text(a.sudahLewat ? 'Pendaftaran sudah ditutup.' : 'Kuota sudah penuh.'),
          ]),
        );
      },
    );
  }
}
