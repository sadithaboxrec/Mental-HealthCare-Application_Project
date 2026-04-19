import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/controllers/chat_controller.dart';
// Updated import to production widgets file
import '../chat/chat_widgets.dart';

class CounselorChat extends StatefulWidget {
  final AppUser     counselorUser;
  final ChatSession session;

  const CounselorChat({
    super.key,
    required this.counselorUser,
    required this.session,
  });

  @override
  State<CounselorChat> createState() => _CounselorChatState();
}

class _CounselorChatState extends State<CounselorChat> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ChatController.sendMessage(
      sessionId:  widget.session.id,
      senderUid:  widget.counselorUser.uid,
      senderRole: 'counselor',
      text:       text,
    );
    _scrollToBottom();
  }

  Future<void> _endChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        backgroundColor: Colors.white.withOpacity(0.94),
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.12),
        title: const Text(
          'End Session?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Color(0xFF37474F),
          ),
        ),
        content: Text(
          'This will close the chat. The history will be saved.',
          style: TextStyle(
            color: Colors.black.withOpacity(0.62),
            height: 1.45,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              elevation: 2,
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'End',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ChatController.endSession(widget.session.id);
    if (mounted) Navigator.pop(context);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  static const _bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAFAFA),
      Color(0xFFF5F5F5),
      Color(0xFFEEEEEE),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.session.patientName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Color(0xFF212121),
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
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
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF212121),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: _endChat,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF212121),
              ),
              child: const Text(
                'End Session',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: StreamBuilder<ChatSession>(
          stream: ChatController.sessionStream(widget.session.id),
          builder: (ctx, sessionSnap) {
            final session = sessionSnap.data ?? widget.session;

            return Column(children: [

              StatusBar(session: session),

              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: ChatController.messagesStream(session.id),
                  builder: (ctx, msgSnap) {
                    final msgs = msgSnap.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollToBottom());
                    return msgs.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Colors.black.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet. Say hello!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.55),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                      itemCount: msgs.length,
                      itemBuilder: (ctx, i) => MessageBubble(
                        message: msgs[i],
                        isMe:    msgs[i].senderUid ==
                            widget.counselorUser.uid,
                      ),
                    );
                  },
                ),
              ),

              if (!session.isEnded)
                ChatInput(
                  controller: _msgCtrl,
                  enabled:    session.isActive,
                  hint:       'Type a message...',
                  onSend:     _send,
                )
              else
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        border: Border(
                          top: BorderSide(
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_clock_rounded,
                              size: 18,
                              color: Colors.black.withOpacity(0.45),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Session ended',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.62),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}