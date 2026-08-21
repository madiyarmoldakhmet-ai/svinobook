class SecurityAlertModel {
  final String source;
  final String type;
  final String status;
  final String details;
  final DateTime createdAt;

  SecurityAlertModel({
    required this.source,
    required this.type,
    required this.status,
    required this.details,
    required this.createdAt,
  });

  factory SecurityAlertModel.fromJson(Map<String, dynamic> json) {
    final source = (json['source'] ?? '').toString().trim();
    final type = (json['type'] ?? '').toString().trim();
    final status = (json['status'] ?? '').toString().trim();
    final details = (json['details'] ?? '').toString().trim();

    return SecurityAlertModel(
      source: source,
      type: type,
      status: status,
      details: details,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'type': type,
        'status': status,
        'details': details,
        'createdAt': createdAt.toIso8601String(),
      };
}
