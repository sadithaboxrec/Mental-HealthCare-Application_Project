import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/models/app_notification.dart';
import 'package:mental_health_support_app/core/services/auth_service.dart';
import 'package:mental_health_support_app/core/services/notification_inbox_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/presentation/components/atoms/shimmer_card.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _userDoc;
  Map<String, dynamic>? _patientDoc;
  String? _error;

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
      if (!mounted) return;
      final uid = userDoc?['uid'] as String? ?? '';

      Map<String, dynamic>? patientData;
      if (uid.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('patients')
            .doc(uid)
            .get();
        if (snap.exists) {
          patientData = snap.data();
        }
      }

      if (!mounted) return;
      setState(() {
        _userDoc = userDoc;
        _patientDoc = patientData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cloud,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('Sign Out', style: AppTypography.headline4),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.label.copyWith(
                color: AppColors.lavenderDeep,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
              style: AppTypography.label.copyWith(
                color: AppColors.criticalDeep,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      // Router redirect handles navigation
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.mist,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              children: const [
                ShimmerCard(height: 220),
                SizedBox(height: AppSpacing.base),
                ShimmerCard(height: 140),
                SizedBox(height: AppSpacing.sm),
                ShimmerCard(height: 140),
                SizedBox(height: AppSpacing.base),
                ShimmerCard(height: 200),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.mist,
        body: SafeArea(
          child: Center(
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
                  Text('Could not load profile', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.xl),
                  MindCarePillButton(
                    label: 'Retry',
                    onPressed: _load,
                    color: AppColors.lavenderDeep,
                    variant: PillButtonVariant.outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name = _userDoc?['name'] as String? ?? 'Patient';
    final email = _userDoc?['email'] as String? ?? '';
    final phone = _userDoc?['phone'] as String? ?? '';
    final uid = _userDoc?['uid'] as String? ?? '';

    final dob = _patientDoc?['dob'] as String? ?? '-';
    final gender = _patientDoc?['gender'] as String? ?? '-';
    final employment = _patientDoc?['employmentStatus'] as String? ?? '-';

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.lavenderDeep,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile hero
                _ProfileHero(
                  name: name,
                  email: email,
                  initials: _initials(name),
                ),

                const SizedBox(height: AppSpacing.base),

                // Personal info
                _InfoSection(
                  title: 'Personal',
                  items: [
                    _InfoItem(
                      icon: PhosphorIcons.cake(PhosphorIconsStyle.regular),
                      label: 'Date of Birth',
                      value: dob,
                    ),
                    _InfoItem(
                      icon: PhosphorIcons.genderIntersex(
                        PhosphorIconsStyle.regular,
                      ),
                      label: 'Gender',
                      value: gender,
                    ),
                    _InfoItem(
                      icon: PhosphorIcons.briefcase(PhosphorIconsStyle.regular),
                      label: 'Employment',
                      value: employment,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Account info
                _InfoSection(
                  title: 'Account',
                  items: [
                    _InfoItem(
                      icon: PhosphorIcons.envelope(PhosphorIconsStyle.regular),
                      label: 'Email',
                      value: email,
                    ),
                    _InfoItem(
                      icon: PhosphorIcons.phone(PhosphorIconsStyle.regular),
                      label: 'Phone',
                      value: phone.isNotEmpty ? phone : '-',
                    ),
                    _InfoItem(
                      icon: PhosphorIcons.shieldCheck(
                        PhosphorIconsStyle.regular,
                      ),
                      label: 'Role',
                      value: 'Patient',
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.base),

                // Notifications section
                if (uid.isNotEmpty) _NotificationsSection(uid: uid),

                const SizedBox(height: AppSpacing.xl),

                // Sign out
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                  ),
                  child: MindCarePillButton(
                    label: 'Sign Out',
                    variant: PillButtonVariant.destructive,
                    onPressed: _signOut,
                    width: double.infinity,
                    compact: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile Hero ──────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final String initials;

  const _ProfileHero({
    required this.name,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.lavender, AppColors.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lavenderDeep.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.cloud, width: 3),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTypography.headline3.copyWith(color: AppColors.cloud),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: AppTypography.headline3.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            email,
            style: AppTypography.bodySmall.copyWith(color: AppColors.inkLight),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.cloud.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              'Patient',
              style: AppTypography.label.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Section ──────────────────────────────────────────────────────────────

class _InfoItem {
  final PhosphorIconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTypography.label.copyWith(color: AppColors.slate),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lavender.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            item.icon,
                            size: AppSpacing.iconMd,
                            color: AppColors.slate,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            item.label,
                            style: AppTypography.body.copyWith(
                              color: AppColors.inkLight,
                            ),
                          ),
                          const Spacer(),
                          Text(item.value, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
                      const Divider(
                        height: 1,
                        color: AppColors.divider,
                        indent: AppSpacing.xl + AppSpacing.md,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications Section ─────────────────────────────────────────────────────

class _NotificationsSection extends StatelessWidget {
  final String uid;
  const _NotificationsSection({required this.uid});

  PhosphorIconData _iconForType(String type) {
    switch (type) {
      case 'medication':
        return PhosphorIcons.pill(PhosphorIconsStyle.duotone);
      case 'appointment':
        return PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.bell(PhosphorIconsStyle.duotone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              'Notifications',
              style: AppTypography.label.copyWith(color: AppColors.slate),
            ),
          ),
          StreamBuilder<List<AppNotification>>(
            stream: NotificationInboxService.notificationsStream(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const ShimmerCard(height: 160);
              }

              final notifications = (snap.data ?? []).take(10).toList();

              if (notifications.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.bellSlash(PhosphorIconsStyle.duotone),
                        size: 40,
                        color: AppColors.slate.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No notifications yet',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lavender.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: notifications.asMap().entries.map((e) {
                    final i = e.key;
                    final notif = e.value;
                    return Column(
                      children: [
                        Semantics(
                          label:
                              '${notif.title}. ${notif.isRead ? 'Read' : 'Unread'}. Tap to mark as read.',
                          button: true,
                          child: InkWell(
                            onTap: notif.isRead
                                ? null
                                : () => NotificationInboxService.markRead(
                                    notif.id,
                                  ),
                            borderRadius: i == 0
                                ? const BorderRadius.vertical(
                                    top: Radius.circular(AppSpacing.radiusLg),
                                  )
                                : (i == notifications.length - 1
                                      ? const BorderRadius.vertical(
                                          bottom: Radius.circular(
                                            AppSpacing.radiusLg,
                                          ),
                                        )
                                      : BorderRadius.zero),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.base,
                                vertical: AppSpacing.md,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: notif.isRead
                                          ? AppColors.fog
                                          : AppColors.lavenderMist,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: PhosphorIcon(
                                      _iconForType(notif.type),
                                      size: AppSpacing.iconMd,
                                      color: notif.isRead
                                          ? AppColors.slate
                                          : AppColors.lavenderDeep,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif.title,
                                          style: AppTypography.title.copyWith(
                                            color: notif.isRead
                                                ? AppColors.slate
                                                : AppColors.ink,
                                            fontWeight: notif.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        if (notif.body.isNotEmpty) ...[
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            notif.body,
                                            style: AppTypography.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(
                                        top: AppSpacing.xs,
                                      ),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.lavenderDeep,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (i < notifications.length - 1)
                          const Divider(
                            height: 1,
                            color: AppColors.divider,
                            indent:
                                AppSpacing.xl + AppSpacing.md + AppSpacing.md,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
