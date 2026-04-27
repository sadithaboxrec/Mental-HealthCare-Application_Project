import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/services/patient_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';
import 'package:mental_health_support_app/core/models/app_user.dart';
import 'package:mental_health_support_app/core/services/phenotyping_service.dart';
import 'package:mental_health_support_app/core/utils/typing_cadence_tracker.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mood_orb.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const DiaryEditorScreen({super.key, this.entryId});

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  late TextEditingController _contentCtrl;
  String? _savedEntryId;
  String _saveStatus = '';
  bool _saving = false;
  bool _hasChanges = false;
  Timer? _autoSaveTimer;
  int _selectedMood = 0; // 0 = none selected, 1-5 = selected
  bool _loadingEntry = false;
  final TypingCadenceTracker _cadenceTracker = TypingCadenceTracker();

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController();
    _savedEntryId = widget.entryId;
    if (widget.entryId != null) _loadEntry();
  }

  Future<void> _loadEntry() async {
    setState(() => _loadingEntry = true);
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      final uid = (userDoc?['uid'] as String?) ?? '';
      final entries = await PatientService.getDiaryEntries(uid);
      final entry = entries.firstWhere(
        (e) => e.id == widget.entryId,
        orElse: () => throw Exception('Entry not found'),
      );
      _contentCtrl.text = entry.content;
      _hasChanges = false;
    } catch (_) {
      // If load fails, just show an empty editor
    } finally {
      if (mounted) setState(() => _loadingEntry = false);
    }
  }

  void _onChanged(String val) {
    _cadenceTracker.onTextChanged(val);
    setState(() {
      _hasChanges = true;
      _saveStatus = 'Unsaved';
    });
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), _autoSave);
  }

  Future<void> _autoSave() async {
    final content = _contentCtrl.text.trim();
    if (!_hasChanges || content.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _saveStatus = 'Saving...';
    });
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      final uid = (userDoc?['uid'] as String?) ?? '';
      final entryId = _savedEntryId;
      if (entryId == null) {
        _savedEntryId = await PatientService.createDiaryEntry(uid, content);
      } else {
        await PatientService.updateDiaryEntry(entryId, content);
      }
      _hasChanges = false;
      if (mounted) {
        setState(() {
          _saving = false;
          _saveStatus = 'Saved';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveStatus = 'Save failed';
        });
      }
    }
  }

  Future<void> _saveIfChanged() async {
    _autoSaveTimer?.cancel();
    await _autoSave();
  }

  Future<void> _syncCadenceMetrics() async {
    final metrics = _cadenceTracker.generateMetrics();
    if (metrics != null) {
      try {
        final userDoc = await ref.read(currentUserDocProvider.future);
        if (userDoc != null) {
          final user = AppUser.fromMap(userDoc);
          await PhenotypingService.recordTypingCadence(user, metrics);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _contentCtrl.text.length;
    final now = DateTime.now();
    final dateLabel = AppDateUtils.formatDate(now);

    return Scaffold(
      backgroundColor: AppColors.cloud,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.cloud,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          label: 'Go back',
          button: true,
          child: IconButton(
            icon: PhosphorIcon(
              PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
              color: AppColors.ink,
              size: AppSpacing.iconLg,
            ),
            onPressed: () async {
              await _saveIfChanged();
              await _syncCadenceMetrics();
              if (context.mounted) context.pop();
            },
            tooltip: 'Go back',
            splashRadius: AppSpacing.tapTargetMin / 2,
          ),
        ),
        title: Text(
          widget.entryId == null ? 'New Entry' : 'Edit Entry',
          style: AppTypography.title.copyWith(color: AppColors.ink),
        ),
        actions: [
          Semantics(
            label: 'Save journal entry',
            button: true,
            child: IconButton(
              tooltip: 'Save',
              onPressed:
                  (_saving || !_hasChanges || _contentCtrl.text.trim().isEmpty)
                  ? null
                  : _saveIfChanged,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : PhosphorIcon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      color: _hasChanges
                          ? AppColors.lavenderDeep
                          : AppColors.slate,
                      size: AppSpacing.iconLg,
                    ),
              splashRadius: AppSpacing.tapTargetMin / 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _saveStatus,
                  key: ValueKey(_saveStatus),
                  style: AppTypography.caption.copyWith(
                    color: _saveStatus == 'Saved'
                        ? AppColors.stableDeep
                        : _saveStatus == 'Save failed'
                        ? AppColors.criticalDeep
                        : AppColors.slate,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loadingEntry
          ? const Center(child: CircularProgressIndicator.adaptive())
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async {
                FocusScope.of(context).unfocus();
                await _saveIfChanged();
              },
              child: Stack(
                children: [
                // ── Ruled-line background ──────────────────────────────────
                Positioned.fill(child: CustomPaint(painter: _RuledPainter())),

                // ── Scrollable content ─────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.base,
                    right: AppSpacing.base,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.huge + AppSpacing.xl,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date + mood row
                      Row(
                        children: [
                          // Date pill
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.calendarBlank(
                                    PhosphorIconsStyle.regular,
                                  ),
                                  size: 13,
                                  color: AppColors.lavenderDeep,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  dateLabel,
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.lavenderDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Mood orbs
                          Semantics(
                            label: 'Select your mood',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                final level = i + 1;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: i == 0 ? 0 : AppSpacing.xs,
                                  ),
                                  child: MoodOrb(
                                    level: level,
                                    size: 32,
                                    selected: _selectedMood == level,
                                    showLabel: false,
                                    onTap: () {
                                      setState(() {
                                        _selectedMood = _selectedMood == level
                                            ? 0
                                            : level;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // Text input — no decoration, paper-like
                      Semantics(
                        label: 'Journal entry text area',
                        textField: true,
                        multiline: true,
                        child: TextField(
                          controller: _contentCtrl,
                          autofocus: widget.entryId == null,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          onChanged: _onChanged,
                          style: AppTypography.body.copyWith(
                            color: AppColors.ink,
                            height: 1.8,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Write your thoughts...',
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.slate.withValues(alpha: 0.6),
                              height: 1.8,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Char count overlay ─────────────────────────────────────
                Positioned(
                  bottom: AppSpacing.base,
                  right: AppSpacing.base,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fog.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      '$charCount chars',
                      style: AppTypography.caption,
                    ),
                  ),
                ),
                ],
              ),
            ),
    );
  }
}

// ── Ruled lines painter ────────────────────────────────────────────────────────

class _RuledPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;
    const lineSpacing = 28.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
