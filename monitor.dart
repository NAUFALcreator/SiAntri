import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'data.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});
  @override
  State<MonitorScreen> createState() => _MonitorState();
}

class _MonitorState extends State<MonitorScreen> {
  final tts = FlutterTts();
  final seen = <int, String>{};
  StreamSubscription<QueueData>? sub;
  QueueData? data;
  bool sound = false;

  @override
  void initState() {
    super.initState();
    tts.setLanguage('id-ID');
    sub = watchQueue().listen((d) {
      for (final c in d.counters) {
        final id = c['id'] as int;
        final cur = d.current(id);
        final key = cur == null ? '' : '${cur['id']}${cur['called_at']}';
        if (seen.containsKey(id) && key.isNotEmpty && seen[id] != key && sound) {
          tts.speak('Nomor ${(cur!['number'] as String).split('').join(' ')}, silakan menuju ${c['name']}');
        }
        seen[id] = key;
      }
      if (mounted) setState(() => data = d);
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    return SafeArea(
      child: d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Row(children: [
                const Expanded(child: Text('Sedang dilayani', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800))),
                IconButton(
                  icon: Icon(sound ? Icons.volume_up : Icons.volume_off),
                  tooltip: 'Suara panggilan',
                  onPressed: () {
                    setState(() => sound = !sound);
                    if (sound) tts.speak('Suara panggilan aktif');
                  },
                ),
              ]),
              const SizedBox(height: 16),
              GridView.extent(
                maxCrossAxisExtent: 260, shrinkWrap: true, mainAxisSpacing: 14, crossAxisSpacing: 14,
                physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.15,
                children: [
                  for (final c in d.counters) counterCard(c, d.current(c['id'] as int)),
                ],
              ),
              const SizedBox(height: 20),
              glass(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Menunggu per layanan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  for (final s in d.services)
                    ListTile(
                      dense: true, contentPadding: EdgeInsets.zero,
                      title: Text('${s['code']} · ${s['name']}'),
                      trailing: Text('${d.waitingOf(s['id'] as int).length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                ]),
              ),
            ]),
    );
  }

  Widget counterCard(M c, M? cur) => glass(
        border: cur != null ? const Color(0xFF34D399) : null,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(c['name'], style: const TextStyle(color: mu)),
          Text(cur?['number'] ?? '—', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2)),
          Text(cur != null ? 'Dilayani' : 'Kosong', style: TextStyle(color: cur != null ? const Color(0xFF34D399) : mu)),
        ]),
      );
}
