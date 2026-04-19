import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/models/chat_message.dart';

// ── Status bar ────────────────────────────────────────────
class StatusBar extends StatelessWidget {
  final ChatSession session;
  const StatusBar({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color accent;

    switch (session.status) {
      case 'waiting':
        label = 'Waiting for counselor...';
        icon = Icons.schedule_rounded;
        accent = const Color(0xFFE65100);
        break;
      case 'active':
        label = 'Connected with ${session.counselorName ?? "Counselor"}';
        icon = Icons.link_rounded;
        accent = const Color(0xFF1A1A1A);
        break;
      default:
        label = 'Session ended';
        icon = Icons.event_busy_rounded;
        accent = const Color(0xFF424242);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: session.status == 'waiting'
                        ? const Color(0xFFBF360C)
                        : const Color(0xFF212121),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.35,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Waiting view ──────────────────────────────────────────
class WaitingView extends StatelessWidget {
  final String patientName;
  const WaitingView({super.key, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) {
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - v)),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.black.withOpacity(0.35),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Looking for a counselor...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A counselor will join you shortly.\n'
                    'Please stay on this screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.06),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.favorite_outline_rounded,
                          size: 22,
                          color: Colors.black.withOpacity(0.45),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hi $patientName, you are not alone.\n'
                                'We are connecting you with support.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.78),
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const MessageBubble(
      {super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Basic safety check for timestamp length
    final time = message.timestamp.length >= 16
        ? message.timestamp.substring(11, 16)
        : '';

    final maxW = MediaQuery.of(context).size.width * 0.78;

    const r = 22.0;
    const tail = 7.0;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: maxW),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(r),
            topRight: const Radius.circular(r),
            bottomLeft: Radius.circular(isMe ? r : tail),
            bottomRight: Radius.circular(isMe ? tail : r),
          ),
          border: Border.all(
            color: isMe
                ? Colors.black.withOpacity(0.12)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isMe ? 0.14 : 0.07),
              blurRadius: isMe ? 14 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message.senderRole == 'counselor'
                      ? 'Counselor'
                      : 'You',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.2,
                    color: Colors.black.withOpacity(0.45),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF212121),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.15,
                color: isMe
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat input ────────────────────────────────────────────
class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
  });

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            border: Border(
              top: BorderSide(
                color: Colors.black.withOpacity(0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.38),
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: enabled ? (_) => onSend() : null,
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled ? onSend : null,
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: enabled
                            ? const Color(0xFF1976D2)
                            : Colors.black.withOpacity(0.12),
                        boxShadow: enabled
                            ? [
                          BoxShadow(
                            color: const Color(0xFF1976D2)
                                .withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : null,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.85),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: enabled ? Colors.white : Colors.black26,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}