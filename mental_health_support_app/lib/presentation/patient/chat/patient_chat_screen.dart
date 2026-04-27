import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/models/chat_message.dart';
import 'package:mental_health_support_app/core/models/chat_session.dart';
import 'package:mental_health_support_app/core/services/chat_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class PatientChatScreen extends ConsumerStatefulWidget {
  const PatientChatScreen({super.key});

  @override
  ConsumerState<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends ConsumerState<PatientChatScreen> {
  bool _loading = true;
  ChatSession? _session;
  String? _sessionId;
  String? _error;

  String _uid = '';
  String _userName = '';

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  StreamSubscription<ChatSession>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    setState(() => _loading = true);
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      _uid = userDoc?['uid'] as String? ?? '';
      _userName = userDoc?['name'] as String? ?? '';

      final snap = await FirebaseFirestore.instance
          .collection('chat_sessions')
          .where('patientUid', isEqualTo: _uid)
          .where('status', whereIn: ['waiting', 'active'])
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final session = ChatSession.fromMap(
          snap.docs.first.id,
          snap.docs.first.data(),
        );
        if (!mounted) return;
        setState(() {
          _session = session;
          _sessionId = session.id;
        });
        _sessionSub = ChatService.sessionStream(session.id).listen((s) {
          if (mounted) setState(() => _session = s);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestSupport() async {
    setState(() => _loading = true);
    try {
      final session = await ChatService.requestSupport(
        patientUid: _uid,
        patientName: _userName,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _sessionId = session.id;
      });
      _sessionSub?.cancel();
      _sessionSub = ChatService.sessionStream(session.id).listen((s) {
        if (mounted) setState(() => _session = s);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelSession() async {
    if (_sessionId == null) return;
    try {
      await ChatService.endSession(_sessionId!);
    } catch (_) {}
    _sessionSub?.cancel();
    _sessionSub = null;
    if (mounted) {
      setState(() {
        _session = null;
        _sessionId = null;
      });
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sessionId == null) return;
    _msgCtrl.clear();
    setState(() {});
    await ChatService.sendMessage(
      sessionId: _sessionId!,
      senderUid: _uid,
      senderRole: 'patient',
      text: text,
    );
  }

  void _startNew() {
    _sessionSub?.cancel();
    _sessionSub = null;
    setState(() {
      _session = null;
      _sessionId = null;
    });
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return ts;
    }
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.senderRole == 'patient';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          bottom: AppSpacing.sm,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [
                    AppColors.lavender,
                    AppColors.lavenderDeep.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : AppColors.cloud,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: isMe
                ? const Radius.circular(AppSpacing.radiusMd)
                : const Radius.circular(AppSpacing.xs),
            bottomRight: isMe
                ? const Radius.circular(AppSpacing.xs)
                : const Radius.circular(AppSpacing.radiusMd),
          ),
          border: isMe ? null : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: AppTypography.body.copyWith(
                color: isMe ? AppColors.cloud : AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs2),
            Text(
              _formatTimestamp(msg.timestamp),
              style: AppTypography.caption.copyWith(
                color: isMe
                    ? AppColors.cloud.withValues(alpha: 0.7)
                    : AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotStarted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.chatTeardrop(PhosphorIconsStyle.duotone),
              size: 80,
              color: AppColors.slate.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Talk to a Counselor', style: AppTypography.headline4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Connect with a trained counselor for support',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MindCarePillButton(
              label: 'Request Support',
              icon: PhosphorIcons.handHeart(PhosphorIconsStyle.regular),
              onPressed: _requestSupport,
              color: AppColors.lavenderDeep,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingDot(color: AppColors.amber),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Connecting you with a counselor...',
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This usually takes just a moment',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MindCarePillButton(
              label: 'Cancel',
              variant: PillButtonVariant.ghost,
              color: AppColors.slate,
              onPressed: _cancelSession,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnded() {
    return Column(
      children: [
        Container(
          color: AppColors.amberMist,
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.info(PhosphorIconsStyle.duotone),
                size: AppSpacing.iconMd,
                color: AppColors.amberDeep,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'This session has ended',
                  style: AppTypography.title.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.chatTeardropSlash(PhosphorIconsStyle.duotone),
                    size: 64,
                    color: AppColors.slate,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text('Session ended', style: AppTypography.headline4),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'How are you feeling after the session?',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MindCarePillButton(
                    label: 'Start New Session',
                    onPressed: _startNew,
                    color: AppColors.lavenderDeep,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChat() {
    final session = _session!;
    return Column(
      children: [
        // Header / AppBar replacement
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Semantics(
                label: 'Go back',
                button: true,
                child: IconButton(
                  icon: PhosphorIcon(
                    PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
                    color: AppColors.ink,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.counselorName ?? 'Counselor',
                      style: AppTypography.title.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintMist,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        'Active',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mintDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // Messages list
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: ChatService.messagesStream(_sessionId!),
            builder: (ctx, snap) {
              final messages = snap.data ?? [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollCtrl.hasClients &&
                    _scrollCtrl.position.hasContentDimensions) {
                  _scrollCtrl.animateTo(
                    _scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.chatDots(PhosphorIconsStyle.duotone),
                        size: 48,
                        color: AppColors.slate.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Say hello to start the conversation',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _buildBubble(messages[i]),
              );
            },
          ),
        ),

        // Input area
        Container(
          margin: EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.sm,
            AppSpacing.base,
            AppSpacing.base + MediaQuery.of(context).padding.bottom,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.lavender.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Type a message...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                  style: AppTypography.body.copyWith(color: AppColors.ink),
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                label: 'Send message',
                button: true,
                child: GestureDetector(
                  onTap: _msgCtrl.text.trim().isEmpty ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _msgCtrl.text.trim().isEmpty
                          ? AppColors.fog
                          : AppColors.lavenderDeep,
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                      size: 18,
                      color: _msgCtrl.text.trim().isEmpty
                          ? AppColors.slate
                          : AppColors.cloud,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Builder(
          builder: (ctx) {
            if (_loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.lavenderDeep),
              );
            }

            if (_error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.wifiSlash(PhosphorIconsStyle.duotone),
                        size: AppSpacing.iconHuge,
                        color: AppColors.slate,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text('Something went wrong', style: AppTypography.title),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      MindCarePillButton(
                        label: 'Retry',
                        onPressed: _initSession,
                        color: AppColors.lavenderDeep,
                        variant: PillButtonVariant.outlined,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_session == null) return _buildNotStarted();
            if (_session!.isWaiting) return _buildWaiting();
            if (_session!.isEnded) return _buildEnded();
            return _buildActiveChat();
          },
        ),
      ),
    );
  }
}

// ── Pulsing Dot ───────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (ctx, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.25),
          border: Border.all(color: widget.color, width: 2),
        ),
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
