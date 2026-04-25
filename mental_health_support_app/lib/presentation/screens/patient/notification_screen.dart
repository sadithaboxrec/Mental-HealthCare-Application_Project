import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/controllers/notification_inbox_controller.dart';

class NotificationScreen extends StatelessWidget {
  final String uid;
  const NotificationScreen({super.key, required this.uid});

  String _timeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'medication': return Colors.blueAccent;
      case 'appointment': return Colors.indigoAccent;
      default: return Colors.lightBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication': return Icons.medical_services_outlined;
      case 'appointment': return Icons.event_note_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFC), // Modern off-white/slate
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () => NotificationInboxController.markAllRead(uid),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationInboxController.notificationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final notifications = snap.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationCard(
                notification: n,
                time: _timeAgo(n.createdAt),
                icon: _typeIcon(n.type),
                color: _typeColor(n.type),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined,
                size: 64, color: Colors.blue.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No new notifications at the moment.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String time;
  final IconData icon;
  final Color color;

  const _NotificationCard({
    required this.notification,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => NotificationInboxController.markRead(notification.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 25),
          decoration: BoxDecoration(
            color: Colors.blueAccent.shade700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.done_all, color: Colors.white, size: 28),
        ),
        child: GestureDetector(
          onTap: () => NotificationInboxController.markRead(notification.id),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.white.withOpacity(0.7)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: notification.isRead
                        ? Colors.white.withOpacity(0.2)
                        : Colors.blueAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Glass Icon Container
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    fontSize: 15,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: notification.isRead
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4),
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.blueAccent.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}