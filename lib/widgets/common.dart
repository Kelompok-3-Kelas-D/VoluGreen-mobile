import 'package:flutter/material.dart';

import '../core/api_client.dart';

const kGreen = Color(0xFF2E7D4F);

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
}

/// Menjalankan [action], menampilkan snackbar bila gagal. Mengembalikan true jika berhasil.
Future<bool> guarded(BuildContext context, Future<void> Function() action,
    {String? success}) async {
  try {
    await action();
    if (context.mounted && success != null) showSnack(context, success);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
    return false;
  }
}

/// Daftar dengan pull-to-refresh, indikator memuat, error + coba lagi, dan keadaan kosong.
class AsyncListView<T> extends StatefulWidget {
  const AsyncListView({
    super.key,
    required this.load,
    required this.itemBuilder,
    this.emptyText = 'Belum ada data.',
    this.header,
    this.padding = const EdgeInsets.all(16),
  });

  final Future<List<T>> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function() reload) itemBuilder;
  final String emptyText;
  final Widget? header;
  final EdgeInsets padding;

  @override
  State<AsyncListView<T>> createState() => AsyncListViewState<T>();
}

class AsyncListViewState<T> extends State<AsyncListView<T>> {
  late Future<List<T>> _future = widget.load();

  Future<void> reload() async {
    final next = widget.load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ErrorState(message: '${snap.error}', onRetry: reload);
        }
        final items = snap.data!;
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: widget.padding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (widget.header != null) widget.header!,
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(widget.emptyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).hintColor)),
                  ),
                ),
              for (final item in items) widget.itemBuilder(context, item, reload),
            ],
          ),
        );
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Coba lagi')),
          ]),
        ),
      );
}

/// Chip status berwarna untuk status pendaftaran / publikasi / moderasi.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, this.label, {super.key});
  final String status;
  final String label;

  Color _color() {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
      case 'attended':
      case 'approved':
      case 'verified':
      case 'published':
      case 'resolved':
        return Colors.green;
      case 'rejected':
      case 'absent':
      case 'cancelled':
        return Colors.red;
      case 'pending':
      case 'draft':
      case 'open':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile(this.label, this.value, this.icon, {super.key});
  final String label;
  final Object value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: kGreen),
            const SizedBox(height: 8),
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}

/// Menampilkan galat validasi per-field dari server pada form.
String? fieldError(ApiException? e, String field) => e?.errors[field]?.first;

Future<String?> askText(BuildContext context, String title, {String hint = ''}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
          controller: ctrl, autofocus: true, maxLines: 3, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Kirim')),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String message) async =>
    (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
        ],
      ),
    )) ??
    false;
