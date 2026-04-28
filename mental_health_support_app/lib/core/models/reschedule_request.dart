
class RescheduleRequest {

  final String id;
  final String patientUid;
  final String doctorUid;
  final String appointmentId;
  final String requestedDate;
  final String reason;
  final String status; // pending , approved , rejected
  final String createdAt;

  const RescheduleRequest ( {

    required this.id,
    required this.patientUid,
    required this.doctorUid,
    required this.appointmentId,
    required this.requestedDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  
  } );

  factory RescheduleRequest.fromMap( String id , Map<String , dynamic> m ) => RescheduleRequest (

    id : id,
    patientUid : m[ 'patientUid' ] ?? '',
    doctorUid : m[ 'doctorUid' ] ?? '',
    appointmentId : m[ 'appointmentId' ] ?? '',
    requestedDate : m[ 'requestedDate' ] ?? '',
    reason : m[ 'reason' ] ?? '',
    status : m[ 'status' ] ?? 'pending',
    createdAt : m[ 'createdAt' ] ?? '',
  
  );

  Map<String , dynamic> toMap( ) => {

    'patientUid' : patientUid,
    'doctorUid' : doctorUid,
    'appointmentId' : appointmentId,
    'requestedDate' : requestedDate,
    'reason' : reason,
    'status' : status,
    'createdAt' : createdAt,
  
  };

}
