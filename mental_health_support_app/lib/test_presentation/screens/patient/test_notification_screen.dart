import 'package:flutter/material.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/controllers/notification_inbox_controller.dart';

class TestNotificationScreen extends StatelessWidget {
  final String uid;
  const TestNotificationScreen({super.key, required this.uid});

  String _timeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'medication':  return Colors.green;
      case 'appointment': return Colors.blue;
      default:            return Colors.orange;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication':  return Icons.medication;
      case 'appointment': return Icons.calendar_today;
      default:            return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => NotificationInboxController.markAllRead(uid),
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationInboxController.notificationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snap.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Dismissible(
                key: Key(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check, color: Colors.red),
                ),
                onDismissed: (_) =>
                    NotificationInboxController.markRead(n.id),
                child: GestureDetector(
                  onTap: () => NotificationInboxController.markRead(n.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? Colors.white
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: n.isRead
                            ? Colors.grey.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _typeColor(n.type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_typeIcon(n.type),
                              color: _typeColor(n.type), size: 20),
                        ),

                        const SizedBox(width: 12),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: TextStyle(
                                        fontWeight: n.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        fontSize: 14,
                                      )),
                                ),
                                if (!n.isRead)
                                  Container(
                                    width:  8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color:  Colors.green,
                                      shape:  BoxShape.circle,
                                    ),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Text(n.body,
                                  style: const TextStyle(
                                      fontSize:  13,
                                      color:     Colors.black87)),
                              const SizedBox(height: 6),
                              Text(_timeAgo(n.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color:    Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}