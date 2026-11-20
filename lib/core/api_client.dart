import 'dart:convert';

import 'package:http/http.dart' as http;

/// Alamat server Django. Ubah saat build:
/// `flutter run --dart-define=API_BASE=https://rayhan-fairuz51-volugreen.pws.cs.ui.ac.id`
/// Default `10.0.2.2` = localhost milik host untuk emulator Android.
const String kApiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8000');
const String _prefix = '/api/v1';

class ApiException implements Exception {
  ApiException(this.message, {this.status, this.errors = const {}});
  final String message;
  final int? status;
  final Map<String, List<String>> errors;

  bool get unauthorized => status == 401;

  @override
  String toString() => message;
}

/// Pembungkus HTTP tunggal: menambah header token dan mengubah error JSON DRF
/// (`{"detail": ..., "errors": {...}}`) menjadi [ApiException].
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  /// Dipanggil saat server menjawab 401 (token kedaluwarsa/dicabut).
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String?>? query]) {
    final q = <String, String>{
      for (final e in (query ?? {}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    final base = Uri.parse('$kApiBase$_prefix/$path');
    return q.isEmpty ? base : base.replace(queryParameters: q);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Future<dynamic> get(String path, {Map<String, String?>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() => _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Object? body]) => _send(() => _client.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, [Object? body]) =>
      _send(() => _client.patch(_uri(path),
          headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 20));
    } on Exception {
      throw ApiException(
          'Tidak dapat terhubung ke server. Periksa koneksi internet kamu.');
    }
    dynamic body;
    if (res.bodyBytes.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        body = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    if (res.statusCode == 401 && token != null) onUnauthorized?.call();
    final errors = <String, List<String>>{};
    if (body is Map && body['errors'] is Map) {
      (body['errors'] as Map).forEach((k, v) {
        errors['$k'] = [for (final m in (v as List)) '$m'];
      });
    }
    final message = (body is Map && body['detail'] != null)
        ? '${body['detail']}'
        : 'Terjadi kesalahan (${res.statusCode}).';
    throw ApiException(message, status: res.statusCode, errors: errors);
  }
}
