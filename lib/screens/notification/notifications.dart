
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../enums.dart';
import '../../models/notification_model.dart';
import '../../provider/notification_provider.dart';


class Notifications extends ConsumerStatefulWidget {
  const Notifications({super.key});

  @override
  ConsumerState createState() => _NotificationsState();
}

class _NotificationsState extends ConsumerState<Notifications> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notificationList;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                ref.read(notificationProvider.notifier).clearAll();
              },
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body: notificationState.isLoading
          ? _buildLoadingState()
          : notifications.isEmpty
          ? _buildEmptyState(ref)
          : _buildNotificationsList(notifications, ref),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) { // Fixed: Added WidgetRef parameter
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 50,
              color: Colors.blue.shade300,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(notificationProvider.notifier).loadSampleData();
            },
            icon: Icon(Icons.refresh_rounded),
            label: Text('Load Sample Notifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications, WidgetRef ref) { // Fixed: Added proper parameters
    return Column(
      children: [
        // Header with counts
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifications.length} total • ${ref.read(notificationProvider).unreadCount} unread',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Notifications List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, ref); // Fixed: Pass ref here
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, WidgetRef ref) { // Fixed: Added proper parameters
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade50,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Colors.red, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context, notification, ref); // Fixed: Pass context and ref
        }
        return false;
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 1,
          child: InkWell(
            onTap: () {
              if (!notification.isRead!) {
                ref.read(notificationProvider.notifier).markAsRead(notification.id);
              }
              _showNotificationDetails(context, notification); // Fixed: Pass context
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: notification.isRead! ? Colors.transparent : Colors.blue.shade100,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Notification Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: notification.isRead! ? FontWeight.w500 : FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (notification.patientName.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      'Patient: ${notification.patientName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!notification.isRead!)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, NotificationItem notification, WidgetRef ref) async { // Fixed: Added proper parameters
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      ref.read(notificationProvider.notifier).deleteNotification(notification.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
      return true;
    }
    return false;
  }

  void _showNotificationDetails(BuildContext context, NotificationItem notification) { // Fixed: Added context parameter
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.message,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              if (notification.patientName.isNotEmpty)
                Text('Patient: ${notification.patientName}'),
              if (notification.patientId != null)
                Text('Patient ID: ${notification.patientId}'),
              SizedBox(height: 8),
              Text(
                'Received: ${DateFormat('MMM dd, yyyy • HH:mm').format(notification.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.technical:
        return Colors.orange;
      case NotificationType.notLinked:
        return Colors.red;
      case NotificationType.invalidDemographic:
        return Colors.amber;
      case NotificationType.patientUpdate:
        return Colors.blue;
      case NotificationType.patientDelete:
        return Colors.red;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.technical:
        return Icons.error_outline_rounded;
      case NotificationType.notLinked:
        return Icons.link_off_rounded;
      case NotificationType.invalidDemographic:
        return Icons.person_off_rounded;
      case NotificationType.patientUpdate:
        return Icons.edit_note_rounded;
      case NotificationType.patientDelete:
        return Icons.delete_forever_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(time);
    }
  }
}