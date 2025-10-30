
// Define a model class for your patient summary data
class PatientSummary {
  final int totalPatients;
  final int verified;
  final int notVerified;
  final int active;
  final int inactive;
  final int payerCount;
  final int pendingCount;

  PatientSummary({
    required this.totalPatients,
    required this.verified,
    required this.notVerified,
    required this.active,
    required this.inactive,
    required this.payerCount,
    required this.pendingCount,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    return PatientSummary(
      totalPatients: json['totalPatients'] ?? 0,
      verified: json['verified'] ?? 0,
      notVerified: json['notVerified'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      payerCount: json['payerCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
    );
  }
}