import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_provider.dart';
import '../core/models.dart';
import '../widgets/common.dart';
import 'auth/register_screen.dart' show orgTypes;
import 'explore/explore_screen.dart';

/// Modul 1: profil, ubah data, ganti kata sandi, keluar. Dipakai semua peran.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user!;
    final roleLabel = {'volunteer': 'Relawan', 'organizer': 'Penyelenggara', 'admin': 'Admin'}[u.role]!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(
        child: CircleAvatar(
          radius: 36,
          backgroundColor: kGreen,
          child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 28, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 12),
      Center(child: Text(u.name, style: Theme.of(context).textTheme.titleLarge)),
      Center(child: Text(u.username)),
      const SizedBox(height: 6),
      Center(child: Wrap(spacing: 8, children: [
        Chip(label: Text(roleLabel)),
        if (u.isOrganizer && u.organizationStatus != null)
          StatusChip(u.organizationStatus!, {
                'pending': 'Menunggu verifikasi',
                'verified': 'Terverifikasi',
                'rejected': 'Ditolak'
              }[u.organizationStatus!] ??
              u.organizationStatus!),
      ])),
      const SizedBox(height: 16),
      if (u.phone.isNotEmpty) ListTile(leading: const Icon(Icons.phone), title: Text(u.phone)),
      if (u.city.isNotEmpty) ListTile(leading: const Icon(Icons.place), title: Text(u.city)),
      const Divider(),
      if (!u.isAdmin)
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Ubah profil'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: u))),
        ),
      if (u.isVolunteer)
        ListTile(
          leading: const Icon(Icons.bookmark),
          title: const Text('Arsip kegiatan'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen())),
        ),
      ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Ganti kata sandi'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
      ),
      ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: const Text('Laporkan masalah'),
        onTap: () => _report(context),
      ),
      ListTile(
        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
        title: const Text('Keluar'),
        onTap: () async {
          if (await confirm(context, 'Keluar dari akun ini?') && context.mounted) {
            await context.read<AuthProvider>().logout();
          }
        },
      ),
    ]);
  }

  Future<void> _report(BuildContext context) async {
    final text = await askText(context, 'Laporkan masalah', hint: 'Jelaskan masalah atau kegiatan yang dilaporkan');
    if (text == null || text.isEmpty || !context.mounted) return;
    await guarded(context, () async {
      await context.read<ApiClient>().post('admin/reports/', {
        'subject': text.length > 60 ? '${text.substring(0, 60)}…' : text,
        'details': text,
      });
    }, success: 'Laporan terkirim ke admin.');
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});
  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _city = TextEditingController(text: widget.user.city);
  late final _desc = TextEditingController(text: widget.user.organizationDescription);
  late String _type =
      orgTypes.containsKey(widget.user.organizationType) ? widget.user.organizationType : 'campus';
  bool _busy = false;
  ApiException? _err;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await context.read<AuthProvider>().updateProfile({
        'name': _name.text,
        'phone_number': _phone.text,
        'city': _city.text,
        if (widget.user.isOrganizer) ...{'organization_type': _type, 'organization_description': _desc.text},
      });
      if (!mounted) return;
      showSnack(context, 'Perubahan profil tersimpan.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(TextEditingController c, String label, String key, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
            controller: c,
            maxLines: lines,
            decoration: InputDecoration(labelText: label, errorText: fieldError(_err, key))),
      );

  @override
  Widget build(BuildContext context) {
    final org = widget.user.isOrganizer;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah profil')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _f(_name, org ? 'Nama organisasi' : 'Nama lengkap', 'name'),
        _f(_phone, 'Nomor HP', 'phone_number'),
        _f(_city, 'Kota', 'city'),
        if (org) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Jenis organisasi'),
              items: [for (final e in orgTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _type = v!),
            ),
          ),
          _f(_desc, 'Tentang organisasi', 'organization_description', lines: 3),
          const Text('Mengubah data organisasi membutuhkan verifikasi ulang oleh admin.'),
          const SizedBox(height: 12),
        ],
        if (_err != null && _err!.errors.isEmpty)
          Text(_err!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan')),
      ]),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  bool _busy = false;
  ApiException? _err;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await context.read<AuthProvider>().changePassword(_old.text, _new.text);
      if (!mounted) return;
      showSnack(context, 'Kata sandi diperbarui.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ganti kata sandi')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _old,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Kata sandi lama', errorText: fieldError(_err, 'old_password'))),
          const SizedBox(height: 12),
          TextField(
              controller: _new,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: 'Kata sandi baru', errorText: fieldError(_err, 'new_password2'))),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan')),
        ]),
      );
}

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Arsip kegiatan')),
        body: AsyncListView<Activity>(
          load: () async => [
            for (final a in await context.read<ApiClient>().get('bookmarks/') as List)
              Activity.fromJson(a as Map<String, dynamic>)
          ],
          emptyText: 'Belum ada kegiatan yang diarsipkan.',
          itemBuilder: (context, a, reload) =>
              ActivityCard(activity: a, guest: false, onReturn: reload),
        ),
      );
}
