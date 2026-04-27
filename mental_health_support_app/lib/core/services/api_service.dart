/// Central HTTP client configuration for the MindCare backend API.
/// Update [backendBaseUrl] to match the deployed Flask server URL.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  /// Base URL for the Flask backend. Override via environment or build flavour.
  /// For local dev: http://localhost:5000
  /// For production: https://your-backend.com
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:5000',
  );

  static final _client = http.Client();

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(backendBaseUrl);
    return base.replace(path: '${base.path}$path', queryParameters: query);
  }

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

  /// Returns raw bytes (used for PDF download).
  static Future<({List<int> bytes, String contentType})> getBytes(
    String path,
  ) async {
    final res = await _client.get(_uri(path));
    if (res.statusCode == 200) {
      return (
        bytes: res.bodyBytes.toList(),
        contentType: res.headers['content-type'] ?? 'application/octet-stream',
      );
    }
    throw ApiException(res.statusCode, res.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  const ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
