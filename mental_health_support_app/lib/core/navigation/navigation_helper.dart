import 'package:flutter/material.dart';
import '../models/app_user.dart';

import '../../test_presentation/screens/test_login_screen.dart';
import '../../test_presentation/screens/test_doctor_screen.dart';
// import '../../test_presentation/screens/test_patient_screen.dart';
//  import '../../test_presentation/screens/test_counselor_screen.dart';
//import '../../test_presentation/screens/counselor/test_counselor_screen.dart';
// import '../../test_presentation/screens/test_guardian_screen.dart';
// import '../../presentation/screens/login_screen.dart';
// import '../../test_presentation/screens/doctor/test_doctor_home.dart';
// import '../../test_presentation/screens/patient/test_patient_home.dart';
// import '../../test_presentation/screens/guardian/test_guardian_home.dart';
import '../../test_presentation/screens/doctor/test_doctor_root.dart';
import '../../test_presentation/screens/patient/test_patient_root.dart';

// presentation
import '../../presentation/screens/counselor/counselor_home.dart';
import '../../presentation/screens/guardian/guardian_home.dart';





// Decides where to go after login
// Maps roles  screens
class NavigationHelper {

  //  Navigate based on role
  static void goToRoleScreen(BuildContext context, AppUser user) {
    final screen = _screenForRole(user);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
          (_) => false,
    );
  }

  //  Go to login
  static void goToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TestLoginScreen()),
          (_) => false,
    );
  }

  ////  Role to screen mapping
  // static Widget _screenForRole(AppUser user) {
  //   switch (user.role) {
  //     case 'doctor':
  //       return TestDoctorScreen(user: user);
  //       // TestDoctorScreen → RealDoctorScreen
  //     case 'patient':
  //       return TestPatientScreen(user: user);
  //     case 'counselor':
  //       return TestCounselorScreen(user: user);
  //     case 'guardian':
  //       return TestGuardianScreen(user: user);
  //     default:
  //       return const TestLoginScreen();
  //   }

  static Widget _screenForRole(AppUser user) {
    switch (user.role) {
      case 'doctor':
        // return TestDoctorHome(user: user);
        return TestDoctorRoot(user: user);
      case 'patient':
        // return TestPatientHome(user: user);
        return TestPatientRoot(user: user);
      case 'guardian':
        // return TestGuardianHome(user: user);
        return GuardianHome(user: user);
      case 'counselor':
      //  return TestCounselorScreen(user: user);
      return CounselorHome(user: user);
      default:
        return const TestLoginScreen();
    }


  }
}
