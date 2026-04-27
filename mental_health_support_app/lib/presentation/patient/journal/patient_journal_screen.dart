import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/assets/app_assets.dart';
import 'package:mental_health_support_app/core/models/diary_entry.dart';
import 'package:mental_health_support_app/core/services/patient_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_asset.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/presentation/components/atoms/shimmer_card.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class PatientJournalScreen extends ConsumerStatefulWidget {
  const PatientJournalScreen({super.key});

  @override
  ConsumerState<PatientJournalScreen> createState() =>
      _PatientJournalScreenState();
}

class _PatientJournalScreenState extends ConsumerState<PatientJournalScreen> {
  List<DiaryEntry> _entries = [];
  bool _loading = false;
  String? _error;

  // ── Daily prompts ──────────────────────────────────────────────────────────
  static const _prompts = [
    "How are you feeling about your progress today?",
    "What's one thing you're grateful for right now?",
    "Describe a moment today that brought you calm.",
    "What challenge did you face today, and how did you handle it?",
    "What would make tomorrow feel more manageable?",
    "Write about someone who has supported you recently.",
    "What emotions have you noticed most today?",
    "If you could tell your past self one thing, what would it be?",
    "What does rest look like for you today?",
    "Describe a small win from this week.",
  ];

  String get _todaysPrompt {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _prompts[dayOfYear % _prompts.length];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      final uid = userDoc?['uid'] as String? ?? '';
      _entries = await PatientService.getDiaryEntries(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(DiaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cloud,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          'Delete entry?',
          style: AppTypography.title.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'This entry will be permanently removed from your journal.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.label.copyWith(
                color: AppColors.lavenderDeep,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Confirm delete',
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Delete',
                style: AppTypography.label.copyWith(
                  color: AppColors.criticalDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PatientService.deleteDiaryEntry(entry.id);
      await _load();
    }
  }

  // ── Entry card ─────────────────────────────────────────────────────────────
  Widget _buildEntryCard(DiaryEntry entry) {
    DateTime? dt;
    try {
      dt = DateTime.parse(entry.createdDateKey);
    } catch (_) {}

    return Semantics(
      label:
          'Journal entry from ${dt != null ? AppDateUtils.formatShortDate(dt) : entry.createdDateKey}',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Container(
                color: AppColors.lavenderMist,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
                      size: 14,
                      color: AppColors.lavenderDeep,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      dt != null
                          ? AppDateUtils.formatShortDate(dt)
                          : entry.createdDateKey,
                      style: AppTypography.label.copyWith(
                        color: AppColors.lavenderDeep,
                      ),
                    ),
                    const Spacer(),

                    // Edit button
                    Semantics(
                      label: 'Edit entry',
                      button: true,
                      child: InkWell(
                        onTap: () => context.push(
                          '/patient/journal/editor?id=${entry.id}',
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: PhosphorIcon(
                            PhosphorIcons.pencil(PhosphorIconsStyle.regular),
                            size: 16,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Delete button
                    Semantics(
                      label: 'Delete entry',
                      button: true,
                      child: InkWell(
                        onTap: () => _confirmDelete(entry),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: PhosphorIcon(
                            PhosphorIcons.trash(PhosphorIconsStyle.regular),
                            size: 16,
                            color: AppColors.criticalDeep,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card content preview
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Text(
                  entry.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MindCareAsset(
              asset: AppAssets.journal,
              width: 180,
              height: 150,
              fallbackIcon: PhosphorIconsDuotone.notebook,
              fallbackColor: AppColors.lavenderDeep,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Your story starts here',
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the button below to write your first entry',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MindCarePillButton(
              label: 'Write first entry',
              onPressed: () => context.push('/patient/journal/editor'),
              color: AppColors.lavenderDeep,
              icon: PhosphorIcons.pencilLine(PhosphorIconsStyle.regular),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.warning(PhosphorIconsStyle.duotone),
              size: 48,
              color: AppColors.criticalDeep,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Could not load entries',
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'An unexpected error occurred.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MindCarePillButton(
              label: 'Retry',
              onPressed: _load,
              color: AppColors.lavenderDeep,
              variant: PillButtonVariant.outlined,
              icon: PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entryCount = _entries.length;

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  children: [
                    Text(
                      'My Journal',
                      style: AppTypography.headline3.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    if (!_loading && _error == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderMist,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.lavenderDeep,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Daily prompt banner ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.base,
                  right: AppSpacing.base,
                  bottom: AppSpacing.base,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lavender.withValues(alpha: 0.4),
                        AppColors.sky.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.lavender.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.lightbulb(PhosphorIconsStyle.duotone),
                        color: AppColors.lavenderDeep,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _todaysPrompt,
                          style: AppTypography.body.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── List content ───────────────────────────────────────────────
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ShimmerCard(
                        height: 120,
                        borderRadius: AppSpacing.radiusLg,
                      ),
                    ),
                    childCount: 3,
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(),
              )
            else if (_entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.base,
                  right: AppSpacing.base,
                  bottom: AppSpacing.huge + AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildEntryCard(_entries[i]),
                    childCount: _entries.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: MindCarePillButton(
          label: 'New Entry',
          icon: PhosphorIcons.plus(PhosphorIconsStyle.regular),
          onPressed: () async {
            await context.push('/patient/journal/editor');
            // Reload when returning from editor
            if (mounted) {
              _load();
            }
          },
          color: AppColors.lavenderDeep,
          semanticLabel: 'Write new journal entry',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
