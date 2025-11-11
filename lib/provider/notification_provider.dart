import 'dart:developer';
import 'package:riverpod/riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';


 final notificationProvider= StateNotifierProvider<NotificationNotifier,NotificationState>((ref) {
   return NotificationNotifier();
 });


class NotificationState {
  final List<NotificationItem> notificationList;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notificationList = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationItem>? notificationList,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notificationList: notificationList ?? this.notificationList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  int get unreadCount => notificationList.where((n) => n.isRead == false).length;
}


class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState());

  // Convert your JSON data to NotificationItem objects
  void loadNotificationsFromJson(Map<String, dynamic> jsonData) {
    try {
      final List<dynamic> data = jsonData['data'];
      final notifications = data.map((item) {
        return NotificationItem(
          id: item['id'] as int,
          isRead: item['isRead'] as bool? ?? false,
          message: item['message'] as String? ?? 'No message',
          patientName: item['patientName'] as String? ?? 'Unknown Patient',
          patientId: item['patientId']?.toString(),
          adminId: item['adminId']?.toString(),
          createdAt: DateTime.parse(item['createdAt'] as String),
          updatedAt: DateTime.parse(item['updatedAt'] as String),
          isSuccess: item['isSuccess'] as bool?,
          istechnical: item['istechnical'] as bool?,
          notlinked: item['notlinked'] as bool?,
          demographic: item['demographic'] as bool?,
          isPatientUpdate: item['isPatientUpdate'] as bool?,
          isPatientDelete: item['isPatientDelete'] as bool?,
        );
      }).toList();

      // Sort by creation date, newest first
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        notificationList: notifications,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load notifications: $e',
        isLoading: false,
      );
      log('Error loading notifications: $e');
    }
  }


  getNotifications() async {
    Map<String, dynamic> body = {
      "typeofnotify": "opendental",
      "notifyinapp": ["success"],
      "fromDate": null,
      "toDate": null,
      "isinapp": true,
      "isemail": true,
      "issms": true,
      "ismanual": "",
      "isscheduled": "",
      "isimport": "",
      "ispatientupdate": "",
      "ispatientdelete": ""
    };

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await ApiService().get('/notification/getAll', body);

      if (response.data == null) {
        throw Exception('Response data is null');
      }

      final results = ApiService().decryptData(
          response.data['encryptedData']!,
          response.data['iv']
      );

      log('Full decrypted response: $results');

      List<NotificationItem> notifications = [];

      // Extract notifications based on actual response structure
      if (results.containsKey('data')) {
        final data = results['data'];

        if (data is List) {
          log('Data is a List with ${data.length} items');
          notifications = _convertJsonListToNotificationItems(data);
        } else if (data is Map) {
          log('Data is a Map with keys: ${data.keys}');
          notifications = _extractNotificationsFromMap(data as Map<String, dynamic>);
        } else {
          log('Unexpected data type: ${data.runtimeType}');
        }
      } else {
        // If no 'data' key, check if results itself is the list
        if (results is List) {
          log('Results is a List with ${results.length} items');
          notifications = _convertJsonListToNotificationItems(results);
        } else if (results is Map) {
          log('Results is a Map, trying to extract notifications');
          notifications = _extractNotificationsFromMap(results as Map<String, dynamic>);
        }
      }

      log('Successfully loaded ${notifications.length} notifications');
      state = state.copyWith(
        notificationList: notifications,
        isLoading: false,
      );

    } catch (e) {
      log('Error in getNotifications: $e');
      state = state.copyWith(
        error: 'Failed to load notifications: $e',
        isLoading: false,
      );
    }
  }

  List<NotificationItem> _convertJsonListToNotificationItems(List<dynamic> jsonList) {
    return jsonList.map((item) {
      try {
        if (item is Map<String, dynamic>) {
          return NotificationItem.fromJson(item);
        } else {
          log('Skipping invalid item type: ${item.runtimeType}');
          return _createDefaultNotification();
        }
      } catch (e) {
        log('Error converting item to NotificationItem: $e');
        return _createDefaultNotification();
      }
    }).where((notification) => notification.id != 0).toList(); // Filter out invalid ones
  }

  List<NotificationItem> _extractNotificationsFromMap(Map<String, dynamic> dataMap) {
    final List<dynamic>? notificationsList = dataMap['notifications'] ??
        dataMap['items'] ??
        dataMap['data'] ??
        dataMap['results'];

    if (notificationsList is List) {
      return _convertJsonListToNotificationItems(notificationsList);
    }

    // If no list found, try to create from the map itself
    try {
      final notification = NotificationItem.fromJson(dataMap);
      return [notification];
    } catch (e) {
      log('Could not extract notifications from map: $e');
      return [];
    }
  }

  NotificationItem _createDefaultNotification() {
    return NotificationItem(
      id: 0, // Use 0 to indicate invalid notification
      isRead: false,
      message: 'Invalid notification format',
      patientName: 'Unknown',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }



// Helper method to convert JSON data to NotificationItem objects
  List<NotificationItem> _convertJsonToNotificationItems(List<dynamic> jsonData) {
    return jsonData.map((item) {
      return NotificationItem(
        id: item['id'] as int? ?? 0,
        isRead: item['isRead'] as bool? ?? false,
        message: item['message'] as String? ?? 'No message',
        patientName: item['patientName'] as String? ?? 'Unknown Patient',
        patientId: item['patientId']?.toString(),
        adminId: item['adminId']?.toString(),
        createdAt: _parseDateTime(item['createdAt']),
        updatedAt: _parseDateTime(item['updatedAt']),
        isSuccess: item['isSuccess'] as bool?,
        istechnical: item['istechnical'] as bool?,
        notlinked: item['notlinked'] as bool?,
        demographic: item['demographic'] as bool?,
        isPatientUpdate: item['isPatientUpdate'] as bool?,
        isPatientDelete: item['isPatientDelete'] as bool?,
      );
    }).toList();
  }

// Helper method to parse DateTime safely
  DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    try {
      if (dateTime is String) {
        return DateTime.parse(dateTime);
      }
      return DateTime.now();
    } catch (e) {
      log('Error parsing date: $dateTime, error: $e');
      return DateTime.now();
    }
  }


  void markAsRead(int notificationId) {
    final updatedNotifications = state.notificationList.map((notification) {
      if (notification.id == notificationId) {
        return NotificationItem(
          id: notification.id,
          isRead: true,
          message: notification.message,
          patientName: notification.patientName,
          patientId: notification.patientId,
          adminId: notification.adminId,
          createdAt: notification.createdAt,
          updatedAt: notification.updatedAt,
          isSuccess: notification.isSuccess,
          istechnical: notification.istechnical,
          notlinked: notification.notlinked,
          demographic: notification.demographic,
          isPatientUpdate: notification.isPatientUpdate,
          isPatientDelete: notification.isPatientDelete,
        );
      }
      return notification;
    }).toList();

    state = state.copyWith(notificationList: updatedNotifications);
  }

  void deleteNotification(int notificationId) {
    final updatedNotifications = state.notificationList
        .where((notification) => notification.id != notificationId)
        .toList();

    state = state.copyWith(notificationList: updatedNotifications);
  }

  void clearAll() {
    state = state.copyWith(notificationList: []);
  }

  void loadSampleData() {
    // You can call loadNotificationsFromJson with your sample data here
    // For now, we'll simulate loading
    state = state.copyWith(isLoading: true);

    // Simulate API call delay
    Future.delayed(Duration(seconds: 1), () {
      // In your actual implementation, you would call:
      // loadNotificationsFromJson(yourJsonData);
      state = state.copyWith(isLoading: false);
    });
  }
}

