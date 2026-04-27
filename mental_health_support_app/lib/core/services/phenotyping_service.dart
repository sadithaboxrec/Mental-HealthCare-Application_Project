import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class PhenotypingService {
  static final _db = FirebaseFirestore.instance;
  static const _sampleLimit = 20;

  static Future<void> recordAppOpen(AppUser user) async {
    if (!user.isPatient) return;

    final now = DateTime.now().toUtc();
    await _db.collection('app_activity_logs').add({
      'patientUid': user.uid,
      'eventType': 'app_open',
      'timestamp': now.toIso8601String(),
      'source': 'flutter_app',
      'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
    });
  }

  static Future<void> recordTypingCadence(
    AppUser user,
    Map<String, dynamic> metrics,
  ) async {
    if (!user.isPatient) return;

    final now = DateTime.now().toUtc();
    await _db.collection('app_activity_logs').add({
      'patientUid': user.uid,
      'eventType': 'typing_cadence',
      'timestamp': now.toIso8601String(),
      'source': 'flutter_app',
      'metrics': metrics,
    });
  }

  static Future<void> collectPreciseGeolocation(AppUser user) async {
    if (!user.isPatient) return;

    final permissionOk = await _ensureLocationPermission();
    if (!permissionOk) {
      await _db.collection('app_activity_logs').add({
        'patientUid': user.uid,
        'eventType': 'coarse_location_unavailable',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'source': 'flutter_app',
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );
    final now = DateTime.now().toUtc();
    final prefs = await SharedPreferences.getInstance();
    final key = 'coarse_location_samples_${user.uid}';
    final samples = _readSamples(prefs, key);
    samples.add(
      _LocationSample(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: now,
        coarseAreaHash: _coarseAreaHash(position.latitude, position.longitude),
      ),
    );
    final trimmed = samples.length > _sampleLimit
        ? samples.sublist(samples.length - _sampleLimit)
        : samples;
    await prefs.setString(
      key,
      jsonEncode(trimmed.map((sample) => sample.toJson()).toList()),
    );

    await _db.collection('geolocations').add({
      'patientUid': user.uid,
      'timestamp': now.toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'mobilityRadius': _mobilityRadiusKm(trimmed),
      'homeStayRatio': _homeStayRatio(trimmed),
      'coarseAreaHash': trimmed.last.coarseAreaHash,
      'sampleCount': trimmed.length,
      'source': 'flutter_app',
    });
  }

  static Future<void> collectStartupSignals(AppUser user) async {
    if (!user.isPatient) return;
    try {
      await recordAppOpen(user);
    } catch (_) {
      return;
    }
    try {
      await collectPreciseGeolocation(user);
    } catch (_) {
      try {
        await _db.collection('app_activity_logs').add({
          'patientUid': user.uid,
          'eventType': 'coarse_location_unavailable',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'source': 'flutter_app',
        });
      } catch (_) {}
    }
  }

  static Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static List<_LocationSample> _readSamples(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => _LocationSample.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _coarseAreaHash(double latitude, double longitude) {
    final latBucket = (latitude * 100).round();
    final lonBucket = (longitude * 100).round();
    return '${latBucket}_$lonBucket';
  }

  static double _mobilityRadiusKm(List<_LocationSample> samples) {
    if (samples.length < 2) return 0;
    final avgLat =
        samples.fold<double>(0, (sum, sample) => sum + sample.latitude) /
        samples.length;
    final avgLon =
        samples.fold<double>(0, (sum, sample) => sum + sample.longitude) /
        samples.length;
    final maxDistance = samples
        .map(
          (sample) =>
              _distanceKm(avgLat, avgLon, sample.latitude, sample.longitude),
        )
        .fold<double>(0, max);
    return double.parse(maxDistance.toStringAsFixed(2));
  }

  static double _homeStayRatio(List<_LocationSample> samples) {
    if (samples.isEmpty) return 0;
    final counts = <String, int>{};
    for (final sample in samples) {
      counts[sample.coarseAreaHash] = (counts[sample.coarseAreaHash] ?? 0) + 1;
    }
    final maxCount = counts.values.fold<int>(0, max);
    return double.parse((maxCount / samples.length).toStringAsFixed(2));
  }

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}

class _LocationSample {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String coarseAreaHash;

  const _LocationSample({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.coarseAreaHash,
  });

  factory _LocationSample.fromJson(Map<String, dynamic> json) {
    return _LocationSample(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'].toString()),
      coarseAreaHash: json['coarseAreaHash'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'coarseAreaHash': coarseAreaHash,
  };
}
