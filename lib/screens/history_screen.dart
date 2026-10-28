import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';

/// Historique d'un magasin + temps moyen de réaction.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.storeId});
  final String storeId;

  static const _statusColor = {
    'open': Colors.red,
    'taken': Colors.orange,
    'resolved': Colors.green,
    'cancelled': Colors.grey,
  };

  String _fmt(Duration? d) {
    if (d == null) return '—';
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    return '${d.inMinutes} min ${d.inSeconds % 60} s';
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLang.instance.value;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text(tr('history'))),
      body: StreamBuilder<List<CaisseAlert>>(
        stream: AlertService().history(storeId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final alerts = snap.data!;
          final reactions = alerts.map((a) => a.reactionTime).whereType<Duration>().toList();
          final avg = reactions.isEmpty
              ? null
              : Duration(
                  seconds: reactions.map((d) => d.inSeconds).reduce((a, b) => a + b) ~/
                      reactions.length);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(children: [
                _Stat(label: tr('alertsCount'), value: '${alerts.length}'),
                _Stat(label: tr('avgReaction'), value: _fmt(avg)),
              ]),
              const SizedBox(height: 12),
              ...alerts.map((a) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (_statusColor[a.status] ?? Colors.grey).withOpacity(0.2),
                        child: Text(a.register, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text('${a.typeLabel(lang)} · ${a.cashierName}'),
                      subtitle: Text([
                        if (a.createdAt != null) dateFmt.format(a.createdAt!),
                        if (a.message.isNotEmpty) '« ${a.message} »',
                        if (a.takenByName != null)
                          tr('reaction', {'d': _fmt(a.reactionTime), 'name': a.takenByName!}),
                        if (a.resolutionTime != null) tr('solvedIn', {'d': _fmt(a.resolutionTime)}),
                      ].join('\n')),
                      isThreeLine: true,
                      trailing: Text(tr('st_${a.status}'),
                          style: TextStyle(color: _statusColor[a.status])),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label),
          ]),
        ),
      ),
    );
  }
}
