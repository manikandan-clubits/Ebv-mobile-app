import '../enums.dart';

class NotificationItem {
  final int id;
  final bool? isRead;
  final String message;
  final String patientName;
  final String? patientId;
  final String? adminId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isSuccess;
  final bool? istechnical;
  final bool? notlinked;
  final bool? demographic;
  final bool? isPatientUpdate;
  final bool? isPatientDelete;

  NotificationItem({
    required this.id,
    required this.isRead,
    required this.message,
    required this.patientName,
    this.patientId,
    this.adminId,
    required this.createdAt,
    required this.updatedAt,
    this.isSuccess,
    this.istechnical,
    this.notlinked,
    this.demographic,
    this.isPatientUpdate,
    this.isPatientDelete,
  });

  // Factory constructor to create NotificationItem from JSON
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      isRead: json['isRead'] as bool? ?? false,
      message: json['message'] as String? ?? 'No message',
      patientName: json['patientName'] as String? ?? 'Unknown Patient',
      patientId: json['patientId']?.toString(),
      adminId: json['adminId']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isSuccess: json['isSuccess'] as bool?,
      istechnical: json['istechnical'] as bool?,
      notlinked: json['notlinked'] as bool?,
      demographic: json['demographic'] as bool?,
      isPatientUpdate: json['isPatientUpdate'] as bool?,
      isPatientDelete: json['isPatientDelete'] as bool?,
    );
  }

  // Helper method to parse DateTime
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    try {
      if (dateTime is String) {
        return DateTime.parse(dateTime);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper getter to determine notification type from your data
  NotificationType get type {
    if (isSuccess == true) {
      return NotificationType.success;
    } else if (istechnical == true) {
      return NotificationType.technical;
    } else if (notlinked == true) {
      return NotificationType.notLinked;
    } else if (demographic == true) {
      return NotificationType.invalidDemographic;
    } else if (isPatientUpdate == true) {
      return NotificationType.patientUpdate;
    } else if (isPatientDelete == true) {
      return NotificationType.patientDelete;
    }
    return NotificationType.system;
  }

  // Helper getter for title based on message
  String get title {
    if (message.contains('Successful Verification')) {
      return 'Verification Successful';
    } else if (message.contains('Technical Error')) {
      return 'Technical Error';
    } else if (message.contains('Not Linked')) {
      return 'Clearing House Issue';
    } else if (message.contains('Invalid Demographic')) {
      return 'Invalid Information';
    } else if (message.contains('Patient Information Update')) {
      return 'Patient Update Required';
    } else if (message.contains('Patient Information Deletion')) {
      return 'Patient Deleted';
    }
    return 'System Notification';
  }
}