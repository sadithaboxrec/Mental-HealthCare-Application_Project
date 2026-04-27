import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/controllers/doctor_controller.dart';
import 'package:mental_health_support_app/core/utils/severity_utils.dart';
import 'package:mental_health_support_app/presentation/components/atoms/shimmer_card.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() =>
      _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  List<Map<String, dynamic>> _patients = [];
  Map<String, Map<String, dynamic>> _xaiData = {};
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedSeverity = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userDoc = ref.read(currentUserDocProvider).asData?.value;
      final uid = userDoc?['uid'] as String? ?? '';
      if (uid.isEmpty) throw Exception('Not authenticated');

      final patients = await DoctorController.getAllPatients(uid);

      final Map<String, Map<String, dynamic>> xai = {};
      await Future.wait(
        patients.map((p) async {
          final pUid = p['uid'] as String? ?? '';
          if (pUid.isNotEmpty) {
            final snap = await DoctorController.getXaiAnalysisSnapshot(pUid);
            if (snap != null) xai[pUid] = snap;
          }
        }),
      );

      if (mounted) {
        setState(() {
          _patients = patients;
          _xaiData = xai;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  String _severityFromXai(Map<String, dynamic>? snap) {
    if (snap == null) return 'stable';
    final raw =
        (snap['severity'] as String? ??
                snap['riskLevel'] as String? ??
                'stable')
            .toLowerCase();
    if (raw.contains('critical')) return 'critical';
    if (raw.contains('warning') || raw.contains('high')) return 'warning';
    if (raw.contains('watch') || raw.contains('moderate')) return 'watch';
    return 'stable';
  }

  List<Map<String, dynamic>> get _filteredPatients {
    final filtered = _patients.where((p) {
      final name = (p['name'] as String? ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty &&
          !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedSeverity != 'All') {
        final xai = _xaiData[p['uid'] as String? ?? ''];
        final sev = _severityFromXai(xai);
        if (sev.toLowerCase() != _selectedSeverity.toLowerCase()) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final sevA = _severityFromXai(_xaiData[a['uid'] as String? ?? '']);
      final sevB = _severityFromXai(_xaiData[b['uid'] as String? ?? '']);
      return SeverityUtils.rank(sevB).compareTo(SeverityUtils.rank(sevA));
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Text('My Patients', style: AppTypography.headline3),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    PhosphorIcon(
                      PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
                      size: 18,
                      color: AppColors.slate,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration.collapsed(
                          hintText: 'Search patients...',
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                        style: AppTypography.body,
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: PhosphorIcon(
                            PhosphorIcons.x(PhosphorIconsStyle.regular),
                            size: 16,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Severity filter pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Row(
                children: ['All', 'Critical', 'Warning', 'Watch', 'Stable'].map(
                  (s) {
                    final isSelected = _selectedSeverity == s;
                    final bgColor = isSelected
                        ? (s == 'All'
                              ? AppColors.skyDeep
                              : AppColors.severityDeepColor(s.toLowerCase()))
                        : AppColors.fog;
                    return Semantics(
                      label: 'Filter by $s',
                      button: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSeverity = s),
                        child: Container(
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                          child: Text(
                            s,
                            style: AppTypography.label.copyWith(
                              color: isSelected
                                  ? AppColors.cloud
                                  : AppColors.slate,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _error != null
                  ? _buildError()
                  : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      children: const [
        ShimmerCard(height: 80),
        SizedBox(height: AppSpacing.sm),
        ShimmerCard(height: 80),
        SizedBox(height: AppSpacing.sm),
        ShimmerCard(height: 80),
        SizedBox(height: AppSpacing.sm),
        ShimmerCard(height: 80),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIcons.wifiSlash(PhosphorIconsStyle.regular),
              size: AppSpacing.iconHuge,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Failed to load patients', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Retry loading patients',
              button: true,
              child: ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyDeep,
                  foregroundColor: AppColors.cloud,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: AppTypography.label.copyWith(color: AppColors.cloud),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final patients = _filteredPatients;
    if (patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIcons.users(PhosphorIconsStyle.regular),
              size: AppSpacing.iconHuge,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              _searchQuery.isNotEmpty || _selectedSeverity != 'All'
                  ? 'No patients match your filter'
                  : 'No patients yet',
              style: AppTypography.title,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchQuery.isNotEmpty || _selectedSeverity != 'All'
                  ? 'Try changing the search or filter'
                  : 'Patients assigned to you will appear here',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.skyDeep,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
        itemCount: patients.length,
        itemBuilder: (ctx, i) => _buildPatientCard(patients[i]),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final uid = patient['uid'] as String? ?? '';
    final name = patient['name'] as String? ?? 'Unknown';
    final xai = _xaiData[uid];
    final severity = _severityFromXai(xai);
    final score =
        xai?['score'] as int? ??
        (xai?['score'] is double ? (xai!['score'] as double).round() : 0);
    final color = AppColors.severityColor(severity);
    final deep = AppColors.severityDeepColor(severity);

    return Semantics(
      label: 'Patient: $name, status: $severity',
      button: true,
      child: GestureDetector(
        onTap: () => context.push('/doctor/patient/$uid'),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Severity colored left bar
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: deep,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: AppTypography.title.copyWith(color: deep),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
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
                            const SizedBox(height: AppSpacing.xs),
                            if (xai != null)
                              Row(
                                children: [
                                  _SeverityChip(severity: severity),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Score: $score',
                                    style: AppTypography.labelSmall,
                                  ),
                                ],
                              )
                            else
                              Text(
                                'No analysis yet',
                                style: AppTypography.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
                        size: 16,
                        color: AppColors.slate,
                      ),
                    ],
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

class _SeverityChip extends StatelessWidget {
  final String severity;
  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severityColor(severity);
    final deep = AppColors.severityDeepColor(severity);
    final label = SeverityUtils.label(severity);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: deep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
