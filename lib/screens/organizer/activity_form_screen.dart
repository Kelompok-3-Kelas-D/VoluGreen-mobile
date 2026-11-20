import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';

/// Ajukan kegiatan baru atau ubah draft ([existing]). Kegiatan selalu masuk antrean tinjauan admin.
class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({super.key, this.existing});
  final Activity? existing;

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  late final _nama = TextEditingController(text: widget.existing?.nama);
  late final _desk = TextEditingController(text: widget.existing?.deskripsi);
  late final _lokasi = TextEditingController(text: widget.existing?.namaLokasi);
  late final _alamat = TextEditingController(text: widget.existing?.alamat);
  late final _kota = TextEditingController(text: widget.existing?.kota);
  late final _kuota = TextEditingController(text: widget.existing?.kuota.toString());
  late final _lat = TextEditingController(text: widget.existing?.latitude?.toString());
  late final _lng = TextEditingController(text: widget.existing?.longitude?.toString());
  late DateTime? _date = widget.existing?.tanggalMulai;
  int? _category;
  List<Category> _categories = [];
  bool _busy = false;
  ApiException? _err;

  @override
  void initState() {
    super.initState();
    context.read<ApiClient>().get('categories/').then((res) {
      if (!mounted) return;
      setState(() {
        _categories = [for (final c in res as List) Category.fromJson(c as Map<String, dynamic>)];
        final current = widget.existing?.kategori;
        _category = _categories.where((c) => c.name == current).map((c) => c.id).firstOrNull;
      });
    }).catchError((_) {});
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: _date ?? now.add(const Duration(days: 7)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 730)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_date ?? DateTime(2000, 1, 1, 8)));
    if (t == null) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final body = {
      'nama': _nama.text.trim(),
      'deskripsi': _desk.text.trim(),
      'kategori': _category,
      'tanggal_mulai': _date?.toUtc().toIso8601String() ?? '',
      'nama_lokasi': _lokasi.text.trim(),
      'alamat': _alamat.text.trim(),
      'kota': _kota.text.trim(),
      'kuota': _kuota.text.trim(),
      'latitude': _lat.text.trim().isEmpty ? null : _lat.text.trim(),
      'longitude': _lng.text.trim().isEmpty ? null : _lng.text.trim(),
    };
    final api = context.read<ApiClient>();
    try {
      if (widget.existing != null) {
        await api.put('organizer/activities/${widget.existing!.id}/', body);
      } else {
        await api.post('organizer/activities/', body);
      }
      if (!mounted) return;
      showSnack(context, 'Kegiatan terkirim untuk ditinjau admin.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(TextEditingController c, String label, String key,
          {int lines = 1, TextInputType? type}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: lines,
          keyboardType: type,
          decoration: InputDecoration(labelText: label, errorText: fieldError(_err, key)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Ajukan kegiatan' : 'Edit draft kegiatan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _f(_nama, 'Nama kegiatan', 'nama'),
        _f(_desk, 'Deskripsi', 'deskripsi', lines: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<int>(
            initialValue: _category,
            decoration: InputDecoration(labelText: 'Kategori', errorText: fieldError(_err, 'kategori')),
            items: [for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
            onChanged: (v) => setState(() => _category = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                  labelText: 'Waktu mulai',
                  errorText: fieldError(_err, 'tanggal_mulai'),
                  suffixIcon: const Icon(Icons.calendar_month)),
              child: Text(_date == null ? 'Pilih tanggal & jam' : DateFormat('d MMM yyyy · HH.mm').format(_date!)),
            ),
          ),
        ),
        _f(_lokasi, 'Nama lokasi', 'nama_lokasi'),
        _f(_alamat, 'Alamat (opsional)', 'alamat'),
        _f(_kota, 'Kota', 'kota'),
        Row(children: [
          Expanded(child: _f(_lat, 'Latitude', 'latitude', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
          const SizedBox(width: 12),
          Expanded(child: _f(_lng, 'Longitude', 'longitude', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
        ]),
        _f(_kuota, 'Kuota relawan', 'kuota', type: TextInputType.number),
        if (_err != null && _err!.errors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_err!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_err?.errors['__all__'] != null)
          Text(_err!.errors['__all__']!.first, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        FilledButton(onPressed: _busy ? null : _submit, child: const Text('Kirim untuk ditinjau')),
      ]),
    );
  }
}
