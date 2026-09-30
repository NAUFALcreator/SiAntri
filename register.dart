import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  late final Stream<QueueData> stream = watchQueue();
  String? myId;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) => setState(() => myId = p.getString('ticket')));
  }

  Future<void> take(int serviceId) async {
    try {
      final r = await sb.rpc('take_ticket', params: {'p_service': serviceId});
      final id = (r as Map)['id'] as String;
      (await SharedPreferences.getInstance()).setString('ticket', id);
      setState(() => myId = id);
    } catch (e) {
      if (mounted) snack(context, 'Gagal mengambil nomor: $e');
    }
  }

  Future<void> cancel() async {
    await sb.rpc('cancel_ticket', params: {'p_id': myId});
  }

  Future<void> leave() async {
    (await SharedPreferences.getInstance()).remove('ticket');
    setState(() => myId = null);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: StreamBuilder<QueueData>(
          stream: stream,
          builder: (c, s) {
            if (s.hasError) return Center(child: Text('Gagal memuat: ${s.error}'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final d = s.data!;
            final t = d.byId(myId);
            return ListView(padding: const EdgeInsets.all(20), children: t == null ? pick(d) : [ticket(d, t)]);
          },
        ),
      );

  List<Widget> pick(QueueData d) => [
        const Text('Ambil nomor antrean,\ntanpa berdiri menunggu.',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 6),
        const Text('Pilih layanan untuk mendapatkan nomor.', style: TextStyle(color: mu)),
        const SizedBox(height: 20),
        for (final s in d.services)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => take(s['id'] as int),
              child: glass(
                child: Row(children: [
                  Container(
                    width: 48, height: 48, alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(12)),
                    child: Text(s['code'], style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('${d.waitingOf(s['id'] as int).length} orang menunggu · ±${s['avg_minutes']} menit/orang',
                          style: const TextStyle(color: mu, fontSize: 13)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
      ];

  Widget ticket(QueueData d, M t) {
    final s = d.service(t['service_id'] as int?);
    final c = d.counter(t['counter_id'] as int?);
    final status = t['status'] as String;
    final called = status == 'called';
    final ahead = d.waitingOf(t['service_id'] as int).where((x) => (x['created_at'] as String).compareTo(t['created_at'] as String) < 0).length;
    final avg = (s?['avg_minutes'] ?? 5) as int;
    final msg = called
        ? 'Giliran Anda. Menuju ${c?['name'] ?? 'loket'}.'
        : status == 'waiting' ? '$ahead orang di depan Anda · estimasi ${ahead * avg} menit' : 'Antrean ini sudah berakhir.';
    return glass(
      border: called ? const Color(0xFF34D399) : null,
      pad: const EdgeInsets.all(28),
      child: Column(children: [
        Chip(label: Text(label[status] ?? status)),
        Text(t['number'], style: const TextStyle(fontSize: 88, fontWeight: FontWeight.w800, letterSpacing: -3)),
        const Divider(height: 32),
        Text(s?['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: mu)),
        const SizedBox(height: 18),
        status == 'waiting'
            ? gradBtn('Batalkan antrean', cancel, color: const Color(0xFFF87171))
            : gradBtn('Ambil nomor lagi', leave),
      ]),
    );
  }
}
