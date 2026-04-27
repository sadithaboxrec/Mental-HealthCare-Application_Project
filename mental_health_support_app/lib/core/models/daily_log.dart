class DailyLog {
  final String id;
  final String patientUid;
  final String date;
  final int mood;
  final String moodUpdatedAt;
  final int waterIntake;
  final String sleepHours;
  final bool medicationTaken;
  final String createdAt;
  final String updatedAt;

  const DailyLog({
    required this.id,
    required this.patientUid,
    required this.date,
    required this.mood,
    required this.moodUpdatedAt,
    required this.waterIntake,
    required this.sleepHours,
    required this.medicationTaken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyLog.fromMap(String id, Map<String, dynamic> m) => DailyLog(
    id: id,
    patientUid: m['patientUid'] ?? '',
    date: m['date'] ?? '',
    mood: m['mood'] ?? 0,
    moodUpdatedAt: m['moodUpdatedAt'] ?? '',
    waterIntake: m['waterIntake'] ?? 0,
    sleepHours: m['sleepHours'] ?? '',
    medicationTaken: m['medicationTaken'] ?? false,
    createdAt: m['createdAt'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'patientUid': patientUid,
    'date': date,
    'mood': mood,
    'moodUpdatedAt': moodUpdatedAt,
    'waterIntake': waterIntake,
    'sleepHours': sleepHours,
    'medicationTaken': medicationTaken,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
