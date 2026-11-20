import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';

/// Modul 4: catat/ubah dampak kegiatan (sampah, pohon, area) setelah kegiatan berlangsung.
class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key, required this.activity});
  final Activity activity;

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  late final _trash = TextEditingController(text: '${widget.activity.dampak?['sampah_terkumpul_kg'] ?? 0}');
  late final _trees = TextEditingController(text: '${widget.activity.dampak?['pohon_ditanam'] ?? 0}');
  late final _area = TextEditingController(text: '${widget.activity.dampak?['area_dibersihkan_m2'] ?? 0}');
  late final _note = TextEditingController(text: '${widget.activity.dampak?['catatan'] ?? ''}');
  bool _busy = false;
  ApiException? _err;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await context.read<ApiClient>().put('organizer/activities/${widget.activity.id}/impact/', {
        'sampah_terkumpul_kg': _trash.text.trim(),
        'pohon_ditanam': _trees.text.trim(),
        'area_dibersihkan_m2': _area.text.trim(),
        'catatan': _note.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'Laporan dampak tersimpan.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(TextEditingController c, String label, String key, {int lines = 1, bool number = true}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: lines,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
          decoration: InputDecoration(labelText: label, errorText: fieldError(_err, key)),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Dampak · ${widget.activity.nama}')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _f(_trash, 'Sampah terkumpul (kg)', 'sampah_terkumpul_kg'),
          _f(_trees, 'Pohon ditanam', 'pohon_ditanam'),
          _f(_area, 'Area dibersihkan (m²)', 'area_dibersihkan_m2'),
          _f(_note, 'Catatan', 'catatan', lines: 3, number: false),
          if (_err != null && _err!.errors.isEmpty)
            Text(_err!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan laporan')),
        ]),
      );
}
