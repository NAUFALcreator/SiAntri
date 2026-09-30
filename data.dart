import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef M = Map<String, dynamic>;
SupabaseClient get sb => Supabase.instance.client;

const mu = Color(0xFF93A0C4);
const ink = Color(0xFF06122B);
const grad = LinearGradient(colors: [Color(0xFF7C83FF), Color(0xFF2DD4EE)]);
const label = {'waiting': 'Menunggu', 'called': 'Dipanggil', 'done': 'Selesai', 'skipped': 'Dilewati', 'cancelled': 'Dibatalkan'};

String today() => DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String().substring(0, 10);

class QueueData {
  final List<M> services, counters, tickets;
  QueueData(this.services, this.counters, this.tickets);
  List<M> waitingOf(int sid) => tickets.where((t) => t['service_id'] == sid && t['status'] == 'waiting').toList();
  M? byId(String? id) {
    for (final t in tickets) { if (t['id'] == id) return t; }
    return null;
  }
  M? service(int? id) {
    for (final s in services) { if (s['id'] == id) return s; }
    return null;
  }
  M? counter(int? id) {
    for (final c in counters) { if (c['id'] == id) return c; }
    return null;
  }
  M? current(int counterId) {
    M? r;
    for (final t in tickets) { if (t['counter_id'] == counterId && t['status'] == 'called') r = t; }
    return r;
  }
}

/// Data antrean hari ini, realtime lewat Supabase Realtime.
Stream<QueueData> watchQueue() async* {
  final sv = List<M>.from(await sb.from('services').select().order('code'));
  final ct = List<M>.from(await sb.from('counters').select().eq('active', true).order('name'));
  await for (final rows in sb.from('tickets').stream(primaryKey: ['id']).order('created_at')) {
    yield QueueData(sv, ct, rows.where((t) => t['queue_date'] == today()).toList());
  }
}

void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Widget glass({required Widget child, Color? border, EdgeInsets pad = const EdgeInsets.all(20)}) => Container(
      padding: pad,
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border ?? const Color(0x1AFFFFFF), width: border == null ? 1 : 2),
      ),
      child: child,
    );

Widget gradBtn(String text, VoidCallback onTap, {Color? color}) => Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(gradient: color == null ? grad : null, borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(text, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
