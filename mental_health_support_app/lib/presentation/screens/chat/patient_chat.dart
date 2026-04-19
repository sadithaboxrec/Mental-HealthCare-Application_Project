import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/controllers/chat_controller.dart';
// Updated import to production widgets
import 'chat_widgets.dart';

class PatientChat extends StatefulWidget {
  final AppUser user;
  const PatientChat({super.key, required this.user});

  @override
  State<PatientChat> createState() => _PatientChatState();
}

class _PatientChatState extends State<PatientChat> {
  ChatSession? _session;
  ChatSession? _liveSession;
  bool         _loading    = true;
  final _msgCtrl           = TextEditingController();
  final _scrollCtrl        = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final session = await ChatController.requestSupport(
        patientUid:  widget.user.uid,
        patientName: widget.user.name,
      );
      if (mounted) setState(() {
        _session = session;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Chat init error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final session = _liveSession ?? _session;
    if (session == null) return;

    if (!session.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 12,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
          backgroundColor: Colors.white,
          content: Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Waiting for counselor to join...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: Colors.black.withOpacity(0.78),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    _msgCtrl.clear();
    await ChatController.sendMessage(
      sessionId:  session.id,
      senderUid:  widget.user.uid,
      senderRole: 'patient',
      text:       text,
    );
    _scrollToBottom();
  }

  Future<void> _endChat() async {
    final session = _liveSession ?? _session;
    if (session == null) return;

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
          'End Chat?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Color(0xFF37474F),
          ),
        ),
        content: Text(
          'This will end the session. You can start a new one anytime.',
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
              )),
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
              )),
        ],
      ),
    );
    if (confirm != true) return;
    await ChatController.endSession(session.id);
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
        title: const Text(
          'Support Chat',
          style: TextStyle(
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
          if (_liveSession?.isActive == true || _session?.isActive == true)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: _endChat,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF212121),
                ),
                child: const Text(
                  'End Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.7),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                    width: 1.5,
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
              const SizedBox(height: 20),
              Text(
                'Connecting…',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.72),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      )
          : _session == null
          ? Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.black.withOpacity(0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not start session',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.78),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          : StreamBuilder<ChatSession>(
        stream: ChatController.sessionStream(_session!.id),
        builder: (ctx, sessionSnap) {
          final session = sessionSnap.data ?? _session!;

          _liveSession = session;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: _bgGradient),
            child: Column(children: [

              StatusBar(session: session),

              Expanded(
                child: session.isWaiting
                    ? WaitingView(patientName: widget.user.name)
                    : StreamBuilder<List<ChatMessage>>(
                  stream: ChatController
                      .messagesStream(session.id),
                  builder: (ctx, msgSnap) {
                    final msgs = msgSnap.data ?? [];
                    WidgetsBinding.instance
                        .addPostFrameCallback(
                            (_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                      itemCount: msgs.length,
                      itemBuilder: (ctx, i) => MessageBubble(
                        message: msgs[i],
                        isMe:    msgs[i].senderUid ==
                            widget.user.uid,
                      ),
                    );
                  },
                ),
              ),

              if (!session.isEnded)
                ChatInput(
                  controller: _msgCtrl,
                  enabled:    session.isActive,
                  hint: session.isWaiting
                      ? 'Waiting for counselor...'
                      : 'Type a message...',
                  onSend: _send,
                ),

              if (session.isEnded)
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
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: Colors.black.withOpacity(0.45),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'This session has ended',
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
            ]),
          );
        },
      ),
    );
  }
}