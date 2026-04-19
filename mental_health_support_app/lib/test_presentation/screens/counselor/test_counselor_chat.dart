import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/controllers/chat_controller.dart';
import '../chat/test_chat_widgets.dart';

class TestCounselorChat extends StatefulWidget {
  final AppUser     counselorUser;
  final ChatSession session;

  const TestCounselorChat({
    super.key,
    required this.counselorUser,
    required this.session,
  });

  @override
  State<TestCounselorChat> createState() => _TestCounselorChatState();
}

class _TestCounselorChatState extends State<TestCounselorChat> {
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
        title: const Text('End Session?'),
        content: const Text(
            'This will close the chat. The history will be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('End',
                style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.session.patientName),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _endChat,
            child: const Text('End Session',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<ChatSession>(
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
                      ? const Center(
                      child: Text('No messages yet. Say hello!',
                          style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(12),
                color:   Colors.grey.shade200,
                child: const Center(child: Text(
                  'Session ended',
                  style: TextStyle(color: Colors.grey),
                )),
              ),
          ]);
        },
      ),
    );
  }
}