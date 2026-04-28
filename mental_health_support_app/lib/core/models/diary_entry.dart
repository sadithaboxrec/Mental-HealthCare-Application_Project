import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String id;
  final String patientUid;
  final String content;
  final String createdAt;
  final String? updatedAt;

  const DiaryEntry({
    required this.id,
    required this.patientUid,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromMap(String id, Map<String, dynamic> m) => DiaryEntry(
    id: id,
    patientUid: (m['patientUid'] ?? m['uid'] ?? '').toString(),
    content: _readContent(m),
    createdAt: _normalizeDate(m['createdAt']),
    updatedAt: _normalizeNullableDate(m['updatedAt']),
  );

  DateTime? get createdAtDate => _parseDate(createdAt);

  DateTime? get updatedAtDate =>
      updatedAt == null ? null : _parseDate(updatedAt!);

  String get createdDateKey {
    final parsed = createdAtDate;
    if (parsed == null) {
      return createdAt.length >= 10 ? createdAt.substring(0, 10) : '';
    }

    return _dateKey(parsed);
  }

  String get sortKey {
    final parsed = updatedAtDate ?? createdAtDate;
    if (parsed != null) {
      return parsed.toUtc().toIso8601String();
    }
    final raw = updatedAt ?? createdAt;
    return raw;
  }

  bool get isEdited {
    final updated = updatedAtDate;
    final created = createdAtDate;
    if (updated != null && created != null) {
      return updated.isAfter(created);
    }

    return updatedAt != null && updatedAt!.isNotEmpty && updatedAt != createdAt;
  }

  Map<String, dynamic> toMap() => {
    'patientUid': patientUid,
    'content': content,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  static String _readContent(Map<String, dynamic> m) {
    const fallbackFields = ['content', 'entry', 'entryText', 'text', 'body'];
    for (final field in fallbackFields) {
      final value = m[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static String? _normalizeNullableDate(dynamic value) {
    final normalized = _normalizeDate(value);
    return normalized.isEmpty ? null : normalized;
  }

  static String _normalizeDate(dynamic value) {
    if (value == null) return '';

    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }

    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
        isUtc: true,
      ).toIso8601String();
    }

    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      if (seconds is int) {
        final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
        final milliseconds =
            (seconds * 1000) + ((nanoseconds as int) ~/ 1000000);
        return DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
          isUtc: true,
        ).toIso8601String();
      }
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return '';

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed.toUtc().toIso8601String();
    }

    return raw;
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String _dateKey(DateTime value) {
    final utc = value.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }
}
