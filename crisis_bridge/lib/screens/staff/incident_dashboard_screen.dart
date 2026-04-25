import 'package:crisis_bridge/models/sos_report.dart';
import 'package:crisis_bridge/providers/auth_provider.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class IncidentDashboardScreen extends StatelessWidget {
  const IncidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final propertyId = auth.responder?.propertyId ?? '';
    final fs = FirestoreService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('◆ INCIDENT DASHBOARD')),
      body: propertyId.isEmpty
          ? const Center(child: Text('No property'))
          : StreamBuilder<List<SosReport>>(
              stream: fs.activeSosStream(propertyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        const Text('ALL CLEAR — No active SOS'),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = reports[i];
                    return _SosCard(report: r, fs: fs);
                  },
                );
              },
            ),
    );
  }
}

class _SosCard extends StatelessWidget {
  final SosReport report;
  final FirestoreService fs;
  const _SosCard({required this.report, required this.fs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sos, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SOS — Floor ${report.floor} · ${report.areaName}',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
                Text(
                  DateFormat('HH:mm:ss').format(report.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('By: ${report.reportedBy}', style: theme.textTheme.bodySmall),
            if (report.latitude != null)
              Text(
                'GPS: ${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => fs.updateSosStatus(report.id, SosStatus.acknowledged),
                    child: const Text('ACKNOWLEDGE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => fs.updateSosStatus(report.id, SosStatus.resolved),
                    child: const Text('RESOLVE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}