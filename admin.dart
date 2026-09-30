import 'package:flutter/material.dart';
import 'data.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminState();
}

class _AdminState extends State<AdminScreen> {
  final email = TextEditingController(), pass = TextEditingController();
  Stream<QueueData>? stream;
  int? counterId;

  bool get loggedIn => sb.auth.currentSession != null;

  Future<void> signIn() async {
    try {
      await sb.auth.signInWithPassword(email: email.text.trim(), password: pass.text);
      setState(() => stream = watchQueue());
    } catch (_) {
      if (mounted) snack(context, 'Login gagal: email atau kata sandi salah');
    }
  }

  Future<void> signOut() async {
    await sb.auth.signOut();
    setState(() => stream = null);
  }

  Future<void> callNext() async {
    try {
      final r = await sb.rpc('call_next', params: {'p_counter': counterId});
      if (mounted) snack(context, r == null ? 'Tidak ada antrean menunggu' : 'Memanggil ${(r as Map)['number']}');
    } catch (e) {
      if (mounted) snack(context, '$e');
    }
  }

  Future<void> update(M? t, String a) async {
    if (t == null) return snack(context, 'Belum ada nomor yang dipanggil');
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await sb.from('tickets').update(a == 'recall' ? {'called_at': now} : {'status': a, 'done_at': now}).eq('id', t['id']);
      if (mounted) snack(context, a == 'recall' ? 'Memanggil ulang ${t['number']}' : '${label[a]}: ${t['number']}');
    } catch (e) {
      if (mounted) snack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: loggedIn ? panel() : login());

  Widget login() => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Masuk petugas', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Gunakan akun yang dibuat di Supabase Auth.', style: TextStyle(color: mu)),
        const SizedBox(height: 20),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: true, onSubmitted: (_) => signIn(), decoration: const InputDecoration(labelText: 'Kata sandi', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: gradBtn('Masuk', signIn)),
      ]);

  Widget panel() => StreamBuilder<QueueData>(
        stream: stream ??= watchQueue(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final d = s.data!;
          if (d.counters.isEmpty) return const Center(child: Text('Belum ada loket aktif.'));
          counterId ??= d.counters.first['id'] as int;
          final cur = d.current(counterId!);
          final waiting = d.tickets.where((t) => t['status'] == 'waiting').toList();
          int n(String k) => d.tickets.where((t) => t['status'] == k).length;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              const Expanded(child: Text('Panel loket', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800))),
              TextButton(onPressed: signOut, child: const Text('Keluar')),
            ]),
            const SizedBox(height: 12),
            glass(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                DropdownButton<int>(
                  value: counterId, isExpanded: true,
                  items: [for (final k in d.counters) DropdownMenuItem(value: k['id'] as int, child: Text(k['name']))],
                  onChanged: (v) => setState(() => counterId = v),
                ),
                const SizedBox(height: 8),
                const Text('Sedang dilayani', style: TextStyle(color: mu)),
                Text(cur?['number'] ?? '—', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800, letterSpacing: -3)),
                Text(cur == null ? 'Belum ada yang dilayani' : (d.service(cur['service_id'] as int?)?['name'] ?? ''), style: const TextStyle(color: mu)),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  gradBtn('Panggil berikutnya', callNext, color: const Color(0xFF34D399)),
                  gradBtn('Panggil ulang', () => update(cur, 'recall')),
                  gradBtn('Lewati', () => update(cur, 'skipped'), color: const Color(0xFFFBBF24)),
                  gradBtn('Selesai', () => update(cur, 'done'), color: const Color(0xFFCBD5E1)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            glass(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  for (final e in {'Menunggu': n('waiting'), 'Selesai': n('done'), 'Dilewati': n('skipped')}.entries)
                    Column(children: [Text('${e.value}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)), Text(e.key, style: const TextStyle(color: mu))]),
                ]),
                const Divider(height: 28),
                const Text('Antrean menunggu', style: TextStyle(fontWeight: FontWeight.w700)),
                if (waiting.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Tidak ada antrean.', style: TextStyle(color: mu))),
                for (final t in waiting.take(8))
                  ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(t['number']),
                      trailing: Text((t['created_at'] as String).substring(11, 16), style: const TextStyle(color: mu))),
              ]),
            ),
          ]);
        },
      );
}
