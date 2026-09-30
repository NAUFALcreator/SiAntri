import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin.dart';
import 'config.dart';
import 'monitor.dart';
import 'register.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const SiAntriApp());
}

class SiAntriApp extends StatelessWidget {
  const SiAntriApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SIAntri',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C83FF), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF0A1022),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [const RegisterScreen(), const MonitorScreen(), const AdminScreen()];
    return Scaffold(
      body: pages[i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), label: 'Ambil Nomor'),
          NavigationDestination(icon: Icon(Icons.tv), label: 'Monitor'),
          NavigationDestination(icon: Icon(Icons.support_agent), label: 'Petugas'),
        ],
      ),
    );
  }
}
