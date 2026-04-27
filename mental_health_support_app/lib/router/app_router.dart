import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/patient/patient_root.dart';
import '../presentation/patient/home/patient_home_screen.dart';
import '../presentation/patient/journal/patient_journal_screen.dart';
import '../presentation/patient/journal/diary_editor_screen.dart';
import '../presentation/patient/care/patient_care_screen.dart';
import '../presentation/patient/profile/patient_profile_screen.dart';
import '../presentation/patient/chat/patient_chat_screen.dart';
import '../presentation/doctor/doctor_root.dart';
import '../presentation/doctor/home/doctor_home_screen.dart';
import '../presentation/doctor/patients/doctor_patients_screen.dart';
import '../presentation/doctor/patients/patient_detail_screen.dart';
import '../presentation/doctor/schedule/doctor_schedule_screen.dart';
import '../presentation/doctor/reports/doctor_reports_screen.dart';
import '../presentation/guardian/home/guardian_home_screen.dart';
import '../presentation/counselor/home/counselor_home_screen.dart';
import '../presentation/counselor/chat/counselor_chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserDocProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final onLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !onLogin) return '/login';
      if (isLoggedIn && onLogin) {
        final role = currentUser.asData?.value?['role'] as String? ?? '';
        return _roleRoot(role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),

      // Patient shell
      ShellRoute(
        builder: (ctx, state, child) => PatientRoot(child: child),
        routes: [
          GoRoute(
            path: '/patient/home',
            builder: (ctx, s) => const PatientHomeScreen(),
          ),
          GoRoute(
            path: '/patient/journal',
            builder: (ctx, s) => const PatientJournalScreen(),
          ),
          GoRoute(
            path: '/patient/care',
            builder: (ctx, s) => const PatientCareScreen(),
          ),
          GoRoute(
            path: '/patient/profile',
            builder: (ctx, s) => const PatientProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/patient/chat',
        builder: (ctx, s) => const PatientChatScreen(),
      ),
      GoRoute(
        path: '/patient/journal/editor',
        builder: (ctx, s) {
          final entryId = s.uri.queryParameters['id'];
          return DiaryEditorScreen(entryId: entryId);
        },
      ),

      // Doctor shell
      ShellRoute(
        builder: (ctx, state, child) => DoctorRoot(child: child),
        routes: [
          GoRoute(
            path: '/doctor/dashboard',
            builder: (ctx, s) => const DoctorHomeScreen(),
          ),
          GoRoute(
            path: '/doctor/patients',
            builder: (ctx, s) => const DoctorPatientsScreen(),
          ),
          GoRoute(
            path: '/doctor/schedule',
            builder: (ctx, s) => const DoctorScheduleScreen(),
          ),
          GoRoute(
            path: '/doctor/reports',
            builder: (ctx, s) => const DoctorReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/doctor/patient/:uid',
        builder: (ctx, s) =>
            PatientDetailScreen(patientUid: s.pathParameters['uid']!),
      ),

      // Guardian (single screen)
      GoRoute(
        path: '/guardian',
        builder: (ctx, s) => const GuardianHomeScreen(),
      ),

      // Counselor
      GoRoute(
        path: '/counselor',
        builder: (ctx, s) => const CounselorHomeScreen(),
      ),
      GoRoute(
        path: '/counselor/chat/:sessionId',
        builder: (ctx, s) =>
            CounselorChatScreen(sessionId: s.pathParameters['sessionId']!),
      ),
    ],
  );
});

String _roleRoot(String role) {
  switch (role) {
    case 'doctor':
      return '/doctor/dashboard';
    case 'guardian':
      return '/guardian';
    case 'counselor':
      return '/counselor';
    default:
      return '/patient/home';
  }
}
