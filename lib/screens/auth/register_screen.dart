import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_provider.dart';
import '../../widgets/common.dart';

const orgTypes = {
  'waste_bank': 'Bank sampah',
  'environmental_community': 'Komunitas lingkungan',
  'community_garden': 'Kebun komunitas',
  'social_organization': 'Organisasi sosial',
  'campus': 'Kampus',
};

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _c = {
    for (final k in ['name', 'email', 'phone', 'city', 'pass', 'pass2', 'desc']) k: TextEditingController()
  };
  String _role = 'volunteer';
  String _orgType = 'campus';
  bool _terms = false;
  bool _busy = false;
  ApiException? _err;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await context.read<AuthProvider>().register({
        'role': _role,
        'name': _c['name']!.text.trim(),
        'username': _c['email']!.text.trim(),
        'phone_number': _c['phone']!.text.trim(),
        'city': _c['city']!.text.trim(),
        'password1': _c['pass']!.text,
        'password2': _c['pass2']!.text,
        'terms': _terms,
        if (_role == 'organizer') ...{
          'organization_type': _orgType,
          'organization_description': _c['desc']!.text.trim(),
        },
      });
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String key, String label, String errKey,
      {bool obscure = false, TextInputType? type, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c[key],
        obscureText: obscure,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, errorText: fieldError(_err, errKey)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = _role == 'organizer';
    return Scaffold(
      appBar: AppBar(title: const Text('Buat akun')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'volunteer', label: Text('Relawan'), icon: Icon(Icons.volunteer_activism)),
              ButtonSegment(value: 'organizer', label: Text('Penyelenggara'), icon: Icon(Icons.groups)),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
          const SizedBox(height: 16),
          _field('name', org ? 'Nama organisasi' : 'Nama lengkap', 'name'),
          _field('email', 'Email', 'username', type: TextInputType.emailAddress),
          _field('phone', 'Nomor HP', 'phone_number', type: TextInputType.phone),
          _field('city', 'Kota', 'city'),
          if (org) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                initialValue: _orgType,
                decoration: InputDecoration(
                    labelText: 'Jenis organisasi', errorText: fieldError(_err, 'organization_type')),
                items: [for (final e in orgTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _orgType = v!),
              ),
            ),
            _field('desc', 'Tentang organisasi', 'organization_description', lines: 3),
          ],
          _field('pass', 'Kata sandi (min. 8 karakter)', 'password1', obscure: true),
          _field('pass2', 'Ulangi kata sandi', 'password2', obscure: true),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            title: const Text('Saya menyetujui Syarat & Ketentuan'),
            subtitle: fieldError(_err, 'terms') == null
                ? null
                : Text(fieldError(_err, 'terms')!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_err != null && _err!.errors.isEmpty)
            Text(_err!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Daftar'),
          ),
        ]),
      ),
    );
  }
}
