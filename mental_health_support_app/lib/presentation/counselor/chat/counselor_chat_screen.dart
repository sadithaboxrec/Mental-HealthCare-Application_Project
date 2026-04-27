import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/models/chat_message.dart';
import 'package:mental_health_support_app/core/models/chat_session.dart';
import 'package:mental_health_support_app/core/services/chat_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class CounselorChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const CounselorChatScreen({super.key, required this.sessionId});

  @override
  ConsumerState<CounselorChatScreen> createState() =>
      _CounselorChatScreenState();
}

class _CounselorChatScreenState extends ConsumerState<CounselorChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  StreamSubscription<ChatSession>? _sessionSub;
  ChatSession? _session;
  bool _sending = false;
  bool _ending = false;
  bool _accepting = false;
  String? _counselorUid;
  String? _counselorName;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final userDoc = ref.read(currentUserDocProvider).asData?.value;
    _counselorUid = userDoc?['uid'] as String? ?? '';
    _counselorName = userDoc?['name'] as String? ?? 'Counselor';
    _subscribeSession();
  }

  void _subscribeSession() {
    _sessionSub?.cancel();
    _sessionSub = ChatService.sessionStream(widget.sessionId).listen((session) {
      if (mounted) setState(() => _session = session);
    });
  }

  Future<void> _acceptSession() async {
    if (_counselorUid == null || _counselorUid!.isEmpty) return;
    setState(() => _accepting = true);
    HapticFeedback.mediumImpact();
    try {
      await ChatService.acceptSession(
        sessionId: widget.sessionId,
        counselorUid: _counselorUid!,
        counselorName: _counselorName!,
      );
    } catch (e) {
      if (mounted) _showSnack('Failed to accept session.');
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    if (_counselorUid == null || _counselorUid!.isEmpty) return;

    setState(() => _sending = true);
    HapticFeedback.lightImpact();
    _msgCtrl.clear();

    try {
      await ChatService.sendMessage(
        sessionId: widget.sessionId,
        senderUid: _counselorUid!,
        senderRole: 'counselor',
        text: text,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _msgCtrl.text = text; // restore on failure
        _showSnack('Failed to send message.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text('End Session', style: AppTypography.headline4),
        content: Text(
          'Are you sure you want to end this chat session? The patient will be notified.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.label.copyWith(color: AppColors.slate),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'End Session',
              style: AppTypography.label.copyWith(
                color: AppColors.criticalDeep,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _ending = true);
    HapticFeedback.heavyImpact();
    try {
      await ChatService.endSession(widget.sessionId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _ending = false);
        _showSnack('Failed to end session.');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTypography.bodySmall),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final isActive = session?.status == 'active';
    final isWaiting = session?.status == 'waiting';
    final isEnded = session?.status == 'ended';

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────
            _ChatHeader(
              session: session,
              isActive: isActive,
              ending: _ending,
              onBack: () => context.pop(),
              onEnd: isActive ? _endSession : null,
            ),

            // ── Body ───────────────────────────────────────────────
            Expanded(
              child: session == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.amberDeep,
                        strokeWidth: 2,
                      ),
                    )
                  : isEnded
                  ? _EndedBanner(patientName: session.patientName)
                  : isWaiting
                  ? _WaitingPrompt(
                      session: session,
                      accepting: _accepting,
                      onAccept: _acceptSession,
                    )
                  : _ChatBody(
                      sessionId: widget.sessionId,
                      counselorUid: _counselorUid ?? '',
                      scrollCtrl: _scrollCtrl,
                      onNewMessages: _scrollToBottom,
                    ),
            ),

            // ── Input bar (only when active) ───────────────────────
            if (isActive)
              _InputBar(
                controller: _msgCtrl,
                focusNode: _focusNode,
                sending: _sending,
                onSend: _sendMessage,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Chat header ─────────────────────────────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  final ChatSession? session;
  final bool isActive;
  final bool ending;
  final VoidCallback onBack;
  final VoidCallback? onEnd;

  const _ChatHeader({
    required this.session,
    required this.isActive,
    required this.ending,
    required this.onBack,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final name = session?.patientName ?? 'Chat Session';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Semantics(
            label: 'Go back',
            button: true,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: AppSpacing.tapTargetMin,
                height: AppSpacing.tapTargetMin,
                decoration: BoxDecoration(
                  color: AppColors.amberMist,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    size: AppSpacing.iconMd,
                    color: AppColors.amberDeep,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTypography.label.copyWith(color: AppColors.amberDeep),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isActive)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.stableDeep,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        'Active session',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.stableDeep,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // End session button
          if (onEnd != null)
            Semantics(
              label: 'End session',
              button: true,
              child: GestureDetector(
                onTap: ending ? null : onEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.criticalDeep.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: ending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.criticalDeep,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.phoneSlash(
                                PhosphorIconsStyle.duotone,
                              ),
                              size: 14,
                              color: AppColors.criticalDeep,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'End',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.criticalDeep,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Chat body (message list via StreamBuilder) ──────────────────────────────
class _ChatBody extends StatelessWidget {
  final String sessionId;
  final String counselorUid;
  final ScrollController scrollCtrl;
  final VoidCallback onNewMessages;

  const _ChatBody({
    required this.sessionId,
    required this.counselorUid,
    required this.scrollCtrl,
    required this.onNewMessages,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.messagesStream(sessionId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.amberDeep,
              strokeWidth: 2,
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Could not load messages',
              style: AppTypography.bodySmall,
            ),
          );
        }
        final messages = snap.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIcons.chatDots(PhosphorIconsStyle.duotone),
                  size: AppSpacing.iconHuge,
                  color: AppColors.amberDeep.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.base),
                Text('Session started', style: AppTypography.title),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Send a message to begin the conversation',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => onNewMessages());
        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.base,
          ),
          itemCount: messages.length,
          itemBuilder: (ctx, i) => _Bubble(
            message: messages[i],
            isMe: messages[i].senderUid == counselorUid,
          ),
        );
      },
    );
  }
}

// ── Message bubble ──────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${isMe ? 'You' : 'Patient'}: ${message.text}',
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            bottom: AppSpacing.sm,
            left: isMe ? 64 : 0,
            right: isMe ? 0 : 64,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [AppColors.amberDeep, AppColors.amber],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isMe ? null : AppColors.cloud,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSpacing.radiusLg),
              topRight: const Radius.circular(AppSpacing.radiusLg),
              bottomLeft: Radius.circular(isMe ? AppSpacing.radiusLg : 4),
              bottomRight: Radius.circular(isMe ? 4 : AppSpacing.radiusLg),
            ),
            border: isMe ? null : Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: (isMe ? AppColors.amberDeep : AppColors.amber)
                    .withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: AppTypography.body.copyWith(
              color: isMe ? AppColors.cloud : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input bar ───────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.base + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.amberMist,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration.collapsed(
                  hintText: 'Type a message…',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                style: AppTypography.body,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Send button
          Semantics(
            label: 'Send message',
            button: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: AppSpacing.tapTargetMin,
              height: AppSpacing.tapTargetMin,
              decoration: BoxDecoration(
                gradient: hasText && !sending
                    ? LinearGradient(
                        colors: [AppColors.amberDeep, AppColors.amber],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasText && !sending ? null : AppColors.fog,
                shape: BoxShape.circle,
                boxShadow: hasText && !sending
                    ? [
                        BoxShadow(
                          color: AppColors.amberDeep.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: GestureDetector(
                onTap: hasText && !sending ? onSend : null,
                child: Center(
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cloud,
                          ),
                        )
                      : PhosphorIcon(
                          PhosphorIcons.paperPlaneRight(
                            PhosphorIconsStyle.fill,
                          ),
                          size: AppSpacing.iconMd,
                          color: hasText ? AppColors.cloud : AppColors.slate,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Waiting prompt ───────────────────────────────────────────────────────────
class _WaitingPrompt extends StatelessWidget {
  final ChatSession session;
  final bool accepting;
  final VoidCallback onAccept;

  const _WaitingPrompt({
    required this.session,
    required this.accepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.amberMist,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.chatTeardrop(PhosphorIconsStyle.duotone),
                  size: AppSpacing.iconHuge,
                  color: AppColors.amberDeep,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              session.patientName,
              style: AppTypography.headline4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'is requesting support',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: accepting ? null : onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amberDeep,
                  foregroundColor: AppColors.cloud,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: accepting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cloud,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                            size: AppSpacing.iconMd,
                            color: AppColors.cloud,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Accept Session',
                            style: AppTypography.label.copyWith(
                              color: AppColors.cloud,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ended banner ─────────────────────────────────────────────────────────────
class _EndedBanner extends StatelessWidget {
  final String patientName;
  const _EndedBanner({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.mintMist,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                  size: AppSpacing.iconHuge,
                  color: AppColors.stableDeep,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Session Ended', style: AppTypography.headline4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your session with $patientName has ended.\nThank you for supporting them.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amberDeep,
                foregroundColor: AppColors.cloud,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              child: Text(
                'Back to Dashboard',
                style: AppTypography.label.copyWith(color: AppColors.cloud),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
