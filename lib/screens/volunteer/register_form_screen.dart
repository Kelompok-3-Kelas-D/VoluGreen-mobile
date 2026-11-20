import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';

/// Form pendaftaran relawan (buat baru) atau ubah informasi ([existing]).
class RegisterFormScreen extends StatefulWidget {
  const RegisterFormScreen({super.key, this.activity, this.existing})
      : assert(activity != null || existing != null);
  final Activity? activity;
  final Registration? existing;

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  late final _motivasi = TextEditingController(text: widget.existing?.motivasi);
  late final _kontak = TextEditingController(text: widget.existing?.kontakDarurat);
  late final _pengalaman = TextEditingController(text: widget.existing?.pengalaman);
  late final _kebutuhan = TextEditingController(text: widget.existing?.kebutuhanKhusus);
  bool _busy = false;
  ApiException? _err;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final api = context.read<ApiClient>();
    final body = {
      'motivasi': _motivasi.text,
      'kontak_darurat': _kontak.text,
      'pengalaman_relevan': _pengalaman.text,
      'kebutuhan_khusus': _kebutuhan.text,
    };
    try {
      if (widget.existing != null) {
        await api.patch('volunteer/registrations/${widget.existing!.id}/', body);
      } else {
        await api.post('volunteer/activities/${widget.activity!.id}/register/', body);
      }
      if (!mounted) return;
      showSnack(context, widget.existing != null ? 'Pendaftaran diperbarui.' : 'Pendaftaran terkirim, menunggu konfirmasi penyelenggara.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController c, String label, String key, {int lines = 1, TextInputType? type}) =>
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
    final title = widget.activity?.nama ?? widget.existing!.kegiatanNama;
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Ubah pendaftaran' : 'Daftar kegiatan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _field(_motivasi, 'Motivasi (min. 10 karakter)', 'motivasi', lines: 3),
        _field(_kontak, 'Kontak darurat (nomor telepon)', 'kontak_darurat', type: TextInputType.phone),
        _field(_pengalaman, 'Pengalaman relevan (opsional)', 'pengalaman_relevan', lines: 2),
        _field(_kebutuhan, 'Kebutuhan khusus (opsional)', 'kebutuhan_khusus'),
        if (_err != null && _err!.errors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_err!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_err != null && _err!.errors.containsKey('__all__'))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_err!.errors['__all__']!.first,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.existing != null ? 'Simpan perubahan' : 'Kirim pendaftaran'),
        ),
      ]),
    );
  }
}
