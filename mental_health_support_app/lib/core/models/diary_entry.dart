class DiaryEntry {

  final String id;
  final String patientUid;
  final String content;
  final String createdAt;

  const DiaryEntry({

    required this.id,
    required this.patientUid,
    required this.content,
    required this.createdAt,

  });

  factory DiaryEntry.fromMap(String id, Map<String, dynamic> m) => DiaryEntry(

    id:         id,
    patientUid: m['patientUid'] ?? '',
    content:    m['content']    ?? '',
    createdAt:  m['createdAt']  ?? '',

  );

  Map<String, dynamic> toMap() => {

    'patientUid': patientUid,
    'content':    content,
    'createdAt':  createdAt,

  };
}