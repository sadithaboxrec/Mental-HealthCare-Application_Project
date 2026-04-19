class ChatSession {


  final String  id;
  final String  patientUid;
  final String  patientName;
  final String? counselorUid;
  final String? counselorName;
  final String  status;   // status of the seession, in below bolean
  final String  createdAt;
  final String? startedAt;
  final String? endedAt;

  const ChatSession({
    required this.id,
    required this.patientUid,
    required this.patientName,
    this.counselorUid,
    this.counselorName,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  factory ChatSession.fromMap(String id, Map<String, dynamic> m) =>
      ChatSession(
        id:           id,
        patientUid:   m['patientUid']   ?? '',
        patientName:  m['patientName']  ?? '',
        counselorUid: m['counselorUid'],
        counselorName: m['counselorName'],
        status:       m['status']       ?? 'waiting',
        createdAt:    m['createdAt']    ?? '',
        startedAt:    m['startedAt'],
        endedAt:      m['endedAt'],
      );


  Map<String, dynamic> toMap() => {

    'patientUid':   patientUid,
    'patientName':  patientName,
    'counselorUid': counselorUid,
    'counselorName': counselorName,
    'status':       status,
    'createdAt':    createdAt,
    'startedAt':    startedAt,
    'endedAt':      endedAt,

  };

  bool get isWaiting => status == 'waiting';
  bool get isActive  => status == 'active';
  bool get isEnded   => status == 'ended';
}