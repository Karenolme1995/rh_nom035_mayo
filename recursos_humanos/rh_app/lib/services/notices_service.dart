import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NoticesService {
  static String get baseUrl => AuthService.baseUrl;
  static String get apiBase => '$baseUrl/api/v1';

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();

    final preview = (token == null || token.isEmpty)
        ? 'NULL'
        : token.substring(0, token.length < 20 ? token.length : 20);

    print('TOKEN => $preview');

    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';

    print('HEADERS => $h');
    return h;
  }

  // ===================== USERS =====================
  Future<List<Map<String, dynamic>>> getUsers() async {
    final uri = Uri.parse('$apiBase/users/');
    final res = await http.get(uri, headers: await _headers()).timeout(
          const Duration(seconds: 10),
        );

    if (res.statusCode != 200) {
      throw Exception('GET /users => ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final list = (decoded as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$apiBase/users/');
    final res = await http
        .post(uri, headers: await _headers(json: true), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST /users => ${res.statusCode} ${res.body}');
    }
  }

  Future<void> updateUser(dynamic id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$apiBase/users/$id');
    final res = await http
        .put(uri, headers: await _headers(json: true), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('PUT /users/$id => ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteUser(dynamic id) async {
    final uri = Uri.parse('$apiBase/users/$id');
    final res = await http.delete(uri, headers: await _headers()).timeout(
          const Duration(seconds: 10),
        );

    if (res.statusCode != 200) {
      throw Exception('DELETE /users/$id => ${res.statusCode} ${res.body}');
    }
  }

  Future<String> uploadUserAvatar(dynamic id, File file) async {
    final uri = Uri.parse('$apiBase/users/$id/avatar');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers());

    req.files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final resp = await req.send().timeout(const Duration(seconds: 20));
    final bodyText = await resp.stream.bytesToString();

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('POST /users/$id/avatar => ${resp.statusCode} $bodyText');
    }

    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map) {
        return (decoded['avatar_url'] ??
                decoded['avatar'] ??
                decoded['url'] ??
                '')
            .toString();
      }
    } catch (_) {}

    return '';
  }

  // ===================== AREAS / POSITIONS =====================
  Future<List<Map<String, dynamic>>> getAreas() async {
    // 👇 usa slash final para estandarizar
    final uri = Uri.parse('$apiBase/areas/');
    final res = await http.get(uri, headers: await _headers()).timeout(
          const Duration(seconds: 10),
        );

    print('GET /areas => ${res.statusCode} ${res.body}');

    if (res.statusCode != 200) {
      // Aquí NO regresamos [] silencioso; queremos ver el error real
      throw Exception('GET /areas => ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final list = decoded is List ? decoded : (decoded['items'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getPositions() async {
    final uri = Uri.parse('$apiBase/positions/');
    final res = await http.get(uri, headers: await _headers()).timeout(
          const Duration(seconds: 10),
        );

    print('GET /positions => ${res.statusCode} ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('GET /positions => ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final list = decoded is List ? decoded : (decoded['items'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
