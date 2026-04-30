
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  static const _port = 5000;
  static const _healthPath = '/health';
  static const _cacheKey = '_mindcare_backend_url';
  static const _probeTimeout = Duration(seconds: 2);

  static String _baseUrl = 'http://localhost:$_port';
  static bool _initialized = false;

  static final _client = http.Client();

  // ── Public API ──────────────────────────────────────────────────────────

  /// Must be called once before any request (done in main.dart).
  static Future<void> init() async {
    if (_initialized) return;
    _baseUrl = await _discover();
    _initialized = true;
  }

  static String get backendBaseUrl => _baseUrl;

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  static Future<List<dynamic>> getList(
    String path, [
    Map<String, String>? query,
  ]) async {
    final res = await _client.get(_uri(path, query));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  static Future<({List<int> bytes, String contentType})> getBytes(
    String path,
  ) async {
    final res = await _client.get(_uri(path));
    if (res.statusCode == 200) {
      return (
        bytes: res.bodyBytes.toList(),
        contentType:
            res.headers['content-type'] ?? 'application/octet-stream',
      );
    }
    throw ApiException(res.statusCode, res.body);
  }

  // ── Discovery ───────────────────────────────────────────────────────────

  static Future<String> _discover() async {
    // 1. Compile-time override always wins.
    const envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // 2. Android emulator loopback alias.
    if (!kIsWeb && Platform.isAndroid) {
      const emulatorUrl = 'http://10.0.2.2:$_port';
      if (await _isReachable(emulatorUrl)) return emulatorUrl;
    }

    // 3. Localhost (iOS simulator / web / desktop).
    const localUrl = 'http://localhost:$_port';
    if (await _isReachable(localUrl)) return localUrl;

    // 4. Previously discovered and cached URL.
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && await _isReachable(cached)) return cached;
    } catch (_) {}

    // 5. Scan the device's WiFi subnet in parallel.
    if (!kIsWeb) {
      final found = await _scanSubnet();
      if (found != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, found);
        } catch (_) {}
        return found;
      }
    }

    // 6. Fallback — app will show a connection error which is the correct UX.
    return localUrl;
  }

  static Future<String?> _scanSubnet() async {
    String? deviceIp;
    try {
      deviceIp = await NetworkInfo().getWifiIP();
    } catch (_) {}
    if (deviceIp == null) return null;

    final parts = deviceIp.split('.');
    if (parts.length != 4) return null;
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    // Build a candidate list: .1–.20 (routers/servers often get low IPs),
    // the device's own octet neighbourhood, and a few mid-range slots.
    final ownOctet = int.tryParse(parts[3]) ?? 1;
    final candidates = <String>{
      for (int i = 1; i <= 20; i++) '$subnet.$i',
      for (int i = (ownOctet - 5).clamp(1, 254);
          i <= (ownOctet + 5).clamp(1, 254);
          i++)
        '$subnet.$i',
      '$subnet.100',
      '$subnet.101',
      '$subnet.254',
    }..remove('$subnet.$ownOctet'); // skip the device itself

    final results = await Future.wait(
      candidates.map(
        (ip) async {
          final url = 'http://$ip:$_port';
          return (await _isReachable(url)) ? url : null;
        },
      ),
      eagerError: false,
    );

    return results.firstWhere((r) => r != null, orElse: () => null);
  }

  static Future<bool> _isReachable(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl$_healthPath');
      final res = await _client
          .get(uri)
          .timeout(_probeTimeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_baseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: query,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  const ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
