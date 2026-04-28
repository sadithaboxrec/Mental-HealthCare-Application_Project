import 'medicine.dart';

class Prescription {

  final String id;
  final String patientUid;
  final String doctorUid;
  final String patientName;
  final String diagnosis;
  final String notes;
  final String suggestions;
  final String nextAppointmentDate;
  final bool isActive;
  final List<Medicine> medicines;
  final String createdAt;

  const Prescription ( {

    required this.id,
    required this.patientUid,
    required this.doctorUid,
    required this.patientName,
    required this.diagnosis,
    required this.notes,
    required this.suggestions,
    required this.nextAppointmentDate,
    required this.isActive,
    required this.medicines,
    required this.createdAt,
  
  } );

  factory Prescription.fromMap( String id , Map<String , dynamic> m ) 
  {
    final meds = ( m[ 'medicines' ] as List<dynamic>? ?? [ ] )
      .map( ( e ) => Medicine.fromMap( Map<String , dynamic>.from( e ) ) )
      .toList( );

    return Prescription (

      id : id,
      patientUid : m[ 'patientUid' ] ?? '',
      doctorUid : m[ 'doctorUid' ] ?? '',
      patientName : m[ 'patientName' ] ?? '',
      diagnosis : m[ 'diagnosis' ] ?? '',
      notes : m[ 'notes' ] ?? '',
      suggestions : m[ 'suggestions' ] ?? '',
      nextAppointmentDate : m[ 'nextAppointmentDate' ] ?? '',
      isActive : m[ 'isActive' ] ?? false,
      medicines : meds,
      createdAt : m[ 'createdAt' ] ?? '',
    
    );

  }

  Map<String , dynamic> toMap( ) => {

    'patientUid' : patientUid,
    'doctorUid' : doctorUid,
    'patientName' : patientName,
    'diagnosis' : diagnosis,
    'notes' : notes,
    'suggestions' : suggestions,
    'nextAppointmentDate' : nextAppointmentDate,
    'isActive' : isActive,
    'medicines' : medicines.map ( ( m ) => m.toMap( ) ).toList( ),
    'createdAt' : createdAt,
  
  };

}
