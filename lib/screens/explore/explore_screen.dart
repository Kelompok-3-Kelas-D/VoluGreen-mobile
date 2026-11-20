import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import 'activity_detail_screen.dart';

/// Modul 2: pencarian + filter kegiatan, tampilan daftar atau peta OpenStreetMap.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.guest = false});

  /// Tamu tidak login: hanya melihat, tanpa arsip/pendaftaran.
  final bool guest;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _periode = 'upcoming';
  int? _category;
  String? _city;
  bool _map = false;
  List<Category> _categories = [];
  List<String> _cities = [];
  late Future<List<Activity>> _future = _load();

  @override
  void initState() {
    super.initState();
    context.read<ApiClient>().get('categories/').then((res) {
      if (mounted) {
        setState(() => _categories = [
              for (final c in res as List) Category.fromJson(c as Map<String, dynamic>)
            ]);
      }
    }).catchError((_) {});
  }

  Future<List<Activity>> _load() async {
    final res = await context.read<ApiClient>().get('activities/', query: {
      'q': _search.text.trim(),
      'kategori': _category?.toString(),
      'kota': _city,
      'periode': _periode,
    }) as Map<String, dynamic>;
    _cities = [for (final c in res['cities'] as List) '$c'];
    return [for (final a in res['results'] as List) Activity.fromJson(a as Map<String, dynamic>)];
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _refresh(),
              decoration: InputDecoration(
                hintText: 'Cari kegiatan, lokasi, penyelenggara',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _refresh();
                        }),
              ),
            ),
          ),
          IconButton(
            tooltip: _map ? 'Tampilkan daftar' : 'Tampilkan peta',
            icon: Icon(_map ? Icons.view_list : Icons.map_outlined),
            onPressed: () => setState(() => _map = !_map),
          ),
        ]),
      ),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final p in const {'upcoming': 'Akan datang', 'past': 'Sebelumnya', 'all': 'Semua'}.entries)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ChoiceChip(
                  label: Text(p.value),
                  selected: _periode == p.key,
                  onSelected: (_) {
                    _periode = p.key;
                    _refresh();
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: PopupMenuButton<int?>(
                onSelected: (v) {
                  _category = v;
                  _refresh();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('Semua kategori')),
                  for (final c in _categories) PopupMenuItem(value: c.id, child: Text(c.name)),
                ],
                child: Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(_category == null
                      ? 'Kategori'
                      : _categories.where((c) => c.id == _category).map((c) => c.name).firstOrNull ?? 'Kategori'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: PopupMenuButton<String?>(
                onSelected: (v) {
                  _city = v;
                  _refresh();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('Semua kota')),
                  for (final c in _cities) PopupMenuItem(value: c, child: Text(c)),
                ],
                child: Chip(
                  avatar: const Icon(Icons.place_outlined, size: 18),
                  label: Text(_city ?? 'Kota'),
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Activity>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _refresh);
            final items = snap.data!;
            if (items.isEmpty) {
              return const Center(child: Text('Tidak ada kegiatan yang cocok dengan filter.'));
            }
            return _map ? _MapView(items: items, guest: widget.guest) : _ListView(items: items, guest: widget.guest, onChanged: _refresh);
          },
        ),
      ),
    ]);
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.items, required this.guest, required this.onChanged});
  final List<Activity> items;
  final bool guest;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async => onChanged(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) => ActivityCard(
            activity: items[i],
            guest: guest,
            onReturn: onChanged,
          ),
        ),
      );
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.guest, this.onReturn, this.trailing});
  final Activity activity;
  final bool guest;
  final VoidCallback? onReturn;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(id: a.id, guest: guest)));
          onReturn?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(a.nama, style: Theme.of(context).textTheme.titleMedium)),
              ?trailing,
            ]),
            const SizedBox(height: 4),
            Text(a.penyelenggara, style: TextStyle(color: Theme.of(context).hintColor)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.event, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(formatDate(a.tanggalMulai))),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.place, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text([a.namaLokasi, a.kota].where((e) => e.isNotEmpty).join(', '))),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              Chip(label: Text(a.kategori), visualDensity: VisualDensity.compact),
              Chip(
                  label: Text(a.sudahLewat ? 'Sudah berlalu' : 'Sisa ${a.sisaKuota}/${a.kuota}'),
                  visualDensity: VisualDensity.compact),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({required this.items, required this.guest});
  final List<Activity> items;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final pins = items.where((a) => a.hasCoordinates).toList();
    if (pins.isEmpty) {
      return const Center(child: Text('Belum ada kegiatan dengan koordinat peta.'));
    }
    final points = [for (final a in pins) LatLng(a.latitude!, a.longitude!)];
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: points.length == 1
            ? null
            : CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(48), maxZoom: 14),
        initialCenter: points.first,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.ac.ui.volugreen_mobile',
        ),
        MarkerLayer(markers: [
          for (final a in pins)
            Marker(
              point: LatLng(a.latitude!, a.longitude!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(id: a.id, guest: guest))),
                child: const Icon(Icons.location_on, color: kGreen, size: 40),
              ),
            ),
        ]),
        const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
      ],
    );
  }
}
