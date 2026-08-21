class SecurityAlertModel {
  final String title;
  final String description;
  final String severity;
  final String? source;
  final String? type;
  final DateTime createdAt;

  SecurityAlertModel({
    required this.title,
    required this.description,
    required this.severity,
    this.source,
    this.type,
    required this.createdAt,
  });

  factory SecurityAlertModel.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['source'] ?? 'Security Alert').toString().trim();
    final description = (json['description'] ?? json['details'] ?? '').toString().trim();
    final severity = (json['severity'] ?? json['status'] ?? 'medium').toString().trim();
    final source = (json['source'] ?? 'External').toString().trim();
    final type = (json['type'] ?? 'port_scan_detected').toString().trim();

    return SecurityAlertModel(
      title: title,
      description: description,
      severity: severity,
      source: source,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'severity': severity,
        'source': source,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
      };
}
