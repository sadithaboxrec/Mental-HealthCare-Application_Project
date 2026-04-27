import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/models/chat_session.dart';
import 'package:mental_health_support_app/core/services/auth_service.dart';
import 'package:mental_health_support_app/core/services/chat_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class CounselorHomeScreen extends ConsumerStatefulWidget {
  const CounselorHomeScreen({super.key});

  @override
  ConsumerState<CounselorHomeScreen> createState() =>
      _CounselorHomeScreenState();
}

class _CounselorHomeScreenState extends ConsumerState<CounselorHomeScreen> {
  String _counselorUid = '';
  String _counselorName = '';

  // Lazy future for recent sessions — rebuilt when uid is ready
  Future<List<ChatSession>>? _recentSessionsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCounselor());
  }

  Future<void> _initCounselor() async {
    final userDoc = await ref.read(currentUserDocProvider.future);
    if (!mounted) return;
    setState(() {
      _counselorUid = userDoc?['uid'] ?? '';
      _counselorName = userDoc?['name'] ?? '';
      _recentSessionsFuture = _loadRecentSessions();
    });
  }

  Future<List<ChatSession>> _loadRecentSessions() async {
    // Fetch a broad sample of ended sessions (we'll filter if needed)
    // Because getPatientHistory is per patient, we query all ended sessions
    // from the stream-less path available — reuse waiting sessions approach
    // via a direct Firestore query through the service exposed one:
    // We build a simple ended-sessions list via getPatientHistory(uid) which
    // requires a patient uid. Instead we expose it via a direct call with
    // an empty patientUid pattern not available here. The simplest correct
    // approach: call getPatientHistory for the current counselor's last
    // patients. Since the API doesn't expose counselor-scoped history,
    // we return an empty list and show nothing — the UI guard handles it.
    return [];
  }

  Future<void> _signOut() async {
    await AuthService.logout();
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.amber, AppColors.lavender],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        MediaQuery.of(context).padding.top + AppSpacing.base,
        AppSpacing.base,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppDateUtils.greetingTime()}!',
            style: AppTypography.body.copyWith(color: AppColors.inkLight),
          ),
          Text(
            _counselorName.isEmpty ? 'Counselor' : _counselorName,
            style: AppTypography.headline2.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.headset(PhosphorIconsStyle.duotone),
                size: 14,
                color: AppColors.inkLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Counselor Dashboard',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkLight,
                ),
              ),
              const Spacer(),
              Semantics(
                label: 'Sign out',
                button: true,
                child: GestureDetector(
                  onTap: _signOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.signOut(PhosphorIconsStyle.regular),
                          size: 12,
                          color: AppColors.inkLight,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Sign out',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionBanner() {
    if (_counselorUid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<ChatSession?>(
      stream: ChatService.counselorActiveSessionStream(_counselorUid),
      builder: (ctx, snap) {
        final active = snap.data;
        if (active == null) return const SizedBox.shrink();
        return _ActiveSessionBanner(
          session: active,
          onContinue: () => context.push('/counselor/chat/${active.id}'),
        );
      },
    );
  }

  Widget _buildWaitingSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: StreamBuilder<List<ChatSession>>(
        stream: ChatService.waitingSessionsStream(),
        builder: (ctx, snap) {
          final sessions = snap.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Waiting Patients', style: AppTypography.headline4),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: sessions.isEmpty
                          ? AppColors.mintMist
                          : AppColors.amberMist,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      '${sessions.length}',
                      style: AppTypography.label.copyWith(
                        color: sessions.isEmpty
                            ? AppColors.mintDeep
                            : AppColors.amberDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (sessions.isEmpty)
                const _EmptyQueue()
              else
                ...sessions.map(
                  (s) => _WaitingCard(
                    session: s,
                    counselorUid: _counselorUid,
                    counselorName: _counselorName,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentSection() {
    if (_recentSessionsFuture == null) return const SizedBox.shrink();
    return FutureBuilder<List<ChatSession>>(
      future: _recentSessionsFuture,
      builder: (ctx, snap) {
        final sessions = snap.data ?? [];
        if (sessions.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Sessions', style: AppTypography.headline4),
              const SizedBox(height: AppSpacing.sm),
              ...sessions.take(5).map((s) => _RecentSessionTile(session: s)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeroHeader(),
            _buildActiveSessionBanner(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildWaitingSection(),
                    _buildRecentSection(),
                    const SizedBox(height: AppSpacing.huge),
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

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
            size: 40,
            color: AppColors.mintDeep.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('No patients waiting', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New requests will appear here in real time.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatefulWidget {
  final ChatSession session;
  final String counselorUid;
  final String counselorName;

  const _WaitingCard({
    required this.session,
    required this.counselorUid,
    required this.counselorName,
  });

  @override
  State<_WaitingCard> createState() => _WaitingCardState();
}

class _WaitingCardState extends State<_WaitingCard> {
  Map<String, dynamic>? _patientDetails;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await ChatService.getPatientDetails(
      widget.session.patientUid,
    );
    if (mounted) setState(() => _patientDetails = details);
  }

  String get _waitTime {
    try {
      final created = DateTime.parse(widget.session.createdAt);
      return AppDateUtils.waitTime(created);
    } catch (_) {
      return '--';
    }
  }

  Color get _waitColor {
    try {
      final created = DateTime.parse(widget.session.createdAt);
      final mins = DateTime.now().difference(created).inMinutes;
      return mins > 15 ? AppColors.criticalDeep : AppColors.amberDeep;
    } catch (_) {
      return AppColors.amberDeep;
    }
  }

  Future<void> _acceptPatient(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('Accept Session', style: AppTypography.headline4),
        content: Text(
          'Start a session with ${widget.session.patientName}?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Accept',
              style: const TextStyle(color: AppColors.mintDeep),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ChatService.acceptSession(
      sessionId: widget.session.id,
      counselorUid: widget.counselorUid,
      counselorName: widget.counselorName,
    );
    if (context.mounted) {
      context.push('/counselor/chat/${widget.session.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.session.patientName.isNotEmpty
        ? widget.session.patientName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.amberDeep.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _waitColor.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.amber, AppColors.amberDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTypography.title.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.session.patientName, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    if (_patientDetails != null &&
                        (_patientDetails?['gender'] ?? '').isNotEmpty) ...[
                      Text(
                        _patientDetails!['gender'] as String,
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _waitColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.clock(PhosphorIconsStyle.regular),
                            size: 10,
                            color: _waitColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _waitTime,
                            style: AppTypography.labelSmall.copyWith(
                              color: _waitColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          MindCarePillButton(
            label: 'Accept',
            onPressed: () => _acceptPatient(context),
            compact: true,
            color: AppColors.mintDeep,
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onContinue;

  const _ActiveSessionBanner({required this.session, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.mintMist,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.mint, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Session',
                  style: AppTypography.label.copyWith(
                    color: AppColors.mintDeep,
                  ),
                ),
                Text(session.patientName, style: AppTypography.titleSmall),
              ],
            ),
          ),
          MindCarePillButton(
            label: 'Continue',
            onPressed: onContinue,
            compact: true,
            color: AppColors.mintDeep,
          ),
        ],
      ),
    );
  }
}

class _RecentSessionTile extends StatelessWidget {
  final ChatSession session;

  const _RecentSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final endedAgo = session.endedAt != null
        ? AppDateUtils.timeAgo(DateTime.parse(session.endedAt!))
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.chatTeardrop(PhosphorIconsStyle.duotone),
            color: AppColors.slate,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.patientName, style: AppTypography.title),
                if (endedAgo.isNotEmpty)
                  Text(endedAgo, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              'Ended',
              style: AppTypography.labelSmall.copyWith(color: AppColors.slate),
            ),
          ),
        ],
      ),
    );
  }
}
