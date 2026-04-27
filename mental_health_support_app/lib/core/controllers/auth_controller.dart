
import '../services/auth_service.dart';
import '../state/auth_state.dart';
import '../models/app_user.dart';
import 'notification_controller.dart';
class AuthController {

  static Future<AuthResult> login ( String email , String password ) async {

    final result = await AuthService.login ( email , password );
    
    if ( result.isSuccess && result.user != null ) {

      AuthState.setUser ( result.user! );

      if ( result.user!.role == 'patient' || result.user!.role == 'guardian' ) {

        await NotificationController.saveToken ( result.user!.uid );
      
      }

    }

    return result;

  }

  static Future<void> logout ( ) async {

    await AuthService.logout ( );
    AuthState.clearUser ( );
  
  }

  static Future<AppUser?> restoreSession ( ) async {

    final user = await AuthService.getSessionUser ( );
    if ( user != null ) AuthState.setUser ( user );
    return user;
  
  }

  static AppUser? get currentUser => AuthState.currentUser;

}
