
class AppUser {

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String createdAt;

  const AppUser ( {

    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
  
  } );

  factory AppUser.fromMap( Map<String , dynamic> map ) {

    return AppUser(
      uid : map[ 'uid' ] ?? '',
      name : map[ 'name' ] ?? '',
      email : map[ 'email' ] ?? '',
      phone : map[ 'phone' ] ?? '',
      role : map[ 'role' ] ?? '',
      createdAt : map[ 'createdAt' ] ?? '',
    
    );
  
  }

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';
  bool get isCounselor => role == 'counselor';
  bool get isGuardian => role == 'guardian';

}
