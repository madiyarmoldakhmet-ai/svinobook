import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/security_alert_model.dart';
import '../services/security_alert_service.dart';
import '../utils/app_theme.dart';
import '../widgets/security_alert_card.dart';

class SecurityDashboardTab extends StatefulWidget {
  const SecurityDashboardTab({super.key});

  @override
  State<SecurityDashboardTab> createState() => _SecurityDashboardTabState();
}

class _SecurityDashboardTabState extends State<SecurityDashboardTab> {
  final _alertsQuery = FirebaseFirestore.instance
      .collection('security_alerts')
      .orderBy('createdAt', descending: true);
  String _filter = 'All';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_filter == 'All') return docs;

    return docs.where((doc) {
      final severity = (doc.data()['severity'] ?? '').toString().toLowerCase();
      return severity == _filter.toLowerCase();
    }).toList();
  }

  Future<void> _deleteAlert(String documentId) async {
    await FirebaseFirestore.instance
        .collection('security_alerts')
        .doc(documentId)
        .delete();
  }

  Future<void> _clearOldAlerts() async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 30)),
    );
    final oldAlerts = await FirebaseFirestore.instance
        .collection('security_alerts')
        .where('createdAt', isLessThan: cutoff)
        .get();

    if (oldAlerts.docs.isEmpty || !mounted) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in oldAlerts.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _alertsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan),
              );
            }
            if (snapshot.hasError) {
              return _ErrorState(message: 'Error loading security alerts');
            }

            final docs = snapshot.data?.docs ?? [];
            final visibleDocs = _filteredDocs(docs);
            final counts = _severityCounts(docs);
            final threatDetected = counts['high']! > 0 ||
                counts['critical']! > 0 ||
                counts['warning']! > 0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _DashboardHeader(
                    threatDetected: threatDetected,
                    listenerActive: SecurityAlertService.isListening,
                    onClearOld: docs.isEmpty ? null : _clearOldAlerts,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Summary(
                    total: docs.length,
                    counts: counts,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'All', label: Text('All')),
                        ButtonSegment(value: 'High', label: Text('High')),
                        ButtonSegment(value: 'Medium', label: Text('Medium')),
                        ButtonSegment(value: 'Low', label: Text('Low')),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (selection) {
                        setState(() => _filter = selection.first);
                      },
                    ),
                  ),
                ),
                if (visibleDocs.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No alerts in this filter')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = visibleDocs[index];
                          final alert = SecurityAlertModel.fromJson(doc.data());
                          return Stack(
                            children: [
                              SecurityAlertCard(alert: alert),
                              Positioned(
                                top: 12,
                                right: 22,
                                child: IconButton(
                                  tooltip: 'Delete alert',
                                  onPressed: () => _deleteAlert(doc.id),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          );
                        },
                        childCount: visibleDocs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, int> _severityCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final counts = {'high': 0, 'medium': 0, 'low': 0, 'critical': 0, 'warning': 0};
    for (final doc in docs) {
      final severity = (doc.data()['severity'] ?? '').toString().toLowerCase();
      if (counts.containsKey(severity)) counts[severity] = counts[severity]! + 1;
    }
    return counts;
  }
}

class _DashboardHeader extends StatelessWidget {
  final bool threatDetected;
  final bool listenerActive;
  final VoidCallback? onClearOld;

  const _DashboardHeader({
    required this.threatDetected,
    required this.listenerActive,
    required this.onClearOld,
  });

  @override
  Widget build(BuildContext context) {
    final color = threatDetected ? AppColors.danger : Colors.green.shade300;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        12,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shield_rounded, color: color),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Security Hub',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Clear alerts older than 30 days',
                onPressed: onClearOld,
                icon: const Icon(Icons.cleaning_services_outlined),
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            threatDetected ? 'THREAT DETECTED' : 'SYSTEM STATUS: SECURE',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                listenerActive ? Icons.radio_button_checked : Icons.error_outline,
                size: 15,
                color: listenerActive ? Colors.green.shade300 : AppColors.danger,
              ),
              const SizedBox(width: 6),
              Text(
                listenerActive
                    ? 'HTTP listener active • 8080 • Kali link ready'
                    : 'HTTP listener inactive • port 8080',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int total;
  final Map<String, int> counts;

  const _Summary({required this.total, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _Metric(label: 'Intercepted', value: total.toString(), color: AppColors.neonCyan),
          _Metric(label: 'High', value: '${counts['high']! + counts['critical']!}', color: AppColors.danger),
          _Metric(label: 'Medium', value: '${counts['medium']! + counts['warning']!}', color: Colors.orange.shade300),
          _Metric(label: 'Low', value: counts['low'].toString(), color: Colors.green.shade300),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: const TextStyle(color: AppColors.textSecondary)));
  }
}
