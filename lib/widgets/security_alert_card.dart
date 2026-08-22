import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/security_alert_model.dart';
import '../utils/app_theme.dart';

class SecurityAlertCard extends StatelessWidget {
  final SecurityAlertModel alert;
  const SecurityAlertCard({super.key, required this.alert});

  bool get isCritical => alert.severity.toLowerCase() == 'critical';

  @override
  Widget build(BuildContext context) {
    final accent = isCritical ? AppColors.danger : AppColors.warning;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCritical
              ? [AppColors.danger.withValues(alpha: 0.22), AppColors.bgMid]
              : [Colors.orange.withValues(alpha: 0.18), AppColors.bgMid],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCritical
                      ? Icons.warning_amber_rounded
                      : Icons.security_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${alert.source ?? 'Security'} • ${alert.severity.toUpperCase()}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              DateFormat.jm().format(alert.createdAt),
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
