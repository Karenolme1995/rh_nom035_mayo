import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class Nom035ProfileService {
  static String get baseUrl => AuthService.baseUrl;
  static String get apiBase => '$baseUrl/api/v1';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static dynamic _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      throw Exception('Respuesta no es JSON válido. Body: $body');
    }
  }

  static Map<String, dynamic> _asStringMap(dynamic x) {
    if (x is Map<String, dynamic>) return x;
    if (x is Map) {
      return x.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getProfileStats(int cycleId) async {
    final uri = Uri.parse('$apiBase/nom035/profile-stats?cycle_id=$cycleId');

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    final decoded = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = _asStringMap(decoded);
      if (map.isNotEmpty) return map;
      throw Exception('Respuesta inválida del servidor');
    }

    if (decoded is Map) {
      final err = Map<String, dynamic>.from(decoded);
      throw Exception(err['detail'] ?? 'Error ${response.statusCode}');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
}