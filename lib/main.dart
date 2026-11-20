import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/organizer/organizer_shell.dart';
import 'screens/volunteer/volunteer_shell.dart';
import 'widgets/common.dart';

void main() {
  final api = ApiClient();
  runApp(MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      ChangeNotifierProvider(create: (_) => AuthProvider(api)..restore()),
    ],
    child: const VoluGreenApp(),
  ));
}

class VoluGreenApp extends StatelessWidget {
  const VoluGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoluGreen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300)),
        ),
      ),
      home: const _Gate(),
    );
  }
}

/// Memilih layar awal berdasarkan sesi dan peran pengguna.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = auth.user;
    if (user == null) return const LoginScreen();
    if (user.isAdmin) return const AdminShell();
    if (user.isOrganizer) return const OrganizerShell();
    return const VolunteerShell();
  }
}
