class Appointment {
  final String id;
  final String patientUid;
  final String doctorUid;
  final String patientName;
  final String date;
  final String time;
  final String status; // scheduled, completed, absent, rescheduled  for status
  final String createdAt;

  const Appointment({
    required this.id,
    required this.patientUid,
    required this.doctorUid,
    required this.patientName,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
  });

  factory Appointment.fromMap(String id, Map<String, dynamic> m) => Appointment(
    id: id,
    patientUid: m['patientUid'] ?? '',
    doctorUid: m['doctorUid'] ?? '',
    patientName: m['patientName'] ?? '',
    date: m['date'] ?? '',
    time: m['time'] ?? '',
    status: m['status'] ?? 'scheduled',
    createdAt: m['createdAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'patientUid': patientUid,
    'doctorUid': doctorUid,
    'patientName': patientName,
    'date': date,
    'time': time,
    'status': status,
    'createdAt': createdAt,
  };
}
